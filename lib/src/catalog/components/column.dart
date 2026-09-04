import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/components/flex.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Lays its children out vertically.
class ColumnComponent extends JasprComponent {
  /// Creates a [ColumnComponent].
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
