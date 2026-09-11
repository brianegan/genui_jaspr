// `print` keeps each compile-time reachability fixture observable.
// ignore_for_file: avoid_print

import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/jaspr.dart';

void main() {
  final catalog = BasicJasprCatalog.withIconRenderer(
    (name) => Component.text('custom:$name'),
  );
  print(catalog.components['Icon']!.build(_scope('home')));
}

ComponentScope _scope(String name) => ComponentScope(
  id: 'icon',
  type: 'Icon',
  props: {'name': name},
  theme: const {},
  buildChild: (_) => const Component.empty(),
  buildChildren: (_) => const [],
  reportError: print,
);
