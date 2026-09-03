@TestOn('browser')
library;

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr_test/client_test.dart';
import 'package:universal_web/web.dart' as web;

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
    catalogs: [MinimalJasprCatalog()],
  );
  processor.processMessages([
    A2uiMessage.fromJson({
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': 'main',
        'catalogId': MinimalJasprCatalog.catalogId,
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

    group('a number field', () {
      SurfaceModel<JasprComponent> ageField() => surfaceWith([
        {
          'id': 'root',
          'component': 'TextField',
          'label': 'Age',
          'variant': 'number',
          'value': {'path': '/age'},
        },
      ]);

      testClient('writes a number, not a string', (tester) async {
        final surface = ageField();
        tester.pumpComponent(Surface(surface: surface));

        await tester.input(find.tag('input'), value: '12');

        expect(surface.dataModel.get('/age'), 12);
      });

      testClient('clears the value when the field is emptied', (tester) async {
        final surface = ageField();
        tester.pumpComponent(Surface(surface: surface));

        await tester.input(find.tag('input'), value: '12');
        await tester.input(find.tag('input'), value: '');

        // Not NaN: the data model is sent to the model as JSON, and NaN has no
        // JSON encoding.
        expect(surface.dataModel.get('/age'), isNull);
      });

      testClient('holds nothing while the input is not yet a number', (
        tester,
      ) async {
        final surface = ageField();
        tester.pumpComponent(Surface(surface: surface));

        await tester.input(find.tag('input'), value: '-');

        expect(surface.dataModel.get('/age'), isNull);
      });
    });

    testClient('a long-text field follows the data model after typing', (
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
      await tester.input(find.tag('textarea'), value: 'typed');

      // The model writes to the same path, as an updateDataModel would.
      surface.dataModel.set('/notes', 'from the model');
      await pumpEventQueue();

      final textarea = tester.findNode<web.HTMLTextAreaElement>(
        find.tag('textarea'),
      );
      expect(textarea?.value, 'from the model');
    });

    testClient('a button in a rendered surface dispatches on a real click', (
      tester,
    ) async {
      final actions = <A2uiClientAction>[];
      final processor = MessageProcessor<JasprComponent>(
        catalogs: [MinimalJasprCatalog()],
        onAction: actions.add,
      );
      processor.processMessages([
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': MinimalJasprCatalog.catalogId,
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
