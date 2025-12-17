import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'home_screen.dart';
import 'subscription_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  bool _minShowDone = false;
  bool _navigated = false;

  // افتراضي: لا تظل واقف
  Widget _navTarget = const SubscriptionScreen();

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_fadeCtrl);
    _fadeCtrl.forward();

    Future.delayed(const Duration(seconds: 1), () {
      _minShowDone = true;
      _maybeNavigate();
    });

    _decideTarget();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo.png'), context);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _decideTarget() async {
    try {
      final deviceId = await _getDeviceId().timeout(const Duration(seconds: 3));

      final doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(deviceId)
          .get()
          .timeout(const Duration(seconds: 5));

      final now = DateTime.now();
      if (doc.exists) {
        final data = doc.data()!;
        final endAtTs = data['endAt'];
        final endAt = (endAtTs is Timestamp) ? endAtTs.toDate() : now.subtract(const Duration(days: 1));
        final active = data['active'] == true;

        _navTarget = (active && endAt.isAfter(now))
            ? const HomeScreen()
            : const SubscriptionScreen();
      } else {
        _navTarget = const SubscriptionScreen();
      }
    } catch (_) {
      _navTarget = const SubscriptionScreen();
    }

    _maybeNavigate();
  }

  void _maybeNavigate() {
    if (!mounted || _navigated) return;
    if (!_minShowDone) return;

    _navigated = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => _navTarget),
    );
  }

  Future<String> _getDeviceId() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return a.id;
    } else if (Platform.isIOS) {
      final i = await info.iosInfo;
      return i.identifierForVendor ?? 'unknown_ios';
    }
    return 'unknown_device';
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF000000);
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) {
                final t = _glowCtrl.value;
                final size = 240.0 + 12.0 * t;
                final opacity = 0.10 + 0.18 * t;
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7A3BFF).withOpacity(opacity),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                );
              },
            ),
            FadeTransition(
              opacity: _fade,
              child: Image.asset(
                'assets/images/logo.png',
                width: 160,
                height: 160,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
