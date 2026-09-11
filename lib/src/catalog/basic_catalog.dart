import 'package:a2ui_core/a2ui_core.dart' hide FormatStringFunction;
import 'package:genui_jaspr/src/catalog/components/audio_player.dart';
import 'package:genui_jaspr/src/catalog/components/button.dart';
import 'package:genui_jaspr/src/catalog/components/card.dart';
import 'package:genui_jaspr/src/catalog/components/check_box.dart';
import 'package:genui_jaspr/src/catalog/components/choice_picker.dart';
import 'package:genui_jaspr/src/catalog/components/column.dart';
import 'package:genui_jaspr/src/catalog/components/date_time_input.dart';
import 'package:genui_jaspr/src/catalog/components/divider.dart';
import 'package:genui_jaspr/src/catalog/components/icon.dart';
import 'package:genui_jaspr/src/catalog/components/image.dart';
import 'package:genui_jaspr/src/catalog/components/list.dart';
import 'package:genui_jaspr/src/catalog/components/modal.dart';
import 'package:genui_jaspr/src/catalog/components/row.dart';
import 'package:genui_jaspr/src/catalog/components/slider.dart';
import 'package:genui_jaspr/src/catalog/components/tabs.dart';
import 'package:genui_jaspr/src/catalog/components/text.dart';
import 'package:genui_jaspr/src/catalog/components/text_field.dart';
import 'package:genui_jaspr/src/catalog/components/video.dart';
import 'package:genui_jaspr/src/catalog/functions/boolean.dart';
import 'package:genui_jaspr/src/catalog/functions/format.dart';
import 'package:genui_jaspr/src/catalog/functions/open_url.dart';
import 'package:genui_jaspr/src/catalog/functions/validation.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// The complete pinned A2UI v0.9 standard catalog, rendered as HTML.
///
/// The catalog always includes the package's 59 built-in Material SVG paths,
/// because its official catalog ID promises the standard `Icon` component.
class BasicJasprCatalog extends Catalog<JasprComponent> {
  /// Creates the complete catalog with the built-in icon renderer.
  BasicJasprCatalog({
    String? locale,
    UrlOpener? urlOpener,
  }) : super(
         id: catalogId,
         components: _components(),
         functions: _functions(locale: locale, urlOpener: urlOpener),
         themeSchema: _themeSchema,
       );

  /// The exact catalog id published by the pinned A2UI v0.9 schema.
  static const catalogId =
      'https://a2ui.org/specification/v0_9/standard_catalog.json';
}

List<JasprComponent> _components() => [
  TextComponent(),
  ImageComponent(),
  IconComponent(),
  VideoComponent(),
  AudioPlayerComponent(),
  RowComponent(),
  ColumnComponent(),
  ListComponent(),
  CardComponent(),
  TabsComponent(),
  ModalComponent(),
  DividerComponent(),
  ButtonComponent(),
  TextFieldComponent(),
  CheckBoxComponent(),
  ChoicePickerComponent(),
  SliderComponent(),
  DateTimeInputComponent(),
];

List<FunctionImplementation> _functions({
  required String? locale,
  required UrlOpener? urlOpener,
}) => [
  RequiredFunction(),
  RegexFunction(),
  LengthFunction(),
  NumericFunction(),
  EmailFunction(),
  FormatStringFunction(),
  FormatNumberFunction(locale: locale),
  FormatCurrencyFunction(locale: locale),
  FormatDateFunction(locale: locale),
  PluralizeFunction(locale: locale),
  OpenUrlFunction(opener: urlOpener),
  AndFunction(),
  OrFunction(),
  NotFunction(),
];

final _themeSchema = Schema.object(
  properties: {
    'primaryColor': Schema.string(pattern: r'^#[0-9a-fA-F]{6}$'),
    'iconUrl': Schema.string(format: 'uri'),
    'agentDisplayName': Schema.string(),
  },
  additionalProperties: true,
);
