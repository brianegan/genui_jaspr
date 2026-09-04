import 'dart:io';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genkit/genkit.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:genui_jaspr_example/server/chat_agent.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// What a model would reply with, standing in for the model itself.
const reply = '''
Here's a short form.

```json
{"version":"v0.9","createSurface":{"surfaceId":"s1","catalogId":"https://a2ui.org/specification/v0_9/catalogs/minimal/minimal_catalog.json","sendDataModel":true}}
```

```json
{"version":"v0.9","updateComponents":{"surfaceId":"s1","components":[
  {"id":"root","component":"Column","children":["title","name"]},
  {"id":"title","component":"Text","text":"Details","variant":"h3"},
  {"id":"name","component":"TextField","label":"Name","value":{"path":"/name"}}
]}}
```''';

void main() {
  group('the whole round trip over HTTP', () {
    late HttpServer server;
    late String url;

    /// Every request the stand-in model received, so a test can see what the
    /// agent told it: the system prompt, the history, the user's turn.
    final requests = <ModelRequest>[];

    setUpAll(() async {
      Jaspr.initializeApp(useIsolates: false);

      // A real server on a real port, serving the real agent behind the real
      // handler. Only the model is replaced, so everything between the browser
      // and the model is exercised: Genkit's wire format, its sessions, the
      // parser, and the renderer.
      final ai = Genkit(promptDir: null);
      ai.defineModel(
        name: 'canned',
        fn: (request, context) async {
          requests.add(request);
          if (context.streamingRequested) {
            // Chunked awkwardly on purpose, including a split inside a fence.
            for (var i = 0; i < reply.length; i += 7) {
              context.sendChunk(
                ModelResponseChunk(
                  content: [
                    TextPart(
                      text: reply.substring(i, (i + 7).clamp(0, reply.length)),
                    ),
                  ],
                ),
              );
            }
          }
          return ModelResponse(
            message: Message(
              role: Role.model,
              content: [TextPart(text: reply)],
            ),
            finishReason: FinishReason.stop,
          );
        },
      );

      server = await shelf_io.serve(
        chatHandler(chatAgent(ai, model: modelRef('canned'))),
        InternetAddress.loopbackIPv4,
        0,
      );
      url = 'http://${server.address.host}:${server.port}/$chatPath';
    });

    tearDownAll(() => server.close(force: true));

    setUp(requests.clear);

    /// The browser's view of the agent: one chat, its session kept by the
    /// server.
    AgentChat<dynamic> openChat() => remoteAgent(url: url).chat();

    /// The reply to [prompt] as the text chunks the browser feeds the package.
    Stream<String> ask(AgentChat<dynamic> chat, String prompt) =>
        chat.sendStream(text: prompt).stream.map((chunk) => chunk.text);

    /// Runs one turn the way the browser's @client component does.
    Future<({String html, String prose})> turn(String prompt) async {
      final conversation = GenUiConversation(catalogs: [MinimalJasprCatalog()]);
      final List<GenUiEvent> events = await conversation
          .receive(ask(openChat(), prompt))
          .toList();

      final response = await renderComponent(
        Surface(surface: events.whereType<GenUiSurface>().single.surface),
        standalone: true,
      );
      conversation.dispose();
      return (
        html: String.fromCharCodes(response.body),
        prose: events.whereType<GenUiText>().map((e) => e.text).join().trim(),
      );
    }

    /// The text of every message in [request] with [role].
    Iterable<String> textsOf(ModelRequest request, Role role) =>
        request.messages.where((m) => m.role == role).map((m) => m.text);

    test('the prompt reaches the model', () async {
      await turn('make me a form');

      expect(textsOf(requests.single, Role.user), ['make me a form']);
    });

    test('the model is taught the protocol and this catalog', () async {
      await turn('make me a form');

      final String system = textsOf(requests.single, Role.system).join();
      expect(system, contains(MinimalJasprCatalog.catalogId));
      expect(system, contains('"TextField"'));
    });

    test('the reply becomes a rendered surface', () async {
      final result = await turn('make me a form');

      expect(
        result.html,
        contains('<h3 class="a2ui-text a2ui-text--h3">Details</h3>'),
      );
      expect(
        result.html,
        contains('<span class="a2ui-field__label">Name</span>'),
      );
    });

    test('the model\'s prose is kept out of the surface', () async {
      final result = await turn('make me a form');

      expect(result.prose, "Here's a short form.");
      expect(result.html, isNot(contains('short form')));
    });

    test('an interaction with the generated UI becomes the next turn, '
        'with the history that gives it meaning', () async {
      final interactions = <A2uiClientAction>[];
      final conversation = GenUiConversation(catalogs: [MinimalJasprCatalog()]);
      conversation.actions.listen(interactions.add);
      final AgentChat<dynamic> chat = openChat();

      // Turn one: the model builds a form.
      final List<GenUiEvent> events = await conversation
          .receive(ask(chat, 'make me a form'))
          .toList();
      final surface = events.whereType<GenUiSurface>().single.surface;

      // The user fills the field in. A bound input writes straight to the
      // model, so this is what typing leaves behind.
      surface.dataModel.set('/name', 'Ada');

      // The user presses the button the model generated.
      await surface.dispatchAction({
        'event': {'name': 'submit'},
      }, 'send');
      await Future<void>.delayed(Duration.zero);
      expect(interactions, hasLength(1));

      // Turn two: what the model is told about that interaction.
      await ask(
        chat,
        conversation.actionText(interactions.single),
      ).drain<void>();
      conversation.dispose();

      final ModelRequest second = requests.last;
      final String latest = textsOf(second, Role.user).last;
      expect(latest, contains('"name":"submit"'));
      expect(
        latest,
        contains('Ada'),
        reason: 'the model must be told what the user entered',
      );
      // The session carried the first turn along, so the model sees the form
      // it built and can make sense of an action against it.
      expect(textsOf(second, Role.user).first, 'make me a form');
      expect(textsOf(second, Role.model).single, reply);
    });

    test('a new chat starts a new session', () async {
      await turn('first conversation');
      await turn('second conversation');

      expect(textsOf(requests.last, Role.user), ['second conversation']);
    });

    test('the session can be read back and a turn aborted', () async {
      final AgentApi<dynamic> agent = remoteAgent(url: url);
      final AgentChat<dynamic> chat = agent.chat();
      await ask(chat, 'make me a form').drain<void>();

      final snapshot = await agent.getSnapshot(sessionId: chat.sessionId);
      expect(snapshot?.messages.map((m) => m.role), [Role.user, Role.model]);

      // Nothing is running, so there is nothing to abort. What matters is that
      // the route answers rather than falling through to the page.
      await agent.abort(chat.snapshotId!);
    });

    test('anything else under the path is not found', () async {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('$url/nope'));
      final response = await request.close();

      expect(response.statusCode, 404);
      client.close();
    });
  });
}
