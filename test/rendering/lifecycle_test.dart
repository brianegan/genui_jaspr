import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../support/render.dart';
import '../support/test_catalog.dart';

/// A surface and the processor still driving it, so a test can keep pushing
/// messages in after the tree is mounted.
typedef _LiveSurface = ({
  MessageProcessor<JasprComponent> processor,
  SurfaceModel<JasprComponent> surface,
});

_LiveSurface _emptySurface() {
  final processor = MessageProcessor<JasprComponent>(
    catalogs: [buildTestCatalog()],
  );
  processor.processMessages([
    A2uiMessage.fromJson({
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': 'main',
        'catalogId': testCatalogId,
        'sendDataModel': true,
      },
    }),
  ]);
  return (
    processor: processor,
    surface: processor.groupModel.getSurface('main')!,
  );
}

void _send(_LiveSurface surface, List<Map<String, dynamic>> components) {
  surface.processor.processMessages([
    A2uiMessage.fromJson({
      'version': 'v0.9',
      'updateComponents': {'surfaceId': 'main', 'components': components},
    }),
  ]);
}

/// Hands a [Surface] one of two surface models, and can drop it from the tree.
///
/// Swapping exercises the re-subscribe path, and removing exercises disposal.
/// Neither happens under server rendering, which builds a tree once and throws
/// it away without ever rebuilding or disposing it.
class _SurfaceHost extends StatefulComponent {
  const _SurfaceHost({required this.a, required this.b, super.key});

  final SurfaceModel<JasprComponent> a;
  final SurfaceModel<JasprComponent> b;

  @override
  State<_SurfaceHost> createState() => _SurfaceHostState();
}

class _SurfaceHostState extends State<_SurfaceHost> {
  bool _useB = false;
  bool _visible = true;

  void useB() => setState(() => _useB = true);

  void remove() => setState(() => _visible = false);

  @override
  Component build(BuildContext context) {
    if (!_visible) return div([], classes: 'empty');
    return Surface(surface: _useB ? component.b : component.a);
  }
}

/// Points one [A2uiComponent] at either of two surfaces, so a test can replace
/// the model underneath a mounted component.
class _ComponentHost extends StatefulComponent {
  const _ComponentHost({required this.a, required this.b, super.key});

  final SurfaceModel<JasprComponent> a;
  final SurfaceModel<JasprComponent> b;

  @override
  State<_ComponentHost> createState() => _ComponentHostState();
}

class _ComponentHostState extends State<_ComponentHost> {
  bool _useB = false;

  void useB() => setState(() => _useB = true);

  @override
  Component build(BuildContext context) {
    return A2uiComponent(
      surface: _useB ? component.b : component.a,
      componentId: 'root',
    );
  }
}

/// A catalog whose container hands [ComponentScope.buildChildren] plain id
/// strings rather than the `ChildNode`s the binder produces.
Catalog<JasprComponent> _rawIdCatalog() {
  return Catalog<JasprComponent>(
    id: testCatalogId,
    components: [
      JasprComponent.inline(
        MinimalTextApi(),
        (scope) => span([Component.text('${scope.props['text']}')]),
      ),
      JasprComponent.inline(
        MinimalColumnApi(),
        (scope) => div(scope.buildChildren(const ['greeting']), classes: 'col'),
      ),
    ],
  );
}

void main() {
  group('Surface lifecycle', () {
    testComponents(
      'watches the replacement surface after its model is swapped',
      (tester) async {
        final a = _emptySurface();
        final b = _emptySurface();
        _send(a, [
          {'id': 'root', 'component': 'Text', 'text': 'from A'},
        ]);
        final host = GlobalStateKey<_SurfaceHostState>();

        tester.pumpComponent(
          _SurfaceHost(a: a.surface, b: b.surface, key: host),
        );
        expect(find.text('from A'), findsOneComponent);

        // B is still empty, so the swap leaves nothing on the page.
        host.currentState!.useB();
        await tester.pump();
        expect(find.text('from A'), findsNothing);

        // The component arrives on B only after the swap. Noticing it means the
        // surface subscribed to B when its model changed.
        _send(b, [
          {'id': 'root', 'component': 'Text', 'text': 'from B'},
        ]);
        await tester.pump();

        expect(find.text('from B'), findsOneComponent);
      },
    );

    testComponents('leaves its model usable after being removed from the tree', (
      tester,
    ) async {
      final a = _emptySurface();
      _send(a, [
        {'id': 'root', 'component': 'Text', 'text': 'from A'},
      ]);
      final host = GlobalStateKey<_SurfaceHostState>();

      tester.pumpComponent(
        _SurfaceHost(a: a.surface, b: _emptySurface().surface, key: host),
      );
      expect(find.text('from A'), findsOneComponent);

      host.currentState!.remove();
      await tester.pump();
      expect(find.text('from A'), findsNothing);

      // Disposal drops this surface's own listeners and nothing else. The model
      // is owned by the caller and outlives the component, so a second Surface
      // over the same model has to work: still rendering what is already there,
      // and still following components that arrive afterwards.
      tester.pumpComponent(Surface(surface: a.surface));
      await tester.pump();
      expect(find.text('from A'), findsOneComponent);

      _send(a, [
        {'id': 'second', 'component': 'Text', 'text': 'after remount'},
        {
          'id': 'root',
          'component': 'Column',
          'children': ['second'],
        },
      ]);
      await tester.pump();

      expect(find.text('after remount'), findsOneComponent);
    });
  });

  group('A2uiComponent lifecycle', () {
    testComponents('rebinds when the surface underneath it is replaced', (
      tester,
    ) async {
      final a = _emptySurface();
      final b = _emptySurface();
      _send(a, [
        {'id': 'root', 'component': 'Text', 'text': 'from A'},
      ]);
      _send(b, [
        {'id': 'root', 'component': 'Text', 'text': 'from B'},
      ]);
      final host = GlobalStateKey<_ComponentHostState>();

      tester.pumpComponent(
        _ComponentHost(a: a.surface, b: b.surface, key: host),
      );
      expect(find.text('from A'), findsOneComponent);

      // Same component id, different surface. The binder has to be rebuilt
      // against the new model, and the watch has to move with it.
      host.currentState!.useB();
      await tester.pump();

      expect(find.text('from B'), findsOneComponent);
      expect(find.text('from A'), findsNothing);
    });

    testComponents('follows the replacement surface after the swap', (
      tester,
    ) async {
      final a = _emptySurface();
      final b = _emptySurface();
      _send(a, [
        {'id': 'root', 'component': 'Text', 'text': 'from A'},
      ]);
      _send(b, [
        {'id': 'root', 'component': 'Text', 'text': 'from B'},
      ]);
      final host = GlobalStateKey<_ComponentHostState>();

      tester.pumpComponent(
        _ComponentHost(a: a.surface, b: b.surface, key: host),
      );
      host.currentState!.useB();
      await tester.pump();
      expect(find.text('from B'), findsOneComponent);

      // Replacing root on B is a delete plus a create under the same id, which
      // only the watch registered on B can notice.
      b.surface.componentsModel.removeComponent('root');
      _send(b, [
        {'id': 'root', 'component': 'Text', 'text': 'B replaced'},
      ]);
      await tester.pump();

      expect(find.text('B replaced'), findsOneComponent);
    });

    test('renders a fallback for an id the surface does not have', () async {
      final a = _emptySurface();
      _send(a, [
        {'id': 'root', 'component': 'Text', 'text': 'from A'},
      ]);

      final html = await renderHtml(
        A2uiComponent(surface: a.surface, componentId: 'ghost'),
      );

      expect(
        html,
        '<div class="a2ui-missing" role="alert">'
        'No component with id "ghost".</div>',
      );
    });

    test('builds children handed to it as plain component ids', () async {
      final processor = MessageProcessor<JasprComponent>(
        catalogs: [_rawIdCatalog()],
      );
      processor.processMessages(
        surfaceMessages(
          components: [
            {'id': 'root', 'component': 'Column', 'children': <String>[]},
            {'id': 'greeting', 'component': 'Text', 'text': 'Hello'},
          ],
        ),
      );

      final html = stripSurface(
        await renderHtml(
          Surface(surface: processor.groupModel.getSurface('main')!),
        ),
      );

      expect(html, '<div class="col"><span>Hello</span></div>');
    });
  });
}
