import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // نمنع أي انتقال (لو حاول يضغط رابط)
          onNavigationRequest: (request) {
            return NavigationDecision.prevent;
          },
          onPageFinished: (url) {
            _controller.runJavaScript("""
              // نخفي الأخبار والإعلانات
              document.querySelectorAll('header, footer, .news, .ads, .article').forEach(e => e.style.display='none');

              // نخلي خلفية غامقة مرتبة
              document.body.style.background = '#000';
              document.body.style.overflowY = 'scroll';

              // نلغي أي ضغط على الروابط أو العناصر
              document.querySelectorAll('a, button').forEach(e => {
                e.removeAttribute('href');
                e.style.pointerEvents = 'none';
              });
            """);
          },
        ),
      )
      ..loadRequest(Uri.parse("https://www.yalla1shoot.com/"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
