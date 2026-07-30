import 'package:jaspr/client.dart';

import 'main.client.options.dart';

/// The browser entry point.
///
/// Jaspr hydrates the components marked `@client`; the registrations it needs are
/// in the generated options.
void main() {
  Jaspr.initializeApp(options: defaultClientOptions);
}
