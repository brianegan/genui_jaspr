import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:genui_jaspr/src/catalog/minimal/components/flex.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Lays its children out vertically.
class ColumnComponent extends JasprComponent {
  /// Creates a [ColumnComponent].
  ColumnComponent();

  @override
  final ComponentApi api = MinimalColumnApi();

  /// Only the shared spacing. Direction and alignment are written inline by
  /// [build], because the model chooses them per instance.
  @override
  List<StyleRule> get styles => const [
    StyleRule(
      selector: Selector('.a2ui-column'),
      styles: Styles(raw: {'gap': '0.5rem'}),
    ),
  ];

  @override
  Component build(ComponentScope scope) => flexContainer(
    scope,
    direction: FlexDirection.column,
    className: 'a2ui-column',
  );
}
