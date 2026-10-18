import 'package:flutter/material.dart';
import 'package:pala/api/api.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Kréta's own login page in a WebView (Android, iOS, macOS). The user does
/// every step there, including captcha and two-factor login; Pala only
/// catches the final redirect and pops with its URL (it carries the code).
class KretaWebLoginView extends StatefulWidget {
  final String instituteCode;

  const KretaWebLoginView({super.key, required this.instituteCode});

  @override
  State<KretaWebLoginView> createState() => _KretaWebLoginViewState();
}

class _KretaWebLoginViewState extends State<KretaWebLoginView> {
  late final WebViewController _controller;
  bool _done = false;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) =>
            _finishIfRedirect(request.url) ? NavigationDecision.prevent : NavigationDecision.navigate,
        // Some platforms skip onNavigationRequest for server redirects.
        onPageStarted: _finishIfRedirect,
        onUrlChange: (change) {
          final url = change.url;
          if (url != null) _finishIfRedirect(url);
        },
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      ))
      ..loadRequest(Uri.parse(KretaAPI.authorizeUrl(instituteCode: widget.instituteCode)));
  }

  bool _finishIfRedirect(String url) {
    if (!url.startsWith(KretaAPI.redirectUri)) return false;
    if (!_done && mounted) {
      _done = true;
      Navigator.of(context).pop(url);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bejelentkezés a Kréta oldalán'),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress / 100, minHeight: 2),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
