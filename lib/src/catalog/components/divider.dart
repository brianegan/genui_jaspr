import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// `Divider`'s API from the A2UI v0.9 basic catalog.
class DividerApi extends ComponentApi {
  @override
  String get name => 'Divider';

  @override
  Schema get schema => Schema.object(
    properties: {
      'axis': Schema.string(enumValues: ['horizontal', 'vertical']),
    },
  );
}

/// A dividing rule between pieces of content.
class DividerComponent extends JasprComponent {
  /// Creates a [DividerComponent].
  DividerComponent();

  @override
  final ComponentApi api = DividerApi();

  @override
  Component build(ComponentScope scope) => hr(
    classes: scope.string('axis') == 'vertical'
        ? 'a2ui-divider a2ui-divider--vertical'
        : 'a2ui-divider',
  );
}
