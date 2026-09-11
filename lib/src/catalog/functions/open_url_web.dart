import 'package:universal_web/web.dart' as web;

/// Opens [url] in a new browser context without an opener reference.
void openUrlInBrowser(Uri url) {
  web.window.open(url.toString(), '_blank', 'noopener,noreferrer');
}
