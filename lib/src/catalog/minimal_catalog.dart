import 'package:a2ui_core/a2ui_core.dart';

import 'components/button.dart';
import 'components/column.dart';
import 'components/row.dart';
import 'components/text.dart';
import 'components/text_field.dart';
import 'jaspr_component.dart';

/// The catalog id this package renders.
///
/// It is the A2UI minimal catalog's own id, taken from `a2ui_core`, because the
/// component names and schemas here are that catalog's rather than ones invented
/// for Jaspr. A model told to target this id produces the same messages it would
/// for any other renderer of the same catalog.
final String minimalJasprCatalogId = MinimalCatalog().id;

/// Every component this package can render, paired with its Jaspr builder.
///
/// The five entries are the A2UI minimal catalog: text, the two flex containers,
/// a button, and a text field. Their schemas come from `a2ui_core` untouched, so
/// what the model is told it may send and what this renders cannot drift apart.
Catalog<JasprComponent> minimalJasprCatalog() {
  return Catalog<JasprComponent>(
    id: minimalJasprCatalogId,
    components: [
      textComponent(),
      rowComponent(),
      columnComponent(),
      buttonComponent(),
      textFieldComponent(),
    ],
    functions: [CapitalizeFunction()],
    themeSchema: MinimalCatalog().themeSchema,
  );
}
