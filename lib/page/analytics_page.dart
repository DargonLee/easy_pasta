import 'package:flutter/material.dart';
import 'package:easy_pasta/model/clipboard_analytics.dart';
import 'package:easy_pasta/service/analytics_service.dart';
import 'package:easy_pasta/page/analytics/analytics_background.dart';
import 'package:easy_pasta/page/analytics/analytics_flow_line.dart';
import 'package:easy_pasta/page/analytics/analytics_section.dart';
import 'package:easy_pasta/page/analytics/analytics_styles.dart';
import 'package:easy_pasta/page/analytics/stat_card.dart';
import 'package:easy_pasta/widget/chart_widgets.dart' hide AppColors;
import 'package:easy_pasta/widget/heatmap_widget.dart' hide AppColors;
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
                      child: DuplicateListWidget(period: _selectedPeriod),
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
            value: snapshot.data?.toString() ?? '-',
            change: '本期统计',
            isPositive: null,
            delay: 100,
          ),
        ),
        FutureBuilder<double>(
          future: _getProductivityScore(),
          builder: (context, snapshot) => StatCard(
            label: '效率评分',
            value: snapshot.data?.toStringAsFixed(0) ?? '-',
            change: '满分100',
            isPositive: null,
            delay: 200,
          ),
        ),
        FutureBuilder<int>(
          future: _getActiveApps(),
          builder: (context, snapshot) => StatCard(
            label: '活跃应用',
            value: snapshot.data?.toString() ?? '-',
            change: '应用数量',
            isPositive: null,
            delay: 300,
          ),
        ),
        FutureBuilder<int>(
          future: _getDuplicateCount(),
          builder: (context, snapshot) => StatCard(
            label: '重复内容',
            value: snapshot.data?.toString() ?? '-',
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
          SectionTitle(title: title),
          const SizedBox(height: 24),
          ChartContainer(child: child),
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

  // Real database queries
  Future<int> _getTotalCopies() async {
    return await ClipboardAnalyticsService.instance.getTotalCopies(
      period: _selectedPeriod,
    );
  }

  Future<double> _getProductivityScore() async {
    return await ClipboardAnalyticsService.instance.getProductivityScore(
      period: _selectedPeriod,
    );
  }

  Future<int> _getActiveApps() async {
    return await ClipboardAnalyticsService.instance.getActiveApps(
      period: _selectedPeriod,
    );
  }

  Future<int> _getDuplicateCount() async {
    return await ClipboardAnalyticsService.instance.getDuplicateCount(
      period: _selectedPeriod,
    );
  }
}
