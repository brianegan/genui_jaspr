import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../jaspr_component.dart';
import 'flex.dart';

/// Lays its children out vertically.
class ColumnComponent extends JasprComponent {
  ColumnComponent();

  @override
  final ComponentApi api = MinimalColumnApi();

  @override
  Component build(ComponentScope scope) => flexContainer(
    scope,
    direction: FlexDirection.column,
    className: 'a2ui-column',
  );
}
