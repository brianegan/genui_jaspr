import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:universal_web/web.dart' as web;

import '../jaspr_component.dart';

/// A labelled text input, bound to the data model in both directions.
///
/// The field is wrapped in its `label`, which associates the two without needing
/// generated ids. Typing writes straight to the path the model bound `value` to,
/// so the next request carries what the user entered without the app copying it
/// anywhere.
class TextFieldComponent extends JasprComponent {
  TextFieldComponent();

  @override
  final ComponentApi api = MinimalTextFieldApi();

  @override
  Component build(ComponentScope scope) {
    final String variant = scope.string('variant') ?? 'shortText';
    final String labelText = scope.string('label') ?? '';
    final String value = scope.string('value') ?? '';
    final void Function(Object?)? write = scope.setter('value');
    final List<String> errors = scope.validationErrors;

    // A number input hands over a num, and NaN while its text is not a number.
    // The setter turns that NaN into nothing rather than letting it reach JSON.
    final Component field = variant == 'longText'
        ? _LongText(value: value, onInput: write)
        : input<Object?>(
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
  }
}

/// Maps the schema's `variant` onto the input type that gives the browser's own
/// keyboard and validation for that kind of value.
InputType _inputType(String variant) => switch (variant) {
  'number' => InputType.number,
  'obscured' => InputType.password,
  _ => InputType.text,
};

/// A textarea that follows its bound value in both directions.
///
/// A textarea carries its initial value as content rather than an attribute,
/// and once the user has typed, what the browser shows is the element's `value`
/// property rather than that content. Rendering the content alone therefore
/// works until the first keystroke and then silently stops following the data
/// model, so the property is set as well whenever the two differ.
class _LongText extends StatefulComponent {
  const _LongText({required this.value, required this.onInput});

  final String value;
  final void Function(Object?)? onInput;

  @override
  State<_LongText> createState() => _LongTextState();
}

class _LongTextState extends State<_LongText> {
  final _node = GlobalNodeKey<web.HTMLTextAreaElement>();

  @override
  void didUpdateComponent(_LongText oldComponent) {
    super.didUpdateComponent(oldComponent);
    // The element already exists here, so its value can be brought in line
    // before the new content is rendered. The user's own typing arrives as a
    // value equal to what the element holds, and is left alone: setting a
    // textarea's value, even to what it already holds, moves the caret. The
    // key yields no node outside a browser, where the content is all anyone
    // will see, and the null-aware writes make that a quiet no-op.
    final web.HTMLTextAreaElement? node = _node.currentNode;
    if (node?.value != component.value) node?.value = component.value;
  }

  @override
  Component build(BuildContext context) {
    return textarea(
      [Component.text(component.value)],
      key: _node,
      classes: 'a2ui-field__input',
      onInput: component.onInput,
    );
  }
}
