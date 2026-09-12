import 'package:universal_web/web.dart' as web;

/// Opens [url] in a new browser context without an opener reference.
void openUrlInBrowser(Uri url) {
  // Server coverage cannot load this conditional browser implementation. The
  // browser suite verifies the call, target, features, and synchronous timing.
  // coverage:ignore-start
  web.window.open(url.toString(), '_blank', 'noopener,noreferrer');
  // coverage:ignore-end
}
