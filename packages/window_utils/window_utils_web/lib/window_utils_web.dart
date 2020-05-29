import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:js' as js;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:window_utils_platform_interface/window_utils_platform_interface.dart';
import 'package:window_utils_web/browser.dart' as browser;

/// The web implementation of [WindowUtilsPlatform].
///
/// This class implements (or stubs out) `package:window_utils` functionality for the web.
class WindowUtilsPlugin extends WindowUtilsPlatform {
  /// Registers this class as the default instance of [UrlLauncherPlatform].
  static void registerWith(Registrar registrar) {
    WindowUtilsPlatform.instance = WindowUtilsPlugin();
  }

  /// Stubbed out for web; does nothing except return true
  @override
  Future<bool> hideTitleBar() => Future.value(true);

  /// Stubbed out for web; does nothing except return true
  @override
  Future<bool> setSize(Size size) => Future.value(true);

  /// Stubbed out for web; does nothing except return true
  @override
  Future<bool> startDrag() => Future.value(true);

  /// Stubbed out for web; does nothing except return the zero offset
  @override
  Future<Offset> getWindowOffset([String key]) => Future.value(Offset.zero);

  /// Stubbed out for web; does nothing except return the zero offset
  @override
  Future<Size> getWindowSize([String key]) => Future.value(Size(
        browser.width.toDouble(),
        browser.height.toDouble(),
      ));

  /// On web: just navigate to [url] and return an empty String.
  @override
  Future<String> openWebView(
    String key,
    String url, {
    Offset offset,
    Size size,
    String jsMessage = '',
  }) {
    /**See https://github.com/flutter/flutter/issues/51461 for reference.
    final target = browser.standalone ? '_top' : '';
    html.window.open(url, target); 
    */
    html.window.location.href = url;
    return Future.value('');
  }

  /// Stubbed out for web; does nothing except return true
  @override
  Future<bool> closeWebView(String key) => Future.value(true);

  @override
  Future<Map<String, String>> getCookies() async {
    var cookieString = html.window.document.cookie;
    final cookies = <String, String>{};
    var allCookies = cookieString.split('; ');

    for (final cookie in allCookies) {
      var kvCookie = cookie.split('=');
      if (kvCookie.length != 2) {
        continue;
      }

      var k = kvCookie[0];
      var v = kvCookie[1];
      cookies[k] = v;
    }

    return cookies;
  }

  @override
  Future<bool> initDropTarget() async {
    js.context['filesDropped'] = (dynamic test) {
      if (test is! js.JsArray) {
        return;
      }
      List<DroppedFile> droppedFiles = [];
      for (final item in (test as js.JsArray)) {
        if (item is! js.JsObject) {
          continue;
        }
        var object = item as js.JsObject;
        var filename =
            object['filename'] is String ? object['filename'] as String : null;
        var bytes =
            object['bytes'] is Uint8List ? object['bytes'] as Uint8List : null;
        if (filename != null && bytes != null) {
          droppedFiles.add(DroppedFile(filename, bytes));
        }
      }
      WindowUtilsPlatform.filesDropped?.call(droppedFiles);
    };
    return true;
  }
}
