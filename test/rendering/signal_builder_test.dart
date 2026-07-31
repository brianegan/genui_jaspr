import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../support/render.dart';

/// Hands a [SignalBuilder] one of two signals, and can drop it from the tree
/// entirely. Swapping exercises the re-subscribe path, and removing exercises
/// disposal.
class _Host extends StatefulComponent {
  const _Host({required this.a, required this.b, super.key});

  final ReadonlySignal<int> a;
  final ReadonlySignal<int> b;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool _useB = false;
  bool _visible = true;

  void useB() => setState(() => _useB = true);

  void remove() => setState(() => _visible = false);

  @override
  Component build(BuildContext context) {
    if (!_visible) return div([], classes: 'empty');
    return SignalBuilder<int>(
      signal: _useB ? component.b : component.a,
      builder: (context, value) => span([Component.text('v$value')]),
    );
  }
}

void main() {
  group('SignalBuilder', () {
    // The client binding tolerates a setState from initState, but the server's
    // asynchronous build owner asserts on it, and `subscribe` delivers its first
    // callback from exactly there. Server rendering is the only seam that
    // catches it, so it gets its own test.
    test(
      'renders on the server, where setState from initState would assert',
      () async {
        final html = await renderHtml(
          SignalBuilder<int>(
            signal: signal(3),
            builder: (context, value) => span([Component.text('v$value')]),
          ),
        );

        expect(html, '<span>v3</span>');
      },
    );

    testComponents('renders the signal\'s current value', (tester) async {
      tester.pumpComponent(
        SignalBuilder<int>(
          signal: signal(7),
          builder: (context, value) => span([Component.text('v$value')]),
        ),
      );

      expect(find.text('v7'), findsOneComponent);
    });

    testComponents('rebuilds when the signal changes', (tester) async {
      final count = signal(1);

      tester.pumpComponent(
        SignalBuilder<int>(
          signal: count,
          builder: (context, value) => span([Component.text('v$value')]),
        ),
      );
      expect(find.text('v1'), findsOneComponent);

      count.value = 2;
      await tester.pump();

      expect(find.text('v2'), findsOneComponent);
      expect(find.text('v1'), findsNothing);
    });

    testComponents('builds once for the first frame', (tester) async {
      var builds = 0;

      tester.pumpComponent(
        SignalBuilder<int>(
          signal: signal(1),
          builder: (context, value) {
            builds++;
            return span([Component.text('v$value')]);
          },
        ),
      );
      await tester.pump();

      expect(builds, 1);
    });

    testComponents('follows a replacement signal and drops the old one', (
      tester,
    ) async {
      final a = signal(1);
      final b = signal(99);
      final host = GlobalStateKey<_HostState>();

      tester.pumpComponent(_Host(a: a, b: b, key: host));
      expect(find.text('v1'), findsOneComponent);

      host.currentState!.useB();
      await tester.pump();
      expect(find.text('v99'), findsOneComponent);

      b.value = 100;
      await tester.pump();
      expect(find.text('v100'), findsOneComponent);

      // The old signal must no longer drive this component.
      a.value = 5;
      await tester.pump();
      expect(find.text('v100'), findsOneComponent);
      expect(find.text('v5'), findsNothing);
    });

    testComponents('stops listening once removed from the tree', (
      tester,
    ) async {
      final count = signal(1);
      final host = GlobalStateKey<_HostState>();

      tester.pumpComponent(_Host(a: count, b: signal(0), key: host));
      expect(find.text('v1'), findsOneComponent);

      host.currentState!.remove();
      await tester.pump();
      expect(find.text('v1'), findsNothing);

      // Writing to a signal whose subscriber is gone must not throw. Without
      // disposal this reaches setState on a defunct State.
      count.value = 2;
      await tester.pump();

      expect(find.text('v2'), findsNothing);
    });
  });
}
