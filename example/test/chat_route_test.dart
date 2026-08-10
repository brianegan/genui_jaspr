import 'dart:convert';

import 'package:genui_jaspr_example/server/chat_route.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Future<List<String>> post(Handler handler, Object? body) async {
  final response = await handler(
    Request(
      'POST',
      Uri.parse('http://localhost/api/chat'),
      body: jsonEncode(body),
    ),
  );
  final String text = await response.readAsString();
  return text
      .split('\n\n')
      .map((frame) => frame.trim())
      .where((frame) => frame.isNotEmpty)
      .toList();
}

void main() {
  group('chatRoute', () {
    test('sends one message frame per chunk', () async {
      final handler = chatRoute(
        (prompt) => Stream.fromIterable(['Hello ', 'there']),
      );

      final frames = await post(handler, {'data': 'hi'});

      expect(frames[0], 'data: {"message":"Hello "}');
      expect(frames[1], 'data: {"message":"there"}');
    });

    test('ends with the result frame the client requires', () async {
      final handler = chatRoute(
        (prompt) => Stream.fromIterable(['Hello ', 'there']),
      );

      final frames = await post(handler, {'data': 'hi'});

      // Genkit's client throws if the stream finishes without this.
      expect(frames.last, 'data: {"result":"Hello there"}');
    });

    test('passes the prompt to the model', () async {
      final seen = <String>[];
      final handler = chatRoute((prompt) {
        seen.add(prompt);
        return const Stream<String>.empty();
      });

      await post(handler, {'data': 'plan me a trip'});

      expect(seen, ['plan me a trip']);
    });

    test('still ends with a result frame when the reply is empty', () async {
      final handler = chatRoute((prompt) => const Stream<String>.empty());

      final frames = await post(handler, {'data': 'hi'});

      expect(frames, ['data: {"result":""}']);
    });

    test('reports a model failure in band', () async {
      final handler = chatRoute(
        (prompt) => Stream<String>.error(StateError('model unavailable')),
      );

      final frames = await post(handler, {'data': 'hi'});

      expect(frames.single, startsWith('error: '));
      expect(frames.single, contains('model unavailable'));
    });

    test('reads the prompt out of a map payload', () async {
      final seen = <String>[];
      final handler = chatRoute((prompt) {
        seen.add(prompt);
        return const Stream<String>.empty();
      });

      await post(handler, {
        'data': {'prompt': 'plan me a trip'},
      });

      expect(seen, ['plan me a trip']);
    });

    test('rejects a body that is not JSON', () async {
      final handler = chatRoute((prompt) => const Stream<String>.empty());

      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/chat'),
          body: 'not json',
        ),
      );

      expect(response.statusCode, 400);
    });

    test('rejects a request with no prompt', () async {
      final handler = chatRoute((prompt) => const Stream<String>.empty());

      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/chat'),
          body: jsonEncode({'nothing': true}),
        ),
      );

      expect(response.statusCode, 400);
    });

    test('rejects a GET', () async {
      final handler = chatRoute((prompt) => const Stream<String>.empty());

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/api/chat')),
      );

      expect(response.statusCode, 405);
    });
  });
}
