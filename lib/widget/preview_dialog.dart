import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';
import 'package:easy_pasta/model/clipboard_type.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/core/content_processor.dart';

class PreviewDialog extends StatelessWidget {
  final ClipboardItemModel model;

  const PreviewDialog({
    super.key,
    required this.model,
  });

  static Future<void> show(BuildContext context, ClipboardItemModel model) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Preview',
      barrierColor: Colors.black54,
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, animation, secondaryAnimation) {
        return PreviewDialog(model: model);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // 缩放 + 淡入动画
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: AppCurves.standard,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    // 根据类型确定对话框大小
    final dialogWidth = model.ptype == ClipboardType.image 
        ? screenSize.width * 0.8 
        : screenSize.width * 0.65;
    final dialogHeight = model.ptype == ClipboardType.image 
        ? screenSize.height * 0.8 
        : screenSize.height * 0.7;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth.clamp(400.0, 1000.0),
          height: dialogHeight.clamp(300.0, 800.0),
          margin: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
            boxShadow: AppShadows.xl,
          ),
          // 毛玻璃效果
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppColors.darkCardBackground.withOpacity(0.85)
                      : AppColors.lightCardBackground.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(AppRadius.dialog),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(context, isDark),
                    Expanded(
                      child: _buildContentArea(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? AppColors.darkDivider.withOpacity(0.5)
                : AppColors.lightDivider.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 类型图标
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              _getTypeIcon(),
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          
          // 标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '预览',
                  style: (isDark 
                      ? AppTypography.darkHeadline 
                      : AppTypography.lightHeadline
                  ).copyWith(
                    fontSize: AppFontSizes.lg,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  _getTypeLabel(),
                  style: isDark 
                      ? AppTypography.darkCaption 
                      : AppTypography.lightCaption,
                ),
              ],
            ),
          ),
          
          // 关闭按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContentArea(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: _buildContent(context, isDark),
      ),
    );
  }

  /// 构建内容根据剪贴板类型动态渲染
  Widget _buildContent(BuildContext context, bool isDark) {
    switch (model.ptype) {
      case ClipboardType.image:
        return _buildImageContent();
      
      case ClipboardType.html:
        return _buildHtmlContent(isDark);
      
      case ClipboardType.file:
        return _buildFileContent(isDark);
      
      case ClipboardType.text:
      default:
        return _buildTextContent(isDark);
    }
  }

  /// 构建图片内容
  Widget _buildImageContent() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Image.memory(
          model.imageBytes!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: AppColors.error.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '图片加载失败',
                    style: AppTypography.lightBody.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建 HTML 内容
  Widget _buildHtmlContent(bool isDark) {
    // 从 HTML 中提取纯文本
    final htmlString = model.bytesToString(model.bytes ?? Uint8List(0));
    final plainText = ContentProcessor.extractTextFromHtml(htmlString);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.darkSecondaryBackground.withOpacity(0.3)
            : AppColors.lightSecondaryBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SelectableText(
        plainText.isEmpty ? 'HTML 内容' : plainText,
        style: (isDark 
            ? AppTypography.darkBody 
            : AppTypography.lightBody
        ).copyWith(
          height: 1.6,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// 构建文件内容
  Widget _buildFileContent(bool isDark) {
    final fileUri = model.bytesToString(model.bytes ?? Uint8List(0));
    final fileList = ContentProcessor.extractFileList(fileUri);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文件数量标签
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.darkSecondaryBackground 
                  : AppColors.lightSecondaryBackground,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              fileList.length == 1 ? '1 个项目' : '${fileList.length} 个项目',
              style: (isDark 
                  ? AppTypography.darkCaption 
                  : AppTypography.lightCaption
              ).copyWith(
                fontWeight: AppFontWeights.semiBold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 文件列表
          ...fileList.map((filePath) {
            final fileName = ContentProcessor.extractFileName(filePath);
            final isDir = ContentProcessor.isDirectory(filePath);
            final extension = ContentProcessor.getFileExtension(filePath);
            
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.darkSecondaryBackground.withOpacity(0.3)
                    : AppColors.lightSecondaryBackground.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  // 文件图标
                  Icon(
                    isDir ? Icons.folder_rounded : _getFileIcon(extension),
                    size: 32,
                    color: isDir 
                        ? Colors.blue[600] 
                        : _getFileColor(extension),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // 文件信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: (isDark 
                              ? AppTypography.darkBody 
                              : AppTypography.lightBody
                          ).copyWith(
                            fontWeight: AppFontWeights.medium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          isDir ? '文件夹' : (extension.isEmpty ? '文件' : extension.toUpperCase()),
                          style: isDark 
                              ? AppTypography.darkCaption 
                              : AppTypography.lightCaption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 构建文本内容
  Widget _buildTextContent(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.darkSecondaryBackground.withOpacity(0.3)
            : AppColors.lightSecondaryBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SelectableText(
        model.pvalue,
        style: (isDark 
            ? AppTypography.darkBody 
            : AppTypography.lightBody
        ).copyWith(
          height: 1.6,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// 获取类型图标
  IconData _getTypeIcon() {
    switch (model.ptype) {
      case ClipboardType.image:
        return Icons.image_outlined;
      case ClipboardType.file:
        return Icons.insert_drive_file_outlined;
      case ClipboardType.html:
        return Icons.code;
      case ClipboardType.text:
      default:
        return Icons.text_fields;
    }
  }

  /// 获取类型标签
  String _getTypeLabel() {
    switch (model.ptype) {
      case ClipboardType.image:
        return '图片';
      case ClipboardType.file:
        return '文件';
      case ClipboardType.html:
        return 'HTML';
      case ClipboardType.text:
      default:
        return '文本';
    }
  }
  
  /// 获取文件图标
  IconData _getFileIcon(String extension) {
    const iconMap = {
      // 文档
      'pdf': Icons.picture_as_pdf,
      'doc': Icons.description,
      'docx': Icons.description,
      'txt': Icons.article,
      // 表格
      'xls': Icons.table_chart,
      'xlsx': Icons.table_chart,
      'csv': Icons.table_chart,
      // 图片
      'jpg': Icons.image,
      'jpeg': Icons.image,
      'png': Icons.image,
      'gif': Icons.gif,
      'svg': Icons.image,
      // 音频
      'mp3': Icons.audio_file,
      'wav': Icons.audio_file,
      'm4a': Icons.audio_file,
      // 视频
      'mp4': Icons.video_file,
      'mov': Icons.video_file,
      'avi': Icons.video_file,
      // 压缩包
      'zip': Icons.folder_zip,
      'rar': Icons.folder_zip,
      '7z': Icons.folder_zip,
      // 代码
      'js': Icons.code,
      'py': Icons.code,
      'java': Icons.code,
      'dart': Icons.code,
    };
    return iconMap[extension] ?? Icons.insert_drive_file_rounded;
  }
  
  /// 获取文件颜色
  Color _getFileColor(String extension) {
    const colorMap = {
      'pdf': Colors.red,
      'doc': Colors.blue,
      'docx': Colors.blue,
      'xls': Colors.green,
      'xlsx': Colors.green,
      'jpg': Colors.purple,
      'jpeg': Colors.purple,
      'png': Colors.purple,
      'mp3': Colors.orange,
      'wav': Colors.orange,
      'mp4': Colors.red,
      'mov': Colors.red,
      'zip': Colors.brown,
      'rar': Colors.brown,
    };
    return colorMap[extension]?[600] ?? Colors.grey[600]!;
  }
}
