// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'channels_screen.dart';
import 'matches_screen.dart';
import 'subscription_screen.dart';
import '../widgets/app_menu_drawer.dart';
import '../services/subscription_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0; // البدء على القنوات بشكل افتراضي

  final List<Widget> screens = const [
    ChannelsScreen(),
    MatchesScreen(),
    AccountScreen(), // Me
  ];

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
            Image.asset('assets/images/logo.png', height: 24),
            const SizedBox(width: 8),
            const Text(
              'VAR IP TV',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
          ),
        ],
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8A2BE2), Color(0xFF1E1E2C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: IndexedStack(index: index, children: screens),
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            selectedIcon: Icon(Icons.live_tv),
            label: 'Channels',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Matches',
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

/// =====================
/// تبويب "Me"
/// =====================
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _loading = true;
  String _deviceId = 'غير مُعرّف';
  Map<String, dynamic>? _sub; // بيانات الاشتراك النشط (إن وُجد)
  String? _error; // رسالة ودّية عند غياب الاشتراك/الربط

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _deviceId = 'غير مُعرّف';
      _sub = null;
    });

    try {
      // 1) جلب الـ deviceId الحقيقي المرتبط في مجموعة devices
      final resolved = await SubscriptionService.getResolvedDeviceId();

      if (resolved == null || resolved.isEmpty) {
        // لا يوجد ربط لهذا الجهاز حتى الآن
        if (!mounted) return;
        setState(() {
          _deviceId = 'غير مُعرّف';
          _loading = false;
          _error =
          'لا يوجد ربط لهذا الجهاز ضمن الاشتراكات.\n'
              'فعِّل تجربة مجانية أو كود مدفوع مرة واحدة ليتم إنشاء الربط تلقائياً.';
        });
        return;
      }

      // 2) جلب الاشتراك النشط لهذا الجهاز فقط
      final subDoc =
      await SubscriptionService.getActiveSubscriptionByDeviceId(resolved);

      if (!mounted) return;
      setState(() {
        _deviceId = resolved;
        _sub = subDoc?.data();
        _loading = false;
        if (_sub == null) {
          _error = 'لا يوجد اشتراك نشط لهذا الجهاز حالياً.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'حدث خطأ أثناء جلب البيانات.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _typeLabel(String? t) {
    if (t == 'paid') return 'مدفوع';
    if (t == 'trial') return 'مجاني (تجربة)';
    return 'غير معروف';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text(
                "معلومات الحساب",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text("معرّف الجهاز"),
              subtitle: Text(_deviceId),
            ),
            if (_sub == null) ...[
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.warning, color: Colors.orange),
                title: Text("لا يوجد اشتراك نشط"),
                subtitle: Text("يبدو أنه لا يوجد لديك اشتراك صالح حالياً."),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _load,
                child: const Text('إعادة التحقق من الاشتراك'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ] else ...[
              ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text("نوع الاشتراك"),
                subtitle: Text(_typeLabel(_sub!['type'] as String?)),
              ),
              if (_sub!['endAt'] is Timestamp)
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text("ينتهي في"),
                  subtitle: Builder(
                    builder: (_) {
                      final end = (_sub!['endAt'] as Timestamp).toDate();
                      final remain = end.difference(DateTime.now()).inDays;
                      return Text("${end.toLocal()} (${remain} يوم متبقٍ)");
                    },
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _load,
                child: const Text('تحديث الحالة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
