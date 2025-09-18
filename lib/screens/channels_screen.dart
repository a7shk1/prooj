// lib/screens/channels_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← جديد: للوصول إلى AssetManifest
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/categories_static.dart';
import '../data/channels_repository.dart';
import '../models/channel.dart';
import '../utils/no_cache_url.dart'; // ✅ لمنع الكاش على روابط RAW

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  static const String _playerPackage = 'com.varplayer.app';
  static const String _scheme = 'varplayer';
  static const String _host = 'play';

  Future<void> _openInVarPlayer({
    required String url,
    required String name,
  }) async {
    final token = base64Url.encode(utf8.encode(url));
    final uri = Uri(
      scheme: _scheme,
      host: _host,
      queryParameters: {'t': token, 'q': 'auto', 'n': name},
    );

    try {
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'action_view',
          data: uri.toString(),
          package: _playerPackage,
        );
        await intent.launch();
      } else if (Platform.isIOS) {
        final playUrl = uri.toString();
        if (await canLaunchUrl(Uri.parse(playUrl))) {
          await launchUrl(
            Uri.parse(playUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw "VAR Player not installed";
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تعذر فتح VAR Player")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF6D28D9);
    // ألوان فقط (أفتح لتوضيح الشعار)
    final mainCardBg = const Color(0xFF242A40);
    final mainBorder = purple.withOpacity(0.26);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.tv, color: Colors.white),
            SizedBox(width: 8),
            Text("القنوات"),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemCount: kCategories.length,
        itemBuilder: (context, i) {
          final tile = kCategories[i];
          return _PressableScale(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _CategoryChannelsScreen(
                    categoryId: tile.id,
                    title: tile.title,
                    playlistUrl: tile.playlistUrl,
                    openInVarPlayer: _openInVarPlayer,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: mainCardBg, // ← كان 0xFF1F2937
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: purple.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: mainBorder, width: 1),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 72,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _SmartTileIcon(
                          categoryId: tile.id,
                          primaryPath: tile.assetIcon,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tile.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// شاشة القنوات داخل الباقة
class _CategoryChannelsScreen extends StatefulWidget {
  final String categoryId; // bein / dazn / espn / seriaa / ...
  final String title;
  final String playlistUrl;
  final Future<void> Function({required String url, required String name})
  openInVarPlayer;

  const _CategoryChannelsScreen({
    required this.categoryId,
    required this.title,
    required this.playlistUrl,
    required this.openInVarPlayer,
  });

  @override
  State<_CategoryChannelsScreen> createState() =>
      _CategoryChannelsScreenState();
}

class _CategoryChannelsScreenState extends State<_CategoryChannelsScreen> {
  final repo = ChannelsRepository();
  bool isLoading = true;
  String? error;
  List<Channel> channels = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // ✅ إجبار جلب نسخة فريش من RAW كل مرة (يمكنك وضع TTL دقيقة لتخفيف تغيّر الرابط)
      final freshUrl = noCacheUrl(
        widget.playlistUrl,
        // ttl: const Duration(minutes: 1),
      );
      final fetched = await repo.fetchChannelsFromUrl(freshUrl);
      if (!mounted) return;
      setState(() {
        channels = fetched;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "فشل تحميل القنوات: $e"; // ✅ نعرض الخطأ الحقيقي للتشخيص
        isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => isLoading = true);
    await _load();
  }

  String _assetFolder(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'seriaa':
        return 'assets/SeriaA';
      default:
        return 'assets/${categoryId.toLowerCase()}';
    }
  }

  String _slug(String s, {bool underscored = false, bool lower = false}) {
    var t = s.trim();
    if (lower) t = t.toLowerCase();
    t = t.replaceAll(
        RegExp(r'[^\p{L}\p{N}\s_\.-]+', unicode: true), '');
    t = t.replaceAll(RegExp(r'\s+'), underscored ? '_' : ' ');
    t = t.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    return t;
  }

  List<String> _logoCandidates(String categoryId, String channelName) {
    final folder = _assetFolder(categoryId);
    final raw = channelName.trim();
    final lc = raw.toLowerCase();
    final clean = _slug(raw, underscored: false, lower: false);
    final cleanLc = _slug(raw, underscored: false, lower: true);
    final under = _slug(raw, underscored: true, lower: true);

    final List<String> paths = [
      '$folder/$raw.png',
      '$folder/$lc.png',
      '$folder/$clean.png',
      '$folder/$under.png',
      '$folder/$cleanLc.png',
    ];

    final m = RegExp(r'(\d+)').firstMatch(raw);
    final num = m?.group(1);
    if (num != null) {
      switch (categoryId.toLowerCase()) {
        case 'bein':
          paths.add('$folder/bein$num.png');
          break;
        case 'dazn':
          paths.add('$folder/dazn$num.png');
          break;
        case 'espn':
          paths.add('$folder/espn$num.png');
          break;
        case 'mbc':
          paths.add('$folder/mbc$num.png');
          break;
        case 'premierleague':
          paths.add('$folder/premierleague$num.png');
          break;
        case 'roshnleague':
          paths.add('$folder/roshnleague$num.png');
          break;
        case 'generalsports':
          paths.add('$folder/generalsports$num.png');
          break;
        case 'seriaa':
          paths.addAll([
            '$folder/Stars Play $num.png',
            '$folder/Abu Dhabi Sports $num.png',
          ]);
          break;
      }
    }
    paths.add('$folder/logo.png'); // fallback
    return paths.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF6D28D9);
    // ألوان فقط (أفتح لتوضيح الشعار داخل الباقات)
    final innerCardBg = const Color(0xFF20263A);
    final innerBorder = purple.withOpacity(0.24);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
          ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          ElevatedButton(
              onPressed: _refresh,
              child: const Text("إعادة المحاولة")),
        ]),
      )
          : RefreshIndicator(
        onRefresh: _refresh,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: channels.length,
          itemBuilder: (_, i) {
            final ch = channels[i];
            final candidates =
            _logoCandidates(widget.categoryId, ch.name);
            return _PressableScale(
              onPressed: () =>
                  widget.openInVarPlayer(url: ch.url, name: ch.name),
              child: Container(
                decoration: BoxDecoration(
                  color: innerCardBg, // ← كان 0xFF111827
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: innerBorder, width: 1),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child:
                          _SmartAssetLogo(candidates: candidates),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: Text(
                        ch.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () => widget.openInVarPlayer(
                            url: ch.url, name: ch.name),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text("Play"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          textStyle: const TextStyle(fontSize: 14),
                          minimumSize: const Size.fromHeight(36),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ======= محلّ حل المشكلة: اختيار المسار الصحيح بسرعة من AssetManifest =======
class _AssetPathResolver {
  static Map<String, bool>? _allAssets; // cache of existing asset paths

  static Future<void> _ensureLoaded() async {
    if (_allAssets != null) return;
    final jsonStr = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> map = json.decode(jsonStr);
    _allAssets = {for (final k in map.keys) k: true};
  }

  /// يعيد أول مسار موجود من المرشحين أو null
  static Future<String?> firstExisting(List<String> candidates) async {
    await _ensureLoaded();
    final assets = _allAssets!;
    for (final p in candidates) {
      if (assets.containsKey(p)) return p;
    }
    return null;
  }
}

/// يجرب PNGات متعددة لشعار الكرت في الواجهة الرئيسية (خففنا المرشحين)
class _SmartTileIcon extends StatefulWidget {
  final String categoryId;
  final String primaryPath;

  const _SmartTileIcon({required this.categoryId, required this.primaryPath});

  @override
  State<_SmartTileIcon> createState() => _SmartTileIconState();
}

class _SmartTileIconState extends State<_SmartTileIcon> {
  late final List<String> _candidates;
  String? _resolved;

  @override
  void initState() {
    super.initState();
    _candidates = _buildCandidates(widget.categoryId, widget.primaryPath);
    _resolve();
  }

  List<String> _buildCandidates(String categoryId, String primary) {
    final List<String> c = [primary];
    if (categoryId.toLowerCase() == 'generalsports') {
      c.addAll([
        'assets/images/1.png',
        'assets/generalsports/logo.png',
      ]);
    } else {
      c.add('assets/${categoryId.toLowerCase()}/logo.png');
    }
    return c.toSet().toList();
  }

  Future<void> _resolve() async {
    final path = await _AssetPathResolver.firstExisting(_candidates);
    if (!mounted) return;
    setState(() => _resolved = path);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved != null) {
      precacheImage(AssetImage(_resolved!), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolved == null) {
      return const Icon(Icons.live_tv, size: 48, color: Colors.white);
    }
    return Image.asset(
      _resolved!,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    );
  }
}

/// يجرب أول PNG موجود من قائمة المسارات وإلا يعرض أيقونة TV.
class _SmartAssetLogo extends StatefulWidget {
  final List<String> candidates;
  const _SmartAssetLogo({required this.candidates});

  @override
  State<_SmartAssetLogo> createState() => _SmartAssetLogoState();
}

class _SmartAssetLogoState extends State<_SmartAssetLogo> {
  String? _resolved;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final path = await _AssetPathResolver.firstExisting(widget.candidates);
    if (!mounted) return;
    setState(() => _resolved = path);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved != null) {
      precacheImage(AssetImage(_resolved!), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolved == null) {
      return const Icon(Icons.tv, color: Colors.white, size: 48);
    }
    return Image.asset(
      _resolved!,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    );
  }
}

/// انيميشن ضغط خفيف للكرت عند اللمس (scale).
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  const _PressableScale({required this.child, required this.onPressed});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;
  void _down(_) => setState(() => _scale = 0.98);
  void _up(_) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: (d) => _up(d),
      onTapCancel: () => _up(null),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
