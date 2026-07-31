import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/dom.dart';

import '../jaspr_component.dart';
import 'flex.dart';

/// Lays its children out horizontally.
JasprComponent rowComponent() {
  return JasprComponent(
    MinimalRowApi(),
    (scope) => flexContainer(
      scope,
      direction: FlexDirection.row,
      className: 'a2ui-row',
    ),
  );
}
