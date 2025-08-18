import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'آخر تحديث: 2025-08-15\n\n'
              'نحترم خصوصيتك. لا يقوم Var IPTV بجمع بيانات شخصية حساسة دون موافقتك. '
              'قد نقوم بجمع بيانات تقنية عامة مثل إصدار النظام والمعلومات اللازمة لتحسين الأداء وحل المشاكل.\n\n'
              '• الأذونات: يطلب التطبيق أذونات الشبكة للوصول إلى المحتوى فقط. لا نصل إلى بياناتك الخاصة بدون إذن واضح.\n'
              '• روابط خارجية: قد يحتوي التطبيق على روابط لخدمات خارجية (مثل تيليجرام، واتساب، إنستغرام). '
              'استخدامك لهذه الخدمات يخضع لسياساتها.\n'
              '• الأمان: نعمل على تحديث التطبيق بشكل دوري وتحسين الحماية من الوصول غير المصرّح به.\n'
              '• التواصل: لأي استفسار متعلق بالخصوصية، راسلنا عبر البريد: ahmed.289ahmed@gmail.com\n\n'
              'باستخدامك للتطبيق فأنت توافق على هذه السياسة. قد نقوم بتحديثها من حين لآخر وسيتم نشر التعديلات داخل التطبيق.',
          style: TextStyle(height: 1.6),
        ),
      ),
    );
  }
}
