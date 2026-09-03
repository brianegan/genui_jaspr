# genui_jaspr

Render A2UI generative user interfaces in [Jaspr](https://jaspr.site), so a web
app can offer a generative UI without shipping Flutter web.

A model replies with [A2UI](https://a2ui.org) messages instead of prose, and this
package turns them into real HTML: headings are headings, inputs are inputs, and
the browser supplies its own keyboards, validation, and focus handling.

This is the Jaspr counterpart to Flutter's
[`genui`](https://github.com/flutter/genui/tree/main/packages/genui). It renders
the same protocol to a different target.

## How it fits together

The protocol runtime is not reimplemented here. It lives in
[`a2ui_core`](https://pub.dev/packages/a2ui_core), which is pure Dart and owns the
message model, the data model, expression evaluation, and the binder that resolves
a component's properties into concrete values. This package adds the parts that
have to know about Jaspr:

| | |
|---|---|
| `GenUiConversation` | owns the surfaces of one conversation, and turns each model reply into a `Reply` |
| `Surface` | renders a surface, and keeps rendering as messages arrive |
| `minimalJasprCatalog()` | the components a model may use, and how each becomes HTML |
| `a2uiInstructions()` | the protocol half of a system prompt, generated from the catalog |
| `a2uiActionMessage()` | what to tell the model when the user presses a generated button |
| `genuiJasprStyles` | a default appearance you can use, extend, or replace |
| `A2uiParserTransformer` | the stream transformer underneath, for apps that want the raw events |

## Components

This release renders the five components of the A2UI **minimal catalog**:
`Text`, `Row`, `Column`, `Button`, and `TextField`.

Their schemas come from `a2ui_core` unchanged, and the catalog keeps that
catalog's own id, so what a model is told it may send and what this renders cannot
drift apart.

`Text` becomes `h1` through `h5`, `small`, or `p` depending on its variant.
`Row` and `Column` become flex containers. `Button` dispatches an action and
disables itself while its `checks` fail. `TextField` becomes an `input` or
`textarea`, picks an input type from its variant, and writes what the user types
back to the data model so the next request carries it.

A component the catalog does not implement renders a visible notice rather than
throwing, so one unknown component does not take down the surface around it.
`Surface.fallback` replaces that notice with whatever fits the app, and
`Surface.placeholder` fills the moment between a surface being created and its
components arriving.

To add a component, pair its `a2ui_core` API with a builder and derive a catalog:

```dart
final catalog = minimalJasprCatalog().copyWith(
  id: 'com.example.catalog',
  add: [JasprComponent(DividerApi(), (scope) => hr(classes: 'a2ui-divider'))],
);
```

The builder gets a `ComponentScope` with the properties already resolved: data
bindings read, function calls evaluated, actions turned into callbacks. Read
values with `scope.string`, children with `scope.children()`, and the callback
for an action property with `scope.action`.

### Not included yet

Flutter's `genui` ships a larger basic catalog. `Card`, `Divider`, `List`,
`Image`, `Icon`, `Modal`, `Tabs`, `Slider`, `DateTimeInput`, `ChoicePicker`,
`AudioPlayer`, and `Video` are not here. Most are inexpensive in HTML, so the gap
is scope rather than difficulty.

The system prompt is split in two. `a2uiInstructions(catalog)` writes the half a
model needs to speak the protocol to this app: the messages, the rules that decide
whether anything renders, and every component's schema read from the catalog, so
the two cannot drift. What the assistant is for and how it should sound is the
app's half. `example/lib/prompt.dart` joins the two.

## Usage

```dart
import 'package:genui_jaspr/genui_jaspr.dart';

// One conversation, one set of catalogs. It owns every surface the model
// builds and everything the user types into them.
final conversation = GenUiConversation(
  catalogs: [minimalJasprCatalog()],
  onAction: (action) {
    // A button in a generated surface was pressed. Tell the model: the
    // protocol's action message, then what the user entered, as JSON.
    send(conversation.actionText(action));
  },
);

// Hand each model reply in as a stream of text. The Reply comes back at once
// and fills in as the stream arrives.
final reply = conversation.receive(yourModelStream(prompt));

// Render it. A Reply is a Listenable, so this re-renders as it streams.
ListenableBuilder(
  listenable: reply,
  builder: (context) => div([
    p([Component.text(reply.text)]),
    for (final surface in reply.surfaces) Surface(surface: surface),
  ]),
);
```

Messages the model got wrong land in `reply.errors` rather than stopping the
reply, in the shape `a2uiErrorMessage` sends back. A failed model call lands in
`reply.failure`. Pass `surfaceId` to `receive` to render each reply into a
surface the app names, so a model that reuses an id cannot overwrite an earlier
answer.

A backend that delivers A2UI already parsed, such as an A2A agent, goes through
`receiveMessages` instead. The protocol runtime is a public field,
`conversation.processor`, for anything the conversation does not cover, and
`A2uiParserTransformer` is the stream transformer underneath.

Add `genuiJasprStyles` to your app's styles for a usable default appearance:

```dart
runApp(Document(styles: [...genuiJasprStyles, ...myStyles], body: MyApp()));
```

### Styling

Components emit stable class names, all prefixed `a2ui-`. Two kinds of styling
are deliberately kept apart:

- Layout the model chose per component, such as `justify` and `align`, is written
  inline, because it varies per instance and cannot live in a stylesheet.
- Appearance goes through class names, so `genuiJasprStyles` can be replaced
  wholesale without touching the renderer.

A surface publishes the theme from its `createSurface` message as CSS custom
properties on its root element, kebab-cased and `--a2ui-` prefixed. So
`{"primaryColor": "#0b57d0"}` arrives as `--a2ui-primary-color`, which is how a
static stylesheet reacts to a colour the model picked at runtime.

### Rendering on the server

The renderer reaches the DOM only through `universal_web`, the same stubs Jaspr
uses, so it compiles on the server. A generated surface still cannot be server-rendered in any useful way,
because it only exists once the model has answered something the user did. Render
the shell on the server and let a `@client` component own the conversation, which
is what the example does.

## Running the example

The example is a Jaspr app with a server-rendered shell, the chat as a `@client`
component, and the model call behind a server route so the API key never reaches
the browser. It talks to Gemini through [Genkit](https://pub.dev/packages/genkit).

```sh
dart pub global activate jaspr_cli
export GEMINI_API_KEY=...              # or GOOGLE_API_KEY
cd example
dart run build_runner build            # generates the client and server options
jaspr serve
```

Then open http://localhost:8080 and ask for something: "a signup form", "a
three-question quiz", "a checklist for moving house".

It uses `gemini-3.5-flash-lite`. Set `MODEL` to try another:

```sh
MODEL=gemini-3.5-flash jaspr serve
```

The generated `lib/main.*.options.dart` files are committed, so the tests run
without a build step. Re-run `build_runner` after adding or removing an `@client`
component.

## Tests

```sh
dart test                          # the package
dart test -p chrome test/browser   # the browser-only tests, needs Chrome
cd example && dart test            # the example, including a real HTTP round trip
```

The example's round-trip test starts a real server and drives the real route with
a stand-in for the model, so everything between browser and model is covered
without a key. Only the model call itself needs one.

The browser tests are marked `@TestOn('browser')`, so the plain `dart test` runs
skip them. They exist because two hops cannot be reached from the VM: a real
keystroke in a real input element reaching the data model, and a real click on a
generated button. Deleting a field's `onInput` handler passes every VM test and
fails there.

## Additional information

Issues and pull requests: https://github.com/brianegan/genui_jaspr

- A2UI protocol: https://a2ui.org
- Jaspr: https://jaspr.site
- Flutter's genui: https://github.com/flutter/genui
