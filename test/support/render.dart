import 'dart:convert';

import 'package:jaspr/server.dart';

bool _initialized = false;

/// Renders [component] to the HTML string a browser would receive.
///
/// Used where a test cares about the exact markup. Tests that need to click or
/// type use `testComponents` and the finders instead.
Future<String> renderHtml(Component component) async {
  if (!_initialized) {
    Jaspr.initializeApp(useIsolates: false);
    _initialized = true;
  }
  final response = await renderComponent(component, standalone: true);
  return utf8.decode(response.body).trim();
}

final _surfaceWrapper = RegExp(
  r'^<div class="a2ui-surface"[^>]*>(.*)</div>$',
  dotAll: true,
);

/// Removes the surface wrapper, leaving the markup the components produced.
///
/// Component tests read better when they assert only their own output. The
/// wrapper itself, and the theme properties it carries, are covered in
/// `styles_test.dart`.
String stripSurface(String html) {
  final match = _surfaceWrapper.firstMatch(html);
  // Jaspr indents the wrapper's children, so the captured text carries the
  // surrounding whitespace with it.
  return match == null ? html : match.group(1)!.trim();
}

/// Collapses the whitespace Jaspr puts between nested elements.
///
/// Indentation is a rendering detail, so a test asserting on structure should
/// not break when the nesting depth changes.
String normalizeHtml(String html) =>
    html.replaceAll(RegExp(r'>\s+<'), '><').trim();
