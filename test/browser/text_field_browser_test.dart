@TestOn('browser')
library;

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr_test/client_test.dart';

/// The hop a VM test cannot reach: a real keystroke in a real input element
/// reaching the data model.
///
/// A VM test can only call the setter the renderer hands the builder, which
/// leaves the wiring between the DOM event and that setter untested. Removing
/// `onInput` from the field passes every VM test, so this is the only place that
/// notices.
SurfaceModel<JasprComponent> surfaceWith(
  List<Map<String, dynamic>> components, {
  Map<String, Object?> data = const {},
}) {
  final processor = MessageProcessor<JasprComponent>(
    catalogs: [minimalJasprCatalog()],
  );
  processor.processMessages([
    A2uiMessage.fromJson({
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': 'main',
        'catalogId': minimalJasprCatalogId,
        'sendDataModel': true,
      },
    }),
    A2uiMessage.fromJson({
      'version': 'v0.9',
      'updateComponents': {'surfaceId': 'main', 'components': components},
    }),
  ]);
  final surface = processor.groupModel.getSurface('main')!;
  data.forEach(surface.dataModel.set);
  return surface;
}

void main() {
  group('TextField in a browser', () {
    testClient('typing writes through to the data model', (tester) async {
      final surface = surfaceWith(
        [
          {
            'id': 'root',
            'component': 'TextField',
            'label': 'Name',
            'value': {'path': '/name'},
          },
        ],
        data: {'/name': 'Ada'},
      );

      tester.pumpComponent(Surface(surface: surface));

      await tester.input(find.tag('input'), value: 'Grace');

      expect(surface.dataModel.get('/name'), 'Grace');
    });

    testClient('typing in a long-text field writes through as well', (
      tester,
    ) async {
      final surface = surfaceWith(
        [
          {
            'id': 'root',
            'component': 'TextField',
            'label': 'Notes',
            'variant': 'longText',
            'value': {'path': '/notes'},
          },
        ],
        data: {'/notes': 'before'},
      );

      tester.pumpComponent(Surface(surface: surface));

      await tester.input(find.tag('textarea'), value: 'after');

      expect(surface.dataModel.get('/notes'), 'after');
    });

    testClient('what the user types drives a binding elsewhere', (
      tester,
    ) async {
      // The point of writing to the model rather than to local state: another
      // component bound to the same path follows along.
      final surface = surfaceWith(
        [
          {
            'id': 'root',
            'component': 'Column',
            'children': ['field', 'echo'],
          },
          {
            'id': 'field',
            'component': 'TextField',
            'label': 'Name',
            'value': {'path': '/name'},
          },
          {
            'id': 'echo',
            'component': 'Text',
            'text': {'path': '/name'},
          },
        ],
        data: {'/name': 'Ada'},
      );

      tester.pumpComponent(Surface(surface: surface));
      expect(find.text('Ada'), findsOneComponent);

      await tester.input(find.tag('input'), value: 'Grace');

      expect(find.text('Grace'), findsOneComponent);
      expect(find.text('Ada'), findsNothing);
    });

    testClient('a button in a rendered surface dispatches on a real click', (
      tester,
    ) async {
      final actions = <A2uiClientAction>[];
      final processor = MessageProcessor<JasprComponent>(
        catalogs: [minimalJasprCatalog()],
        onAction: actions.add,
      );
      processor.processMessages([
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': minimalJasprCatalogId,
            'sendDataModel': true,
          },
        }),
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': 'main',
            'components': [
              {
                'id': 'root',
                'component': 'Button',
                'child': 'label',
                'action': {
                  'event': {'name': 'submit'},
                },
              },
              {'id': 'label', 'component': 'Text', 'text': 'Send'},
            ],
          },
        }),
      ]);

      tester.pumpComponent(
        Surface(surface: processor.groupModel.getSurface('main')!),
      );

      await tester.click(find.tag('button'));

      expect(actions.map((action) => action.name), ['submit']);
    });
  });
}
