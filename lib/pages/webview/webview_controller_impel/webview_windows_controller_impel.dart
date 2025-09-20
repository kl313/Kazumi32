import 'dart:async';
import 'package:webview_windows/webview_windows.dart';
import 'package:kazumi/pages/webview/webview_controller.dart';

class WebviewWindowsItemControllerImpel
    extends WebviewItemController<WebviewController> {
  final List<StreamSubscription> subscriptions = [];

  @override
  Future<void> init() async {
    webviewController ??= WebviewController();
    await webviewController!.initialize();
    await webviewController!
        .setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
    initEventController.add(true);
  }

  @override
  Future<void> loadUrl(String url, bool useNativePlayer, bool useLegacyParser,
      {int offset = 0}) async {
    await unloadPage();
    count = 0;
    this.offset = offset;
    isIframeLoaded = false;
    isVideoSourceLoaded = false;
    videoLoadingEventController.add(true);
    subscriptions.add(webviewController!.onM3USourceLoaded.listen((data) {
      String url = data['url'] ?? '';
      if (url.isEmpty) {
        return;
      }
      unloadPage();
      isIframeLoaded = true;
      isVideoSourceLoaded = true;
      videoLoadingEventController.add(false);
      logEventController.add('Loading m3u8 source: $url');
      videoParserEventController.add((url, offset));
    }));
    subscriptions.add(webviewController!.onVideoSourceLoaded.listen((data) {
      String url = data['url'] ?? '';
      if (url.isEmpty) {
        return;
      }
      unloadPage();
      isIframeLoaded = true;
      isVideoSourceLoaded = true;
      videoLoadingEventController.add(false);
      logEventController.add('Loading video source: $url');
      videoParserEventController.add((url, offset));
    }));
    await webviewController!.loadUrl(url);
  }

  @override
  Future<void> unloadPage() async {
    subscriptions.forEach((s) {
      try {
        s.cancel();
      } catch (_) {}
    });
    await redirect2Blank();
  }

  @override
  void dispose() {
    subscriptions.forEach((s) {
      try {
        s.cancel();
      } catch (_) {}
    });
    webviewController!.dispose();
  }

  // The webview_windows package does not have a method to unload the current page. 
  // The loadUrl method opens a new tab, which can lead to memory leaks. 
  // Directly disposing of the webview controller would require reinitialization when switching episodes, which is costly. 
  // Therefore, this method is used to redirect to a blank page instead.
  Future<void> redirect2Blank() async {
    await webviewController!.executeScript('''
      window.location.href = 'about:blank';
    ''');
  }
}
