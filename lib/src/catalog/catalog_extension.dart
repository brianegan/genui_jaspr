import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:jaspr/dom.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Derives new catalogs from an existing one, and reads the styles of any.
///
/// A catalog is immutable, so extending the minimal catalog with an app's own
/// components, or swapping one renderer for another, means building a new one.
/// [copyWith] does that without restating everything that stays the same, and
/// [styles] gathers the rules of whatever the result ended up holding.
extension JasprCatalogComposition on Catalog<JasprComponent> {
  /// The default rules for every class this catalog's components emit.
  ///
  /// Derived rather than declared, so a catalog built with [copyWith] carries
  /// the rules for what it actually holds. Add these to a Jaspr app's styles
  /// for a finished surface, or leave them out and write your own against the
  /// same class names, which nothing in the renderer depends on. The surface
  /// wrapper and the renderer's missing-component fallback are not in here:
  /// no component emits them, so an app styles those two itself.
  List<StyleRule> get styles => [
    for (final component in components.values) ...component.styles,
  ];

  /// A copy of this catalog with some entries changed.
  ///
  /// Components in [add] replace any existing entry with the same name, which
  /// is how a single component's rendering is swapped out. Names in [remove]
  /// are dropped. Functions in [addFunctions] are merged the same way.
  ///
  /// Give the copy its own [id] when its components differ from the original.
  /// The id is what a model is told to target, and a renderer elsewhere that
  /// implements the same id would not know about the additions.
  Catalog<JasprComponent> copyWith({
    String? id,
    Iterable<JasprComponent> add = const [],
    Iterable<String> remove = const [],
    Iterable<FunctionImplementation> addFunctions = const [],
    Schema? themeSchema,
  }) {
    final merged = Map<String, JasprComponent>.of(components)
      ..addEntries(add.map((c) => MapEntry(c.name, c)))
      ..removeWhere((name, _) => remove.contains(name));
    final mergedFunctions = Map<String, FunctionImplementation>.of(functions)
      ..addEntries(addFunctions.map((f) => MapEntry(f.name, f)));

    return Catalog<JasprComponent>(
      id: id ?? this.id,
      components: merged.values.toList(),
      functions: mergedFunctions.values.toList(),
      themeSchema: themeSchema ?? this.themeSchema,
    );
  }
}
