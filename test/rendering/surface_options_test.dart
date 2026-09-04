import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../support/render.dart';
import '../support/test_catalog.dart';

SurfaceModel<JasprComponent> _surface(List<Map<String, dynamic>> components) {
  final processor = MessageProcessor<JasprComponent>(
    catalogs: [buildTestCatalog()],
  );
  if (components.isEmpty) {
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
  } else {
    processor.processMessages(surfaceMessages(components: components));
  }
  return processor.groupModel.getSurface('main')!;
}

void main() {
  group('Surface.placeholder', () {
    test('shows while the surface has no root component', () async {
      final html = stripSurface(
        await renderHtml(
          Surface(
            surface: _surface(const []),
            placeholder: (context) =>
                p([Component.text('Thinking')], classes: 'wait'),
          ),
        ),
      );

      expect(html, '<p class="wait">Thinking</p>');
    });

    test('gives way to the tree once the root exists', () async {
      final html = stripSurface(
        await renderHtml(
          Surface(
            surface: _surface([
              {'id': 'root', 'component': 'Text', 'text': 'Ready'},
            ]),
            placeholder: (context) => p([Component.text('Thinking')]),
          ),
        ),
      );

      expect(html, '<span>Ready</span>');
    });

    testComponents('is replaced as soon as the components arrive', (
      tester,
    ) async {
      final surface = _surface(const []);
      tester.pumpComponent(
        Surface(
          surface: surface,
          placeholder: (context) => p([Component.text('Thinking')]),
        ),
      );
      expect(find.text('Thinking'), findsOneComponent);

      surface.componentsModel.addComponent(
        ComponentModel('root', 'Text', {'text': 'Ready'}),
      );
      await tester.pump();

      expect(find.text('Thinking'), findsNothing);
      expect(find.text('Ready'), findsOneComponent);
    });
  });

  group('Surface.fallback', () {
    test('replaces the notice for an unknown component', () async {
      final html = stripSurface(
        await renderHtml(
          Surface(
            surface: _surface([
              {
                'id': 'root',
                'component': 'Column',
                'children': ['mystery', 'after'],
              },
              {'id': 'mystery', 'component': 'HoloDeck'},
              {'id': 'after', 'component': 'Text', 'text': 'still here'},
            ]),
            fallback: (context, message) =>
                span([Component.text(message)], classes: 'gap'),
          ),
        ),
      );

      expect(
        html,
        '<div class="col">'
        '<span class="gap">Unknown component "HoloDeck".</span>'
        '<span>still here</span>'
        '</div>',
      );
    });

    test('replaces the notice for a missing child, however deep', () async {
      final html = stripSurface(
        await renderHtml(
          Surface(
            surface: _surface([
              {
                'id': 'root',
                'component': 'Column',
                'children': ['inner'],
              },
              {
                'id': 'inner',
                'component': 'Row',
                'children': ['ghost'],
              },
            ]),
            // An empty component hides the gap entirely.
            fallback: (context, message) => const Component.empty(),
          ),
        ),
      );

      expect(html, '<div class="col"><div class="row"></div></div>');
    });
  });
}
