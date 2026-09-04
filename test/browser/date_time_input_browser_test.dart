@TestOn('browser')
library;

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:genui_jaspr/src/catalog/components/date_time_input.dart';
import 'package:jaspr_test/client_test.dart';

/// The hop a VM test cannot reach: a real value entered into a real date or
/// time input, which the browser reports back as a `DateTime`, reaching the
/// data model as the ISO string the schema binds.
SurfaceModel<JasprComponent> surfaceWith(
  List<Map<String, dynamic>> components, {
  Map<String, Object?> data = const {},
}) {
  final catalog = MinimalJasprCatalog().copyWith(
    add: [DateTimeInputComponent()],
  );
  final processor = MessageProcessor<JasprComponent>(catalogs: [catalog])
    ..processMessages([
      A2uiMessage.fromJson({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'main',
          'catalogId': catalog.id,
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
  group('DateTimeInput in a browser', () {
    testClient('picking a date writes the ISO date string through', (
      tester,
    ) async {
      final surface = surfaceWith(
        [
          {
            'id': 'root',
            'component': 'DateTimeInput',
            'label': 'Birthday',
            'value': {'path': '/birthday'},
          },
        ],
        data: {'/birthday': '2024-01-01'},
      );

      tester.pumpComponent(Surface(surface: surface));

      await tester.input(find.tag('input'), value: '2024-06-15');

      expect(surface.dataModel.get('/birthday'), '2024-06-15');
    });

    testClient('picking a time writes the HH:mm string through', (
      tester,
    ) async {
      final surface = surfaceWith(
        [
          {
            'id': 'root',
            'component': 'DateTimeInput',
            'label': 'Alarm',
            'variant': 'time',
            'value': {'path': '/alarm'},
          },
        ],
        data: {'/alarm': '08:00'},
      );

      tester.pumpComponent(Surface(surface: surface));

      await tester.input(find.tag('input'), value: '14:30');

      expect(surface.dataModel.get('/alarm'), '14:30');
    });

    testClient(
      'picking a date and time writes the combined string through',
      (tester) async {
        final surface = surfaceWith(
          [
            {
              'id': 'root',
              'component': 'DateTimeInput',
              'label': 'Appointment',
              'variant': 'datetime',
              'value': {'path': '/appointment'},
            },
          ],
          data: {'/appointment': '2024-01-01T08:00'},
        );

        tester.pumpComponent(Surface(surface: surface));

        await tester.input(find.tag('input'), value: '2024-06-15T14:30');

        expect(
          surface.dataModel.get('/appointment'),
          '2024-06-15T14:30',
        );
      },
    );
  });
}
