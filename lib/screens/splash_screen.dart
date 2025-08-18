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

/// Splash متناسق مع native splash:
/// - خلفية سودة (#000000) مثل إعداد flutter_native_splash.
/// - اللوغو بالوسط تماماً.
/// - فِيد إن → فِيد آوت (3 ثواني) + توهّج خفيف نابض بالخلفية.
/// - نفحص الاشتراك بالتوازي؛ ننتقل بعد ما يكمّل الفيد وتجهز الوجهة.
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // توهّج خفيف
  late final AnimationController _glowCtrl;
  // فِيد 3 ثواني (0→1→0)
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  bool _fadeDone = false;
  Widget? _navTarget;

  @override
  void initState() {
    super.initState();

    // توهج بسيط نابض
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // فِيد (اختفاء/ظهور) لمدة 3 ثواني
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fade = TweenSequence<double>([
      // 0 → 1 (1.5 ثانية تقريباً)
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      // 1 → 0 (1.5 ثانية تقريباً)
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_fadeCtrl);

    _fadeCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _fadeDone = true;
        _maybeNavigate();
      }
    });

    // ابدأ الأنيميشن والفحص سوية
    _fadeCtrl.forward();
    _decideTarget();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _decideTarget() async {
    try {
      final deviceId = await _getDeviceId();
      final doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(deviceId)
          .get();

      final now = DateTime.now();
      if (doc.exists) {
        final data = doc.data()!;
        final endAtTs = data['endAt'];
        final endAt = (endAtTs is Timestamp) ? endAtTs.toDate() : now.subtract(const Duration(days: 1));
        final active = data['active'] == true;

        if (active && endAt.isAfter(now)) {
          _navTarget = const HomeScreen();
        } else {
          _navTarget = const SubscriptionScreen();
        }
      } else {
        _navTarget = const SubscriptionScreen();
      }
    } catch (_) {
      _navTarget = const SubscriptionScreen();
    }
    _maybeNavigate();
  }

  void _maybeNavigate() {
    if (!_fadeDone || _navTarget == null || !mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => _navTarget!),
    );
  }

  Future<String> _getDeviceId() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return a.id; // ANDROID_ID
    } else if (Platform.isIOS) {
      final i = await info.iosInfo;
      return i.identifierForVendor ?? 'unknown_ios';
    }
    return 'unknown_device';
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF000000); // نفس لون الـ native splash

    return Scaffold(
      backgroundColor: bg,
      body: Center( // ← يضمن تمركز كلشي بالنص
        child: Stack(
          alignment: Alignment.center,
          children: [
            // توهج خفيف جداً تحت اللوغو
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) {
                final t = _glowCtrl.value; // 0..1..0
                final size = 240.0 + 12.0 * t;
                final opacity = 0.10 + 0.18 * t; // هادئ
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7A3BFF).withOpacity(opacity), // بنفسجي باهت
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                );
              },
            ),

            // اللوغو: فِيد إن/آوت 3 ثواني
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
