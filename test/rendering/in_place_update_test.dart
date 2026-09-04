import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../support/harness.dart';

/// Revising a surface that is already on screen.
///
/// A2UI has no `updateSurface` message. A model changes a live surface by
/// sending `updateComponents` again with the same `surfaceId`, or by writing
/// to the data model. These cover both.
A2uiMessage updateComponents(List<Map<String, dynamic>> components) {
  return A2uiMessage.fromJson({
    'version': 'v0.9',
    'updateComponents': {'surfaceId': 'main', 'components': components},
  });
}

/// A live surface plus the processor that can send it more messages.
({
  SurfaceModel<JasprComponent> surface,
  MessageProcessor<JasprComponent> processor,
})
start(
  List<Map<String, dynamic>> components, {
  Map<String, Object?> data = const {},
}) {
  final processor =
      MessageProcessor<JasprComponent>(
        catalogs: [MinimalJasprCatalog()],
      )..processMessages([
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': MinimalJasprCatalog.catalogId,
            'sendDataModel': true,
          },
        }),
        updateComponents(components),
      ]);
  final surface = processor.groupModel.getSurface('main')!;
  data.forEach(surface.dataModel.set);
  return (surface: surface, processor: processor);
}

void main() {
  group('revising a live surface', () {
    testComponents("changes a component's properties in place", (
      tester,
    ) async {
      final app = start([
        {'id': 'root', 'component': 'Text', 'text': 'before'},
      ]);

      tester.pumpComponent(surfaceComponent(app.surface));
      expect(find.text('before'), findsOneComponent);

      app.processor.processMessages([
        updateComponents([
          {'id': 'root', 'component': 'Text', 'text': 'after'},
        ]),
      ]);
      await tester.pump();

      expect(find.text('after'), findsOneComponent);
      expect(find.text('before'), findsNothing);
    });

    testComponents('adds a child to a tree already on screen', (tester) async {
      final app = start([
        {
          'id': 'root',
          'component': 'Column',
          'children': ['first'],
        },
        {'id': 'first', 'component': 'Text', 'text': 'first'},
      ]);

      tester.pumpComponent(surfaceComponent(app.surface));
      expect(find.text('second'), findsNothing);

      app.processor.processMessages([
        updateComponents([
          {
            'id': 'root',
            'component': 'Column',
            'children': ['first', 'second'],
          },
          {'id': 'second', 'component': 'Text', 'text': 'second'},
        ]),
      ]);
      await tester.pump();

      expect(find.text('first'), findsOneComponent);
      expect(find.text('second'), findsOneComponent);
    });

    testComponents('swaps a component for a different type', (tester) async {
      final app = start([
        {
          'id': 'root',
          'component': 'Column',
          'children': ['slot'],
        },
        {'id': 'slot', 'component': 'Text', 'text': 'was text'},
      ]);

      tester.pumpComponent(surfaceComponent(app.surface));
      expect(find.tag('button'), findsNothing);

      app.processor.processMessages([
        updateComponents([
          {
            'id': 'slot',
            'component': 'Button',
            'child': 'label',
            'action': {
              'event': {'name': 'go'},
            },
          },
          {'id': 'label', 'component': 'Text', 'text': 'now a button'},
        ]),
      ]);
      await tester.pump();

      expect(find.tag('button'), findsOneComponent);
      expect(find.text('now a button'), findsOneComponent);
    });

    testComponents('writes to the data model without resending components', (
      tester,
    ) async {
      final app = start(
        [
          {
            'id': 'root',
            'component': 'Text',
            'text': {'path': '/greeting'},
          },
        ],
        data: {'/greeting': 'hello'},
      );

      tester.pumpComponent(surfaceComponent(app.surface));
      expect(find.text('hello'), findsOneComponent);

      app.processor.processMessages([
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'updateDataModel': {
            'surfaceId': 'main',
            'path': '/greeting',
            'value': 'goodbye',
          },
        }),
      ]);
      await tester.pump();

      expect(find.text('goodbye'), findsOneComponent);
      expect(find.text('hello'), findsNothing);
    });
  });
}
