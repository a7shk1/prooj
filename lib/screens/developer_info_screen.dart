import 'package:flutter/material.dart';

class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معلومات المطوّر')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أحمد خالد',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'ماجستير في الكيمياء',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              'مهتم ببناء تطبيقات عملية وسلسة تخلّي تجربة المستخدم أبسط وأسرع. '
                  'أجمع بين الدقّة العلمية وحب البرمجة، وأحب كرة القدم وكل جديد في عالم التقنية. '
                  'أطمح دائماً لتقديم حلول محترفة بواجهات أنيقة وأداء ثابت.',
              style: TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
