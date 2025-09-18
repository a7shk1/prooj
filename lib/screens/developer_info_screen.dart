import 'package:flutter/material.dart';

class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عن المطوّر'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            const Text(
              'عين ستور',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'المطوّر الرسمي لتطبيق VAR IPTV',
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurface.withOpacity(.7),
              ),
            ),
            const SizedBox(height: 20),

            // الوصف
            const Text(
              'عين ستور هي صفحة مختصة بتطوير وتوفير تطبيقات عملية تخلي حياتك الرقمية أبسط وأسرع. '
                  'تطبيق VAR IPTV هو واحد من مشاريعنا، صُمم ليقدّم تجربة مشاهدة أنيقة وسلسة مع تحديثات مباشرة للمباريات والقنوات. \n\n'
                  'نهتم دائماً إنو يكون التطبيق ثابت، سريع، وبواجهة عصرية تحافظ على راحة المستخدم. '
                  'مع VAR IPTV راح تلاگي المتعة والجودة بمكان واحد، وبأسلوب يلبّي احتياجاتك اليومية من البث المباشر.',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
