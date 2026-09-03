import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/jaspr.dart';

import '../catalog/jaspr_component.dart';
import '../transport/a2ui_parser_transformer.dart';
import '../transport/generation_events.dart';
import 'client_messages.dart';

/// One conversation's worth of generative UI.
///
/// This owns the A2UI runtime for as long as the conversation lasts: the
/// surfaces a model has built so far, the data the user has typed into them,
/// and the catalogs the model may draw on. Each time the model answers, hand
/// its output to [receive] and render the [Reply] that comes back.
///
/// ```dart
/// final conversation = GenUiConversation(
///   catalogs: [minimalJasprCatalog()],
///   onAction: (action) => send(jsonEncode(a2uiActionMessage(action))),
/// );
///
/// final reply = conversation.receive(model.stream(prompt));
/// // reply.text and reply.surfaces fill in as the stream arrives.
/// ```
///
/// Nothing here talks to a model. The package stays free of any particular
/// client, so the app decides how a prompt becomes a `Stream<String>` and what
/// to do with an action once the user presses a generated button.
class GenUiConversation {
  GenUiConversation({
    required List<Catalog<JasprComponent>> catalogs,
    this.onAction,
    this.onError,
  }) : processor = MessageProcessor<JasprComponent>(catalogs: catalogs) {
    processor.groupModel.onAction.addListener(_dispatchAction);
    processor.groupModel.onSurfaceCreated.addListener(_onSurfaceCreated);
    processor.groupModel.onSurfaceDeleted.addListener(_onSurfaceDeleted);
  }

  /// The runtime underneath, for anything this class does not cover.
  final MessageProcessor<JasprComponent> processor;

  /// Called when the user does something in a generated surface, such as
  /// pressing a button.
  ///
  /// The model has no view of the page, so it has to be told. Pass the action
  /// through [a2uiActionMessage] to get the message the protocol defines, and
  /// send it as the next turn.
  final void Function(A2uiClientAction action)? onAction;

  /// Called when something goes wrong that the model should hear about.
  ///
  /// Errors that happen while a reply is being received are also recorded on
  /// that [Reply]. Errors raised later, such as a generated button whose action
  /// fails when pressed, only arrive here.
  final void Function(A2uiClientError error)? onError;

  final Map<String, void Function(A2uiClientError)> _surfaceErrorForwarders =
      {};

  /// The reply currently applying messages, so surfaces it creates and errors it
  /// raises can be attributed to it.
  Reply? _receiving;

  /// The surface with [id], or null if the model has not created it.
  SurfaceModel<JasprComponent>? surface(String id) =>
      processor.groupModel.getSurface(id);

  /// Every surface the model has created and not deleted.
  Iterable<SurfaceModel<JasprComponent>> get surfaces =>
      processor.groupModel.allSurfaces;

  /// What the user has entered so far, in the shape the protocol sends it.
  ///
  /// Covers every surface created with `sendDataModel: true`, keyed by surface
  /// id, and is null when no surface asked for it. Send this alongside an action
  /// so the model can act on what was typed.
  Map<String, dynamic>? clientDataModel() => processor.getClientDataModel();

  /// What to send the model when the user triggers [action].
  ///
  /// The protocol's action message, then the client data model when any surface
  /// asked for it, each as a line of JSON. A chat app sends this as the user's
  /// next turn. Apps that need another shape compose their own from
  /// [a2uiActionMessage] and [clientDataModel].
  String actionText(A2uiClientAction action) {
    final Map<String, dynamic>? dataModel = clientDataModel();
    return [
      jsonEncode(a2uiActionMessage(action)),
      if (dataModel != null) jsonEncode(dataModel),
    ].join('\n');
  }

  /// Feeds one model reply in as it streams, and returns it as a [Reply].
  ///
  /// The reply is returned at once and fills in as [chunks] arrive: prose lands
  /// in [Reply.text], each `createSurface` adds to [Reply.surfaces], and later
  /// messages update those surfaces in place. Listen to the reply, or await
  /// [Reply.done], to follow along.
  ///
  /// Pass a [surfaceId] to render this reply into a surface named by the app
  /// rather than by the model. Every message in the reply is redirected to it,
  /// so a model that reuses an id across turns cannot overwrite an earlier
  /// answer. Leave it null to let the model manage surface ids itself, which is
  /// what lets one reply revise a surface from an earlier one.
  Reply receive(Stream<String> chunks, {String? surfaceId}) {
    return _receive(
      chunks.transform(const A2uiParserTransformer()),
      surfaceId: surfaceId,
    );
  }

  /// As [receive], for a reply that arrives as messages rather than text.
  ///
  /// For transports that deliver A2UI already parsed, such as an A2A agent or a
  /// tool result, so they need not be serialized to text to be re-parsed here.
  /// The reply has no prose; a failure of the stream is [Reply.failure].
  Reply receiveMessages(Stream<A2uiMessage> messages, {String? surfaceId}) {
    return _receive(messages.map(A2uiMessageEvent.new), surfaceId: surfaceId);
  }

  Reply _receive(Stream<GenerationEvent> events, {String? surfaceId}) {
    final reply = Reply._();
    events.listen(
      (event) => switch (event) {
        TextEvent(:final text) => reply._addText(text),
        A2uiMessageEvent(:final message) => _apply(
          reply,
          surfaceId == null ? message : _retarget(message, surfaceId),
        ),
      },
      onError: (Object error) {
        if (error is A2uiValidationException) {
          // The model wrote something that was meant as a message and is not
          // one. That is the model's mistake, so it is recorded for the model.
          _report(reply, clientErrorFrom(error, surfaceId: surfaceId ?? ''));
        } else {
          // Not a bad message but a failed stream: the model call itself
          // broke. The parser passes the source's own errors through.
          reply._fail(error);
        }
      },
      onDone: reply._complete,
      cancelOnError: false,
    );
    return reply;
  }

  void _apply(Reply reply, A2uiMessage message) {
    _receiving = reply;
    try {
      processor.processMessages([message]);
    } catch (error) {
      _report(reply, clientErrorFrom(error, surfaceId: _surfaceIdOf(message)));
    } finally {
      _receiving = null;
    }
  }

  void _report(Reply reply, A2uiClientError error) {
    reply._addError(error);
    onError?.call(error);
  }

  void _dispatchAction(A2uiClientAction action) => onAction?.call(action);

  void _onSurfaceCreated(SurfaceModel<JasprComponent> surface) {
    // A surface raises errors from user interaction, which happens after its
    // reply has been received, so these are the conversation's rather than any
    // reply's.
    void forward(A2uiClientError error) => onError?.call(error);

    surface.onError.addListener(forward);
    _surfaceErrorForwarders[surface.id] = forward;
    _receiving?._addSurface(surface);
  }

  void _onSurfaceDeleted(String surfaceId) {
    // The surface has already been disposed along with its listeners; only the
    // bookkeeping remains.
    _surfaceErrorForwarders.remove(surfaceId);
  }

  /// Releases every surface. Replies handed out earlier can no longer be
  /// rendered.
  void dispose() {
    processor.groupModel.onAction.removeListener(_dispatchAction);
    processor.groupModel.onSurfaceCreated.removeListener(_onSurfaceCreated);
    processor.groupModel.onSurfaceDeleted.removeListener(_onSurfaceDeleted);
    processor.groupModel.dispose();
    _surfaceErrorForwarders.clear();
  }
}

/// Rewrites [message] to target [surfaceId].
///
/// Every message body carries its own `surfaceId`, so the rewrite is the same
/// regardless of which of the four kinds it is.
A2uiMessage _retarget(A2uiMessage message, String surfaceId) {
  final Map<String, dynamic> json = message.toJson();
  for (final Object? body in json.values) {
    if (body is Map<String, dynamic> && body.containsKey('surfaceId')) {
      body['surfaceId'] = surfaceId;
    }
  }
  return A2uiMessage.fromJson(json);
}

/// The surface [message] concerns, read the same way [_retarget] writes it.
String _surfaceIdOf(A2uiMessage message) {
  for (final Object? body in message.toJson().values) {
    if (body is Map<String, dynamic> && body['surfaceId'] is String) {
      return body['surfaceId'] as String;
    }
  }
  return '';
}

/// One model reply, filling in as it streams.
///
/// A reply is a [Listenable], so a `ListenableBuilder` over it re-renders as
/// prose and surfaces arrive. The surfaces it lists are live models owned by
/// the [GenUiConversation]: render each with a `Surface`, and they keep
/// updating as later messages in the same reply change them.
class Reply extends ChangeNotifier {
  Reply._();

  final StringBuffer _text = StringBuffer();
  final List<SurfaceModel<JasprComponent>> _surfaces = [];
  final List<A2uiClientError> _errors = [];
  final Completer<void> _done = Completer<void>();
  Object? _failure;

  /// The prose the model has written so far, exactly as it wrote it.
  String get text => _text.toString();

  /// The surfaces this reply has created, in the order they were created.
  List<SurfaceModel<JasprComponent>> get surfaces =>
      List.unmodifiable(_surfaces);

  /// Messages in this reply that could not be applied.
  ///
  /// A malformed message, a surface created twice, or a catalog the app does
  /// not have all land here rather than stopping the reply. Each is in the
  /// shape the protocol sends back to a model, see `a2uiErrorMessage`.
  List<A2uiClientError> get errors => List.unmodifiable(_errors);

  /// Whether the model has finished, one way or another.
  bool get isComplete => _done.isCompleted;

  /// Why the reply stopped early, when the model call itself failed.
  ///
  /// Distinct from [errors], which are the model's mistakes. This is the
  /// network's, or the server's. Null while streaming and after a clean end.
  Object? get failure => _failure;

  /// Completes when the model has finished, whether cleanly or with [failure].
  ///
  /// Never completes with an error, so awaiting it in a UI is safe. Check
  /// [failure] afterwards.
  Future<void> get done => _done.future;

  /// Whether the model produced neither words nor a surface.
  bool get isEmpty => _text.isEmpty && _surfaces.isEmpty;

  void _addText(String text) {
    _text.write(text);
    notifyListeners();
  }

  void _addSurface(SurfaceModel<JasprComponent> surface) {
    _surfaces.add(surface);
    notifyListeners();
  }

  void _addError(A2uiClientError error) {
    _errors.add(error);
    notifyListeners();
  }

  void _fail(Object error) {
    _failure = error;
    _complete();
  }

  void _complete() {
    if (_done.isCompleted) return;
    _done.complete();
    notifyListeners();
  }
}
