import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/jaspr.dart';

/// Builds a component from the current value of [signal] and rebuilds whenever
/// that value changes.
///
/// `a2ui_core` reports change through `preact_signals`, while Jaspr rebuilds
/// through [State.setState]. This is the seam between the two, and every part
/// of the renderer that reacts to A2UI data goes through it.
///
/// `subscribe` is built on an effect, and effects run once immediately so they
/// can record their dependencies. That first callback therefore arrives while
/// `initState` is still on the stack, carrying the value this state already
/// read. It has to be dropped: during server rendering, calling `setState`
/// there trips an assertion in Jaspr's asynchronous build owner. The client
/// binding happens to tolerate it, so this is only reproducible by rendering on
/// the server.
///
/// Writing a value equal to the current one does not notify at all, so repeated
/// identical data from a model needs no filtering here.
class SignalBuilder<T> extends StatefulComponent {
  /// Creates a [SignalBuilder] over [signal].
  const SignalBuilder({required this.signal, required this.builder, super.key});

  /// The signal to read and watch.
  final ReadonlySignal<T> signal;

  /// Called with the signal's current value on every build.
  final Component Function(BuildContext context, T value) builder;

  @override
  State<SignalBuilder<T>> createState() => _SignalBuilderState<T>();
}

class _SignalBuilderState<T> extends State<SignalBuilder<T>> {
  late T _value;
  void Function()? _unsubscribe;

  /// Whether the subscription's immediate, synchronous callback has been seen.
  bool _sawInitialCallback = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _value = component.signal.value;
    _sawInitialCallback = false;
    _unsubscribe = component.signal.subscribe((value) {
      if (!_sawInitialCallback) {
        _sawInitialCallback = true;
        return;
      }
      setState(() => _value = value);
    });
  }

  @override
  void didUpdateComponent(SignalBuilder<T> oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.signal != component.signal) {
      _unsubscribe?.call();
      _listen();
    }
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _unsubscribe = null;
    super.dispose();
  }

  @override
  Component build(BuildContext context) => component.builder(context, _value);
}
