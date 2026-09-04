import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// `Slider`'s API, one of the basic catalog's components that `a2ui_core`
/// does not ship. Its schema is copied from the A2UI spec's basic catalog.
class SliderApi extends ComponentApi {
  @override
  String get name => 'Slider';

  @override
  Schema get schema => Schema.combined(
    allOf: [
      CommonSchemas.checkable,
      Schema.object(
        properties: {
          'value': Schema.combined(
            anyOf: [
              Schema.number(),
              CommonSchemas.dataBinding,
              CommonSchemas.functionCall,
            ],
          ),
          'min': Schema.number(),
          'max': Schema.number(),
          'label': CommonSchemas.dynamicString,
        },
        required: ['value'],
      ),
    ],
  );
}

/// A range input, bound to the data model in both directions.
///
/// Inputs bind through `ComponentScope.setter`, which already turns `NaN`
/// into null, so this gets that for free the same way `TextField`'s number
/// variant does.
class SliderComponent extends JasprComponent {
  /// Creates a [SliderComponent].
  SliderComponent();

  @override
  final ComponentApi api = SliderApi();

  @override
  Component build(ComponentScope scope) {
    final labelText = scope.string('label');
    final value = scope.string('value');
    final write = scope.setter('value');
    final errors = scope.validationErrors;

    return label(
      [
        if (labelText != null)
          span([Component.text(labelText)], classes: 'a2ui-slider__label'),
        input<Object?>(
          classes: 'a2ui-slider__input',
          type: InputType.range,
          value: value,
          onInput: write,
          attributes: {
            'min': scope.string('min') ?? '0',
            'max': scope.string('max') ?? '1',
          },
        ),
        for (final error in errors)
          small([Component.text(error)], classes: 'a2ui-slider__error'),
      ],
      classes: errors.isEmpty
          ? 'a2ui-slider'
          : 'a2ui-slider a2ui-slider--invalid',
    );
  }
}
