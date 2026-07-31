import 'package:jaspr_test/jaspr_test.dart';

import '../support/harness.dart';

void main() {
  group('Row', () {
    test('lays children out in a row and renders them in order', () async {
      final html = await renderSurface([
        {
          'id': 'root',
          'component': 'Row',
          'children': ['a', 'b'],
        },
        {'id': 'a', 'component': 'Text', 'text': 'first'},
        {'id': 'b', 'component': 'Text', 'text': 'second'},
      ]);

      expect(html, startsWith('<div class="a2ui-row"'));
      expect(html, contains('display: flex'));
      expect(html, contains('flex-direction: row'));
      expect(
        html,
        contains(
          '<p class="a2ui-text a2ui-text--body">first</p>'
          '<p class="a2ui-text a2ui-text--body">second</p>',
        ),
      );
    });

    test('writes justify and align through to flexbox', () async {
      final html = await renderSurface([
        {
          'id': 'root',
          'component': 'Row',
          'children': <String>[],
          'justify': 'spaceBetween',
          'align': 'center',
        },
      ]);

      expect(html, contains('justify-content: space-between'));
      expect(html, contains('align-items: center'));
    });

    test(
      'omits justify-content for stretch, which it cannot express',
      () async {
        final html = await renderSurface([
          {
            'id': 'root',
            'component': 'Row',
            'children': <String>[],
            'justify': 'stretch',
          },
        ]);

        expect(html, isNot(contains('justify-content')));
      },
    );
  });

  group('Column', () {
    test('lays children out in a column', () async {
      final html = await renderSurface([
        {
          'id': 'root',
          'component': 'Column',
          'children': ['a'],
        },
        {'id': 'a', 'component': 'Text', 'text': 'only'},
      ]);

      expect(html, startsWith('<div class="a2ui-column"'));
      expect(html, contains('flex-direction: column'));
      expect(html, contains('>only</p>'));
    });
  });

  group('child templates', () {
    test('repeats a template over a list in the data model', () async {
      final html = await renderSurface(
        [
          {
            'id': 'root',
            'component': 'Column',
            'children': {'componentId': 'itemText', 'path': '/items'},
          },
          {
            'id': 'itemText',
            'component': 'Text',
            'text': {'path': 'label'},
          },
        ],
        data: {
          '/items': [
            {'label': 'one'},
            {'label': 'two'},
            {'label': 'three'},
          ],
        },
      );

      // One child per element, each resolving its relative binding against its
      // own row of the list.
      expect(html, contains('>one</p>'));
      expect(html, contains('>two</p>'));
      expect(html, contains('>three</p>'));
    });
  });
}
