import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// `CheckBox`'s API, one of the basic catalog's components that `a2ui_core`
/// does not ship. Its schema matches the A2UI spec's basic catalog, taken
/// from Flutter's `genui` reference implementation since `a2ui_core` has none
/// to copy it from.
class CheckBoxApi extends ComponentApi {
  @override
  String get name => 'CheckBox';

  @override
  Schema get schema => Schema.combined(
    allOf: [
      CommonSchemas.checkable,
      Schema.object(
        properties: {
          'label': CommonSchemas.dynamicString,
          'value': CommonSchemas.dynamicBoolean,
        },
        required: ['label', 'value'],
      ),
    ],
  );
}

/// A checkbox with a label, bound to the data model in both directions.
class CheckBoxComponent extends JasprComponent {
  /// Creates a [CheckBoxComponent].
  CheckBoxComponent();

  @override
  final ComponentApi api = CheckBoxApi();

  @override
  Component build(ComponentScope scope) {
    final labelText = scope.string('label') ?? '';
    final checked = scope.props['value'] == true;
    final write = scope.setter('value');
    final errors = scope.validationErrors;

    return label(
      [
        input<bool>(
          classes: 'a2ui-checkbox__input',
          type: InputType.checkbox,
          checked: checked,
          onChange: write,
        ),
        span([Component.text(labelText)], classes: 'a2ui-checkbox__label'),
        for (final error in errors)
          small([Component.text(error)], classes: 'a2ui-checkbox__error'),
      ],
      classes: errors.isEmpty
          ? 'a2ui-checkbox'
          : 'a2ui-checkbox a2ui-checkbox--invalid',
    );
  }
}
