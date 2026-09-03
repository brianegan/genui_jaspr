@TestOn('browser')
library;

import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:genui_jaspr_example/chat.dart';
import 'package:jaspr_test/client_test.dart';

/// A model reply carrying one A2UI message, fenced the way the parser expects.
String fenced(String json) => '```json\n$json\n```\n';

void main() {
  group('ChatView in a browser', () {
    testClient('typing and sending renders the streamed reply', (tester) async {
      final prompts = <String>[];
      tester.pumpComponent(
        ChatView(
          send: (prompt) {
            prompts.add(prompt);
            return Stream.fromIterable(['Hello ', 'there']);
          },
        ),
      );

      await tester.input(find.tag('input'), value: 'hi');
      await tester.click(find.tag('button'));

      expect(prompts, ['hi']);
      expect(find.text('Hello there'), findsOneComponent);
    });

    testClient('a click in a generated surface becomes the next turn', (
      tester,
    ) async {
      final prompts = <String>[];
      tester.pumpComponent(
        ChatView(
          send: (prompt) {
            prompts.add(prompt);
            if (prompts.length > 1) {
              return Stream.fromIterable(['Done.']);
            }
            return Stream.fromIterable([
              'Here you go.\n',
              fenced(
                '{"version":"v0.9","createSurface":{"surfaceId":"s",'
                '"catalogId":"$minimalJasprCatalogId","sendDataModel":true}}',
              ),
              fenced(
                '{"version":"v0.9","updateComponents":{"surfaceId":"s",'
                '"components":['
                '{"id":"root","component":"Button","child":"label",'
                '"action":{"event":{"name":"submit"}}},'
                '{"id":"label","component":"Text","text":"Do it"}]}}',
              ),
            ]);
          },
        ),
      );

      await tester.input(find.tag('input'), value: 'make a button');
      await tester.click(find.tag('button'));

      expect(find.text('Do it'), findsOneComponent);

      await tester.click(
        find.ancestor(of: find.text('Do it'), matching: find.tag('button')),
      );

      // The interaction reaches the model as the protocol's action message.
      expect(prompts, hasLength(2));
      expect(prompts.first, 'make a button');
      expect(prompts.last, contains('"action"'));
      expect(prompts.last, contains('"name":"submit"'));
      expect(find.text('Submitted "submit"'), findsOneComponent);
      expect(find.text('Done.'), findsOneComponent);
    });

    testClient('a message the model got wrong is shown in its turn', (
      tester,
    ) async {
      tester.pumpComponent(
        ChatView(
          send: (prompt) => Stream.fromIterable([
            'Trying.\n',
            fenced('{"version":"v0.8","createSurface":{"surfaceId":"s"}}'),
          ]),
        ),
      );

      await tester.input(find.tag('input'), value: 'anything');
      await tester.click(find.tag('button'));

      expect(find.textContaining('Trying.'), findsOneComponent);
      expect(find.textContaining('v0.9'), findsOneComponent);
    });

    testClient('a failing request is reported, not rendered as a turn', (
      tester,
    ) async {
      tester.pumpComponent(
        ChatView(
          send: (prompt) =>
              Stream<String>.error(StateError('model unavailable')),
        ),
      );

      await tester.input(find.tag('input'), value: 'hi');
      await tester.click(find.tag('button'));

      expect(find.textContaining('model unavailable'), findsOneComponent);
      // The user's own turn stays; the failed reply leaves no empty bubble.
      expect(find.text('hi'), findsOneComponent);
      expect(find.byType(Surface), findsNothing);
    });
  });
}
