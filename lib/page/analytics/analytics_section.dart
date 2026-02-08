import 'package:flutter/material.dart';
import 'package:easy_pasta/page/analytics/analytics_styles.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AnalyticsColors.accentCyan,
                AnalyticsColors.accentPurple
              ],
            ),
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AnalyticsColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class ChartContainer extends StatelessWidget {
  final Widget child;

  const ChartContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AnalyticsColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AnalyticsColors.borderColor),
      ),
      child: Stack(
        children: [
          // Background glow
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AnalyticsColors.glowPurple,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          child,
        ],
      ),
    );
  }
}
