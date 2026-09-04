import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:test/test.dart';

void main() {
  group('a2uiActionMessage', () {
    test("wraps the action in the protocol's envelope", () {
      final action = A2uiClientAction(
        name: 'submit',
        surfaceId: 's1',
        sourceComponentId: 'send',
        timestamp: DateTime.utc(2026, 9, 2, 12),
        context: {'choice': 'blue'},
      );

      expect(a2uiActionMessage(action), {
        'version': 'v0.9',
        'action': {
          'name': 'submit',
          'surfaceId': 's1',
          'sourceComponentId': 'send',
          'timestamp': '2026-09-02T12:00:00.000Z',
          'context': {'choice': 'blue'},
        },
      });
    });
  });

  group('a2uiErrorMessage', () {
    test("wraps the error in the protocol's envelope", () {
      final error = A2uiClientError(
        code: 'VALIDATION_ERROR',
        surfaceId: 's1',
        message: 'Component missing an id.',
      );

      expect(a2uiErrorMessage(error), {
        'version': 'v0.9',
        'error': {
          'code': 'VALIDATION_ERROR',
          'surfaceId': 's1',
          'message': 'Component missing an id.',
        },
      });
    });
  });

  group('clientErrorFrom', () {
    test('passes a client error through unchanged', () {
      final error = A2uiClientError(code: 'X', surfaceId: 's1', message: 'm');

      expect(clientErrorFrom(error), same(error));
    });

    test('keeps the code and details of a runtime error', () {
      final error = clientErrorFrom(
        A2uiValidationError('bad', details: {'id': 1}),
        surfaceId: 's1',
      );

      expect(error.code, 'VALIDATION_ERROR');
      expect(error.surfaceId, 's1');
      expect(error.message, 'bad');
      expect(error.details, {'id': 1});
    });

    test('reports the path of a data error', () {
      final error = clientErrorFrom(A2uiDataError('oops', path: '/a/b'));

      expect(error.code, 'DATA_ERROR');
      expect(error.details, {'path': '/a/b'});
    });

    test('has no details for a runtime error without any', () {
      expect(clientErrorFrom(A2uiStateError('gone')).details, isNull);
    });

    test('treats a message the parser rejected as a validation error', () {
      final error = clientErrorFrom(
        A2uiValidationException(
          'no version',
          json: <String, Object?>{'createSurface': {}},
        ),
      );

      expect(error.code, 'VALIDATION_ERROR');
      expect(error.message, 'no version');
      expect(error.details, {'createSurface': <String, Object?>{}});
    });

    test('describes anything else as an internal error', () {
      final error = clientErrorFrom(StateError('boom'));

      expect(error.code, 'INTERNAL_ERROR');
      expect(error.message, contains('boom'));
      expect(error.surfaceId, '');
    });
  });
}
