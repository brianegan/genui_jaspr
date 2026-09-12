import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/basic/functions/standard_schemas.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Checks that a JSON value is present and not empty.
class RequiredFunction extends FunctionImplementation {
  /// Creates the standard `required` function.
  RequiredFunction();

  @override
  String get name => 'required';

  @override
  A2uiReturnType get returnType => A2uiReturnType.boolean;

  @override
  Schema get argumentSchema => Schema.object(
    properties: {'value': Schema.any()},
    required: ['value'],
    additionalProperties: false,
  );

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    if (!args.containsKey('value')) return false;
    return switch (args['value']) {
      null => false,
      final String value => value.isNotEmpty,
      final List<Object?> value => value.isNotEmpty,
      final Map<Object?, Object?> value => value.isNotEmpty,
      _ => true,
    };
  }
}

/// Checks whether a string contains a match for a regular expression.
class RegexFunction extends FunctionImplementation {
  /// Creates the standard `regex` function.
  RegexFunction();

  @override
  String get name => 'regex';

  @override
  A2uiReturnType get returnType => A2uiReturnType.boolean;

  @override
  Schema get argumentSchema => Schema.object(
    properties: {
      'value': CommonSchemas.dynamicString,
      'pattern': Schema.string(),
    },
    required: ['value', 'pattern'],
    unevaluatedProperties: false,
  );

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    final value = args['value'];
    final pattern = args['pattern'];
    if (value is! String || pattern is! String) return false;
    try {
      return RegExp(pattern).hasMatch(value);
    } on FormatException catch (error) {
      throw FormatException('Invalid regex pattern "$pattern": $error');
    }
  }
}

/// Checks a string's length against inclusive bounds.
class LengthFunction extends FunctionImplementation {
  /// Creates the standard `length` function.
  LengthFunction();

  @override
  String get name => 'length';

  @override
  A2uiReturnType get returnType => A2uiReturnType.boolean;

  @override
  Schema get argumentSchema {
    final objectSchema = Schema.object(
      properties: {
        'value': CommonSchemas.dynamicString,
        'min': Schema.integer(minimum: 0),
        'max': Schema.integer(minimum: 0),
      },
      required: ['value'],
      unevaluatedProperties: false,
    );
    return Schema.fromMap({
      ...objectSchema.value,
      'anyOf': [
        Schema.object(required: ['min']).value,
        Schema.object(required: ['max']).value,
      ],
    });
  }

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    final value = args['value'];
    if (value is! String) return false;

    final hasMin = args.containsKey('min');
    final hasMax = args.containsKey('max');
    if (!hasMin && !hasMax) return false;

    final min = args['min'];
    final max = args['max'];
    if (hasMin && (min is! num || value.length < min)) return false;
    if (hasMax && (max is! num || value.length > max)) return false;
    return true;
  }
}

/// Checks a number against inclusive bounds.
class NumericFunction extends FunctionImplementation {
  /// Creates the standard `numeric` function.
  NumericFunction();

  @override
  String get name => 'numeric';

  @override
  A2uiReturnType get returnType => A2uiReturnType.boolean;

  @override
  Schema get argumentSchema {
    final objectSchema = Schema.object(
      properties: {
        'value': standardDynamicNumberSchema,
        'min': Schema.number(),
        'max': Schema.number(),
      },
      required: ['value'],
      unevaluatedProperties: false,
    );
    return Schema.fromMap({
      ...objectSchema.value,
      'anyOf': [
        Schema.object(required: ['min']).value,
        Schema.object(required: ['max']).value,
      ],
    });
  }

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    final value = args['value'];
    if (value is! num) return false;

    final hasMin = args.containsKey('min');
    final hasMax = args.containsKey('max');
    if (!hasMin && !hasMax) return false;

    final min = args['min'];
    final max = args['max'];
    if (hasMin && (min is! num || value < min)) return false;
    if (hasMax && (max is! num || value > max)) return false;
    return true;
  }
}

/// Checks that a string has the basic shape of an email address.
class EmailFunction extends FunctionImplementation {
  /// Creates the standard `email` function.
  EmailFunction();

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  String get name => 'email';

  @override
  A2uiReturnType get returnType => A2uiReturnType.boolean;

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
    return value is String && _emailPattern.hasMatch(value);
  }
}
