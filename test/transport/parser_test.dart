import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:test/test.dart';

/// Feeds [chunks] through the parser exactly as they arrive, so a test can put
/// the split anywhere it likes.
Future<List<GenerationEvent>> parse(List<String> chunks) {
  return Stream.fromIterable(
    chunks,
  ).transform(const A2uiParserTransformer()).toList();
}

List<String> textsOf(List<GenerationEvent> events) => events
    .whereType<TextEvent>()
    .map((event) => event.text.trim())
    .where((text) => text.isNotEmpty)
    .toList();

List<A2uiMessage> messagesOf(List<GenerationEvent> events) =>
    events.whereType<A2uiMessageEvent>().map((event) => event.message).toList();

const createSurfaceJson = '''
{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"c","sendDataModel":true}}''';

void main() {
  group('A2uiParserTransformer', () {
    test('parses a fenced message arriving in one chunk', () async {
      final events = await parse(['```json\n$createSurfaceJson\n```']);

      final messages = messagesOf(events);
      expect(messages, hasLength(1));
      expect(messages.single, isA<CreateSurfaceMessage>());
      expect((messages.single as CreateSurfaceMessage).surfaceId, 'main');
    });

    test('parses a message split across chunk boundaries', () async {
      // The split lands inside the JSON, which is the case that makes buffering
      // necessary at all.
      const whole = '```json\n$createSurfaceJson\n```';
      final events = await parse([
        whole.substring(0, 20),
        whole.substring(20, 45),
        whole.substring(45),
      ]);

      expect(messagesOf(events), hasLength(1));
    });

    test('parses a message split one character at a time', () async {
      const whole = '```json\n$createSurfaceJson\n```';
      final events = await parse(whole.split(''));

      expect(messagesOf(events), hasLength(1));
      expect(textsOf(events), isEmpty);
    });

    test('holds back a chunk that ends inside the fence marker', () async {
      // A boundary here is the awkward case: a search for the full marker finds
      // nothing, so a naive parser shows the stray backticks as prose and then
      // fails to recognise the message.
      final events = await parse([
        'Here you go.\n``',
        '`json\n$createSurfaceJson\n```',
      ]);

      expect(messagesOf(events), hasLength(1));
      expect(textsOf(events), ['Here you go.']);
    });

    test('separates prose around a message from the message itself', () async {
      final events = await parse([
        'Here is a form for you.\n',
        '```json\n$createSurfaceJson\n```',
        '\nLet me know if that works.',
      ]);

      expect(messagesOf(events), hasLength(1));
      expect(textsOf(events), [
        'Here is a form for you.',
        'Let me know if that works.',
      ]);
    });

    test('parses several messages from one stream', () async {
      const update = '''
{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Text","text":"hi"}]}}''';

      final events = await parse([
        '```json\n$createSurfaceJson\n```\n',
        '```json\n$update\n```',
      ]);

      final messages = messagesOf(events);
      expect(messages, hasLength(2));
      expect(messages[0], isA<CreateSurfaceMessage>());
      expect(messages[1], isA<UpdateComponentsMessage>());
    });

    test('parses a bare message with no fence', () async {
      final events = await parse([createSurfaceJson]);

      expect(messagesOf(events), hasLength(1));
    });

    test('does not end an object at a brace inside a string value', () async {
      // Model-written copy contains braces and quotes. Counting braces without
      // tracking string state would cut the message short here.
      const json =
          '{"version":"v0.9","updateComponents":{"surfaceId":"main",'
          '"components":[{"id":"root","component":"Text",'
          r'"text":"a } brace and a \" quote"}]}}';

      final events = await parse([json]);

      final messages = messagesOf(events);
      expect(messages, hasLength(1));
      expect(
        (messages.single as UpdateComponentsMessage).components.single['text'],
        'a } brace and a " quote',
      );
    });

    test('treats prose with no message as text', () async {
      final events = await parse(['Just talking, no UI this time.']);

      expect(messagesOf(events), isEmpty);
      expect(textsOf(events), ['Just talking, no UI this time.']);
    });

    test('passes through JSON that is not an A2UI message as text', () async {
      final events = await parse(['```json\n{"unrelated":true}\n```']);

      expect(messagesOf(events), isEmpty);
      expect(textsOf(events), ['{"unrelated":true}']);
    });

    test('reports a malformed A2UI message as an error', () async {
      final stream = Stream.fromIterable([
        '```json\n{"version":"v0.9","createSurface":{}}\n```',
      ]).transform(const A2uiParserTransformer());

      await expectLater(stream, emitsError(isA<A2uiValidationException>()));
    });

    test(
      'emits unparseable fenced content as text rather than stalling',
      () async {
        final events = await parse(['```json\n{not valid json at all\n```']);

        expect(messagesOf(events), isEmpty);
        expect(textsOf(events), isNotEmpty);
      },
    );
  });

  group('A2uiTransportAdapter', () {
    test('publishes parsed messages to listeners', () async {
      final adapter = A2uiTransportAdapter();
      final received = <A2uiMessage>[];
      adapter.incomingMessages.listen(received.add);

      adapter.addChunk('```json\n$createSurfaceJson\n```');
      await adapter.flush();

      expect(received, hasLength(1));
      adapter.dispose();
    });

    test('publishes prose separately from messages', () async {
      final adapter = A2uiTransportAdapter();
      final texts = <String>[];
      adapter.incomingText.listen(texts.add);

      adapter.addChunk('Thinking about it. ');
      adapter.addChunk('```json\n$createSurfaceJson\n```');
      await adapter.flush();

      expect(texts.join(), 'Thinking about it. ');
      adapter.dispose();
    });

    test('accepts a message that did not come from text', () async {
      final adapter = A2uiTransportAdapter();
      final received = <A2uiMessage>[];
      adapter.incomingMessages.listen(received.add);

      adapter.addMessage(
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'deleteSurface': {'surfaceId': 'main'},
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      adapter.dispose();
    });

    test('hands the user\'s text to onSend', () async {
      final sent = <String>[];
      final adapter = A2uiTransportAdapter(
        onSend: (text) async => sent.add(text),
      );

      await adapter.sendRequest('Plan me a trip');

      expect(sent, ['Plan me a trip']);
      adapter.dispose();
    });

    test('refuses to send without an onSend callback', () async {
      final adapter = A2uiTransportAdapter();

      await expectLater(
        adapter.sendRequest('anything'),
        throwsA(isA<StateError>()),
      );
      adapter.dispose();
    });
  });
}
