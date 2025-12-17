// lib/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
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

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _startTrial() async {
    setState(() => _loading = true);
    try {
      final err = await SubscriptionService.startTrialOnce();
      if (err != null) {
        _msg(err);
        return;
      }
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
      final err = await SubscriptionService.activateWithCode(code: code);
      if (err != null) {
        _msg(err);
        return;
      }
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
      if (!mounted) return;
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
      appBar: AppBar(title: const Text('الاشتراكات'), centerTitle: true),
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
                child: Image.asset('assets/images/logo.png', height: 100),
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
