import 'package:a2ui_core/a2ui_core.dart' hide FormatStringFunction;
import 'package:a2ui_core/a2ui_core.dart' as core show FormatStringFunction;
import 'package:genui_jaspr/src/catalog/functions/standard_schemas.dart';
import 'package:intl/intl.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Formats a number with locale-aware grouping and decimal separators.
class FormatNumberFunction extends FunctionImplementation {
  /// Creates the standard `formatNumber` function.
  FormatNumberFunction({this.locale});

  /// The locale passed to `intl`, or its current default when null.
  final String? locale;

  @override
  String get name => 'formatNumber';

  @override
  A2uiReturnType get returnType => A2uiReturnType.string;

  @override
  Schema get argumentSchema => Schema.object(
    properties: {
      'value': standardDynamicNumberSchema,
      'decimals': standardDynamicNumberSchema,
      'grouping': CommonSchemas.dynamicBoolean,
    },
    required: ['value'],
    unevaluatedProperties: false,
  );

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    final value = args['value'];
    if (value is! num) return value?.toString() ?? '';

    final formatter = NumberFormat.decimalPattern(locale);
    if (args['grouping'] == false) formatter.turnOffGrouping();

    final decimals = args['decimals'];
    if (decimals is num && decimals.isFinite && decimals >= 0) {
      final places = decimals.toInt();
      formatter
        ..minimumFractionDigits = places
        ..maximumFractionDigits = places;
    }
    return formatter.format(value);
  }
}

/// Formats a monetary amount using an ISO 4217 currency code.
class FormatCurrencyFunction extends FunctionImplementation {
  /// Creates the standard `formatCurrency` function.
  FormatCurrencyFunction({this.locale});

  /// The locale passed to `intl`, or its current default when null.
  final String? locale;

  @override
  String get name => 'formatCurrency';

  @override
  A2uiReturnType get returnType => A2uiReturnType.string;

  @override
  Schema get argumentSchema => Schema.object(
    properties: {
      'value': standardDynamicNumberSchema,
      'currency': CommonSchemas.dynamicString,
      'decimals': standardDynamicNumberSchema,
      'grouping': CommonSchemas.dynamicBoolean,
    },
    required: ['currency', 'value'],
    unevaluatedProperties: false,
  );

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    final value = args['value'];
    final currency = args['currency'];
    if (value is! num || currency is! String) {
      return value?.toString() ?? '';
    }

    final decimals = args['decimals'];
    final decimalPlaces = decimals is num && decimals.isFinite && decimals >= 0
        ? decimals.toInt()
        : null;
    final formatter = NumberFormat.simpleCurrency(
      name: currency,
      locale: locale,
      decimalDigits: decimalPlaces,
    );
    if (args['grouping'] == false) formatter.turnOffGrouping();
    return formatter.format(value);
  }
}

/// Formats an ISO date string or epoch-millisecond timestamp.
class FormatDateFunction extends FunctionImplementation {
  /// Creates the standard `formatDate` function.
  FormatDateFunction({this.locale});

  /// The locale passed to `intl`, or its current default when null.
  final String? locale;

  @override
  String get name => 'formatDate';

  @override
  A2uiReturnType get returnType => A2uiReturnType.string;

  @override
  Schema get argumentSchema => Schema.object(
    properties: {
      'value': standardDynamicValueSchema,
      'format': CommonSchemas.dynamicString,
    },
    required: ['format', 'value'],
    unevaluatedProperties: false,
  );

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    final value = args['value'];
    final format = args['format'];
    if (format is! String) return value?.toString() ?? '';

    try {
      final date = switch (value) {
        final String text => DateTime.tryParse(text),
        final num milliseconds => DateTime.fromMillisecondsSinceEpoch(
          milliseconds.toInt(),
        ),
        _ => null,
      };
      if (date == null) return value?.toString() ?? '';
      return DateFormat(format, locale).format(date);
    } on Object {
      return value?.toString() ?? '';
    }
  }
}

/// Selects a localized string using CLDR plural categories.
class PluralizeFunction extends FunctionImplementation {
  /// Creates the standard `pluralize` function.
  PluralizeFunction({this.locale});

  /// The locale passed to `intl`, or its current default when null.
  final String? locale;

  @override
  String get name => 'pluralize';

  @override
  A2uiReturnType get returnType => A2uiReturnType.string;

  @override
  Schema get argumentSchema => Schema.object(
    properties: {
      'value': standardDynamicNumberSchema,
      'zero': CommonSchemas.dynamicString,
      'one': CommonSchemas.dynamicString,
      'two': CommonSchemas.dynamicString,
      'few': CommonSchemas.dynamicString,
      'many': CommonSchemas.dynamicString,
      'other': CommonSchemas.dynamicString,
    },
    required: ['value', 'other'],
    unevaluatedProperties: false,
  );

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    final value = args['value'];
    final other = args['other'];
    if (value is! num || other is! String) return '';

    return Intl.plural(
      value,
      zero: _string(args['zero']),
      one: _string(args['one']),
      two: _string(args['two']),
      few: _string(args['few']),
      many: _string(args['many']),
      other: other,
      locale: locale,
    );
  }
}

String? _string(Object? value) => value is String ? value : null;

/// Interpolates data paths and client function calls in a string.
///
/// Evaluation is delegated to `a2ui_core`; this adapter supplies the exact
/// argument schema from the pinned standard catalog.
class FormatStringFunction extends FunctionImplementation {
  /// Creates the standard `formatString` function.
  FormatStringFunction();

  final core.FormatStringFunction _delegate = core.FormatStringFunction();

  @override
  String get name => 'formatString';

  @override
  A2uiReturnType get returnType => A2uiReturnType.string;

  @override
  Schema get argumentSchema => Schema.object(
    properties: {'value': CommonSchemas.dynamicString},
    required: ['value'],
    unevaluatedProperties: false,
  );

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    final value = args['value'];
    if (value is! String) return value?.toString() ?? '';
    return _delegate.execute(args, context, cancellationSignal);
  }
}
