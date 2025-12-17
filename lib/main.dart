// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/notifications_service.dart';
import 'services/subscription_service.dart';

import 'screens/splash_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/developer_info_screen.dart';
import 'screens/home_screen.dart';
import 'screens/subscription_screen.dart';

import 'theme/app_theme.dart';
import 'widgets/animated_gradient_background.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // شغّل الواجهة فوراً (حتى لو Firebase علگ)
  runApp(const VarApp());

  // الباقي نخليه بالخلفية بدون ما يوقف الرسم
  _initAsync();
}

Future<void> _initAsync() async {
  // 1) Firebase (timeout حتى ما يعلق)
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 5));
    FirebaseMessaging.onBackgroundMessage(
      NotificationsService.firebaseMessagingBackgroundHandler,
    );
  } catch (_) {
    // إذا فشل Firebase/علگ: نكمل، بس ميزات Firebase ممكن ما تشتغل
  }

  // 2) تسجيل دخول مجهول + إشعارات (كلها محمية)
  try {
    await FirebaseAuth.instance.signInAnonymously().timeout(const Duration(seconds: 5));
  } catch (_) {}

  try {
    await NotificationsService.init();
    await NotificationsService.requestPermission();
    await NotificationsService.subscribeToMatchesTopic();
    await NotificationsService.getToken();
  } catch (_) {}

  // 3) توجيه حسب الاشتراك
  try {
    final hasAccess = await SubscriptionService.hasActiveAccess()
        .timeout(const Duration(seconds: 6));

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    if (hasAccess) {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
    }
  } catch (_) {
    // إذا فشل الفحص: خلي المستخدم يكمل على السبلّاش/Subscription لاحقاً
  }
}

class VarApp extends StatelessWidget {
  const VarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Var IPTV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: navigatorKey,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(child: GlobalBackground()),
            if (child != null) child,
          ],
        );
      },
      routes: {
        '/privacy': (_) => const PrivacyPolicyScreen(),
        '/contact': (_) => const ContactScreen(),
        '/developer': (_) => const DeveloperInfoScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
