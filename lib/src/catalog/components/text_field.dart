import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../jaspr_component.dart';

/// A labelled text input, bound to the data model in both directions.
///
/// The field is wrapped in its `label`, which associates the two without needing
/// generated ids. Typing writes straight to the path the model bound `value` to,
/// so the next request carries what the user entered without the app copying it
/// anywhere.
JasprComponent textFieldComponent() {
  return JasprComponent(MinimalTextFieldApi(), (scope) {
    final String variant = scope.string('variant') ?? 'shortText';
    final String labelText = scope.string('label') ?? '';
    final String value = scope.string('value') ?? '';
    final void Function(Object?)? write = scope.setter('value');
    final List<String> errors = scope.validationErrors;

    final Component field = variant == 'longText'
        // A textarea carries its value as content rather than an attribute.
        ? textarea(
            [Component.text(value)],
            classes: 'a2ui-field__input',
            onInput: write,
          )
        : input(
            classes: 'a2ui-field__input',
            type: _inputType(variant),
            value: value.isEmpty ? null : value,
            onInput: write,
            attributes: {'pattern': ?scope.string('validationRegexp')},
          );

    return label(
      [
        span([Component.text(labelText)], classes: 'a2ui-field__label'),
        field,
        for (final error in errors)
          small([Component.text(error)], classes: 'a2ui-field__error'),
      ],
      classes: errors.isEmpty ? 'a2ui-field' : 'a2ui-field a2ui-field--invalid',
    );
  });
}

/// Maps the schema's `variant` onto the input type that gives the browser's own
/// keyboard and validation for that kind of value.
InputType _inputType(String variant) => switch (variant) {
  'number' => InputType.number,
  'obscured' => InputType.password,
  _ => InputType.text,
};
