## 0.2.0

The API grows a layer above rendering, so an app no longer assembles the
protocol runtime itself.

- **Added** `GenUiConversation`, which owns the surfaces of one conversation and
  turns each model reply into a `Reply`: prose, surfaces, and the model's
  mistakes, filling in as the stream arrives. A `Reply` is a `Listenable`.
- **Added** `a2uiActionMessage` and `a2uiErrorMessage`, the client-to-server
  envelopes A2UI defines, and `clientErrorFrom` to turn anything thrown into
  the error the protocol reports.
- **Added** `Surface.placeholder` and `Surface.fallback`, for what a surface
  shows before its root exists and in place of a component it cannot render.
- **Added** `a2uiInstructions`, the protocol half of a system prompt generated
  from a catalog, so the model is told exactly what the renderer can draw. Its
  `allowUpdates` flag matches the two ways `receive` can treat surface ids.
- **Changed** the catalog to classes. `MinimalJasprCatalog()` replaces
  `minimalJasprCatalog()` and `MinimalJasprCatalog.catalogId` replaces
  `minimalJasprCatalogId`. `JasprComponent` is now a base class to extend, with
  `TextComponent`, `RowComponent`, `ColumnComponent`, `ButtonComponent`, and
  `TextFieldComponent` as its five entries, and `JasprComponent.inline` for the
  closure form.
- **Added** `GenUiConversation.receiveMessages` for backends that deliver A2UI
  already parsed, and `GenUiConversation.actionText` for the text a chat app
  sends the model after an interaction.
- **Added** `Catalog<JasprComponent>.copyWith` to derive a catalog from an
  existing one.
- **Added** `ComponentScope.children()` and `ComponentScope.reportError`. An
  action obtained through `ComponentScope.action` no longer throws out of a
  click handler: its failure is reported to the surface instead.
- **Removed** `A2uiTransportAdapter` and `SendCallback`. `GenUiConversation.receive`
  takes a `Stream<String>` directly, and `A2uiParserTransformer` remains for
  apps that want the raw events.
- **Removed** `Surface.rootId`. The protocol fixes the root component's id.
- **Fixed** a `number` text field writing `NaN` to the data model when emptied
  or mid-edit, which has no JSON encoding. It now writes nothing.
- **Fixed** a `longText` field ignoring data-model changes once the user had
  typed in it.
- **Fixed** the parser emitting the whitespace a model leaves after its last
  message as prose.
- The example's server is now a Genkit agent served by `genkit_shelf`, with
  each conversation's history kept in a session store, so the model remembers
  the UI it built when an interaction with it comes back. The browser talks to
  it with Genkit's `remoteAgent` client.
- Requires `a2ui_core` 0.1.1 and `jaspr` 0.23.4.

## 0.1.0

First release. Renders A2UI generative user interfaces in Jaspr, building on
`a2ui_core` for the protocol runtime.

- `Surface` renders a surface and fills in as messages arrive, with a visible
  placeholder for components the catalog does not implement.
- `minimalJasprCatalog()` renders the five components of the A2UI minimal
  catalog: `Text`, `Row`, `Column`, `Button`, and `TextField`. Schemas and the
  catalog id come from `a2ui_core` unchanged.
- `A2uiTransportAdapter` and `A2uiParserTransformer` turn a model's text stream
  into A2UI messages, buffering across chunk boundaries so a reply renders as it
  arrives.
- `genuiJasprStyles` provides a default appearance against stable class names. A
  surface publishes its theme as CSS custom properties.
- `SignalBuilder` bridges `preact_signals` to Jaspr rebuilds.
- The example app serves a server-rendered shell with the conversation as a
  `@client` component, and calls Gemini through Genkit from a server route.
