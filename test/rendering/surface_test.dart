import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../support/render.dart';
import '../support/test_catalog.dart';

void main() {
  group('Surface', () {
    test('renders a nested component tree', () async {
      final processor = MessageProcessor<JasprComponent>(
        catalogs: [buildTestCatalog()],
      );
      processor.processMessages(
        surfaceMessages(
          components: [
            {
              'id': 'root',
              'component': 'Column',
              'children': ['greeting', 'names'],
            },
            {'id': 'greeting', 'component': 'Text', 'text': 'Hello'},
            {
              'id': 'names',
              'component': 'Row',
              'children': ['first', 'second'],
            },
            {'id': 'first', 'component': 'Text', 'text': 'Ada'},
            {'id': 'second', 'component': 'Text', 'text': 'Grace'},
          ],
        ),
      );

      final html = stripSurface(
        await renderHtml(
          Surface(surface: processor.groupModel.getSurface('main')!),
        ),
      );

      expect(
        html,
        '<div class="col">'
        '<span>Hello</span>'
        '<div class="row"><span>Ada</span><span>Grace</span></div>'
        '</div>',
      );
    });

    test(
      'renders a fallback for an unknown component, keeping its siblings',
      () async {
        final processor = MessageProcessor<JasprComponent>(
          catalogs: [buildTestCatalog()],
        );
        processor.processMessages(
          surfaceMessages(
            components: [
              {
                'id': 'root',
                'component': 'Column',
                'children': ['mystery', 'after'],
              },
              {'id': 'mystery', 'component': 'HoloDeck'},
              {'id': 'after', 'component': 'Text', 'text': 'still here'},
            ],
          ),
        );

        final html = stripSurface(
          await renderHtml(
            Surface(surface: processor.groupModel.getSurface('main')!),
          ),
        );

        // Assert the fallback's own markup, not just its message. A crash would
        // put the same words on the page via Jaspr's error output.
        expect(
          html,
          contains(
            '<div class="a2ui-missing" role="alert">'
            'Unknown component "HoloDeck".</div>',
          ),
        );
        expect(html, contains('<span>still here</span>'));
      },
    );

    test('renders nothing until its root component exists', () async {
      final processor = MessageProcessor<JasprComponent>(
        catalogs: [buildTestCatalog()],
      );
      processor.processMessages([
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': testCatalogId,
            'sendDataModel': true,
          },
        }),
      ]);

      final html = stripSurface(
        await renderHtml(
          Surface(surface: processor.groupModel.getSurface('main')!),
        ),
      );

      expect(html, isEmpty);
    });

    testComponents('appears when its components arrive after mounting', (
      tester,
    ) async {
      final processor = MessageProcessor<JasprComponent>(
        catalogs: [buildTestCatalog()],
      );
      processor.processMessages([
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': testCatalogId,
            'sendDataModel': true,
          },
        }),
      ]);
      final surface = processor.groupModel.getSurface('main')!;

      tester.pumpComponent(Surface(surface: surface));
      expect(find.text('Hello'), findsNothing);

      // A response streams in: createSurface first, components after.
      processor.processMessages([
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': 'main',
            'components': [
              {'id': 'root', 'component': 'Text', 'text': 'Hello'},
            ],
          },
        }),
      ]);
      await tester.pump();

      expect(find.text('Hello'), findsOneComponent);
    });
  });
}
