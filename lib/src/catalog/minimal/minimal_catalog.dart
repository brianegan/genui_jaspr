import 'package:a2ui_core/a2ui_core.dart';

import 'package:genui_jaspr/src/catalog/jaspr_component.dart';
import 'package:genui_jaspr/src/catalog/minimal/components/button.dart';
import 'package:genui_jaspr/src/catalog/minimal/components/column.dart';
import 'package:genui_jaspr/src/catalog/minimal/components/row.dart';
import 'package:genui_jaspr/src/catalog/minimal/components/text.dart';
import 'package:genui_jaspr/src/catalog/minimal/components/text_field.dart';

/// The A2UI minimal catalog, rendered to HTML.
///
/// The five entries are `a2ui_core`'s `MinimalCatalog`: text, the two flex
/// containers, a button, and a text field. Their schemas and the catalog's [id]
/// come from there untouched, so what the model is told it may send and what
/// this renders cannot drift apart, and a model told to target this id produces
/// the same messages it would for any other renderer of the same catalog.
///
/// Derive a catalog with more in it, or a different renderer for one component,
/// with `copyWith`.
class MinimalJasprCatalog extends Catalog<JasprComponent> {
  /// Creates a [MinimalJasprCatalog].
  MinimalJasprCatalog()
    : super(
        id: catalogId,
        components: [
          TextComponent(),
          RowComponent(),
          ColumnComponent(),
          ButtonComponent(),
          TextFieldComponent(),
        ],
        functions: [CapitalizeFunction()],
        themeSchema: MinimalCatalog().themeSchema,
      );

  /// The A2UI minimal catalog's own id, which is also this catalog's `id`.
  static final String catalogId = MinimalCatalog().id;
}
