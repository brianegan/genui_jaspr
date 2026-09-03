# genui_jaspr example

A Jaspr app that drives a GenUI conversation. The page shell renders on the
server, the chat runs in the browser as a `@client` component, and the model
call sits behind a server route so the API key never reaches the browser. It
talks to Gemini through [Genkit](https://pub.dev/packages/genkit).

There is no single `main.dart`, because a server-mode Jaspr app has two
entrypoints:

- `lib/main.server.dart` serves the rendered page and mounts the agent under
  `/api/chat`.
- `lib/main.client.dart` hydrates the `@client` chat component in the browser.

## Running it

```sh
dart pub global activate jaspr_cli
export GEMINI_API_KEY=...              # or GOOGLE_API_KEY
dart run build_runner build            # generates the client and server options
jaspr serve
```

Then open http://localhost:8080 and ask for something: "a signup form", "a
three-question quiz", "a checklist for moving house".

It uses `gemini-3.5-flash-lite`. Set `MODEL` to try another:

```sh
MODEL=gemini-3.5-flash jaspr serve
```

## The pieces

- `lib/chat.dart` — the conversation. `Chat` is the param-free `@client`
  boundary holding the genkit client; `ChatView` does the work and takes the
  send function as a parameter, which is how the browser tests fake the model.
- `lib/prompt.dart` — the system prompt that teaches a model to drive the UI,
  with component schemas generated from the catalog.
- `lib/server/chat_agent.dart` — the Genkit agent that answers, keeping each
  conversation's history in a session store, and the `genkit_shelf` handler
  that serves it. The browser talks to it with Genkit's `remoteAgent` client.
- `lib/interaction.dart` — what the transcript shows for a click in a generated
  surface. What the model is told is `GenUiConversation.actionText`.

## Tests and coverage

`dart test` runs the VM suite, and `dart test -p chrome test/browser` runs the
browser suite against a real DOM. `tool/coverage.sh` runs both with coverage
and merges the two reports, because neither platform alone can reach all of the
code: the agent only runs on the VM, and `chat.dart` only runs in a browser. CI holds the merged number at 100%.
