import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart';

import 'a2ui_parser_transformer.dart';
import 'generation_events.dart';

/// Called to send the user's turn to a model.
///
/// This takes the text rather than a chat-message type on purpose. The package
/// stays free of any particular model client, and an app is left to hold the
/// conversation history in whatever shape its client already wants.
typedef SendCallback = Future<void> Function(String text);

/// Feeds a model's output into the A2UI runtime.
///
/// Push chunks in with [addChunk] as they arrive. Parsed messages come out of
/// [incomingMessages], ready for a `MessageProcessor`, and any prose the model
/// wrote comes out of [incomingText] for a chat log.
class A2uiTransportAdapter {
  A2uiTransportAdapter({this.onSend}) {
    _events = _chunks.stream
        .transform(const A2uiParserTransformer())
        .asBroadcastStream();
  }

  /// Called by [sendRequest]. Required only if [sendRequest] is used.
  final SendCallback? onSend;

  final StreamController<String> _chunks = StreamController<String>();
  final StreamController<A2uiMessage> _messages =
      StreamController<A2uiMessage>.broadcast();

  late final Stream<GenerationEvent> _events;
  StreamSubscription<GenerationEvent>? _subscription;

  /// Adds a chunk of the model's output.
  void addChunk(String text) {
    _listen();
    _chunks.add(text);
  }

  /// Adds a message that arrived some other way, such as a tool result.
  void addMessage(A2uiMessage message) {
    _messages.add(message);
  }

  /// The prose the model wrote, in the pieces it arrived in.
  ///
  /// Pieces are passed through unaltered so a caller can append them and get
  /// back what the model actually wrote. Trimming each piece would look tidier
  /// in isolation and quietly corrupt the result, because a chunk boundary that
  /// lands on a space would lose it and join two words together. Whitespace that
  /// merely separates messages never reaches here: the parser recognises it as
  /// part of the protocol.
  Stream<String> get incomingText =>
      _events.whereType<TextEvent>().map((event) => event.text);

  /// The A2UI messages the model produced.
  Stream<A2uiMessage> get incomingMessages => _messages.stream;

  /// Sends [text] to the model through [onSend].
  Future<void> sendRequest(String text) async {
    final SendCallback? send = onSend;
    if (send == null) {
      throw StateError(
        'A2uiTransportAdapter.onSend must be provided to use sendRequest.',
      );
    }
    await send(text);
  }

  /// Closes the chunk stream and waits for everything buffered to be parsed.
  ///
  /// Call this at the end of a response: the parser holds an incomplete trailing
  /// fragment until it knows no more is coming.
  Future<void> flush() async {
    _listen();
    await _chunks.close();
    await _subscription?.asFuture<void>();
  }

  void dispose() {
    _subscription?.cancel();
    if (!_chunks.isClosed) _chunks.close();
    _messages.close();
  }

  /// Starts consuming parsed events.
  ///
  /// Deferred until the first chunk so that a caller has a chance to subscribe
  /// to [incomingText] first, and only ever done once.
  void _listen() {
    _subscription ??= _events.listen((event) {
      if (event is A2uiMessageEvent) _messages.add(event.message);
    }, onError: _messages.addError);
  }
}

extension _WhereType on Stream<GenerationEvent> {
  Stream<T> whereType<T extends GenerationEvent>() =>
      where((event) => event is T).cast<T>();
}
