import 'package:jaspr_test/jaspr_test.dart';

import '../support/harness.dart';

void main() {
  group('Text', () {
    test('renders body copy as a paragraph by default', () async {
      final html = await renderSurface([
        {'id': 'root', 'component': 'Text', 'text': 'Hello'},
      ]);

      expect(html, '<p class="a2ui-text a2ui-text--body">Hello</p>');
    });

    test('maps each heading variant onto its own tag', () async {
      for (final (variant, tag) in const [
        ('h1', 'h1'),
        ('h2', 'h2'),
        ('h3', 'h3'),
        ('h4', 'h4'),
        ('h5', 'h5'),
      ]) {
        final html = await renderSurface([
          {
            'id': 'root',
            'component': 'Text',
            'text': 'Title',
            'variant': variant,
          },
        ]);

        expect(
          html,
          '<$tag class="a2ui-text a2ui-text--$variant">Title</$tag>',
        );
      }
    });

    test('renders the caption variant as small print', () async {
      final html = await renderSurface([
        {
          'id': 'root',
          'component': 'Text',
          'text': 'Fine print',
          'variant': 'caption',
        },
      ]);

      expect(
        html,
        '<small class="a2ui-text a2ui-text--caption">Fine print</small>',
      );
    });

    test('reads its text from the data model when bound', () async {
      final html = await renderSurface(
        [
          {
            'id': 'root',
            'component': 'Text',
            'text': {'path': '/user/name'},
          },
        ],
        data: {'/user/name': 'Ada'},
      );

      expect(html, '<p class="a2ui-text a2ui-text--body">Ada</p>');
    });
  });
}
