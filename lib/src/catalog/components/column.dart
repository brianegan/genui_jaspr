import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/dom.dart';

import '../jaspr_component.dart';
import 'flex.dart';

/// Lays its children out vertically.
JasprComponent columnComponent() {
  return JasprComponent(
    MinimalColumnApi(),
    (scope) => flexContainer(
      scope,
      direction: FlexDirection.column,
      className: 'a2ui-column',
    ),
  );
}
