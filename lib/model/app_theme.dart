import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';

/// 应用主题配置 - Apple 风格设计系统
class AppTheme {
  AppTheme._();

  // ==================== 亮色主题 ====================
  static ThemeData light() => ThemeData(
        useMaterial3: true,

        // 配色方案
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.primaryLight,
          onSecondary: Colors.white,
          error: AppColors.error,
          onError: Colors.white,
          surface: AppColors.lightCardBackground,
          onSurface: AppColors.lightTextPrimary,
          surfaceContainerHighest: AppColors.lightSecondaryBackground,
          outline: AppColors.lightBorder,
          outlineVariant: AppColors.lightDivider,
        ),

        // 背景色
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardColor: AppColors.lightCardBackground,
        dividerColor: AppColors.lightDivider,

        // 文本主题
        textTheme: AppTypography.getTextTheme(false),

        // AppBar 主题
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: AppColors.lightBackground,
          foregroundColor: AppColors.lightTextPrimary,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontSize: AppFontSizes.headline,
            fontWeight: AppFontWeights.semiBold,
            color: AppColors.lightTextPrimary,
          ),
        ),

        // 卡片主题
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.lightCardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          margin: const EdgeInsets.all(0),
        ),

        // 按钮主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            textStyle: AppTypography.button,
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            textStyle: AppTypography.button,
          ),
        ),

        // 图标主题
        iconTheme: const IconThemeData(
          color: AppColors.lightTextPrimary,
          size: 20,
        ),

        // 输入框主题
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightSecondaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          hintStyle: AppTypography.lightBody.copyWith(
            color: AppColors.lightTextSecondary,
          ),
        ),

        // 对话框主题
        dialogTheme: DialogThemeData(
          elevation: 0,
          backgroundColor: AppColors.lightCardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
          ),
        ),

        // 分割线主题
        dividerTheme: const DividerThemeData(
          color: AppColors.lightDivider,
          thickness: 1,
          space: 1,
        ),

        // Chip 主题
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.lightSecondaryBackground,
          selectedColor: AppColors.primary,
          labelStyle: AppTypography.lightBody,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),

        // ListTile 主题
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ),

        // 滚动条主题
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(
            AppColors.lightTextSecondary.withValues(alpha: 0.3),
          ),
          radius: const Radius.circular(AppRadius.sm),
          thickness: WidgetStateProperty.all(6),
        ),

        // 底部导航栏主题
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.lightBackground,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.lightTextSecondary,
          elevation: 0,
        ),
      );

  // ==================== 暗色主题 ====================
  static ThemeData dark() => ThemeData(
        useMaterial3: true,

        // 配色方案
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryLight,
          onPrimary: AppColors.darkTextPrimary,
          secondary: AppColors.primary,
          onSecondary: Colors.white,
          error: AppColors.error,
          onError: Colors.white,
          surface: AppColors.darkCardBackground,
          onSurface: AppColors.darkTextPrimary,
          surfaceContainerHighest: AppColors.darkSecondaryBackground,
          outline: AppColors.darkBorder,
          outlineVariant: AppColors.darkDivider,
        ),

        // 背景色
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCardBackground,
        dividerColor: AppColors.darkDivider,

        // 文本主题
        textTheme: AppTypography.getTextTheme(true),

        // AppBar 主题
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: AppColors.darkBackground,
          foregroundColor: AppColors.darkTextPrimary,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontSize: AppFontSizes.headline,
            fontWeight: AppFontWeights.semiBold,
            color: AppColors.darkTextPrimary,
          ),
        ),

        // 卡片主题
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.darkCardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          margin: const EdgeInsets.all(0),
        ),

        // 按钮主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.darkTextPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            textStyle: AppTypography.button,
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            textStyle: AppTypography.button,
          ),
        ),

        // 图标主题
        iconTheme: const IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 20,
        ),

        // 输入框主题
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSecondaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide:
                const BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          hintStyle: AppTypography.darkBody.copyWith(
            color: AppColors.darkTextSecondary,
          ),
        ),

        // 对话框主题
        dialogTheme: DialogThemeData(
          elevation: 0,
          backgroundColor: AppColors.darkCardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
          ),
        ),

        // 分割线主题
        dividerTheme: const DividerThemeData(
          color: AppColors.darkDivider,
          thickness: 1,
          space: 1,
        ),

        // Chip 主题
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.darkSecondaryBackground,
          selectedColor: AppColors.primaryLight,
          labelStyle: AppTypography.darkBody,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),

        // ListTile 主题
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ),

        // 滚动条主题
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(
            AppColors.darkTextSecondary.withValues(alpha: 0.3),
          ),
          radius: const Radius.circular(AppRadius.sm),
          thickness: WidgetStateProperty.all(6),
        ),

        // 底部导航栏主题
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkBackground,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.darkTextSecondary,
          elevation: 0,
        ),
      );

  // ==================== 工具方法 ====================

  /// 根据亮度获取对应主题
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.light ? light() : dark();
  }

  /// 判断是否为深色模式
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
