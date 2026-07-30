import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../jaspr_component.dart';

/// Text, rendered with the element that matches its variant.
///
/// A heading variant becomes a real heading element rather than a styled `div`,
/// so a generated page keeps a document outline that screen readers and search
/// engines can follow.
JasprComponent textComponent() {
  return JasprComponent(MinimalTextApi(), (scope) {
    final String variant = scope.string('variant') ?? 'body';
    final String content = scope.string('text') ?? '';
    final String classes = 'a2ui-text a2ui-text--$variant';
    final children = [Component.text(content)];

    return switch (variant) {
      'h1' => h1(children, classes: classes),
      'h2' => h2(children, classes: classes),
      'h3' => h3(children, classes: classes),
      'h4' => h4(children, classes: classes),
      'h5' => h5(children, classes: classes),
      'caption' => small(children, classes: classes),
      _ => p(children, classes: classes),
    };
  });
}
