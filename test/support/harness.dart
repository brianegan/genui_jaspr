import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'render.dart';

/// Drives [components] through the real message processor and the real catalog,
/// then returns the HTML a browser would receive.
///
/// Every catalog test goes through this, so what is under test is the same path
/// production uses: messages in, binder in the middle, markup out.
Future<String> renderSurface(
  List<Map<String, dynamic>> components, {
  Map<String, Object?> data = const {},
  Map<String, dynamic>? theme,
  Catalog<JasprComponent>? catalog,
}) async {
  final surface = buildSurfaceModel(
    components,
    data: data,
    theme: theme,
    catalog: catalog,
  );
  return stripSurface(await renderHtml(Surface(surface: surface)));
}

/// As [renderSurface], but keeps the surface wrapper element.
Future<String> renderSurfaceRaw(
  List<Map<String, dynamic>> components, {
  Map<String, Object?> data = const {},
  Map<String, dynamic>? theme,
}) async {
  final surface = buildSurfaceModel(components, data: data, theme: theme);
  return renderHtml(Surface(surface: surface));
}

/// Builds a populated surface, for tests that need the model itself rather than
/// only its markup.
SurfaceModel<JasprComponent> buildSurfaceModel(
  List<Map<String, dynamic>> components, {
  Map<String, Object?> data = const {},
  Map<String, dynamic>? theme,
  void Function(A2uiClientAction)? onAction,
  Catalog<JasprComponent>? catalog,
}) {
  final activeCatalog = catalog ?? MinimalJasprCatalog();
  final processor =
      MessageProcessor<JasprComponent>(
        catalogs: [activeCatalog],
        onAction: onAction,
      )..processMessages([
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': activeCatalog.id,
            'theme': ?theme,
            'sendDataModel': true,
          },
        }),
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'updateComponents': {'surfaceId': 'main', 'components': components},
        }),
      ]);

  final surface = processor.groupModel.getSurface('main')!;
  data.forEach(surface.dataModel.set);
  return surface;
}

/// Renders a surface built by [buildSurfaceModel].
Future<String> renderSurfaceModel(SurfaceModel<JasprComponent> surface) {
  return renderHtml(Surface(surface: surface));
}

/// The component to pump when a test needs to click or type.
Component surfaceComponent(SurfaceModel<JasprComponent> surface) {
  return Surface(surface: surface);
}

/// Mounts a live tree whose only catalog entry records the scope it is handed,
/// so a test can exercise the contract between the renderer and a builder.
///
/// Used for the parts of that contract a VM test cannot reach through the
/// DOM, such as the setter behind a two-way bound property: the browser
/// calls it from a real input event, which needs a real input element. The
/// component API is the real one, so the schema driving the binder is
/// production's.
///
/// The tree stays mounted, because a setter writes to the data model and
/// that in turn rebuilds whatever is watching. Calling it against a
/// torn-down tree would fail for reasons that have nothing to do with the
/// setter.
Future<({ComponentScope scope, SurfaceModel<JasprComponent> surface})>
captureScope(
  ComponentTester tester,
  ComponentApi api,
  List<Map<String, dynamic>> components, {
  Map<String, Object?> data = const {},
}) async {
  ComponentScope? captured;
  final processor =
      MessageProcessor<JasprComponent>(
        catalogs: [
          Catalog<JasprComponent>(
            id: MinimalJasprCatalog.catalogId,
            components: [
              JasprComponent.inline(api, (scope) {
                captured = scope;
                return const Component.empty();
              }),
            ],
          ),
        ],
      )..processMessages([
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': MinimalJasprCatalog.catalogId,
            'sendDataModel': true,
          },
        }),
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'updateComponents': {'surfaceId': 'main', 'components': components},
        }),
      ]);

  final surface = processor.groupModel.getSurface('main')!;
  data.forEach(surface.dataModel.set);

  tester.pumpComponent(Surface(surface: surface));
  await tester.pump();
  return (scope: captured!, surface: surface);
}
