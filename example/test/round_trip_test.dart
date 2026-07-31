import 'dart:io';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genkit/client.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:genui_jaspr_example/interaction.dart';
import 'package:genui_jaspr_example/server/chat_route.dart';
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
    final prompts = <String>[];
    final interactions = <A2uiClientAction>[];

    setUpAll(() async {
      Jaspr.initializeApp(useIsolates: false);

      // A real server on a real port, serving the real route. Only the model is
      // replaced, so everything between the browser and the model is exercised:
      // Genkit's wire format, the parser, and the renderer.
      server = await shelf_io.serve(
        chatRoute((prompt) {
          prompts.add(prompt);
          // Chunked awkwardly on purpose, including a split inside a fence.
          return Stream.fromIterable([
            for (var i = 0; i < reply.length; i += 7)
              reply.substring(i, (i + 7).clamp(0, reply.length)),
          ]);
        }),
        InternetAddress.loopbackIPv4,
        0,
      );
      url = 'http://${server.address.host}:${server.port}/api/chat';
    });

    tearDownAll(() => server.close(force: true));

    /// Runs one turn the way the browser's @client component does.
    Future<({String html, String prose})> turn(String prompt) async {
      final action = defineRemoteAction<String, String, String, void>(
        url: url,
        fromStreamChunk: (json) => json as String,
        fromResponse: (json) => json as String,
      );

      final processor = MessageProcessor<JasprComponent>(
        catalogs: [minimalJasprCatalog()],
      );
      final adapter = A2uiTransportAdapter();
      final prose = StringBuffer();

      adapter.incomingText.listen(prose.write);
      adapter.incomingMessages.listen(
        (message) => processor.processMessages([message]),
      );

      await for (final chunk in action.stream(input: prompt)) {
        adapter.addChunk(chunk);
      }
      await adapter.flush();

      final response = await renderComponent(
        Surface(surface: processor.groupModel.getSurface('s1')!),
        standalone: true,
      );
      adapter.dispose();
      return (
        html: String.fromCharCodes(response.body),
        prose: prose.toString().trim(),
      );
    }

    test('the prompt reaches the server', () async {
      await turn('make me a form');

      expect(prompts, contains('make me a form'));
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

    test('an interaction with the generated UI becomes the next turn', () async {
      // Turn one: the model builds a form.
      final action = defineRemoteAction<String, String, String, void>(
        url: url,
        fromStreamChunk: (json) => json as String,
        fromResponse: (json) => json as String,
      );
      final processor = MessageProcessor<JasprComponent>(
        catalogs: [minimalJasprCatalog()],
        onAction: (a) => interactions.add(a),
      );
      final adapter = A2uiTransportAdapter();
      adapter.incomingMessages.listen(
        (message) => processor.processMessages([message]),
      );

      await for (final chunk in action.stream(input: 'make me a form')) {
        adapter.addChunk(chunk);
      }
      await adapter.flush();
      adapter.dispose();

      final surface = processor.groupModel.getSurface('s1')!;

      // The user fills the field in. A bound input writes straight to the model,
      // so this is what typing leaves behind.
      surface.dataModel.set('/name', 'Ada');

      // The user presses the button the model generated.
      await surface.dispatchAction({
        'event': {'name': 'submit'},
      }, 'send');

      expect(interactions, hasLength(1));

      // Turn two: what the model is told about that interaction.
      final prompt = describeInteraction(
        interactions.single,
        surface.dataModel.get('/'),
      );
      await for (final _ in action.stream(input: prompt)) {}

      expect(prompts.last, contains('submit'));
      expect(
        prompts.last,
        contains('Ada'),
        reason: 'the model must be told what the user entered',
      );
    });
  });
}
