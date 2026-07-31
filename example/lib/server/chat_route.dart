import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Produces a model's reply to [prompt] as a stream of text chunks.
///
/// Taken as a parameter so the route can be exercised without calling a model.
typedef ReplyStream = Stream<String> Function(String prompt);

/// Serves a streaming reply over Genkit's flow protocol.
///
/// The wire format is Genkit's, not one invented here, which is what lets the
/// browser use `defineRemoteAction` and get a typed stream with server errors
/// propagated. Frames are separated by a blank line:
///
/// ```
/// data: {"message": "<chunk>"}
/// data: {"result": "<whole reply>"}
/// ```
///
/// The final `result` frame is not optional. A client that reaches the end of the
/// stream without one throws, so a route that forgets it looks like it works
/// right up until the reply finishes.
Handler chatRoute(ReplyStream reply) {
  return (Request request) async {
    if (request.method != 'POST') {
      return Response(405, body: 'Use POST.');
    }

    final String body = await request.readAsString();
    final String prompt = _promptFrom(body);
    if (prompt.isEmpty) {
      return Response.badRequest(body: 'Expected {"data": "<prompt>"}.');
    }

    return Response.ok(
      _frames(reply(prompt)),
      headers: {
        'content-type': 'text/event-stream',
        'cache-control': 'no-cache',
      },
      context: {'shelf.io.buffer_output': false},
    );
  };
}

/// Reads the prompt out of a Genkit flow request, whose payload is `{"data": …}`.
String _promptFrom(String body) {
  if (body.isEmpty) return '';
  try {
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map) return '';
    final Object? data = decoded['data'];
    if (data is String) return data;
    if (data is Map && data['prompt'] is String) {
      return data['prompt'] as String;
    }
    return '';
  } on FormatException {
    return '';
  }
}

/// Wraps [chunks] in Genkit's frames, ending with the mandatory result.
Stream<List<int>> _frames(Stream<String> chunks) async* {
  final whole = StringBuffer();
  try {
    await for (final String chunk in chunks) {
      if (chunk.isEmpty) {
        continue;
      }
      whole.write(chunk);
      yield _frame('data', {'message': chunk});
    }
    yield _frame('data', {'result': whole.toString()});
  } catch (error) {
    // Reported in-band, because the response status has already been sent.
    yield _frame('error', {
      'error': {'message': '$error'},
    });
  }
}

List<int> _frame(String label, Map<String, Object?> payload) =>
    utf8.encode('$label: ${jsonEncode(payload)}\n\n');
