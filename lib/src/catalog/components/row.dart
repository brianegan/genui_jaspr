import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../jaspr_component.dart';
import 'flex.dart';

/// Lays its children out horizontally.
class RowComponent extends JasprComponent {
  RowComponent();

  @override
  final ComponentApi api = MinimalRowApi();

  @override
  Component build(ComponentScope scope) =>
      flexContainer(scope, direction: FlexDirection.row, className: 'a2ui-row');
}
