import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/src/catalog/basic/functions/open_url_stub.dart'
    if (dart.library.js_interop) 'package:genui_jaspr/src/catalog/basic/functions/open_url_web.dart'
    as platform;
import 'package:json_schema_builder/json_schema_builder.dart';

/// Opens a URI on behalf of an A2UI surface.
typedef UrlOpener = void Function(Uri url);

/// Opens a URL using the browser, or an application-supplied policy.
class OpenUrlFunction extends FunctionImplementation {
  /// Creates the standard `openUrl` function.
  ///
  /// The default opener uses a new browser context with `noopener,noreferrer`.
  /// It is a no-op during server rendering. Applications that need a scheme or
  /// host allowlist can enforce it by supplying [opener].
  OpenUrlFunction({UrlOpener? opener})
    : _opener = opener ?? platform.openUrlInBrowser;

  final UrlOpener _opener;

  @override
  String get name => 'openUrl';

  @override
  A2uiReturnType get returnType => A2uiReturnType.void_;

  @override
  Schema get argumentSchema => Schema.object(
    properties: {'url': Schema.string(format: 'uri')},
    required: ['url'],
    additionalProperties: false,
  );

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    final value = args['url'];
    if (value is! String || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    _opener(uri);
    return null;
  }
}
