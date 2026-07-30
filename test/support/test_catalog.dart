import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// A catalog with deliberately plain builders, so a renderer test asserts on
/// the renderer's structure rather than on the real catalog's styling.
///
/// The component APIs are the real ones from `a2ui_core`, so the schemas that
/// drive binding behaviour are the same ones production uses.
const testCatalogId = 'test-catalog';

Catalog<JasprComponent> buildTestCatalog() {
  return Catalog<JasprComponent>(
    id: testCatalogId,
    components: [
      JasprComponent(
        MinimalTextApi(),
        (scope) => span([Component.text('${scope.props['text']}')]),
      ),
      JasprComponent(
        MinimalRowApi(),
        (scope) =>
            div(scope.buildChildren(scope.props['children']), classes: 'row'),
      ),
      JasprComponent(
        MinimalColumnApi(),
        (scope) =>
            div(scope.buildChildren(scope.props['children']), classes: 'col'),
      ),
    ],
  );
}

/// Builds the canned messages for a surface, ready for [MessageProcessor].
List<A2uiMessage> surfaceMessages({
  String surfaceId = 'main',
  String catalogId = testCatalogId,
  Map<String, dynamic>? theme,
  required List<Map<String, dynamic>> components,
}) {
  return [
    A2uiMessage.fromJson({
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': surfaceId,
        'catalogId': catalogId,
        'theme': ?theme,
        'sendDataModel': true,
      },
    }),
    A2uiMessage.fromJson({
      'version': 'v0.9',
      'updateComponents': {'surfaceId': surfaceId, 'components': components},
    }),
  ];
}
