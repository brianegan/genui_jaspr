// `print` keeps each compile-time reachability fixture observable.
// ignore_for_file: avoid_print

import 'package:genui_jaspr/genui_jaspr.dart';

void main() {
  final catalog = MinimalJasprCatalog();
  print(
    '${catalog.id}:${catalog.components.length}:${catalog.functions.length}',
  );
}
