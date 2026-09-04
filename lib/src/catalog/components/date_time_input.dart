import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// `DateTimeInput`'s API, one of the basic catalog's components that
/// `a2ui_core` does not ship. Its schema is copied from the A2UI spec's basic
/// catalog.
class DateTimeInputApi extends ComponentApi {
  @override
  String get name => 'DateTimeInput';

  @override
  Schema get schema => Schema.combined(
    allOf: [
      CommonSchemas.checkable,
      Schema.object(
        properties: {
          'value': CommonSchemas.dynamicString,
          'variant': Schema.string(enumValues: ['date', 'time', 'datetime']),
          'min': Schema.string(),
          'max': Schema.string(),
          'label': CommonSchemas.dynamicString,
        },
        required: ['value'],
      ),
    ],
  );
}

/// A date, time, or date-and-time input, bound to the data model in both
/// directions.
///
/// The browser reports what the user picked as a `DateTime`, not the ISO
/// string the schema binds. It is converted back before it reaches
/// `ComponentScope.setter`, so what lands in the data model is the same
/// shape the model sent: a plain date or time string, not a `DateTime` object
/// the data model's JSON has no encoding for.
class DateTimeInputComponent extends JasprComponent {
  /// Creates a [DateTimeInputComponent].
  DateTimeInputComponent();

  @override
  final ComponentApi api = DateTimeInputApi();

  @override
  Component build(ComponentScope scope) {
    final variant = scope.string('variant') ?? 'date';
    final labelText = scope.string('label');
    final value = scope.string('value');
    final write = scope.setter('value');
    final errors = scope.validationErrors;

    return label(
      [
        if (labelText != null)
          span([
            Component.text(labelText),
          ], classes: 'a2ui-date-time-input__label'),
        input<DateTime>(
          classes: 'a2ui-date-time-input__input',
          type: _inputType(variant),
          value: value?.isEmpty ?? true ? null : value,
          onInput: write == null
              ? null
              : (picked) => write(_format(picked, variant)),
          attributes: {
            'min': ?scope.string('min'),
            'max': ?scope.string('max'),
          },
        ),
        for (final error in errors)
          small([
            Component.text(error),
          ], classes: 'a2ui-date-time-input__error'),
      ],
      classes: errors.isEmpty
          ? 'a2ui-date-time-input'
          : 'a2ui-date-time-input a2ui-date-time-input--invalid',
    );
  }
}

/// Maps the schema's `variant` onto the input type that gives the browser's
/// own date or time picker for that kind of value.
InputType _inputType(String variant) => switch (variant) {
  'time' => InputType.time,
  'datetime' => InputType.dateTimeLocal,
  _ => InputType.date,
};

/// Formats what the browser reports back into the ISO shape the variant's
/// string binds, the reverse of what the browser's own date and time pickers
/// show the user.
String _format(DateTime picked, String variant) {
  String two(int n) => n.toString().padLeft(2, '0');
  final date =
      '${picked.year.toString().padLeft(4, '0')}-'
      '${two(picked.month)}-${two(picked.day)}';
  final time = '${two(picked.hour)}:${two(picked.minute)}';
  return switch (variant) {
    'time' => time,
    'datetime' => '${date}T$time',
    _ => date,
  };
}
