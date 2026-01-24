import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';

/// 排版系统 - 统一的文本样式
/// 参考 Apple SF Pro 字体规范
class AppTypography {
  AppTypography._();

  // ==================== 基础字体家族 ====================
  /// 根据平台自动选择最佳字体
  static const String fontFamily = '.SF Pro Text'; // macOS 系统字体
  static const String displayFontFamily = '.SF Pro Display'; // 标题字体
  static const String monospaceFontFamily = '.SF Mono'; // 等宽字体

  // ==================== 浅色模式文本样式 ====================

  /// 大标题 1 - 34pt
  static TextStyle lightTitle1 = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: AppFontSizes.title1,
    fontWeight: AppFontWeights.bold,
    height: 1.2,
    color: AppColors.lightTextPrimary,
    letterSpacing: -0.5,
  );

  /// 大标题 2 - 28pt
  static TextStyle lightTitle2 = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: AppFontSizes.title2,
    fontWeight: AppFontWeights.bold,
    height: 1.25,
    color: AppColors.lightTextPrimary,
    letterSpacing: -0.4,
  );

  /// 大标题 3 - 24pt
  static TextStyle lightTitle3 = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: AppFontSizes.title3,
    fontWeight: AppFontWeights.semiBold,
    height: 1.3,
    color: AppColors.lightTextPrimary,
    letterSpacing: -0.3,
  );

  /// 标题 - 20pt
  static TextStyle lightHeadline = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.headline,
    fontWeight: AppFontWeights.semiBold,
    height: 1.35,
    color: AppColors.lightTextPrimary,
    letterSpacing: -0.2,
  );

  /// 副标题 - 17pt
  static TextStyle lightSubheadline = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.subheadline,
    fontWeight: AppFontWeights.regular,
    height: 1.4,
    color: AppColors.lightTextPrimary,
    letterSpacing: 0,
  );

  /// 强调文本 - 15pt
  static TextStyle lightCallout = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.callout,
    fontWeight: AppFontWeights.regular,
    height: 1.4,
    color: AppColors.lightTextPrimary,
    letterSpacing: 0,
  );

  /// 正文 - 13pt (默认)
  static TextStyle lightBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.body,
    fontWeight: AppFontWeights.regular,
    height: 1.45,
    color: AppColors.lightTextPrimary,
    letterSpacing: 0,
  );

  /// 正文（加粗）
  static TextStyle lightBodyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.body,
    fontWeight: AppFontWeights.semiBold,
    height: 1.45,
    color: AppColors.lightTextPrimary,
    letterSpacing: 0,
  );

  /// 脚注 - 11pt
  static TextStyle lightFootnote = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.footnote,
    fontWeight: AppFontWeights.regular,
    height: 1.5,
    color: AppColors.lightTextSecondary,
    letterSpacing: 0,
  );

  /// 说明文字 - 10pt
  static TextStyle lightCaption = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.caption,
    fontWeight: AppFontWeights.regular,
    height: 1.5,
    color: AppColors.lightTextTertiary,
    letterSpacing: 0,
  );

  /// 等宽字体（代码）
  static TextStyle lightMonospace = TextStyle(
    fontFamily: monospaceFontFamily,
    fontSize: AppFontSizes.body,
    fontWeight: AppFontWeights.regular,
    height: 1.5,
    color: AppColors.lightTextPrimary,
    letterSpacing: 0,
  );

  // ==================== 深色模式文本样式 ====================

  /// 大标题 1 - 34pt
  static TextStyle darkTitle1 = lightTitle1.copyWith(
    color: AppColors.darkTextPrimary,
  );

  /// 大标题 2 - 28pt
  static TextStyle darkTitle2 = lightTitle2.copyWith(
    color: AppColors.darkTextPrimary,
  );

  /// 大标题 3 - 24pt
  static TextStyle darkTitle3 = lightTitle3.copyWith(
    color: AppColors.darkTextPrimary,
  );

  /// 标题 - 20pt
  static TextStyle darkHeadline = lightHeadline.copyWith(
    color: AppColors.darkTextPrimary,
  );

  /// 副标题 - 17pt
  static TextStyle darkSubheadline = lightSubheadline.copyWith(
    color: AppColors.darkTextPrimary,
  );

  /// 强调文本 - 15pt
  static TextStyle darkCallout = lightCallout.copyWith(
    color: AppColors.darkTextPrimary,
  );

  /// 正文 - 13pt
  static TextStyle darkBody = lightBody.copyWith(
    color: AppColors.darkTextPrimary,
  );

  /// 正文（加粗）
  static TextStyle darkBodyBold = lightBodyBold.copyWith(
    color: AppColors.darkTextPrimary,
  );

  /// 脚注 - 11pt
  static TextStyle darkFootnote = lightFootnote.copyWith(
    color: AppColors.darkTextSecondary,
  );

  /// 说明文字 - 10pt
  static TextStyle darkCaption = lightCaption.copyWith(
    color: AppColors.darkTextTertiary,
  );

  /// 等宽字体（代码）
  static TextStyle darkMonospace = lightMonospace.copyWith(
    color: AppColors.darkTextPrimary,
  );

  // ==================== 特殊样式 ====================

  /// 链接样式
  static TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.body,
    fontWeight: AppFontWeights.regular,
    height: 1.45,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    letterSpacing: 0,
  );

  /// 按钮文本
  static TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.callout,
    fontWeight: AppFontWeights.semiBold,
    height: 1.2,
    letterSpacing: 0.2,
  );

  /// 数字（表格数字）
  static TextStyle tabularNumbers = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.body,
    fontWeight: AppFontWeights.regular,
    height: 1.45,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // ==================== 工具方法 ====================

  /// 根据主题模式获取对应的文本主题
  static TextTheme getTextTheme(bool isDark) {
    return TextTheme(
      displayLarge: isDark ? darkTitle1 : lightTitle1,
      displayMedium: isDark ? darkTitle2 : lightTitle2,
      displaySmall: isDark ? darkTitle3 : lightTitle3,
      headlineMedium: isDark ? darkHeadline : lightHeadline,
      headlineSmall: isDark ? darkSubheadline : lightSubheadline,
      titleLarge: isDark ? darkTitle3 : lightTitle3,
      titleMedium: isDark ? darkHeadline : lightHeadline,
      titleSmall: isDark ? darkCallout : lightCallout,
      bodyLarge: isDark ? darkBody : lightBody,
      bodyMedium: isDark ? darkBody : lightBody,
      bodySmall: isDark ? darkFootnote : lightFootnote,
      labelLarge: isDark ? darkCallout : lightCallout,
      labelMedium: button,
      labelSmall: isDark ? darkCaption : lightCaption,
    );
  }

  /// 创建自定义文本样式
  static TextStyle custom({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight ?? AppFontWeights.regular,
      color: color ??
          (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      height: height ?? 1.4,
      letterSpacing: letterSpacing ?? 0,
    );
  }
}

/// 文本样式扩展方法
extension TextStyleExtensions on TextStyle {
  /// 设置为粗体
  TextStyle get bold => copyWith(fontWeight: AppFontWeights.bold);

  /// 设置为半粗体
  TextStyle get semiBold => copyWith(fontWeight: AppFontWeights.semiBold);

  /// 设置为中等粗细
  TextStyle get medium => copyWith(fontWeight: AppFontWeights.medium);

  /// 设置为常规粗细
  TextStyle get regular => copyWith(fontWeight: AppFontWeights.regular);

  /// 设置为细体
  TextStyle get light => copyWith(fontWeight: AppFontWeights.light);

  /// 设置主色
  TextStyle get primary => copyWith(color: AppColors.primary);

  /// 设置次要文本色
  TextStyle get secondary => copyWith(color: AppColors.lightTextSecondary);

  /// 设置三级文本色
  TextStyle get tertiary => copyWith(color: AppColors.lightTextTertiary);

  /// 设置成功色
  TextStyle get success => copyWith(color: AppColors.success);

  /// 设置警告色
  TextStyle get warning => copyWith(color: AppColors.warning);

  /// 设置错误色
  TextStyle get error => copyWith(color: AppColors.error);

  /// 添加下划线
  TextStyle get underline => copyWith(decoration: TextDecoration.underline);

  /// 添加删除线
  TextStyle get lineThrough => copyWith(decoration: TextDecoration.lineThrough);

  /// 设置斜体
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);

  /// 设置透明度
  TextStyle withOpacity(double opacity) => copyWith(
        color: color?.withValues(alpha: opacity),
      );
}
