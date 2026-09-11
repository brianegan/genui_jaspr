import 'package:a2ui_core/a2ui_core.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// A dynamic number in the shape understood by the `a2ui_core` binder.
final standardDynamicNumberSchema = Schema.combined(
  description:
      r'REF:common_types.json#/$defs/DynamicNumber|Represents a number',
  anyOf: [
    Schema.number(),
    CommonSchemas.dataBinding,
    CommonSchemas.functionCall,
  ],
);

/// A dynamic JSON value in the shape understood by the `a2ui_core` binder.
final standardDynamicValueSchema = Schema.combined(
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
