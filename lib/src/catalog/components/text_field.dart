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

    // A number input reports what it holds as a number, and NaN while its text
    // is not one: empty, or a lone minus sign. NaN has no JSON encoding, and the
    // data model is sent to the model as JSON, so it is written as nothing.
    //
    // Only a real input event reaches this closure, so the browser suite is
    // what covers it.
    // coverage:ignore-start
    final void Function(Object?)? onInput = write == null
        ? null
        : (Object? typed) =>
              write(typed is double && typed.isNaN ? null : typed);
    // coverage:ignore-end

    final Component field = variant == 'longText'
        ? _LongText(value: value, onInput: onInput)
        : input<Object?>(
            classes: 'a2ui-field__input',
            type: _inputType(variant),
            value: value.isEmpty ? null : value,
            onInput: onInput,
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
  Component build(BuildContext context) {
    // After the frame, once the element exists. The key yields no node during
    // server rendering, where the content is all a browser will ever see.
    context.binding.addPostFrameCallback(_followValue);
    return textarea(
      [Component.text(component.value)],
      key: _node,
      classes: 'a2ui-field__input',
      onInput: component.onInput,
    );
  }

  /// Runs only in a browser: post-frame callbacks need a frame, and the key
  /// yields a node only once the element is in a document. The browser suite
  /// covers it.
  // coverage:ignore-start
  void _followValue() {
    final web.HTMLTextAreaElement? node = _node.currentNode;
    if (node == null || node.value == component.value) return;
    node.value = component.value;
  }

  // coverage:ignore-end
}
