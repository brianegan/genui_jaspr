import 'package:a2ui_core/a2ui_core.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'jaspr_component.dart';

/// Derives new catalogs from an existing one.
///
/// A catalog is immutable, so extending the minimal catalog with an app's own
/// components, or swapping one renderer for another, means building a new one.
/// This does that without restating everything that stays the same.
extension JasprCatalogComposition on Catalog<JasprComponent> {
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
