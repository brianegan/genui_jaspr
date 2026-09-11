import 'package:a2ui_core/a2ui_core.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Returns true when every supplied value is true.
class AndFunction extends FunctionImplementation {
  /// Creates the standard `and` function.
  AndFunction();

  @override
  String get name => 'and';

  @override
  A2uiReturnType get returnType => A2uiReturnType.boolean;

  @override
  Schema get argumentSchema => Schema.object(
    properties: {
      'values': Schema.list(
        items: CommonSchemas.dynamicBoolean,
        minItems: 2,
      ),
    },
    required: ['values'],
    unevaluatedProperties: false,
  );

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    final values = args['values'];
    return values is List &&
        values.length >= 2 &&
        values.every((value) => value == true);
  }
}

/// Returns true when at least one supplied value is true.
class OrFunction extends FunctionImplementation {
  /// Creates the standard `or` function.
  OrFunction();

  @override
  String get name => 'or';

  @override
  A2uiReturnType get returnType => A2uiReturnType.boolean;

  @override
  Schema get argumentSchema => Schema.object(
    properties: {
      'values': Schema.list(
        items: CommonSchemas.dynamicBoolean,
        minItems: 2,
      ),
    },
    required: ['values'],
    unevaluatedProperties: false,
  );

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    final values = args['values'];
    return values is List &&
        values.length >= 2 &&
        values.any((value) => value == true);
  }
}

/// Negates a Boolean value.
class NotFunction extends FunctionImplementation {
  /// Creates the standard `not` function.
  NotFunction();

  @override
  String get name => 'not';

  @override
  A2uiReturnType get returnType => A2uiReturnType.boolean;

  @override
  Schema get argumentSchema => Schema.object(
    properties: {'value': CommonSchemas.dynamicBoolean},
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
    return value is bool && !value;
  }
}
