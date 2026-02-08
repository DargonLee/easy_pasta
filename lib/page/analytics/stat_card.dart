import 'package:flutter/material.dart';
import 'package:easy_pasta/page/analytics/analytics_styles.dart';

class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final String change;
  final bool? isPositive;
  final int delay;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.change,
    this.isPositive,
    this.delay = 0,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
            decoration: BoxDecoration(
              color: AnalyticsColors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? AnalyticsColors.accentCyan
                    : AnalyticsColors.borderColor,
                width: 1,
              ),
              boxShadow: _isHovered
                  ? [
                      const BoxShadow(
                        color: AnalyticsColors.glowCyan,
                        blurRadius: 40,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Top accent line
                if (_isHovered)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AnalyticsColors.accentCyan,
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),

                // Content
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 110;
                    final double verticalPadding = isCompact ? 12 : 16;
                    final double valueSize = isCompact ? 24 : 28;
                    final double labelSize = isCompact ? 10 : 11;
                    final double changeSize = isCompact ? 11 : 12;
                    final double iconSize = isCompact ? 12 : 14;
                    final double gapLarge = isCompact ? 6 : 8;
                    final double gapSmall = isCompact ? 3 : 4;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: verticalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: labelSize,
                              color: AnalyticsColors.textSecondary,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: gapLarge),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                AnalyticsColors.textPrimary,
                                AnalyticsColors.accentCyan,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              widget.value,
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: valueSize,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: gapSmall),
                          Row(
                            children: [
                              if (widget.isPositive != null)
                                Text(
                                  widget.isPositive! ? '↗' : '↘',
                                  style: TextStyle(
                                    color: widget.isPositive!
                                        ? AnalyticsColors.accentGreen
                                        : AnalyticsColors.accentPink,
                                    fontSize: iconSize,
                                  ),
                                ),
                              if (widget.isPositive != null)
                                const SizedBox(width: 6),
                              Text(
                                widget.change,
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: changeSize,
                                  color: widget.isPositive == null
                                      ? AnalyticsColors.textMuted
                                      : (widget.isPositive!
                                          ? AnalyticsColors.accentGreen
                                          : AnalyticsColors.accentPink),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
