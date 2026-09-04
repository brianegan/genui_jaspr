import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../support/harness.dart';

/// A button whose action calls a function the catalog does not have.
List<Map<String, dynamic>> brokenButton() => [
  {
    'id': 'root',
    'component': 'Button',
    'child': 'label',
    'action': {
      'functionCall': {'call': 'noSuchFunction', 'args': <String, Object?>{}},
    },
  },
  {'id': 'label', 'component': 'Text', 'text': 'Send'},
];

void main() {
  group('ComponentScope.action', () {
    testComponents('reports a failing action instead of throwing', (
      tester,
    ) async {
      final errors = <A2uiClientError>[];
      final surface = buildSurfaceModel(brokenButton());
      surface.onError.addListener(errors.add);

      tester.pumpComponent(surfaceComponent(surface));
      // A throw here would escape the click handler and fail the test.
      await tester.click(find.tag('button'));
      await tester.pump();

      expect(errors, hasLength(1));
      expect(errors.single.surfaceId, 'main');
      expect(errors.single.code, 'INTERNAL_ERROR');
      expect(errors.single.message, contains('noSuchFunction'));
    });

    testComponents('is null for a property that is not an action', (
      tester,
    ) async {
      final captured = await captureScope(tester, MinimalTextApi(), [
        {'id': 'root', 'component': 'Text', 'text': 'hi'},
      ]);

      expect(captured.scope.action('text'), isNull);
    });
  });

  group('ComponentScope.reportError', () {
    testComponents('hands an error to the surface', (tester) async {
      final errors = <A2uiClientError>[];
      final captured = await captureScope(tester, MinimalTextApi(), [
        {'id': 'root', 'component': 'Text', 'text': 'hi'},
      ]);
      captured.surface.onError.addListener(errors.add);

      captured.scope.reportError(A2uiDataError('bad path', path: '/x'));

      expect(errors.single.code, 'DATA_ERROR');
      expect(errors.single.surfaceId, 'main');
      expect(errors.single.details, {'path': '/x'});
    });
  });

  group('ComponentScope.children', () {
    testComponents('reads the children property by default', (tester) async {
      final captured = await captureScope(tester, MinimalColumnApi(), [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['a', 'b'],
        },
      ]);

      expect(captured.scope.children(), hasLength(2));
      expect(captured.scope.children('nothing'), isEmpty);
    });
  });
}
