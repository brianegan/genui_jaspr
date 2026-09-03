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
    required this.reportError,
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

  /// Renders a resolved `children` property.
  ///
  /// The binder resolves such a property into a list of child references, which
  /// may come either from a literal list of ids or from a template repeated over
  /// a path in the data model. Both arrive here in the same shape. Most builders
  /// want [children] instead, which reads the property for them.
  final List<Component> Function(Object? childrenProp) buildChildren;

  /// Reports something that went wrong inside this component.
  ///
  /// The error reaches the surface and, through it, whoever is listening for
  /// errors to send back to the model. Actions obtained through [action] report
  /// their own failures, so a builder only needs this for problems it detects
  /// itself.
  final void Function(Object error) reportError;

  /// Renders the children named by the property [key].
  ///
  /// Used by containers such as `Row` and `Column`, whose schema has a
  /// `children` list.
  List<Component> children([String key = 'children']) =>
      buildChildren(props[key]);

  /// Reads [key] from [props] as a string, or null when absent.
  String? string(String key) {
    final Object? value = props[key];
    return value == null ? null : '$value';
  }

  /// Reads [key] from [props] as a callback, or null when absent.
  ///
  /// A property whose schema describes an action resolves to a function. The
  /// returned callback never throws: a failure inside the action, such as a
  /// call to a function the catalog does not have, is passed to [reportError]
  /// instead, so a broken action cannot take down the page from inside a click
  /// handler.
  Future<void> Function()? action(String key) {
    final Object? value = props[key];
    if (value is! Future<void> Function()) return null;
    return () async {
      try {
        await value();
      } catch (error) {
        reportError(error);
      }
    };
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

/// Renders a component from its resolved properties.
typedef ComponentBuilder = Component Function(ComponentScope scope);

/// A catalog entry: a component's A2UI API paired with how to render it.
///
/// The API side comes from `a2ui_core`, which owns the name and the schema that
/// decides how each property binds. Subclasses add the Jaspr half, so the
/// protocol definition and the renderer stay separable:
///
/// ```dart
/// class DividerComponent extends JasprComponent {
///   @override
///   final ComponentApi api = DividerApi();
///
///   @override
///   Component build(ComponentScope scope) => hr(classes: 'a2ui-divider');
/// }
/// ```
///
/// For a one-off, or in a test, [JasprComponent.inline] takes the two halves
/// directly without a class of their own.
abstract class JasprComponent implements ComponentApi {
  const JasprComponent();

  /// A component from its [api] and a [build] closure.
  const factory JasprComponent.inline(
    ComponentApi api,
    ComponentBuilder build,
  ) = _InlineJasprComponent;

  /// The protocol definition for this component.
  ComponentApi get api;

  /// Renders the component from its resolved properties.
  Component build(ComponentScope scope);

  @override
  String get name => api.name;

  @override
  Schema get schema => api.schema;
}

final class _InlineJasprComponent extends JasprComponent {
  const _InlineJasprComponent(this.api, this._build);

  @override
  final ComponentApi api;

  final ComponentBuilder _build;

  @override
  Component build(ComponentScope scope) => _build(scope);
}
