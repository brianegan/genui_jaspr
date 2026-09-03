import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';

/// The technical half of a system prompt: how to speak A2UI to this app.
///
/// A model has to be told the protocol, the rules that decide whether anything
/// appears on screen, and exactly which components it may use. The first two
/// are the same for every app. The third is read from [catalog], so adding a
/// component to the catalog tells the model about it without anyone editing
/// prose, and the schema the model sees is the schema the renderer binds with.
///
/// This is deliberately only the technical half. What the assistant is for, how
/// it should sound, and what it should refuse are the app's to write. Put this
/// after that:
///
/// ```dart
/// final systemPrompt = [
///   'You help people plan trips. Reply with a sentence, then the UI.',
///   a2uiInstructions(minimalJasprCatalog()),
/// ].join('\n\n');
/// ```
///
/// The output is plain text with fenced JSON, which every model client accepts
/// as a system prompt. It imports nothing from Jaspr, so it runs on the server
/// that holds the prompt as well as in the browser.
String a2uiInstructions(Catalog<ComponentApi> catalog) {
  return [
    'The active catalog ID is "${catalog.id}". '
        'Use exactly this ID when creating a surface.',
    _messages,
    _rules,
    _components(catalog),
    if (catalog.functions.isNotEmpty) _functions(catalog),
    if (catalog.themeSchema != null) _theme(catalog),
    _example(catalog),
  ].join('\n\n');
}

const _messages = '''
Emit each message as its own ```json fenced block. Four kinds exist:

- createSurface: opens a surface. Needs surfaceId, catalogId, and
  sendDataModel: true. Optionally takes a theme.
- updateComponents: fills a surface. Needs surfaceId and a components list.
- updateDataModel: sets a value. Needs surfaceId, path, and value.
- deleteSurface: removes a surface. Needs surfaceId.

Every message also needs "version": "v0.9".''';

const _rules = '''
Rules that decide whether anything appears on screen:

- Exactly one component in updateComponents must have "id": "root". Without it
  nothing renders.
- Every id referenced by a parent must also be sent in the components list.
- Use a new, unique surfaceId for each reply. Do not modify an earlier surface.
- Bind a value to the data model with {"path": "/some/path"} anywhere a plain
  value is allowed. An input whose value is bound writes back to that path as
  the user types, which is how you read their answer on the next turn.
- Give every input a label.
- Include at least one Button so the user can submit. Its action names an event,
  e.g. {"event": {"name": "submit"}}. When the user presses it you receive an
  A2UI action message naming that event, followed by the data model of every
  surface as JSON, which is where the user's answers are.
- Use checks to validate. Each check has a condition and a message, and a Button
  whose checks fail is disabled automatically.''';

const _encoder = JsonEncoder.withIndent('  ');

String _components(Catalog<ComponentApi> catalog) {
  final schemas = <String, Object?>{
    for (final ComponentApi component in catalog.components.values)
      component.name: component.schema.value,
  };
  return 'These are the only components available, with their schemas:\n\n'
      '${_encoder.convert(schemas)}';
}

String _functions(Catalog<ComponentApi> catalog) {
  final functions = <String, Object?>{
    for (final FunctionImplementation function in catalog.functions.values)
      function.name: {
        'returnType': function.returnType.jsonValue,
        'args': function.argumentSchema.value,
      },
  };
  return 'These functions may be called with {"call": "name", "args": {...}} '
      'anywhere a value is allowed:\n\n'
      '${_encoder.convert(functions)}';
}

String _theme(Catalog<ComponentApi> catalog) {
  return 'A createSurface may carry a theme with these properties:\n\n'
      '${_encoder.convert(catalog.themeSchema!.value)}';
}

/// A complete, valid reply against [catalog]'s own id.
///
/// Uses only the minimal catalog's components, which every A2UI catalog is
/// expected to have. The example is what a model imitates most closely, so it
/// is worth more than any rule above it.
String _example(Catalog<ComponentApi> catalog) {
  final id = catalog.id;
  return '''
A complete reply looks like this:

Here's a short form to get started.

```json
{"version":"v0.9","createSurface":{"surfaceId":"s1","catalogId":"$id","sendDataModel":true}}
```

```json
{"version":"v0.9","updateComponents":{"surfaceId":"s1","components":[
  {"id":"root","component":"Column","align":"stretch","children":["title","name","send"]},
  {"id":"title","component":"Text","text":"Your details","variant":"h2"},
  {"id":"name","component":"TextField","label":"Full name","value":{"path":"/name"}},
  {"id":"send","component":"Button","child":"sendLabel","action":{"event":{"name":"submit"}}},
  {"id":"sendLabel","component":"Text","text":"Continue"}
]}}
```''';
}
