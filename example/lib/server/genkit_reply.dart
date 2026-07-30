import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';

import '../prompt.dart';
import 'chat_route.dart';

/// The model this example talks to.
const modelName = 'gemini-flash-latest';

/// Builds a [ReplyStream] backed by Gemini through Genkit.
///
/// The API key never reaches the browser: `googleAI()` reads `GOOGLE_API_KEY` or
/// `GEMINI_API_KEY` from the server's environment, and only the generated text
/// crosses the wire.
///
/// The conversation is not carried between turns here. Each request stands alone,
/// which keeps the example about rendering rather than about session storage. An
/// app that wants continuity passes prior turns as `messages`.
ReplyStream genkitReply({String? apiKey}) {
  final ai = Genkit(plugins: [googleAI(apiKey: apiKey)], promptDir: null);

  return (String prompt) {
    return ai
        .generateStream(
          model: googleAI.gemini(modelName),
          system: a2uiSystemPrompt,
          prompt: prompt,
        )
        .map((chunk) => chunk.text);
  };
}
