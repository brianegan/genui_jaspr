@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:universal_web/web.dart' as web;

import '../support/harness.dart';

void main() {
  testComponents('a Basic catalog button opens the URL synchronously', (
    tester,
  ) async {
    final original = web.window.getProperty<JSAny?>('open'.toJS);
    addTearDown(() => web.window.setProperty('open'.toJS, original));

    String? openedUrl;
    String? openedTarget;
    String? openedFeatures;
    var executing = false;
    var calledDuringExecute = false;
    final fakeOpen = ((JSString url, JSString target, JSString features) {
      openedUrl = url.toDart;
      openedTarget = target.toDart;
      openedFeatures = features.toDart;
      calledDuringExecute = executing;
      return null;
    }).toJS;
    web.window.setProperty('open'.toJS, fakeOpen);

    final surface = buildSurfaceModel(
      [
        {
          'id': 'root',
          'component': 'Button',
          'child': 'label',
          'action': {
            'functionCall': {
              'call': 'openUrl',
              'args': {'url': 'https://example.com/path'},
              'returnType': 'void',
            },
          },
        },
        {'id': 'label', 'component': 'Text', 'text': 'Open'},
      ],
      catalog: BasicJasprCatalog(),
    );
    tester.pumpComponent(surfaceComponent(surface));

    executing = true;
    await tester.click(find.tag('button'));
    executing = false;

    expect(calledDuringExecute, isTrue);
    expect(openedUrl, 'https://example.com/path');
    expect(openedTarget, '_blank');
    expect(openedFeatures, 'noopener,noreferrer');
  });
}
