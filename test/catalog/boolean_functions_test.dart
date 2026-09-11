import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

final _context = DataContext(DataModel(), (_, _, _) => null, '/');

Object? runFunction(
  FunctionImplementation function,
  Map<String, dynamic> args,
) => function.execute(args, _context);

void main() {
  group('Boolean functions', () {
    test('and matches the pinned API and requires every value to be true', () {
      final function = AndFunction();

      expect(function.name, 'and');
      expect(function.returnType, A2uiReturnType.boolean);
      expect(
        function.argumentSchema.value,
        Schema.object(
          properties: {
            'values': Schema.list(
              items: CommonSchemas.dynamicBoolean,
              minItems: 2,
            ),
          },
          required: ['values'],
          unevaluatedProperties: false,
        ).value,
      );
      expect(
        runFunction(function, {
          'values': [true, true],
        }),
        isTrue,
      );
      expect(
        runFunction(function, {
          'values': [true, false],
        }),
        isFalse,
      );
      expect(
        runFunction(function, {
          'values': [true, 1],
        }),
        isFalse,
      );
      expect(runFunction(function, const {}), isFalse);
    });

    test('or matches the pinned API and requires one true value', () {
      final function = OrFunction();

      expect(function.name, 'or');
      expect(function.returnType, A2uiReturnType.boolean);
      expect(
        function.argumentSchema.value,
        Schema.object(
          properties: {
            'values': Schema.list(
              items: CommonSchemas.dynamicBoolean,
              minItems: 2,
            ),
          },
          required: ['values'],
          unevaluatedProperties: false,
        ).value,
      );
      expect(
        runFunction(function, {
          'values': [false, true],
        }),
        isTrue,
      );
      expect(
        runFunction(function, {
          'values': [false, false],
        }),
        isFalse,
      );
      expect(
        runFunction(function, {
          'values': [false, 1],
        }),
        isFalse,
      );
      expect(runFunction(function, const {}), isFalse);
    });

    test('not matches the pinned API and only negates booleans', () {
      final function = NotFunction();

      expect(function.name, 'not');
      expect(function.returnType, A2uiReturnType.boolean);
      expect(
        function.argumentSchema.value,
        Schema.object(
          properties: {'value': CommonSchemas.dynamicBoolean},
          required: ['value'],
          unevaluatedProperties: false,
        ).value,
      );
      expect(runFunction(function, {'value': true}), isFalse);
      expect(runFunction(function, {'value': false}), isTrue);
      expect(runFunction(function, {'value': null}), isFalse);
      expect(runFunction(function, const {}), isFalse);
    });
  });
}
