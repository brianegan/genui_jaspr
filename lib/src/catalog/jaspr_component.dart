import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Everything a builder needs to render one A2UI component.
///
/// The [props] are already resolved: data bindings have been read, function
/// calls evaluated, and actions turned into callbacks. A builder reads values
/// out of the map and never resolves a binding itself.
final class ComponentScope {
  const ComponentScope({
    required this.id,
    required this.type,
    required this.props,
    required this.theme,
    required this.buildChild,
    required this.buildChildren,
  });

  /// This component's id within its surface.
  final String id;

  /// The component type, as named in the catalog.
  final String type;

  /// The component's resolved properties.
  final Map<String, dynamic> props;

  /// The surface's theme, as sent with `createSurface`.
  final Map<String, dynamic> theme;

  /// Renders a single child by its component id.
  ///
  /// Used by components whose schema names one child, such as `Button`.
  final Component Function(String componentId) buildChild;

  /// Renders a `children` property.
  ///
  /// The binder resolves such a property into a list of child references, which
  /// may come either from a literal list of ids or from a template repeated over
  /// a path in the data model. Both arrive here in the same shape.
  final List<Component> Function(Object? childrenProp) buildChildren;

  /// Reads [key] from [props] as a string, or null when absent.
  String? string(String key) {
    final Object? value = props[key];
    return value == null ? null : '$value';
  }

  /// Reads [key] from [props] as a callback, or null when absent.
  ///
  /// A property whose schema describes an action resolves to a function.
  Future<void> Function()? action(String key) {
    final Object? value = props[key];
    return value is Future<void> Function() ? value : null;
  }

  /// Writes back to whatever the property named [key] is bound to.
  ///
  /// Present only when the model bound the property to a data-model path, which
  /// is what makes an input two-way. A field bound to a literal has no setter,
  /// and is therefore read-only by the model's own choosing.
  void Function(Object?)? setter(String key) {
    final String name = 'set${key[0].toUpperCase()}${key.substring(1)}';
    final Object? value = props[name];
    return value is void Function(Object?) ? value : null;
  }

  /// Whether this component's `checks` currently pass.
  ///
  /// Components without `checks` are always valid, so the absence of the
  /// property reads as valid rather than as a failure.
  bool get isValid => props['isValid'] != false;

  /// The messages for the `checks` that are currently failing.
  List<String> get validationErrors {
    final Object? value = props['validationErrors'];
    if (value is! List) return const [];
    return value.map((error) => '$error').toList();
  }
}

/// A catalog entry: a component's A2UI API paired with how to render it.
///
/// The API side comes from `a2ui_core`, which owns the name and the schema that
/// decides how each property binds. This class adds the Jaspr half, so the
/// protocol definition and the renderer stay separable.
final class JasprComponent implements ComponentApi {
  const JasprComponent(this.api, this.build);

  /// The protocol definition for this component.
  final ComponentApi api;

  /// Renders the component from its resolved properties.
  final Component Function(ComponentScope scope) build;

  @override
  String get name => api.name;

  @override
  Schema get schema => api.schema;
}
