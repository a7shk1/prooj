import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.actions,
    this.logoPath = 'assets/images/logo.png', // غيّر المسار إذا غيرته لاحقاً
    this.title = 'VAR IP TV',
  });

  final List<Widget>? actions;
  final String logoPath;
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // نستخدم DrawerButton بدل leading الافتراضي
      centerTitle: false,
      titleSpacing: 0, // يشيل الفراغ بين الأيقونة والعنوان
      title: Row(
        children: [
          const DrawerButton(), // يفتح الـ Drawer تلقائياً إذا موجود بالـ Scaffold
          const SizedBox(width: 6),
          // اللوغو
          Image.asset(
            logoPath,
            height: 24, // عدّل المقاس حسب لوغوك
          ),
          const SizedBox(width: 8),
          // النص
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
