import 'package:a2ui_core/a2ui_core.dart' hide FormatStringFunction;
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

final _dynamicValue = Schema.combined(
  description:
      r'REF:common_types.json#/$defs/DynamicValue|Represents any JSON value',
  anyOf: [
    Schema.string(),
    Schema.number(),
    Schema.boolean(),
    Schema.list(),
    CommonSchemas.dataBinding,
    CommonSchemas.functionCall,
  ],
);

Object? runFunction(
  FunctionImplementation function,
  Map<String, dynamic> args,
) => function.execute(args, _context);

void main() {
  group('format functions', () {
    test('formatNumber matches the pinned API and locale formatting', () {
      final function = FormatNumberFunction(locale: 'en_US');

      expect(function.name, 'formatNumber');
      expect(function.returnType, A2uiReturnType.string);
      expect(
        function.argumentSchema.value,
        Schema.object(
          properties: {
            'value': _dynamicNumber,
            'decimals': _dynamicNumber,
            'grouping': CommonSchemas.dynamicBoolean,
          },
          required: ['value'],
          unevaluatedProperties: false,
        ).value,
      );
      expect(
        runFunction(function, {
          'value': 1234.5,
          'decimals': 2,
          'grouping': true,
        }),
        '1,234.50',
      );
      expect(
        runFunction(function, {
          'value': 1234.5,
          'decimals': 2,
          'grouping': false,
        }),
        '1234.50',
      );
      expect(runFunction(function, {'value': '12'}), '12');
      expect(runFunction(function, {'value': null}), '');
    });

    test('formatCurrency matches the pinned API and currency metadata', () {
      final function = FormatCurrencyFunction(locale: 'en_US');

      expect(function.name, 'formatCurrency');
      expect(function.returnType, A2uiReturnType.string);
      expect(
        function.argumentSchema.value,
        Schema.object(
          properties: {
            'value': _dynamicNumber,
            'currency': CommonSchemas.dynamicString,
            'decimals': _dynamicNumber,
            'grouping': CommonSchemas.dynamicBoolean,
          },
          required: ['currency', 'value'],
          unevaluatedProperties: false,
        ).value,
      );
      expect(
        runFunction(function, {'value': 1234.5, 'currency': 'USD'}),
        r'$1,234.50',
      );
      expect(
        runFunction(function, {
          'value': 1234.5,
          'currency': 'USD',
          'decimals': 0,
        }),
        r'$1,235',
      );
      expect(
        runFunction(function, {
          'value': 1234.5,
          'currency': 'USD',
          'grouping': false,
        }),
        r'$1234.50',
      );
      expect(
        runFunction(function, {'value': 12, 'currency': null}),
        '12',
      );
    });

    test('formatDate matches the pinned API and Unicode date patterns', () {
      final function = FormatDateFunction(locale: 'en_US');

      expect(function.name, 'formatDate');
      expect(function.returnType, A2uiReturnType.string);
      expect(
        function.argumentSchema.value,
        Schema.object(
          properties: {
            'value': _dynamicValue,
            'format': CommonSchemas.dynamicString,
          },
          required: ['format', 'value'],
          unevaluatedProperties: false,
        ).value,
      );
      expect(
        runFunction(function, {
          'value': '2026-01-16T14:30:00Z',
          'format': 'MMM dd, yyyy HH:mm',
        }),
        'Jan 16, 2026 14:30',
      );
      expect(
        runFunction(function, {
          'value': 1768573800000,
          'format': 'yyyy-MM-dd',
        }),
        '2026-01-16',
      );
      expect(
        runFunction(function, {'value': 'not-a-date', 'format': 'yyyy'}),
        'not-a-date',
      );
      expect(
        runFunction(FormatDateFunction(locale: 'fr_FR'), {
          'value': '2026-01-16T14:30:00Z',
          'format': 'd MMMM yyyy',
        }),
        '16 janvier 2026',
      );
    });

    test('pluralize matches the pinned API and CLDR categories', () {
      final function = PluralizeFunction(locale: 'ar');
      final forms = {
        'zero': 'zero',
        'one': 'one',
        'two': 'two',
        'few': 'few',
        'many': 'many',
        'other': 'other',
      };

      expect(function.name, 'pluralize');
      expect(function.returnType, A2uiReturnType.string);
      expect(
        function.argumentSchema.value,
        Schema.object(
          properties: {
            'value': _dynamicNumber,
            'zero': CommonSchemas.dynamicString,
            'one': CommonSchemas.dynamicString,
            'two': CommonSchemas.dynamicString,
            'few': CommonSchemas.dynamicString,
            'many': CommonSchemas.dynamicString,
            'other': CommonSchemas.dynamicString,
          },
          required: ['value', 'other'],
          unevaluatedProperties: false,
        ).value,
      );
      expect(runFunction(function, {'value': 0, ...forms}), 'zero');
      expect(runFunction(function, {'value': 1, ...forms}), 'one');
      expect(runFunction(function, {'value': 2, ...forms}), 'two');
      expect(runFunction(function, {'value': 3, ...forms}), 'few');
      expect(runFunction(function, {'value': 11, ...forms}), 'many');
      expect(runFunction(function, {'value': 100, ...forms}), 'other');
      expect(
        runFunction(function, {'value': 3, 'other': 'fallback'}),
        'fallback',
      );
      expect(
        runFunction(function, {'value': 'three', 'other': 'fallback'}),
        '',
      );
    });

    test('formatString keeps the pinned API and core reactivity', () {
      final dataModel = DataModel({'name': 'Ada'});
      final context = DataContext(dataModel, (_, _, _) => null, '/');
      final function = FormatStringFunction();

      expect(function.name, 'formatString');
      expect(function.returnType, A2uiReturnType.string);
      expect(
        function.argumentSchema.value,
        Schema.object(
          properties: {'value': CommonSchemas.dynamicString},
          required: ['value'],
          unevaluatedProperties: false,
        ).value,
      );

      final result = function.execute(
        {'value': r'Hello ${/name}'},
        context,
      );
      expect(result, isA<ReadonlySignal<Object?>>());
      final signal = result! as ReadonlySignal<Object?>;
      expect(signal.value, 'Hello Ada');

      dataModel.set('/name', 'Grace');
      expect(signal.value, 'Hello Grace');

      expect(function.execute({'value': null}, context), '');
      expect(function.execute({'value': 42}, context), '42');
    });

    test('reformats when a bound function argument changes', () {
      final dataModel = DataModel(<String, Object?>{'amount': 1234.5});
      late final Catalog<ComponentApi> catalog;
      catalog = Catalog<ComponentApi>(
        id: 'test',
        components: const [],
        functions: [FormatNumberFunction(locale: 'en_US')],
      );
      final context = DataContext(dataModel, catalog.invoke, '/');
      final result = context.resolveListenable({
        'call': 'formatNumber',
        'args': {
          'value': {'path': '/amount'},
          'decimals': 2,
        },
        'returnType': 'string',
      });

      expect(result.value, '1,234.50');
      dataModel.set('/amount', 6);
      expect(result.value, '6.00');
    });
  });
}
