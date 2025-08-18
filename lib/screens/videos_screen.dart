import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  late final WebViewController _controller;

  // استعلامات جاهزة (فلترات سريعة)
  final List<_QueryChip> _chips = const [
    _QueryChip(label: 'ملخصات مباريات', query: 'ملخصات مباريات'),
    _QueryChip(label: 'أهداف اليوم',    query: 'اهداف اليوم'),
    _QueryChip(label: 'Skills',          query: 'football skills'),
    _QueryChip(label: 'Premier League',  query: 'premier league highlights'),
    _QueryChip(label: 'LaLiga',          query: 'laliga highlights'),
  ];

  int _currentChip = 0;

  String _youtubeSearchUrl(String q) {
    final encoded = Uri.encodeQueryComponent(q);
    return 'https://m.youtube.com/results?search_query=$encoded';
  }

  Future<void> _loadQuery(int i) async {
    setState(() => _currentChip = i);
    await _controller.loadRequest(Uri.parse(_youtubeSearchUrl(_chips[i].query)));
  }

  @override
  void initState() {
    super.initState();

    // ملاحظة: في webview_flutter 4.x ما نستخدم WebView.platform = AndroidWebView();
    // الحزمة تختار الـ platform المناسب تلقائياً.

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        // User-Agent موبايل حتى واجهة يوتيوب الموبايل تفتح داخليًا
        'Mozilla/5.0 (Linux; Android 12; Mobile; rv:117.0) Gecko/117.0 Firefox/117.0',
      )
    // setMediaPlaybackRequiresUserGesture أُزيلت في الإصدارات الحديثة
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final u = req.url;

            // اسمح فقط بـ http/https
            final isHttp = u.startsWith('http://') || u.startsWith('https://');
            if (!isHttp) return NavigationDecision.prevent;

            // امنع روابط تفتح التطبيقات أو تخرج خارج الويب فيو
            final lower = u.toLowerCase();
            final blocked = [
              'intent:',
              'snssdk://',
              'tiktok://',
              'instagram://',
              'mailto:',
              'tel:',
              'whatsapp://',
              'tg://',
              'twitter://',
              'facebook://',
              'vnd.youtube'
            ].any((p) => lower.startsWith(p));

            if (blocked) return NavigationDecision.prevent;

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(
        _youtubeSearchUrl(_chips[_currentChip].query),
      ));
  }

  Future<bool> _handleWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false; // لا تخرج من الشاشة
    }
    return true; // اطلع من الشاشة إذا ماكو back
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('فيديوهات رياضية'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Column(
          children: [
            // شريط الفلاتر
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final selected = i == _currentChip;
                  return ChoiceChip(
                    label: Text(_chips[i].label),
                    selected: selected,
                    onSelected: (_) => _loadQuery(i),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                    ),
                    selectedColor: const Color(0xFF8A2BE2),
                    backgroundColor: const Color(0xFF222222),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _chips.length,
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            // الويب فيو
            Expanded(
              child: SafeArea(
                top: false,
                child: WebViewWidget(controller: _controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueryChip {
  final String label;
  final String query;
  const _QueryChip({required this.label, required this.query});
}
