import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../jaspr_component.dart';

/// Renders a flex container for `Row` and `Column`.
///
/// The alignment properties are per instance: the model chooses them for each
/// component it sends, so they cannot live in a stylesheet and are written
/// inline. The class name is still emitted, so a host stylesheet has something
/// to hang spacing and other presentation on.
Component flexContainer(
  ComponentScope scope, {
  required FlexDirection direction,
  required String className,
}) {
  return div(
    scope.children(),
    classes: className,
    styles: Styles(
      display: Display.flex,
      flexDirection: direction,
      justifyContent: _justify(scope.string('justify')),
      alignItems: _align(scope.string('align')),
    ),
  );
}

/// Maps the schema's `justify` values onto `justify-content`.
///
/// `stretch` is not a `justify-content` value, so it falls through to the
/// default rather than emitting something a browser would ignore.
JustifyContent? _justify(String? value) => switch (value) {
  'start' => JustifyContent.start,
  'center' => JustifyContent.center,
  'end' => JustifyContent.end,
  'spaceBetween' => JustifyContent.spaceBetween,
  'spaceAround' => JustifyContent.spaceAround,
  'spaceEvenly' => JustifyContent.spaceEvenly,
  _ => null,
};

AlignItems? _align(String? value) => switch (value) {
  'start' => AlignItems.start,
  'center' => AlignItems.center,
  'end' => AlignItems.end,
  'stretch' => AlignItems.stretch,
  _ => null,
};
