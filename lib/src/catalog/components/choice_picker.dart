import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// `ChoicePicker`'s API, one of the basic catalog's components that
/// `a2ui_core` does not ship. Its schema is trimmed to the fields this
/// renderer acts on: a labelled group of options, rendered as radio buttons
/// when `mutuallyExclusive` or checkboxes when `multipleSelection`.
class ChoicePickerApi extends ComponentApi {
  @override
  String get name => 'ChoicePicker';

  @override
  Schema get schema => Schema.combined(
    allOf: [
      CommonSchemas.checkable,
      Schema.object(
        properties: {
          'label': CommonSchemas.dynamicString,
          'options': Schema.list(
            items: Schema.object(
              properties: {
                'label': CommonSchemas.dynamicString,
                'value': Schema.string(),
              },
              required: ['label', 'value'],
            ),
          ),
          'value': Schema.combined(
            anyOf: [
              Schema.string(),
              Schema.list(items: Schema.string()),
              CommonSchemas.dataBinding,
              CommonSchemas.functionCall,
            ],
          ),
          'variant': Schema.string(
            enumValues: ['mutuallyExclusive', 'multipleSelection'],
          ),
        },
        required: ['options', 'value'],
      ),
    ],
  );
}

/// A group of options the user picks one or more of, bound to the data model
/// in both directions.
///
/// `mutuallyExclusive` (the default) renders radio buttons sharing this
/// component's id as their group name, so only one can ever be checked.
/// `multipleSelection` renders a checkbox per option, and writes back the
/// list of every option currently checked.
class ChoicePickerComponent extends JasprComponent {
  /// Creates a [ChoicePickerComponent].
  ChoicePickerComponent();

  @override
  final ComponentApi api = ChoicePickerApi();

  @override
  Component build(ComponentScope scope) {
    final labelText = scope.string('label');
    final isMulti = scope.string('variant') == 'multipleSelection';
    final options = (scope.props['options'] as List? ?? const [])
        .cast<Map<Object?, Object?>>();
    final write = scope.setter('value');
    final errors = scope.validationErrors;

    final selected = isMulti
        ? (scope.props['value'] as List? ?? const [])
              .map((value) => '$value')
              .toSet()
        : {if (scope.props['value'] != null) '${scope.props['value']}'};

    return fieldset(
      [
        if (labelText != null)
          legend([
            Component.text(labelText),
          ], classes: 'a2ui-choice-picker__label'),
        for (final option in options)
          _option(
            groupName: scope.id,
            option: option,
            isMulti: isMulti,
            selected: selected,
            write: write,
          ),
        for (final error in errors)
          small([
            Component.text(error),
          ], classes: 'a2ui-choice-picker__error'),
      ],
      classes: errors.isEmpty
          ? 'a2ui-choice-picker'
          : 'a2ui-choice-picker a2ui-choice-picker--invalid',
    );
  }

  Component _option({
    required String groupName,
    required Map<Object?, Object?> option,
    required bool isMulti,
    required Set<String> selected,
    required void Function(Object?)? write,
  }) {
    final value = '${option['value']}';
    final optionLabel = '${option['label']}';
    final checked = selected.contains(value);

    ValueChanged<bool>? onChange;
    if (write != null) {
      onChange = isMulti
          ? (isChecked) {
              final next = Set<String>.of(selected);
              if (isChecked) {
                next.add(value);
              } else {
                next.remove(value);
              }
              write(next.toList());
            }
          : (isChecked) {
              if (isChecked) write(value);
            };
    }

    return label(
      [
        input<bool>(
          classes: 'a2ui-choice-picker__input',
          type: isMulti ? InputType.checkbox : InputType.radio,
          name: isMulti ? null : groupName,
          checked: checked,
          onChange: onChange,
        ),
        span([
          Component.text(optionLabel),
        ], classes: 'a2ui-choice-picker__option-label'),
      ],
      classes: 'a2ui-choice-picker__option',
    );
  }
}
