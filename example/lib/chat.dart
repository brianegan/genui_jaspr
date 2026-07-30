import 'package:a2ui_core/a2ui_core.dart';
import 'package:genkit/client.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// One entry in the transcript.
class Turn {
  Turn.user(this.text) : surface = null, fromUser = true;
  Turn.model(this.text, this.surface) : fromUser = false;

  final String text;

  /// The surface this turn generated, if it generated one.
  final SurfaceModel<JasprComponent>? surface;

  final bool fromUser;
}

/// The conversation, running entirely in the browser.
///
/// A generated surface only exists once the model has answered something the user
/// did, so there is nothing for the server to pre-render. The server's job is to
/// hold the API key and stream text back, which it does through the route this
/// talks to.
@client
class Chat extends StatefulComponent {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  /// Calls the server route. Genkit's client handles the frames and surfaces a
  /// server-side failure as an error on the stream.
  final _chat = defineRemoteAction<String, String, String, void>(
    url: '/api/chat',
    fromStreamChunk: (json) => json as String,
    fromResponse: (json) => json as String,
  );

  late final MessageProcessor<JasprComponent> _processor;

  final List<Turn> _turns = [];
  String _draft = '';
  bool _busy = false;
  String? _error;

  /// Surfaces are numbered so each reply renders into its own.
  int _replies = 0;

  @override
  void initState() {
    super.initState();
    _processor = MessageProcessor<JasprComponent>(
      catalogs: [minimalJasprCatalog()],
      onAction: _onSurfaceAction,
    );
  }

  /// A button in a generated surface was pressed.
  ///
  /// The interaction becomes the next thing the model hears, along with whatever
  /// the user typed into that surface, which the data model already holds.
  void _onSurfaceAction(A2uiClientAction action) {
    final SurfaceModel<JasprComponent>? surface = _processor.groupModel
        .getSurface(action.surfaceId);
    final Object? data = surface?.dataModel.get('/');

    final description = StringBuffer('The user triggered "${action.name}".');
    if (action.context.isNotEmpty) {
      description.write(' Context: ${action.context}.');
    }
    if (data is Map && data.isNotEmpty) {
      description.write(' They had entered: $data.');
    }
    _send(description.toString(), show: 'Submitted "${action.name}"');
  }

  Future<void> _sendDraft() async {
    final String text = _draft.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _draft = '');
    await _send(text, show: text);
  }

  Future<void> _send(String prompt, {required String show}) async {
    if (_busy) return;

    final adapter = A2uiTransportAdapter();
    final surfaceId = 'reply${_replies++}';
    final prose = StringBuffer();

    setState(() {
      _busy = true;
      _error = null;
      _turns.add(Turn.user(show));
    });

    // Each reply targets a surface named here rather than one the model invents,
    // so a model that reuses an id cannot overwrite an earlier answer.
    adapter.incomingMessages.listen((message) {
      try {
        _processor.processMessages([_retarget(message, surfaceId)]);
      } catch (error) {
        setState(() => _error = '$error');
      }
    });
    adapter.incomingText.listen((chunk) {
      prose.write(chunk);
      setState(() {});
    });

    try {
      await for (final String chunk in _chat.stream(input: prompt)) {
        adapter.addChunk(chunk);
      }
      await adapter.flush();
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      adapter.dispose();
      setState(() {
        _busy = false;
        _turns.add(
          Turn.model(
            prose.toString().trim(),
            _processor.groupModel.getSurface(surfaceId),
          ),
        );
      });
    }
  }

  /// Rewrites a message to target this reply's surface.
  A2uiMessage _retarget(A2uiMessage message, String surfaceId) {
    final Map<String, dynamic> json = message.toJson();
    for (final Object? body in json.values) {
      if (body is Map<String, dynamic> && body.containsKey('surfaceId')) {
        body['surfaceId'] = surfaceId;
      }
    }
    return A2uiMessage.fromJson(json);
  }

  @override
  Component build(BuildContext context) {
    return div([
      div([for (final turn in _turns) _turnView(turn)], classes: 'transcript'),
      if (_busy) p([Component.text('Thinking...')], classes: 'status'),
      if (_error != null)
        p(
          [Component.text(_error!)],
          classes: 'error',
          attributes: const {'role': 'alert'},
        ),
      _composer(),
    ], classes: 'chat');
  }

  Component _turnView(Turn turn) {
    return div([
      if (turn.text.isNotEmpty) p([Component.text(turn.text)]),
      if (turn.surface != null) Surface(surface: turn.surface!),
    ], classes: turn.fromUser ? 'turn turn--user' : 'turn turn--model');
  }

  Component _composer() {
    return div([
      input<String>(
        type: InputType.text,
        value: _draft,
        disabled: _busy,
        attributes: const {
          'placeholder': 'Ask for a form, a quiz, a checklist',
        },
        onInput: (value) => _draft = value,
        onChange: (value) => _draft = value,
      ),
      button(
        [Component.text('Send')],
        type: ButtonType.button,
        disabled: _busy,
        onClick: _sendDraft,
      ),
    ], classes: 'composer');
  }
}
