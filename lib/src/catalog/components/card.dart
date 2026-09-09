import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// `Card`'s API from the A2UI v0.9 basic catalog.
class CardApi extends ComponentApi {
  @override
  String get name => 'Card';

  @override
  Schema get schema => Schema.object(
    properties: {'child': CommonSchemas.componentId},
    required: ['child'],
  );
}

/// A card-like container around one child component.
class CardComponent extends JasprComponent {
  /// Creates a [CardComponent].
  CardComponent();

  @override
  final ComponentApi api = CardApi();

  @override
  Component build(ComponentScope scope) {
    final childId = scope.string('child');
    return div(
      [if (childId != null) scope.buildChild(childId)],
      classes: 'a2ui-card',
    );
  }
}
