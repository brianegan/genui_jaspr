@TestOn('browser')
library;

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:genui_jaspr/src/catalog/basic/components/choice_picker.dart';
import 'package:jaspr_test/client_test.dart';

/// The hop a VM test cannot reach: a real click on a real radio or checkbox
/// reaching the data model.
SurfaceModel<JasprComponent> surfaceWith(
  List<Map<String, dynamic>> components, {
  Map<String, Object?> data = const {},
}) {
  final catalog = MinimalJasprCatalog().copyWith(
    add: [ChoicePickerComponent()],
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

List<Map<String, dynamic>> pickerSurface(Map<String, dynamic> extra) => [
  {
    'id': 'root',
    'component': 'ChoicePicker',
    'options': [
      {'label': 'Red', 'value': 'red'},
      {'label': 'Blue', 'value': 'blue'},
    ],
    ...extra,
  },
];

void main() {
  group('ChoicePicker in a browser', () {
    testClient('picking a radio writes its value through', (tester) async {
      final surface = surfaceWith(
        pickerSurface({
          'variant': 'mutuallyExclusive',
          'value': {'path': '/colour'},
        }),
        data: {'/colour': 'red'},
      );

      tester.pumpComponent(Surface(surface: surface));

      await tester.click(find.tag('input').at(1));

      expect(surface.dataModel.get('/colour'), 'blue');
    });

    testClient('checking a box adds its value to the list', (tester) async {
      final surface = surfaceWith(
        pickerSurface({
          'variant': 'multipleSelection',
          'value': {'path': '/colours'},
        }),
        data: {
          '/colours': ['red'],
        },
      );

      tester.pumpComponent(Surface(surface: surface));

      await tester.click(find.tag('input').at(1));

      expect(surface.dataModel.get('/colours'), ['red', 'blue']);
    });

    testClient('unchecking a box removes its value from the list', (
      tester,
    ) async {
      final surface = surfaceWith(
        pickerSurface({
          'variant': 'multipleSelection',
          'value': {'path': '/colours'},
        }),
        data: {
          '/colours': ['red', 'blue'],
        },
      );

      tester.pumpComponent(Surface(surface: surface));

      await tester.click(find.tag('input').at(0));

      expect(surface.dataModel.get('/colours'), ['blue']);
    });
  });
}
