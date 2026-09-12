// `print` keeps each compile-time reachability fixture observable.
// ignore_for_file: avoid_print

import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:genui_jaspr/src/catalog/basic/components/choice_picker.dart';

void main() {
  final catalog = MinimalJasprCatalog().copyWith(
    add: [ChoicePickerComponent()],
  );
  print(
    '${catalog.id}:${catalog.components.length}:${catalog.functions.length}',
  );
  for (final rule in catalog.styles) {
    print(rule.toCss());
  }
}
