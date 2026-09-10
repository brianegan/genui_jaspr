import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:genui_jaspr/src/catalog/components/audio_player.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

import '../support/harness.dart';
import '../support/render.dart';

void main() {
  group('AudioPlayer', () {
    test('exposes the A2UI v0.9 API', () {
      final api = AudioPlayerApi();

      expect(api.name, 'AudioPlayer');
      expect(
        api.schema.value,
        Schema.object(
          properties: {
            'url': CommonSchemas.dynamicString,
            'description': CommonSchemas.dynamicString,
          },
          required: ['url'],
        ).value,
      );
    });

    test(
      'renders bound audio with native controls and an accessible name',
      () async {
        final html = normalizeHtml(
          await renderSurface(
            [
              {
                'id': 'root',
                'component': 'AudioPlayer',
                'url': {'path': '/audio/url'},
                'description': {'path': '/audio/description'},
              },
            ],
            data: {
              '/audio/url': '/episode.mp3',
              '/audio/description': 'Episode one',
            },
            catalog: MinimalJasprCatalog().copyWith(
              add: [AudioPlayerComponent()],
            ),
          ),
        );

        expect(
          html,
          '<audio class="a2ui-audio-player" aria-label="Episode one" '
          'controls src="/episode.mp3"></audio>',
        );
      },
    );
  });
}
