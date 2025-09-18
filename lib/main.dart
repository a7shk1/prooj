import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ✅ الهاندلر الخلفي (التسجيل ما يعرقل لأنه غير متزامن)
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/notifications_service.dart';
import 'screens/splash_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/developer_info_screen.dart';
import 'theme/app_theme.dart';

// 👇 الخلفية
import 'widgets/animated_gradient_background.dart'; // يحتوي GlobalBackground

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ لازم قبل أي Firebase، هذا سريع ومقبول ننتظره
    await Firebase.initializeApp();

    // ✅ تسجيل الهاندلر الخلفي (ما يأخر لأنه مش await)
    FirebaseMessaging.onBackgroundMessage(
      NotificationsService.firebaseMessagingBackgroundHandler,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  // 🚀 شغّل الواجهة فورًا
  runApp(const VarApp());

  // ⚡️ بعد أول فريم: نفّذ الأمور الشبكية بدون حجب الواجهة
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint("Anon sign-in error: $e");
    }

    try {
      await NotificationsService.init();
    } catch (e) {
      debugPrint("Notifications init error: $e");
    }

    try {
      await NotificationsService.requestPermission();
    } catch (e) {
      debugPrint("Notifications permission error: $e");
    }

    try {
      await NotificationsService.subscribeToMatchesTopic();
    } catch (e) {
      debugPrint("Subscribe topic error: $e");
    }

    try {
      final token = await NotificationsService.getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint("Get token error: $e");
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

      // 👇 خلفية عالمية ثابتة خلف كل الشاشات
      builder: (context, child) {
        return Stack(
          children: [
            // خليه بدون const مثل ما كاتب
            Positioned.fill(child: GlobalBackground()),
            if (child != null) child,
          ],
        );
      },

      // ✅ الراوتات الداخلية
      routes: {
        '/privacy': (_) => const PrivacyPolicyScreen(),
        '/contact': (_) => const ContactScreen(),
        '/developer': (_) => const DeveloperInfoScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
