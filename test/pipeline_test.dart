import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'support/render.dart';

/// A model's reply: a sentence, then the messages that build a small form.
///
/// Written the way a model writes it, as one text stream with fenced JSON in the
/// middle, rather than as pre-parsed objects.
const modelReply = '''
Sure, here's a quick sign-up form.

```json
{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"https://a2ui.org/specification/v0_9/catalogs/minimal/minimal_catalog.json","theme":{"primaryColor":"#0b57d0"},"sendDataModel":true}}
```

```json
{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[
  {"id":"root","component":"Column","children":["heading","email","submit"],"align":"stretch"},
  {"id":"heading","component":"Text","text":"Sign up","variant":"h2"},
  {"id":"email","component":"TextField","label":"Email","value":{"path":"/email"}},
  {"id":"submit","component":"Button","child":"submitLabel","action":{"event":{"name":"signUp"}}},
  {"id":"submitLabel","component":"Text","text":"Create account"}
]}}
```

Fill that in and press the button.''';

/// Splits [text] into fixed-size pieces, so the seams land mid-token the way a
/// real stream's do.
List<String> chunked(String text, int size) => [
  for (var i = 0; i < text.length; i += size)
    text.substring(i, i + size > text.length ? text.length : i + size),
];

/// Runs a model reply all the way through to a rendered surface.
Future<({String html, String prose})> runPipeline(
  List<String> chunks, {
  void Function(A2uiClientAction)? onAction,
}) async {
  final conversation = GenUiConversation(
    catalogs: [minimalJasprCatalog()],
    onAction: onAction,
  );
  final reply = conversation.receive(Stream.fromIterable(chunks));
  await reply.done;

  final html = await renderHtml(Surface(surface: reply.surfaces.single));
  conversation.dispose();
  return (html: html, prose: reply.text);
}

void main() {
  group('the whole pipeline', () {
    test('turns a streamed model reply into rendered HTML', () async {
      final result = await runPipeline(chunked(modelReply, 17));

      expect(
        normalizeHtml(stripSurface(result.html)),
        '<div class="a2ui-column" style="display: flex; '
        'flex-direction: column; align-items: stretch">'
        '<h2 class="a2ui-text a2ui-text--h2">Sign up</h2>'
        '<label class="a2ui-field">'
        '<span class="a2ui-field__label">Email</span>'
        '<input class="a2ui-field__input" type="text"/>'
        '</label>'
        '<button class="a2ui-button a2ui-button--primary" type="button">'
        '<p class="a2ui-text a2ui-text--body">Create account</p>'
        '</button>'
        '</div>',
      );
    });

    test('keeps the model\'s prose out of the surface', () async {
      final result = await runPipeline(chunked(modelReply, 17));

      // Pieces arrive as the stream delivers them; joining them must give back
      // exactly what the model wrote, whitespace included.
      // The blank lines that surrounded the two fenced blocks survive; the
      // blocks themselves, and the separator between them, do not.
      expect(
        result.prose,
        "Sure, here's a quick sign-up form.\n\n"
        '\n\nFill that in and press the button.',
      );
    });

    test('carries the theme through to the rendered surface', () async {
      final result = await runPipeline(chunked(modelReply, 17));

      expect(result.html, contains('--a2ui-primary-color: #0b57d0'));
    });

    test('produces the same result however the stream is chopped up', () async {
      final sizes = [1, 2, 3, 17, 64, 512, modelReply.length];
      final results = <({String html, String prose})>[];
      for (final size in sizes) {
        results.add(await runPipeline(chunked(modelReply, size)));
      }

      // Chunk size is an accident of the network and must not change what the
      // user ends up seeing. The prose is checked as well as the markup, because
      // a boundary inside a fence marker corrupts the text channel while leaving
      // the surface intact.
      for (var i = 1; i < results.length; i++) {
        expect(
          results[i].html,
          results.first.html,
          reason: 'chunk size ${sizes[i]} rendered different markup',
        );
        expect(
          results[i].prose,
          results.first.prose,
          reason: 'chunk size ${sizes[i]} produced different prose',
        );
      }
    });

    testComponents('a click on the generated button reaches the app', (
      tester,
    ) async {
      final actions = <A2uiClientAction>[];
      final conversation = GenUiConversation(
        catalogs: [minimalJasprCatalog()],
        onAction: actions.add,
      );
      final reply = conversation.receive(
        Stream.fromIterable(chunked(modelReply, 17)),
      );
      await reply.done;

      tester.pumpComponent(Surface(surface: reply.surfaces.single));
      await tester.click(find.tag('button'));

      expect(actions, hasLength(1));
      expect(actions.single.name, 'signUp');
      conversation.dispose();
    });

    testComponents('the surface fills in as the reply streams', (tester) async {
      final conversation = GenUiConversation(catalogs: [minimalJasprCatalog()]);
      // Only enough of the reply to create the surface, not to fill it.
      const upToFirstMessage = 320;
      final chunks = StreamController<String>();
      final reply = conversation.receive(chunks.stream);

      chunks.add(modelReply.substring(0, upToFirstMessage));
      await Future<void>.delayed(Duration.zero);

      tester.pumpComponent(Surface(surface: reply.surfaces.single));
      expect(find.text('Sign up'), findsNothing);

      chunks.add(modelReply.substring(upToFirstMessage));
      await chunks.close();
      await reply.done;
      await tester.pump();

      expect(find.text('Sign up'), findsOneComponent);
      conversation.dispose();
    });
  });
}
