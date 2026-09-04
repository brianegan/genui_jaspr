import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/components/flex.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Lays its children out horizontally.
class RowComponent extends JasprComponent {
  /// Creates a [RowComponent].
  RowComponent();

  @override
  final ComponentApi api = MinimalRowApi();

  @override
  Component build(ComponentScope scope) =>
      flexContainer(scope, direction: FlexDirection.row, className: 'a2ui-row');
}
