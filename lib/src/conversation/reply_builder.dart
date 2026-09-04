import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/jaspr.dart';

import '../catalog/jaspr_component.dart';
import 'gen_ui_event.dart';

/// What a model reply has produced so far.
///
/// A snapshot, folded from a reply's [GenUiEvent]s by [ReplyBuilder]. The
/// surfaces in it are live models owned by the `GenUiConversation`, so they
/// keep updating after the snapshot was taken; everything else is fixed.
final class Reply {
  const Reply._({
    required this.text,
    required this.surfaces,
    required this.errors,
    required this.failure,
    required this.isComplete,
  });

  /// A reply nothing has arrived for yet.
  const Reply.empty()
    : text = '',
      surfaces = const [],
      errors = const [],
      failure = null,
      isComplete = false;

  /// The prose the model has written so far, exactly as it wrote it.
  final String text;

  /// The surfaces this reply opened, in the order it opened them.
  final List<SurfaceModel<JasprComponent>> surfaces;

  /// The messages in this reply that could not be applied.
  final List<A2uiClientError> errors;

  /// Why the reply stopped early, when the model call itself failed.
  ///
  /// Distinct from [errors], which are the model's mistakes. Null while the
  /// reply is streaming and after a clean end.
  final Object? failure;

  /// Whether the reply has ended, cleanly or with a [failure].
  final bool isComplete;

  /// Whether the model has produced neither words nor a surface.
  bool get isEmpty => text.isEmpty && surfaces.isEmpty;

  Reply _after(GenUiEvent event) => switch (event) {
    GenUiText(:final text) => _with(text: this.text + text),
    GenUiSurface(:final surface) => _with(
      surfaces: List.unmodifiable([...surfaces, surface]),
    ),
    GenUiError(:final error) => _with(
      errors: List.unmodifiable([...errors, error]),
    ),
  };

  Reply _with({
    String? text,
    List<SurfaceModel<JasprComponent>>? surfaces,
    List<A2uiClientError>? errors,
    Object? failure,
    bool? isComplete,
  }) {
    return Reply._(
      text: text ?? this.text,
      surfaces: surfaces ?? this.surfaces,
      errors: errors ?? this.errors,
      failure: failure ?? this.failure,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// Renders a model reply as it streams in.
///
/// Folds the [events] from `GenUiConversation.receive` into a [Reply] and
/// rebuilds with each one, so a transcript entry fills in while the model is
/// still writing:
///
/// ```dart
/// ReplyBuilder(
///   events: conversation.receive(model.stream(prompt)),
///   builder: (context, reply) => div([
///     p([Component.text(reply.text)]),
///     for (final surface in reply.surfaces) Surface(surface: surface),
///   ]),
/// )
/// ```
///
/// Keep the stream in state rather than calling `receive` in `build`: a
/// different stream instance makes this resubscribe, and a reply's stream can
/// only be listened to once. This is that one listener, so anything else that
/// needs to know how the reply ended, such as a transcript re-enabling its
/// composer, gets it from [onComplete] rather than a second subscription. Like
/// every stream builder in Jaspr, this cannot run on the server, where a reply
/// cannot exist anyway.
class ReplyBuilder extends StreamBuilderBase<GenUiEvent, Reply> {
  const ReplyBuilder({
    required Stream<GenUiEvent> events,
    required this.builder,
    this.onComplete,
    super.key,
  }) : super(stream: events);

  /// Builds the reply as it stands after each event.
  final Component Function(BuildContext context, Reply reply) builder;

  /// Called once, when the reply has ended, with the finished [Reply].
  ///
  /// The reply's [Reply.failure] says whether the model call broke, and
  /// [Reply.isEmpty] whether it produced anything worth keeping.
  final void Function(Reply reply)? onComplete;

  @override
  Reply initial() => const Reply.empty();

  @override
  Reply afterData(Reply current, GenUiEvent data) => current._after(data);

  @override
  Reply afterError(Reply current, Object error, StackTrace stackTrace) =>
      current._with(failure: error);

  @override
  Reply afterDone(Reply current) {
    final Reply complete = current._with(isComplete: true);
    onComplete?.call(complete);
    return complete;
  }

  @override
  Component build(BuildContext context, Reply currentSummary) =>
      builder(context, currentSummary);
}
