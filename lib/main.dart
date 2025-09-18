// main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/splash_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/developer_info_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/animated_gradient_background.dart'; // GlobalBackground

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إظهار الأخطاء بدل شاشة سودة أثناء التشخيص
  FlutterError.onError = (FlutterErrorDetails details) {
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.empty,
    );
  };

  ErrorWidget.builder = (FlutterErrorDetails d) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Flutter error:\n${d.exception}\n\n${d.stack}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ),
      );

  // (اختياري) قفل الاتجاه
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // تهيئة Firebase فقط
  try {
    await Firebase.initializeApp();
  } catch (e, s) {
    debugPrint('Firebase init error: $e\n$s');
  }

  // شغّل الواجهة فورًا
  runApp(const VarApp());

  // بعد أول فريم: تسجيل دخول مجهول حتى تقدر تتعامل مع Firestore
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      // debugPrint('Signed in anonymously');
    } catch (e) {
      debugPrint('Anon sign-in error: $e');
    }
  });
}

class VarApp extends StatelessWidget {
  const VarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Var IPTV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // خلفية متحركة عالمية خلف كل الشاشات
      builder: (context, child) {
        return Stack(
          children: [
            const Positioned.fill(child: GlobalBackground()),
            if (child != null) child,
          ],
        );
      },

      // الراوتات الداخلية
      routes: {
        '/privacy': (_) => const PrivacyPolicyScreen(),
        '/contact': (_) => const ContactScreen(),
        '/developer': (_) => const DeveloperInfoScreen(),
      },

      // شاشة البداية
      home: const SplashScreen(),
    );
  }
}
