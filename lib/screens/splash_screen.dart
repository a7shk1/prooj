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

/// Splash سريع ومتناسق مع native splash:
/// - خلفية سوداء.
/// - اللوغو بالوسط.
/// - فِيد دخول فقط (1 ثانية) + توهج خفيف.
/// - ننتقل بمجرد: (مرور ثانية واحدة) && (تحديد الوجهة).
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // توهّج خفيف
  late final AnimationController _glowCtrl;

  // فِيد دخول 1 ثانية (0→1)
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  bool _minShowDone = false; // يضمن بقاء الشاشة 1 ثانية فقط كحد أدنى
  Widget? _navTarget;

  @override
  void initState() {
    super.initState();

    // توهج بسيط نابض وسريع
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // فِيد دخول 1 ثانية
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_fadeCtrl);
    _fadeCtrl.forward();

    // حد أدنى للعرض = 1 ثانية
    Future.delayed(const Duration(seconds: 1), () {
      _minShowDone = true;
      _maybeNavigate();
    });

    // حدد الوجهة بالتوازي
    _decideTarget();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحميل شعار السبلّاش مسبقاً لظهور فوري
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
      final deviceId = await _getDeviceId();
      final doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(deviceId)
          .get();

      final now = DateTime.now();
      if (doc.exists) {
        final data = doc.data()!;
        final endAtTs = data['endAt'];
        final endAt = (endAtTs is Timestamp)
            ? endAtTs.toDate()
            : now.subtract(const Duration(days: 1));
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
    if (!_minShowDone || _navTarget == null || !mounted) return;
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

            // اللوغو: فِيد دخول 1 ثانية
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
