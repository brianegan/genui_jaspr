import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/dom.dart';

import '../jaspr_component.dart';

/// A button that dispatches its action when pressed.
///
/// A button whose `checks` are failing is disabled, so the surface stops an
/// invalid submission at the point of interaction rather than sending it and
/// waiting for the model to object.
JasprComponent buttonComponent() {
  return JasprComponent(MinimalButtonApi(), (scope) {
    final String variant = scope.string('variant') ?? 'primary';
    final String? childId = scope.string('child');
    final Future<void> Function()? onPressed = scope.action('action');
    final bool enabled = scope.isValid && onPressed != null;

    return button(
      [if (childId != null) scope.buildChild(childId)],
      classes: 'a2ui-button a2ui-button--$variant',
      type: ButtonType.button,
      disabled: !enabled,
      onClick: enabled ? () => onPressed() : null,
    );
  });
}
