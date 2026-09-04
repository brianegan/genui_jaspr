import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

/// The fenced JSON blocks in [text], decoded.
List<Map<String, dynamic>> fencedJson(String text) {
  return RegExp(r'```json\n([\s\S]*?)\n```')
      .allMatches(text)
      .map((match) => jsonDecode(match.group(1)!) as Map<String, dynamic>)
      .toList();
}

class _DividerApi extends ComponentApi {
  @override
  String get name => 'Divider';

  @override
  Schema get schema => Schema.object(
    properties: {'thickness': Schema.integer()},
    description: 'A horizontal rule.',
  );
}

void main() {
  group('a2uiInstructions', () {
    final catalog = MinimalJasprCatalog();
    final prompt = a2uiInstructions(catalog);

    test('names the catalog the model must target', () {
      expect(prompt, contains('The active catalog ID is "${catalog.id}"'));
    });

    test('explains the four messages and the version', () {
      for (final kind in [
        'createSurface',
        'updateComponents',
        'updateDataModel',
        'deleteSurface',
      ]) {
        expect(prompt, contains('- $kind:'));
      }
      expect(prompt, contains('"version": "v0.9"'));
    });

    test('carries every component\'s schema straight from the catalog', () {
      final section = prompt.split('with their schemas:\n\n')[1];
      final schemas =
          jsonDecode(section.split('\n\nThese functions')[0])
              as Map<String, dynamic>;

      expect(schemas.keys, catalog.components.keys);
      for (final name in catalog.components.keys) {
        expect(
          schemas[name],
          catalog.components[name]!.schema.value,
          reason: '$name drifted from the catalog',
        );
      }
    });

    test('lists the catalog\'s functions and theme', () {
      expect(prompt, contains('"capitalize"'));
      expect(prompt, contains('"returnType": "string"'));
      expect(prompt, contains('"primaryColor"'));
    });

    test('ends with an example that is itself valid A2UI', () {
      final messages = fencedJson(prompt).map(A2uiMessage.fromJson).toList();

      expect(messages, hasLength(2));
      expect(messages.first, isA<CreateSurfaceMessage>());
      expect((messages.first as CreateSurfaceMessage).catalogId, catalog.id);
      expect(messages.last, isA<UpdateComponentsMessage>());
    });

    test('the example renders through the real pipeline', () async {
      final conversation = GenUiConversation(catalogs: [catalog]);
      final example = prompt.substring(
        prompt.indexOf('A complete reply looks like this:'),
      );

      final reply = conversation.receive(Stream.value(example));
      await reply.done;

      expect(reply.errors, isEmpty);
      expect(reply.surfaces, hasLength(1));
      expect(
        reply.surfaces.single.componentsModel.all.map((c) => c.type),
        containsAll(['Column', 'Text', 'TextField', 'Button']),
      );
      conversation.dispose();
    });

    test('follows the catalog it is given', () {
      final custom = catalog.copyWith(
        id: 'com.example.custom',
        add: [JasprComponent.inline(_DividerApi(), (scope) => throw 0)],
      );

      final text = a2uiInstructions(custom);

      expect(text, contains('"com.example.custom"'));
      expect(text, contains('"Divider"'));
      expect(text, contains('A horizontal rule.'));
    });

    test('tells the model to open a new surface per reply by default', () {
      expect(prompt, contains('Use a new, unique surfaceId for each reply'));
      expect(prompt, isNot(contains('existing surfaceId')));
    });

    test('can let the model revise surfaces from earlier turns', () {
      final revising = a2uiInstructions(catalog, allowUpdates: true);

      expect(revising, contains("with that surface's existing surfaceId"));
      expect(revising, isNot(contains('Do not modify an earlier surface')));
      // Everything else is the same prompt.
      expect(revising.length, greaterThan(prompt.length ~/ 2));
      expect(revising, contains('"TextField"'));
    });

    test('says nothing about functions or a theme a catalog lacks', () {
      final bare = Catalog<ComponentApi>(
        id: 'bare',
        components: [MinimalTextApi()],
      );

      final text = a2uiInstructions(bare);

      expect(text, isNot(contains('These functions')));
      expect(text, isNot(contains('theme with these properties')));
    });
  });
}
