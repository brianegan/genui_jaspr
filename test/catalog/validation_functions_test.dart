import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

final _context = DataContext(DataModel(), (_, _, _) => null, '/');

final _dynamicNumber = Schema.combined(
  description:
      r'REF:common_types.json#/$defs/DynamicNumber|Represents a number',
  anyOf: [
    Schema.number(),
    CommonSchemas.dataBinding,
    CommonSchemas.functionCall,
  ],
);

Object? runFunction(
  FunctionImplementation function,
  Map<String, dynamic> args,
) => function.execute(args, _context);

void main() {
  group('validation functions', () {
    test('required matches the pinned API and rejects empty JSON values', () {
      final function = RequiredFunction();

      expect(function.name, 'required');
      expect(function.returnType, A2uiReturnType.boolean);
      expect(
        function.argumentSchema.value,
        Schema.object(
          properties: {'value': Schema.any()},
          required: ['value'],
          additionalProperties: false,
        ).value,
      );
      expect(runFunction(function, {'value': null}), isFalse);
      expect(runFunction(function, {'value': ''}), isFalse);
      expect(runFunction(function, {'value': <Object?>[]}), isFalse);
      expect(runFunction(function, {'value': <String, Object?>{}}), isFalse);
      expect(runFunction(function, {'value': 'value'}), isTrue);
      expect(runFunction(function, {'value': 0}), isTrue);
      expect(runFunction(function, const {}), isFalse);
    });

    test('regex matches the pinned API and regular expressions', () {
      final function = RegexFunction();

      expect(function.name, 'regex');
      expect(function.returnType, A2uiReturnType.boolean);
      expect(
        function.argumentSchema.value,
        Schema.object(
          properties: {
            'value': CommonSchemas.dynamicString,
            'pattern': Schema.string(),
          },
          required: ['value', 'pattern'],
          unevaluatedProperties: false,
        ).value,
      );
      expect(
        runFunction(function, {'value': 'hello', 'pattern': r'^h.*o$'}),
        isTrue,
      );
      expect(
        runFunction(function, {'value': 'hello', 'pattern': r'^goodbye$'}),
        isFalse,
      );
      expect(
        runFunction(function, {'value': 42, 'pattern': '.*'}),
        isFalse,
      );
      expect(
        () => runFunction(function, {'value': 'x', 'pattern': '['}),
        throwsFormatException,
      );
    });

    test('length matches the pinned API and inclusive bounds', () {
      final function = LengthFunction();
      final objectSchema = Schema.object(
        properties: {
          'value': CommonSchemas.dynamicString,
          'min': Schema.integer(minimum: 0),
          'max': Schema.integer(minimum: 0),
        },
        required: ['value'],
        unevaluatedProperties: false,
      );

      expect(function.name, 'length');
      expect(function.returnType, A2uiReturnType.boolean);
      expect(
        function.argumentSchema.value,
        {
          ...objectSchema.value,
          'anyOf': [
            Schema.object(required: ['min']).value,
            Schema.object(required: ['max']).value,
          ],
        },
      );
      expect(runFunction(function, {'value': 'abc', 'min': 3}), isTrue);
      expect(runFunction(function, {'value': 'abc', 'max': 3}), isTrue);
      expect(
        runFunction(function, {'value': 'abc', 'min': 4, 'max': 8}),
        isFalse,
      );
      expect(
        runFunction(function, {'value': 'abcdef', 'min': 2, 'max': 5}),
        isFalse,
      );
      expect(runFunction(function, {'value': 3, 'min': 1}), isFalse);
      expect(runFunction(function, {'value': 'abc'}), isFalse);
    });

    test('numeric matches the pinned API and inclusive bounds', () {
      final function = NumericFunction();
      final objectSchema = Schema.object(
        properties: {
          'value': _dynamicNumber,
          'min': Schema.number(),
          'max': Schema.number(),
        },
        required: ['value'],
        unevaluatedProperties: false,
      );

      expect(function.name, 'numeric');
      expect(function.returnType, A2uiReturnType.boolean);
      expect(
        function.argumentSchema.value,
        {
          ...objectSchema.value,
          'anyOf': [
            Schema.object(required: ['min']).value,
            Schema.object(required: ['max']).value,
          ],
        },
      );
      expect(runFunction(function, {'value': 2, 'min': 2}), isTrue);
      expect(runFunction(function, {'value': 4.5, 'max': 4.5}), isTrue);
      expect(
        runFunction(function, {'value': 2, 'min': 3, 'max': 5}),
        isFalse,
      );
      expect(
        runFunction(function, {'value': 6, 'min': 3, 'max': 5}),
        isFalse,
      );
      expect(runFunction(function, {'value': '4', 'min': 3}), isFalse);
      expect(runFunction(function, {'value': 4}), isFalse);
    });

    test('email matches the pinned API and common address forms', () {
      final function = EmailFunction();

      expect(function.name, 'email');
      expect(function.returnType, A2uiReturnType.boolean);
      expect(
        function.argumentSchema.value,
        Schema.object(
          properties: {'value': CommonSchemas.dynamicString},
          required: ['value'],
          unevaluatedProperties: false,
        ).value,
      );
      expect(
        runFunction(function, {'value': 'ada.lovelace+math@example.co.uk'}),
        isTrue,
      );
      expect(runFunction(function, {'value': 'ada.example.com'}), isFalse);
      expect(runFunction(function, {'value': '@example.com'}), isFalse);
      expect(runFunction(function, {'value': 'ada@example'}), isFalse);
      expect(runFunction(function, {'value': 'ada @example.com'}), isFalse);
      expect(runFunction(function, {'value': null}), isFalse);
    });
  });
}
