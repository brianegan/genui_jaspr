/// The path the browser reaches the agent at. Two more hang off it, for
/// reading a session back and for aborting a turn, which the Genkit client
/// expects.
///
/// Split out of `chat_agent.dart` so the browser-side `chat.dart` can import
/// just this constant without pulling in `genkit_shelf`, which imports
/// `dart:io` and would stop the client entrypoint from compiling for the web.
const String chatPath = 'api/chat';
