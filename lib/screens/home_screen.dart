import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import '../widgets/animated_gradient_background.dart';

// شاشاتك الحالية
import 'matches_screen.dart';
import 'channels_screen.dart';
import 'subscription_screen.dart';

// الشاشات الجديدة
import 'news_screen.dart';
import 'videos_screen.dart';

// 👇 استيراد القائمة الجانبية
import '../widgets/app_menu_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 1; // نبدأ على القنوات مثل قبل

  // ترتيب الصفحات: Matches / Channels / News / Videos / Me
  final List<Widget> screens = const [
    MatchesScreen(), // 0
    ChannelsScreen(), // 1
    NewsScreen(), // 2
    VideosScreen(), // 3
    AccountScreen(), // 4
  ];

  // ✨ متغير يتحكم بتبديل الألوان بالتناوب
  bool toggleGradient = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppMenuDrawer(),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const DrawerButton(),
            const SizedBox(width: 6),
            Image.asset(
              'assets/images/logo.png',
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'VAR IP TV',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
          )
        ],

        // ✨ خلفية متدرج متحركة
        flexibleSpace: AnimatedContainer(
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: toggleGradient
                  ? const [
                Color(0xFF6A11CB), // بنفسجي رايق
                Color(0xFF2575FC), // أزرق فاتح
              ]
                  : const [
                Color(0xFF8A2BE2), // بنفسجي غني
                Color(0xFF1E1E2C), // رمادي/أسود متناسق
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          onEnd: () {
            setState(() {
              toggleGradient = !toggleGradient;
            });
          },
        ),
        elevation: 8,
        backgroundColor: Colors.transparent,
      ),

      body: AnimatedGradientBackground(
        child: SafeArea(
          child: IndexedStack(index: index, children: screens),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            selectedIcon: Icon(Icons.live_tv),
            label: 'Channels',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'News',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}

// ================= شاشة الحساب / معلومات الاشتراك =================
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _deviceId = "loading...";
  Map<String, dynamic>? _subscription;

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

  Future<void> _loadData() async {
    final deviceId = await _getDeviceId();
    final snap = await FirebaseFirestore.instance
        .collection("subscriptions")
        .doc(deviceId)
        .get();

    if (mounted) {
      setState(() {
        _deviceId = deviceId;
        _subscription = snap.data();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_subscription == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final type = _subscription?['type'] ?? 'unknown';
    final endAt = (_subscription?['endAt'] as Timestamp?)?.toDate();
    final name = _subscription?['name'] ?? '';
    final remaining =
    endAt != null ? endAt.difference(DateTime.now()).inDays : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text("معلومات الحساب",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text("معرّف الجهاز"),
              subtitle: Text(_deviceId),
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: const Text("نوع الاشتراك"),
              subtitle: Text(
                type == "trial"
                    ? "مجاني (تجربة)"
                    : type == "paid"
                    ? "مدفوع"
                    : "غير معروف",
              ),
            ),
            if (endAt != null)
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text("ينتهي في"),
                subtitle: Text(
                  "${endAt.toLocal()} (${remaining != null ? "$remaining يوم متبقي" : ""})",
                ),
              ),
            if (type == "paid" && name.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("اسم المشترك"),
                subtitle: Text(name),
              ),
          ],
        ),
      ),
    );
  }
}
