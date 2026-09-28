/// dartnative_webview demo — a native in-app WebView (WKWebView on iOS,
/// android.webkit.WebView on Android).
///
/// The bottom bar: Back / Forward (browser
/// history) · Share · Open-in-browser — drawn with Cupertino icons on iOS and
/// Material icons on Android. Live load progress + page title up top, and the
/// system navigation bar is made transparent.
library;

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_share/dartnative_share.dart';
import 'package:dartnative_url_launcher/dartnative_url_launcher.dart';
import 'package:dartnative_webview/dartnative_webview.dart';

const _homeUrl = 'https://www.youtube.com';

class WebViewDemoScreen extends StatefulWidget {
  const WebViewDemoScreen({super.key});

  @override
  State<WebViewDemoScreen> createState() => _WebViewDemoScreenState();
}

class _WebViewDemoScreenState extends State<WebViewDemoScreen> {
  late final WebViewController _controller;
  String _currentUrl = _homeUrl;
  int _progress = 100;
  String _title = 'dartnative_webview';
  bool _canGoBack = false;
  bool _canGoForward = false;
  // The last navigation the app kept for itself, shown above the page.
  String? _kept;

  @override
  void initState() {
    super.initState();
    // White status + system navigation bars with dark icons — set in
    // initState so the overlay style applies before the first frame.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarColor: Color(0xFFFFFFFF),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFFFFFF),
      systemNavigationBarDividerColor: Color(0xFFFFFFFF),
    ));
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Every navigation the page asks for comes here first. A URL of
          // another app's scheme (a sign-in flow returning to the app, a
          // store link) is the app's to take: the web view keeps its page.
          onNavigationRequest: (request) {
            final scheme = Uri.tryParse(request.url)?.scheme ?? '';
            if (scheme == 'http' || scheme == 'https' || scheme == 'about') {
              return NavigationDecision.navigate;
            }
            if (mounted) setState(() => _kept = request.url);
            return NavigationDecision.prevent;
          },
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageStarted: (url) {
            if (mounted && url.isNotEmpty) setState(() => _currentUrl = url);
          },
          onPageFinished: _refreshHistory,
        ),
      )
      ..loadRequest(Uri.parse(_homeUrl));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Once a navigation settles, pull the new title + back/forward availability
  // and update the bar.
  Future<void> _refreshHistory(String url) async {
    if (!mounted) return;
    final title = await _controller.getTitle();
    final canBack = await _controller.canGoBack();
    final canForward = await _controller.canGoForward();
    if (!mounted) return;
    setState(() {
      if (url.isNotEmpty) _currentUrl = url;
      _title =
          (title == null || title.isEmpty) ? Uri.parse(_currentUrl).host : title;
      _canGoBack = canBack;
      _canGoForward = canForward;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(title: Text(_title)),
      body: Column(
        children: [
          // Thin top progress line while loading. Always present (height collapses
          // to 0 when idle) so the WebView keeps a stable slot in the Column and
          // isn't remounted when the bar appears/disappears.
          Container(
            height: _progress < 100 ? 2 : 0,
            color: const Color(0xFF0A84FF),
          ),
          if (_kept != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF4CE),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Kept for the app: $_kept',
                maxLines: 2,
                style: const TextStyle(fontSize: 13, color: Color(0xFF5C4400)),
              ),
            ),
          // the web view fills the space between the app bar and the bottom bar
          Expanded(child: WebViewWidget(controller: _controller)),
          _bottomBar(context),
        ],
      ),
    );
  }

  // ── Browser-style bottom bar: Back · Forward · Share · Open-in-browser ──
  // The bar's background reaches the screen's bottom edge; its buttons sit
  // above the home indicator or the gesture bar, by the bottom inset.
  Widget _bottomBar(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(top: BorderSide(color: Color(0x22000000), width: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(13, 4, 13, 4 + inset),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _barButton(
              icon: Platform.isIOS
                  ? CupertinoIcons.chevron_back
                  : MaterialSymbolsRounded.arrow_back,
              enabled: _canGoBack,
              onTap: () async {
                if (await _controller.canGoBack()) _controller.goBack();
              },
            ),
            _barButton(
              icon: Platform.isIOS
                  ? CupertinoIcons.chevron_forward
                  : MaterialSymbolsRounded.arrow_forward,
              enabled: _canGoForward,
              onTap: () async {
                if (await _controller.canGoForward()) _controller.goForward();
              },
            ),
            _barButton(
              icon: Platform.isIOS
                  ? CupertinoIcons.square_arrow_up
                  : MaterialSymbolsRounded.share,
              onTap: () => Share.share('Check out $_currentUrl'),
            ),
            _barButton(
              icon: Platform.isIOS
                  ? CupertinoIcons.compass
                  : MaterialSymbolsRounded.explore,
              onTap: () => DartNativeUrlLauncher.launch(_currentUrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barButton({
    required IconData icon,
    required void Function() onTap,
    bool enabled = true,
  }) =>
      GestureDetector(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.25,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 24, color: const Color(0xFF1C1C1E)),
          ),
        ),
      );
}
