import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// `Image`'s API from the A2UI v0.9 basic catalog.
class ImageApi extends ComponentApi {
  @override
  String get name => 'Image';

  @override
  Schema get schema => Schema.object(
    properties: {
      'url': CommonSchemas.dynamicString,
      'description': CommonSchemas.dynamicString,
      'fit': Schema.string(
        enumValues: ['contain', 'cover', 'fill', 'none', 'scaleDown'],
      ),
      'variant': Schema.string(
        enumValues: [
          'icon',
          'avatar',
          'smallFeature',
          'mediumFeature',
          'largeFeature',
          'header',
        ],
      ),
    },
    required: ['url'],
  );
}

/// Displays an image from an A2UI-provided URL.
class ImageComponent extends JasprComponent {
  /// Creates an [ImageComponent].
  ImageComponent();

  @override
  final ComponentApi api = ImageApi();

  @override
  Component build(ComponentScope scope) {
    final variant = scope.string('variant') ?? 'mediumFeature';
    final fit = scope.string('fit') ?? 'fill';

    return img(
      src: scope.string('url') ?? '',
      alt: scope.string('description') ?? '',
      classes: 'a2ui-image a2ui-image--${_cssName(variant)}',
      styles: Styles(raw: {'object-fit': _cssName(fit)}),
    );
  }
}

String _cssName(String value) => value.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => '-${match.group(0)!.toLowerCase()}',
);
