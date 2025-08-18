import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'home_screen.dart';
import 'admin_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  int _tapCount = 0;

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

  void _msg(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _startTrial() async {
    setState(() => _loading = true);
    try {
      final deviceId = await _getDeviceId();
      final subRef =
      FirebaseFirestore.instance.collection('subscriptions').doc(deviceId);
      final snap = await subRef.get();

      if (snap.exists && (snap.data()?['type'] == 'trial')) {
        _msg('انت مستخدم التجربة المجانية سابقًا!');
        return;
      }

      final now = DateTime.now();
      final end = now.add(const Duration(days: 7));

      await subRef.set({
        'deviceId': deviceId,
        'type': 'trial',
        'startAt': Timestamp.fromDate(now),
        'endAt': Timestamp.fromDate(end),
        'active': true,
        'name': '',
        'notes': 'Free trial',
      }, SetOptions(merge: true));

      _msg('تم تفعيل التجربة المجانية (7 أيام) ✅');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      _msg('صار خطأ بالتجربة: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _activateCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      _msg('اكتب الكود أولاً');
      return;
    }

    setState(() => _loading = true);
    try {
      final deviceId = await _getDeviceId();
      final codeRef =
      FirebaseFirestore.instance.collection('codes').doc(code);
      final codeSnap = await codeRef.get();

      if (!codeSnap.exists) {
        _msg('الكود غير موجود ❌');
        return;
      }

      final data = codeSnap.data()!;
      final active = data['active'] == true;
      final used = data['used'] == true;
      final bound = (data['boundDeviceId'] as String?);

      if (used && bound != null && bound != deviceId) {
        _msg('الكود مستخدم على جهاز آخر ❌');
        return;
      }
      if (!active) {
        _msg('الكود غير مفعل ❌');
        return;
      }

      final days =
      (data['durationDays'] is int) ? data['durationDays'] as int : 30;

      final now = DateTime.now();
      final end = now.add(Duration(days: days));

      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(deviceId)
          .set({
        'deviceId': deviceId,
        'type': 'paid',
        'code': code,
        'startAt': Timestamp.fromDate(now),
        'endAt': Timestamp.fromDate(end),
        'active': true,
        'name': '',
        'notes': '',
      }, SetOptions(merge: true));

      await codeRef.set({
        'used': true,
        'boundDeviceId': deviceId,
        'active': true,
      }, SetOptions(merge: true));

      _msg('تم تفعيل الاشتراك ✅');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      _msg('صار خطأ بالتفعيل: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onLogoTap() {
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاشتراكات'),
        centerTitle: true,
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _onLogoTap,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startTrial,
                  child: const Text('ابدأ التجربة المجانية (7 أيام)'),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeCtrl,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'ادخل كود الاشتراك المدفوع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _activateCode,
                  child: const Text('تفعيل الكود'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
