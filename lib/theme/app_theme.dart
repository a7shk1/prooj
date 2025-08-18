import 'package:flutter/material.dart';

/// لوحة ألوان داكنة أنيقة مع لمسة بنفسجي كهربائي
class AppTheme {
  static const _seed = Color(0xFF8A2BE2); // بنفسجي مميز
  static const _bg   = Color(0xFF0E0E12); // خلفية أسود داكن
  static const _card = Color(0xFF17171C); // بطاقات
  static const _line = Color(0x22FFFFFF); // فاصل خفيف

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.dark,
    primary: _seed,
    surface: _bg,
    background: _bg,
    onBackground: Colors.white,
    onSurface: Colors.white,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: _darkScheme,
      scaffoldBackgroundColor: _bg,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: const Color(0xEE0E0E12),
        indicatorColor: _seed.withOpacity(0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: sel ? Colors.white : Colors.white70,
          );
        }),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF131318),
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),

      // ✅ التعديل هنا: CardTheme -> CardThemeData
      cardTheme: CardThemeData(
        color: _card,
        elevation: 10,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
      ),

      dividerTheme: const DividerThemeData(
        color: _line,
        thickness: 1,
        space: 1,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _seed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: Colors.white70,
        textColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      }),

      splashColor: _seed.withOpacity(0.15),
      highlightColor: Colors.white.withOpacity(0.03),
    );
  }
}
