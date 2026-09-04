import 'package:genui_jaspr_example/main.client.options.dart';
import 'package:jaspr/client.dart';

/// The browser entry point.
///
/// [ClientApp] is what locates the `@client` components the server marked in
/// the HTML and hydrates them. `Jaspr.initializeApp` only records the
/// options, so without mounting this the page keeps the markup the server
/// sent and ignores every click.
void main() {
  Jaspr.initializeApp(options: defaultClientOptions);
  runApp(const ClientApp());
}
