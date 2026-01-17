import 'package:flutter/material.dart';

/// 设计令牌系统 - 定义整个应用的设计基础
/// 参考 Apple Human Interface Guidelines

/// 颜色系统
class AppColors {
  AppColors._();

  // ==================== 品牌色 ====================
  /// 主品牌色 - 苹果系统蓝
  static const Color primary = Color(0xFF007AFF);
  static const Color primaryLight = Color(0xFF5AC8FA);
  static const Color primaryDark = Color(0xFF0051D5);

  /// 辅助色系
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF5AC8FA);

  // ==================== 中性色 - 浅色模式 ====================
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSecondaryBackground = Color(0xFFF5F5F7);
  static const Color lightTertiaryBackground = Color(0xFFEFEFF4);
  
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF5F5F7);
  static const Color lightCardSelected = Color(0xFFE3F2FD);
  
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  static const Color lightTextTertiary = Color(0xFFC7C7CC);
  
  static const Color lightDivider = Color(0xFFE5E5EA);
  static const Color lightBorder = Color(0xFFD1D1D6);

  // ==================== 中性色 - 深色模式 ====================
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSecondaryBackground = Color(0xFF1C1C1E);
  static const Color darkTertiaryBackground = Color(0xFF2C2C2E);
  
  static const Color darkCardBackground = Color(0xFF1C1C1E);
  static const Color darkCardHover = Color(0xFF2C2C2E);
  static const Color darkCardSelected = Color(0xFF1E3A5F);
  
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkTextTertiary = Color(0xFF48484A);
  
  static const Color darkDivider = Color(0xFF38383A);
  static const Color darkBorder = Color(0xFF48484A);

  // ==================== 语义色 - 浅色模式 ====================
  static const Color lightSuccessBackground = Color(0xFFE8F5E9);
  static const Color lightWarningBackground = Color(0xFFFFF3E0);
  static const Color lightErrorBackground = Color(0xFFFFEBEE);
  static const Color lightInfoBackground = Color(0xFFE3F2FD);

  // ==================== 语义色 - 深色模式 ====================
  static const Color darkSuccessBackground = Color(0xFF1B5E20);
  static const Color darkWarningBackground = Color(0xFFE65100);
  static const Color darkErrorBackground = Color(0xFFB71C1C);
  static const Color darkInfoBackground = Color(0xFF01579B);

  // ==================== 特殊色 ====================
  static const Color overlay = Color(0x66000000);
  static const Color shimmer = Color(0xFFE0E0E0);
  static const Color favorite = Color(0xFFFFCC00);
}

/// 间距系统 - 基于 4px 网格
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  /// 卡片内边距
  static const double cardPadding = 12.0;
  static const double cardPaddingLarge = 16.0;

  /// 列表间距
  static const double listItemSpacing = 8.0;
  static const double listSectionSpacing = 24.0;

  /// 网格间距
  static const double gridSpacing = 8.0;
  static const double gridPadding = 16.0;
}

/// 圆角系统
class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 20.0;
  static const double full = 999.0;

  /// 常用圆角
  static const double button = 8.0;
  static const double card = 12.0;
  static const double dialog = 16.0;
  static const double image = 8.0;
}

/// 阴影系统
class AppShadows {
  AppShadows._();

  /// 无阴影
  static const List<BoxShadow> none = [];

  /// 轻微阴影 - 用于卡片默认状态
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  /// 中等阴影 - 用于悬浮状态
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  /// 较大阴影 - 用于弹窗
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  /// 超大阴影 - 用于模态对话框
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x29000000),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  /// 深色模式阴影 - 更明显的高光
  static const List<BoxShadow> darkSm = [
    BoxShadow(
      color: Color(0x14FFFFFF),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
}

/// 动画时长系统
class AppDurations {
  AppDurations._();

  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration slower = Duration(milliseconds: 500);

  /// 特定场景动画时长
  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration cardHover = Duration(milliseconds: 200);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration dialogOpen = Duration(milliseconds: 250);
}

/// 动画曲线系统
class AppCurves {
  AppCurves._();

  /// Apple 标准曲线
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;

  /// 弹性曲线
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
}

/// 字体大小系统
class AppFontSizes {
  AppFontSizes._();

  static const double xs = 10.0;
  static const double sm = 11.0;
  static const double base = 13.0;
  static const double md = 15.0;
  static const double lg = 17.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 28.0;
  static const double huge = 34.0;

  /// 语义化字号
  static const double caption = 10.0;
  static const double footnote = 11.0;
  static const double body = 13.0;
  static const double callout = 15.0;
  static const double subheadline = 17.0;
  static const double headline = 20.0;
  static const double title3 = 24.0;
  static const double title2 = 28.0;
  static const double title1 = 34.0;
}

/// 字重系统
class AppFontWeights {
  AppFontWeights._();

  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

/// 断点系统 - 响应式设计
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 640.0;
  static const double tablet = 768.0;
  static const double desktop = 1024.0;
  static const double wide = 1280.0;
}

/// Z-index 层级系统
class AppZIndex {
  AppZIndex._();

  static const int base = 0;
  static const int dropdown = 1000;
  static const int sticky = 1020;
  static const int fixed = 1030;
  static const int modalBackdrop = 1040;
  static const int modal = 1050;
  static const int popover = 1060;
  static const int tooltip = 1070;
}

/// 透明度系统
class AppOpacity {
  AppOpacity._();

  static const double invisible = 0.0;
  static const double disabled = 0.38;
  static const double hint = 0.6;
  static const double secondary = 0.74;
  static const double primary = 0.87;
  static const double full = 1.0;
}
