import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// `Video`'s API from the A2UI v0.9 basic catalog.
class VideoApi extends ComponentApi {
  @override
  String get name => 'Video';

  @override
  Schema get schema => Schema.object(
    properties: {'url': CommonSchemas.dynamicString},
    required: ['url'],
  );
}

/// Plays video from an A2UI-provided URL using the browser's native controls.
class VideoComponent extends JasprComponent {
  /// Creates a [VideoComponent].
  VideoComponent();

  @override
  final ComponentApi api = VideoApi();

  @override
  Component build(ComponentScope scope) {
    return video(
      const [],
      src: scope.string('url') ?? '',
      controls: true,
      classes: 'a2ui-video',
    );
  }
}
