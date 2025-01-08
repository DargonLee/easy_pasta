import 'package:flutter/material.dart';

/// 应用主题配置
class AppTheme {
  /// 亮色主题
  static ThemeData light() => ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        dividerColor: Colors.grey[200]!,
        useMaterial3: true,
      );

  /// 暗色主题
  static ThemeData dark() => ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          surface: Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.grey[800]!,
        useMaterial3: true,
      );
}
