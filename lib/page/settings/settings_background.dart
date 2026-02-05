import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';

class SettingsBackground extends StatelessWidget {
  const SettingsBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.darkPaperBackground
              : AppGradients.lightPaperBackground,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -140,
              left: -80,
              child: SettingsGlow(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.08),
                radius: 220,
              ),
            ),
            Positioned(
              bottom: -160,
              right: -90,
              child: SettingsGlow(
                color: isDark
                    ? AppColors.primaryLight.withValues(alpha: 0.08)
                    : AppColors.primaryLight.withValues(alpha: 0.12),
                radius: 260,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsGlow extends StatelessWidget {
  final Color color;
  final double radius;

  const SettingsGlow({
    super.key,
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
