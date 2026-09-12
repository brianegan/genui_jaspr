import 'dart:io';
import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:genui_jaspr_example/app.dart';
import 'package:genui_jaspr_example/main.server.options.dart';
import 'package:genui_jaspr_example/server/chat_agent.dart';
import 'package:genui_jaspr_example/server/chat_path.dart';
import 'package:jaspr/server.dart';

/// The model this example talks to.
///
/// Override with `MODEL=<name>` to try another without editing this file. Any
/// name the Gemini API accepts works: the plugin passes it straight through and
/// does not check it against a list.
final String modelName =
    Platform.environment['MODEL'] ?? 'gemini-3.5-flash-lite';

/// Serves the page, and the agent the browser talks to.
///
/// The model is only ever called from here, so the API key stays on the server
/// and only generated text crosses the wire. `googleAI()` reads it from
/// `GOOGLE_API_KEY` or `GEMINI_API_KEY`.
void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  final ai = Genkit(plugins: [googleAI()], promptDir: null);
  final chat = chatHandler(
    chatAgent(ai, model: googleAI.gemini(modelName)),
  );

  // Everything except the agent's routes falls through to the rendered page.
  ServerApp.addMiddleware(
    (inner) => (request) async {
      if (request.url.path.startsWith(chatPath)) return chat(request);
      return inner(request);
    },
  );

  runApp(
    Document(
      title: 'GenUI for Jaspr',
      lang: 'en',
      styles: appStyles,
      body: const App(),
    ),
  );
}
