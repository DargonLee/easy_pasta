import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/model/pboard_sort_type.dart';
import 'package:easy_pasta/core/animation_helper.dart';

/// 分类空状态组件
/// 为不同的剪贴板类型提供专属的空状态展示
class CategoryEmptyState extends StatefulWidget {
  final NSPboardSortType category;

  const CategoryEmptyState({
    super.key,
    required this.category,
  });

  @override
  State<CategoryEmptyState> createState() => _CategoryEmptyStateState();
}

class _CategoryEmptyStateState extends State<CategoryEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 延迟启动动画，让切换更自然
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _getEmptyConfig();

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 标题
                Text(
                  config.title,
                  style: (isDark
                          ? AppTypography.darkTitle3
                          : AppTypography.lightTitle3)
                      .copyWith(
                    fontWeight: AppFontWeights.semiBold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.md),

                // 描述
                Text(
                  config.description,
                  style: (isDark
                          ? AppTypography.darkBody
                          : AppTypography.lightBody)
                      .copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxl),

                // 提示卡片
                _buildTipsCard(config, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建提示卡片
  Widget _buildTipsCard(_EmptyConfig config, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: config.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 标题行
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                size: 18,
                color: config.color,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '使用提示',
                style: (isDark
                        ? AppTypography.darkFootnote
                        : AppTypography.lightFootnote)
                    .copyWith(
                  fontWeight: AppFontWeights.semiBold,
                  color: config.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 提示列表
          ...config.tips.map((tip) => _buildTipItem(tip, isDark)),
        ],
      ),
    );
  }

  /// 构建提示项
  Widget _buildTipItem(String tip, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              tip,
              style: (isDark
                      ? AppTypography.darkFootnote
                      : AppTypography.lightFootnote)
                  .copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取空状态配置
  _EmptyConfig _getEmptyConfig() {
    switch (widget.category) {
      case NSPboardSortType.all:
        return _EmptyConfig(
          icon: Icons.content_paste_rounded,
          color: AppColors.primary,
          title: '开始使用 EasyPasta',
          description: '你的剪贴板历史将在这里呈现',
          tips: [
            '使用 Cmd+C 复制任何内容，自动保存',
            '支持文本、图片、文件等多种格式',
            '使用 Cmd+Shift+V 快速唤起面板',
            '双击卡片或点击复制按钮即可使用',
          ],
          decorations: [
            Colors.blue,
            Colors.green,
            Colors.orange,
            Colors.purple,
          ],
        );

      case NSPboardSortType.text:
        return _EmptyConfig(
          icon: Icons.text_fields_rounded,
          color: Colors.blue,
          title: '暂无文本内容',
          description: '复制文字后将自动显示在这里',
          tips: [
            '选中文本后按 Cmd+C 复制',
            '支持纯文本、富文本和 Markdown',
            '自动提取网页中的文字内容',
            '代码片段也会被完美保存',
          ],
          decorations: [
            Colors.blue,
            Colors.lightBlue,
            Colors.cyan,
          ],
        );

      case NSPboardSortType.image:
        return _EmptyConfig(
          icon: Icons.image_rounded,
          color: Colors.purple,
          title: '暂无图片内容',
          description: '复制图片后将自动显示在这里',
          tips: [
            '右键图片选择“复制图片”',
            '支持 PNG、JPG、GIF、WebP 等格式',
            '截图内容会自动保存',
            '双击卡片可查看大图',
          ],
          decorations: [
            Colors.purple,
            Colors.deepPurple,
            Colors.pink,
          ],
        );

      case NSPboardSortType.file:
        return _EmptyConfig(
          icon: Icons.folder_rounded,
          color: Colors.orange,
          title: '暂无文件内容',
          description: '复制文件或文件夹后将显示在这里',
          tips: [
            '在访达中选中文件按 Cmd+C 复制',
            '支持单个文件和多个文件',
            '文件夹也会被记录',
            '文件路径中的中文完美支持',
          ],
          decorations: [
            Colors.orange,
            Colors.deepOrange,
            Colors.amber,
          ],
        );

      case NSPboardSortType.favorite:
        return _EmptyConfig(
          icon: Icons.star_rounded,
          color: Colors.amber,
          title: '暂无收藏内容',
          description: '点击卡片上的星标图标即可收藏',
          tips: [
            '将常用内容添加到收藏',
            '收藏的内容不会被自动清理',
            '方便快速找到重要内容',
            '再次点击星标可取消收藏',
          ],
          decorations: [
            Colors.amber,
            Colors.yellow,
            Colors.orange,
          ],
        );

      default:
        return _EmptyConfig(
          icon: Icons.content_paste_rounded,
          color: AppColors.primary,
          title: '暂无内容',
          description: '开始复制内容吧',
          tips: ['使用 Cmd+C 复制内容'],
          decorations: [AppColors.primary],
        );
    }
  }
}

/// 空状态配置
class _EmptyConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final List<String> tips;
  final List<Color> decorations;

  _EmptyConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.tips,
    required this.decorations,
  });
}
