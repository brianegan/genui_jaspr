@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:test/test.dart';
import 'package:universal_web/web.dart' as web;

void main() {
  test('the default opener invokes window.open synchronously', () {
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

    final function = OpenUrlFunction();
    final context = DataContext(DataModel(), (_, _, _) => null, '/');
    executing = true;
    function.execute({'url': 'https://example.com/path'}, context);
    executing = false;

    expect(calledDuringExecute, isTrue);
    expect(openedUrl, 'https://example.com/path');
    expect(openedTarget, '_blank');
    expect(openedFeatures, 'noopener,noreferrer');
  });
}
