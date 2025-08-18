import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _askPassword);
  }

  Future<void> _askPassword() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('رمز الدخول'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'ادخل الرمز السري'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim() == 'a7shk') {
                Navigator.pop(ctx, true);
              } else {
                Navigator.pop(ctx, false);
              }
            },
            child: const Text('دخول'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _authorized = true);
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authorized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الاشتراكات')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ====== المدفوعات (codes) ======
            const _SectionHeader(title: '💎 الاشتراكات المدفوعة (codes)'),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('codes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _EmptyBox(text: 'لا توجد أكواد مدفوعة بعد');
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final m = docs[i].data();
                    final code = m['code'] ?? docs[i].id;
                    final active = m['active'] == true;
                    final used = m['used'] == true;
                    final days = m['durationDays'];
                    final name = (m['name'] ?? '').toString();
                    final notes = (m['notes'] ?? '').toString();
                    final bound = (m['boundDeviceId'] ?? '').toString();

                    return Card(
                      child: ListTile(
                        title: Text(
                          '$code • ${active ? "ACTIVE" : "INACTIVE"} • ${used ? "USED" : "NEW"}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (name.isNotEmpty) Text('الاسم: $name'),
                            if (notes.isNotEmpty) Text('ملاحظات: $notes'),
                            if (days != null) Text('المدة: $days يوم'),
                            if (bound.isNotEmpty) Text('مرتبط بجهاز: $bound'),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 6,
                          children: [
                            IconButton(
                              tooltip: 'نسخ الكود',
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: code.toString()));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تم نسخ الكود: $code')),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'تعديل',
                              icon: const Icon(Icons.edit, color: Colors.amber),
                              onPressed: () =>
                                  _editCodeDialog(docs[i].id, m),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            // ====== التجارب المجانية (subscriptions) ======
            const _SectionHeader(title: '🎁 التجارب المجانية (subscriptions)'),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('subscriptions')
                  .snapshots(), // ✅ جبت كل المستندات بدون شروط
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _EmptyBox(text: 'لا توجد تجارب مجانية');
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final m = docs[i].data();
                    final deviceId = (m['deviceId'] ?? docs[i].id).toString();
                    final type = (m['type'] ?? '---').toString();
                    final active = m['active'] == true;
                    final start = (m['startAt'] as Timestamp?)?.toDate();
                    final end = (m['endAt'] as Timestamp?)?.toDate();
                    final notes = (m['notes'] ?? '').toString();

                    return Card(
                      child: ListTile(
                        title: Text(
                            '$deviceId • $type • ${active ? "ACTIVE" : "INACTIVE"}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (start != null) Text('من: $start'),
                            if (end != null) Text('إلى: $end'),
                            if (notes.isNotEmpty) Text('ملاحظات: $notes'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPaidCodeDialog,
        icon: const Icon(Icons.add),
        label: const Text('إضافة كود مدفوع'),
      ),
    );
  }

  // ====== إنشاء كود عشوائي ======
  String _generateCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ====== Dialog إضافة كود مدفوع ======
  Future<void> _createPaidCodeDialog() async {
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '30');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنشاء كود مدفوع جديد'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration:
                const InputDecoration(labelText: 'اسم المشترك (اختياري)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration:
                const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                decoration:
                const InputDecoration(labelText: 'عدد الأيام (افتراضي 30)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final code = _generateCode(8);
              final days = int.tryParse(daysCtrl.text) ?? 30;

              await FirebaseFirestore.instance.collection('codes').doc(code).set({
                'code': code,
                'active': true,
                'used': false,
                'durationDays': days,
                'name': nameCtrl.text.trim(),
                'notes': notesCtrl.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ تم إنشاء الكود: $code')),
                );
              }
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  // ====== Dialog تعديل كود ======
  Future<void> _editCodeDialog(String docId, Map<String, dynamic> data) async {
    final codeCtrl = TextEditingController(text: data['code'] ?? docId);
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final notesCtrl = TextEditingController(text: data['notes'] ?? '');
    final daysCtrl =
    TextEditingController(text: data['durationDays']?.toString() ?? '30');
    bool active = data['active'] == true;
    bool used = data['used'] == true;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الكود'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'الكود'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'عدد الأيام'),
              ),
              SwitchListTile(
                title: const Text('فعال'),
                value: active,
                onChanged: (val) => active = val,
              ),
              SwitchListTile(
                title: const Text('مستخدم'),
                value: used,
                onChanged: (val) => used = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final newCode = codeCtrl.text.trim();
              final days = int.tryParse(daysCtrl.text) ?? 30;

              if (newCode != docId) {
                final oldData = Map<String, dynamic>.from(data);
                oldData['code'] = newCode;
                oldData['name'] = nameCtrl.text.trim();
                oldData['notes'] = notesCtrl.text.trim();
                oldData['durationDays'] = days;
                oldData['active'] = active;
                oldData['used'] = used;

                await FirebaseFirestore.instance
                    .collection('codes')
                    .doc(newCode)
                    .set(oldData);
                await FirebaseFirestore.instance
                    .collection('codes')
                    .doc(docId)
                    .delete();
              } else {
                await FirebaseFirestore.instance
                    .collection('codes')
                    .doc(docId)
                    .update({
                  'code': newCode,
                  'name': nameCtrl.text.trim(),
                  'notes': notesCtrl.text.trim(),
                  'durationDays': days,
                  'active': active,
                  'used': used,
                });
              }

              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

// ====== Widgets مساعدة ======
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text(text)),
        ),
      ),
    );
  }
}
