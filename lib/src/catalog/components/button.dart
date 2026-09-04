import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A button that dispatches its action when pressed.
///
/// A button whose `checks` are failing is disabled, so the surface stops an
/// invalid submission at the point of interaction rather than sending it and
/// waiting for the model to object.
class ButtonComponent extends JasprComponent {
  /// Creates a [ButtonComponent].
  ButtonComponent();

  @override
  final ComponentApi api = MinimalButtonApi();

  @override
  Component build(ComponentScope scope) {
    final variant = scope.string('variant') ?? 'primary';
    final childId = scope.string('child');
    final onPressed = scope.action('action');
    final enabled = scope.isValid && onPressed != null;

    return button(
      [if (childId != null) scope.buildChild(childId)],
      classes: 'a2ui-button a2ui-button--$variant',
      type: ButtonType.button,
      disabled: !enabled,
      onClick: enabled ? onPressed : null,
    );
  }
}
