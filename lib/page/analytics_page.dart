import 'package:flutter/material.dart';
import 'package:easy_pasta/model/clipboard_analytics.dart';
import 'package:easy_pasta/service/analytics_service.dart';
import 'package:easy_pasta/widget/chart_widgets.dart';
import 'package:easy_pasta/widget/heatmap_widget.dart';
import 'package:easy_pasta/widget/insights_widgets.dart';

/// 剪贴板分析主页面
///
/// 设计风格：深色科技感，与 Web 界面保持一致
/// - 深色背景 + 赛博朋克配色
/// - 动画效果和光晕
/// - 数据可视化组件
class ClipboardAnalyticsPage extends StatefulWidget {
  const ClipboardAnalyticsPage({super.key});

  @override
  State<ClipboardAnalyticsPage> createState() => _ClipboardAnalyticsPageState();
}

class _ClipboardAnalyticsPageState extends State<ClipboardAnalyticsPage>
    with TickerProviderStateMixin {
  TimePeriod _selectedPeriod = TimePeriod.week;
  late AnimationController _glowController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    // 光晕脉动动画
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // 淡入动画
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildDarkTheme(),
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Stack(
          children: [
            // 背景网格和光晕效果
            const AnimatedBackground(),

            // 主内容
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Header
                  _buildHeader(),

                  // Stats Grid
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: _buildStatsGrid(),
                  ),

                  // Divider
                  const SliverToBoxAdapter(child: DataFlowLine()),

                  // Heatmap Section
                  SliverToBoxAdapter(
                    child: _buildSection(
                      title: '复制活动热力图',
                      child: const HeatmapWidget(),
                    ),
                  ),

                  // Charts Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSection(
                              title: '内容类型分布',
                              child: const PurposeChartWidget(),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildSection(
                              title: '每日复制趋势',
                              child: const TrendChartWidget(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: DataFlowLine()),

                  // App Flow Section
                  SliverToBoxAdapter(
                    child: _buildSection(
                      title: '应用间流转关系',
                      child: const AppFlowWidget(),
                    ),
                  ),

                  const SliverToBoxAdapter(child: DataFlowLine()),

                  // Duplicates Section
                  SliverToBoxAdapter(
                    child: _buildSection(
                      title: '重复内容检测',
                      child: const DuplicateListWidget(),
                    ),
                  ),

                  const SliverToBoxAdapter(child: DataFlowLine()),

                  // Insights Section
                  SliverToBoxAdapter(
                    child: _buildSection(
                      title: '智能洞察',
                      child: const InsightsWidget(),
                    ),
                  ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button and Title row
            Row(
              children: [
                // Back button
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.accentCyan,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Title with gradient
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.accentCyan, AppColors.accentPurple],
                      ).createShader(bounds),
                      child: const Text(
                        'CLIPBOARD ANALYTICS',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Subtitle
            FadeTransition(
              opacity: _fadeController,
              child: const Text(
                '剪贴板数据分析中心',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  letterSpacing: 3,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Time Selector
            _buildTimeSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeButton('今日', TimePeriod.day),
          _buildTimeButton('本周', TimePeriod.week),
          _buildTimeButton('本月', TimePeriod.month),
        ],
      ),
    );
  }

  Widget _buildTimeButton(String label, TimePeriod period) {
    final isSelected = _selectedPeriod == period;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedPeriod = period),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [AppColors.accentCyan, AppColors.accentPurple],
                    )
                  : null,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.accentCyan.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.8,
        mainAxisSpacing: 10,
      ),
      delegate: SliverChildListDelegate([
        FutureBuilder<int>(
          future: _getTotalCopies(),
          builder: (context, snapshot) => StatCard(
            label: '总复制次数',
            value: snapshot.data?.toString() ?? '0',
            change: '+23% vs 上周',
            isPositive: true,
            delay: 100,
          ),
        ),
        FutureBuilder<double>(
          future: _getProductivityScore(),
          builder: (context, snapshot) => StatCard(
            label: '效率评分',
            value: snapshot.data?.toStringAsFixed(0) ?? '0',
            change: '+5分',
            isPositive: true,
            delay: 200,
          ),
        ),
        FutureBuilder<int>(
          future: _getActiveApps(),
          builder: (context, snapshot) => StatCard(
            label: '活跃应用',
            value: snapshot.data?.toString() ?? '0',
            change: '-2 vs 上周',
            isPositive: false,
            delay: 300,
          ),
        ),
        FutureBuilder<int>(
          future: _getDuplicateCount(),
          builder: (context, snapshot) => StatCard(
            label: '重复内容',
            value: snapshot.data?.toString() ?? '0',
            change: '可优化',
            isPositive: null,
            delay: 400,
          ),
        ),
      ]),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title),
          const SizedBox(height: 24),
          _ChartContainer(child: child),
        ],
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.bgPrimary,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  // Mock data methods
  Future<int> _getTotalCopies() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 1247;
  }

  Future<double> _getProductivityScore() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 87;
  }

  Future<int> _getActiveApps() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 12;
  }

  Future<int> _getDuplicateCount() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 34;
  }
}

// ==================== 颜色主题 ====================

class AppColors {
  static const bgPrimary = Color(0xFF0A0E14);
  static const bgSecondary = Color(0xFF121820);
  static const bgTertiary = Color(0xFF1A1F2E);

  static const accentCyan = Color(0xFF00D9FF);
  static const accentPurple = Color(0xFFA855F7);
  static const accentPink = Color(0xFFEC4899);
  static const accentGreen = Color(0xFF10B981);
  static const accentOrange = Color(0xFFF59E0B);

  static const textPrimary = Color(0xFFE0E7FF);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  static const borderColor = Color(0x1A94A3B8);
  static const glowCyan = Color(0x4D00D9FF);
  static const glowPurple = Color(0x4DA855F7);
}

// ==================== 背景动画 ====================

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grid pattern
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            painter: GridPainter(opacity: 0.3 + (_controller.value * 0.3)),
            size: Size.infinite,
          ),
        ),

        // Floating orbs
        const Positioned(
          top: -100,
          left: -100,
          child: _GlowOrb(
            color: AppColors.accentCyan,
            size: 400,
            delay: 0,
          ),
        ),
        const Positioned(
          bottom: -150,
          right: -150,
          child: _GlowOrb(
            color: AppColors.accentPurple,
            size: 500,
            delay: 5,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          right: MediaQuery.of(context).size.width * 0.1,
          child: const _GlowOrb(
            color: AppColors.accentPink,
            size: 300,
            delay: 10,
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  final double opacity;

  GridPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentCyan.withOpacity(opacity * 0.03)
      ..strokeWidth = 1;

    const spacing = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => opacity != oldDelegate.opacity;
}

class _GlowOrb extends StatefulWidget {
  final Color color;
  final double size;
  final int delay;

  const _GlowOrb({
    required this.color,
    required this.size,
    required this.delay,
  });

  @override
  State<_GlowOrb> createState() => _GlowOrbState();
}

class _GlowOrbState extends State<_GlowOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _animation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(30, -30)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(30, -30), end: const Offset(-20, 20)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-20, 20), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(_controller);

    Future.delayed(Duration(seconds: widget.delay), () {
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.translate(
        offset: _animation.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withOpacity(0.15),
                widget.color.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== 统计卡片 ====================

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
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _isHovered ? AppColors.accentCyan : AppColors.borderColor,
                width: 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AppColors.glowCyan,
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
                            AppColors.accentCyan,
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
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            AppColors.textPrimary,
                            AppColors.accentCyan,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          widget.value,
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (widget.isPositive != null)
                            Text(
                              widget.isPositive! ? '↗' : '↘',
                              style: TextStyle(
                                color: widget.isPositive!
                                    ? AppColors.accentGreen
                                    : AppColors.accentPink,
                                fontSize: 14,
                              ),
                            ),
                          if (widget.isPositive != null)
                            const SizedBox(width: 6),
                          Text(
                            widget.change,
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 12,
                              color: widget.isPositive == null
                                  ? AppColors.textMuted
                                  : (widget.isPositive!
                                      ? AppColors.accentGreen
                                      : AppColors.accentPink),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== 分割线 ====================

class DataFlowLine extends StatefulWidget {
  const DataFlowLine({super.key});

  @override
  State<DataFlowLine> createState() => _DataFlowLineState();
}

class _DataFlowLineState extends State<DataFlowLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: FlowLinePainter(progress: _controller.value),
        ),
      ),
    );
  }
}

class FlowLinePainter extends CustomPainter {
  final double progress;

  FlowLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: const [
          Colors.transparent,
          AppColors.accentCyan,
          AppColors.accentPurple,
          Colors.transparent,
        ],
        stops: [
          (progress - 0.3).clamp(0, 1),
          progress.clamp(0, 1),
          (progress + 0.1).clamp(0, 1),
          (progress + 0.3).clamp(0, 1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(FlowLinePainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// ==================== Section Title ====================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

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
              colors: [AppColors.accentCyan, AppColors.accentPurple],
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
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ==================== Chart Container ====================

class _ChartContainer extends StatelessWidget {
  final Widget child;

  const _ChartContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
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
                    AppColors.glowPurple,
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
