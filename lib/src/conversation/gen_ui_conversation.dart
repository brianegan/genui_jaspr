import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';

import '../catalog/jaspr_component.dart';
import '../transport/a2ui_parser_transformer.dart';
import '../transport/generation_events.dart';
import 'client_messages.dart';
import 'gen_ui_event.dart';

/// One conversation's worth of generative UI.
///
/// This owns the A2UI runtime for as long as the conversation lasts: the
/// surfaces a model has built so far, the data the user has typed into them,
/// and the catalogs the model may draw on. Each time the model answers, hand
/// its output to [receive] and render the events that come back.
///
/// ```dart
/// final conversation = GenUiConversation(
///   catalogs: [MinimalJasprCatalog()],
///   onAction: (action) => send(conversation.actionText(action)),
/// );
///
/// final Stream<GenUiEvent> reply = conversation.receive(model.stream(prompt));
/// // GenUiText, GenUiSurface, and GenUiError events arrive as the model writes.
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
    this.onSurfaceDeleted,
  }) : processor = MessageProcessor<JasprComponent>(catalogs: catalogs) {
    processor.groupModel.onAction.addListener(_onAction);
    processor.groupModel.onSurfaceCreated.addListener(_onSurfaceCreated);
    processor.groupModel.onSurfaceDeleted.addListener(_onSurfaceDeleted);
  }

  /// The runtime underneath, for anything this class does not cover.
  final MessageProcessor<JasprComponent> processor;

  /// Called when the user does something in a generated surface, such as
  /// pressing a button.
  ///
  /// The model has no view of the page, so it has to be told. [actionText]
  /// composes the text to send it as the next turn.
  final void Function(A2uiClientAction action)? onAction;

  /// Called for everything that goes wrong that the model should hear about.
  ///
  /// Errors inside a reply also arrive on that reply's own stream as
  /// [GenUiError]. Errors raised later, such as a generated button whose action
  /// fails when pressed, only arrive here.
  final void Function(A2uiClientError error)? onError;

  /// Called with the id of a surface the model has deleted.
  ///
  /// A deleted surface's model is disposed, and a `Surface` still showing it
  /// renders its placeholder the next time it builds. Use this to drop it from
  /// wherever the app keeps it.
  final void Function(String surfaceId)? onSurfaceDeleted;

  /// The events of the reply currently applying messages, so the surfaces it
  /// creates can be attributed to it.
  StreamSink<GenUiEvent>? _receiving;

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

  /// Applies one model reply as it streams, and reports what it produces.
  ///
  /// Prose arrives as [GenUiText], each surface the model opens as
  /// [GenUiSurface], and each message it got wrong as [GenUiError]. A failure
  /// of [chunks] itself is an error on the returned stream, which then ends. The
  /// stream is single-subscription and does nothing until it is listened to.
  /// `ReplyBuilder` folds it into something a component can render.
  ///
  /// Pass a [surfaceId] to render this reply into a surface named by the app
  /// rather than by the model. Every message in the reply is redirected to it,
  /// so a model that reuses an id across turns cannot overwrite an earlier
  /// answer. Leave it null to let the model manage surface ids itself, which is
  /// what lets one reply revise a surface from an earlier one.
  Stream<GenUiEvent> receive(Stream<String> chunks, {String? surfaceId}) {
    return _receive(
      chunks.transform(const A2uiParserTransformer()),
      surfaceId: surfaceId,
    );
  }

  /// As [receive], for a reply that arrives as messages rather than text.
  ///
  /// For transports that deliver A2UI already parsed, such as an A2A agent or a
  /// tool result, so they need not be serialized to text to be re-parsed here.
  /// Such a reply has no prose.
  Stream<GenUiEvent> receiveMessages(
    Stream<A2uiMessage> messages, {
    String? surfaceId,
  }) {
    return _receive(messages.map(A2uiMessageEvent.new), surfaceId: surfaceId);
  }

  Stream<GenUiEvent> _receive(
    Stream<GenerationEvent> events, {
    String? surfaceId,
  }) {
    late final StreamController<GenUiEvent> out;
    StreamSubscription<GenerationEvent>? subscription;

    out = StreamController<GenUiEvent>(
      onListen: () {
        subscription = events.listen(
          (event) => switch (event) {
            TextEvent(:final text) => out.add(GenUiText(text)),
            A2uiMessageEvent(:final message) => _apply(
              out,
              surfaceId == null ? message : _retarget(message, surfaceId),
            ),
          },
          onError: (Object error, StackTrace stack) {
            if (error is A2uiValidationException) {
              // The model wrote something that was meant as a message and is
              // not one. That is the model's mistake, so the reply carries on.
              _report(out, clientErrorFrom(error, surfaceId: surfaceId ?? ''));
            } else {
              // Not a bad message but a failed stream: the model call itself
              // broke. The parser passes the source's own errors through.
              out.addError(error, stack);
            }
          },
          onDone: out.close,
          cancelOnError: false,
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () => subscription?.cancel(),
    );
    return out.stream;
  }

  void _apply(StreamSink<GenUiEvent> out, A2uiMessage message) {
    _receiving = out;
    try {
      processor.processMessages([message]);
    } catch (error) {
      _report(out, clientErrorFrom(error, surfaceId: _surfaceIdOf(message)));
    } finally {
      _receiving = null;
    }
  }

  void _report(StreamSink<GenUiEvent> out, A2uiClientError error) {
    out.add(GenUiError(error));
    onError?.call(error);
  }

  void _onAction(A2uiClientAction action) => onAction?.call(action);

  void _onLaterError(A2uiClientError error) => onError?.call(error);

  void _onSurfaceDeleted(String surfaceId) => onSurfaceDeleted?.call(surfaceId);

  void _onSurfaceCreated(SurfaceModel<JasprComponent> surface) {
    // A surface raises errors from user interaction, which happens after its
    // reply has ended, so those are the conversation's rather than any reply's.
    surface.onError.addListener(_onLaterError);
    _receiving?.add(GenUiSurface(surface));
  }

  /// Releases every surface. Surfaces handed out earlier can no longer be
  /// rendered, and no callback fires afterwards.
  void dispose() {
    processor.groupModel.onAction.removeListener(_onAction);
    processor.groupModel.onSurfaceCreated.removeListener(_onSurfaceCreated);
    processor.groupModel.onSurfaceDeleted.removeListener(_onSurfaceDeleted);
    processor.groupModel.dispose();
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
