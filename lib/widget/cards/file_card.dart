import 'package:flutter/material.dart';
import 'package:easy_pasta/core/content_processor.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';

/// A widget that displays a file icon and name in a vertical layout
/// Supports single file, multiple files, and directory display
class FileContent extends StatelessWidget {
  final String fileName;
  final String fileUri;

  // Constants for styling
  static const double _iconSize = 56.0;
  static const double _fontSize = 13.0;
  static const int _maxFilesToShow = 3; // 最多显示3个文件

  const FileContent({
    super.key,
    required this.fileName,
    required this.fileUri,
  });
  
  /// 获取文件列表
  List<String> get _fileList => ContentProcessor.extractFileList(fileUri);

  @override
  Widget build(BuildContext context) {
    // 检查是否为多文件
    if (_fileList.length > 1) {
      return _buildMultipleFiles(context);
    }
    
    // 单文件显示
    return _buildSingleFile(context);
  }
  
  /// 构建单文件显示
  Widget _buildSingleFile(BuildContext context) {
    final decodedPath = ContentProcessor.decodeFilePath(fileUri);
    final displayName = ContentProcessor.extractFileName(decodedPath);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIcon(decodedPath),
        const SizedBox(height: AppSpacing.sm),
        _buildFileName(displayName, context),
      ],
    );
  }
  
  /// 构建多文件显示
  Widget _buildMultipleFiles(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final files = _fileList;
    final displayFiles = files.take(_maxFilesToShow).toList();
    final remainingCount = files.length - displayFiles.length;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 文件堆叠图标效果
        Stack(
          alignment: Alignment.center,
          children: [
            // 背景层（右下）
            Transform.translate(
              offset: const Offset(8, 8),
              child: _buildFileIconWithBackground(
                files[0], 
                opacity: 0.3,
              ),
            ),
            // 中间层（右上）
            if (files.length > 1)
              Transform.translate(
                offset: const Offset(4, -4),
                child: _buildFileIconWithBackground(
                  files[1], 
                  opacity: 0.5,
                ),
              ),
            // 前景层（中心）
            _buildFileIconWithBackground(files[0]),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
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
            '${files.length} 个项目',
            style: (isDark 
                ? AppTypography.darkCaption 
                : AppTypography.lightCaption
            ).copyWith(
              fontWeight: AppFontWeights.semiBold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // 文件列表预览
        ...displayFiles.map((file) {
          final name = ContentProcessor.extractFileName(file);
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xxs,
              horizontal: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getFileIconForPath(file),
                  size: 14,
                  color: _getIconColorForPath(file),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (isDark 
                        ? AppTypography.darkCaption 
                        : AppTypography.lightCaption
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        // 显示剩余文件数量
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Text(
              '还有 $remainingCount 个...',
              style: (isDark 
                  ? AppTypography.darkCaption 
                  : AppTypography.lightCaption
              ).copyWith(
                color: (isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary
                ).withOpacity(0.6),
              ),
            ),
          ),
      ],
    );
  }
  
  /// 构建带背景的文件图标
  Widget _buildFileIconWithBackground(String path, {double opacity = 1.0}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _getIconColorForPath(path).withOpacity(0.15 * opacity),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        _getFileIconForPath(path),
        size: _iconSize,
        color: _getIconColorForPath(path).withOpacity(opacity),
      ),
    );
  }

  Widget _buildIcon(String path) {
    return Icon(
      _getFileIconForPath(path),
      size: _iconSize,
      color: _getIconColorForPath(path),
    );
  }

  Widget _buildFileName(String name, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Text(
      name,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: (isDark 
          ? AppTypography.darkBody 
          : AppTypography.lightBody
      ).copyWith(
        fontSize: _fontSize,
        height: 1.3,
      ),
    );
  }

  IconData _getFileIconForPath(String path) {
    if (ContentProcessor.isDirectory(path)) {
      return Icons.folder_rounded;
    }
    final extension = ContentProcessor.getFileExtension(path);
    return _fileIconMap[extension] ?? Icons.insert_drive_file_rounded;
  }

  Color _getIconColorForPath(String path) {
    if (ContentProcessor.isDirectory(path)) {
      return AppFileColors.folder;
    }
    final extension = ContentProcessor.getFileExtension(path);
    return _fileColorMap[extension] ?? AppFileColors.generic;
  }

  // File type to icon mapping
  static final Map<String, IconData> _fileIconMap = {
    // Documents
    'pdf': Icons.picture_as_pdf,
    'doc': Icons.description,
    'docx': Icons.description,
    'txt': Icons.article,
    'rtf': Icons.article,

    // Spreadsheets
    'xls': Icons.table_chart,
    'xlsx': Icons.table_chart,
    'csv': Icons.table_chart,

    // Images
    'jpg': Icons.image,
    'jpeg': Icons.image,
    'png': Icons.image,
    'gif': Icons.gif,
    'svg': Icons.image,
    'webp': Icons.image,
    'bmp': Icons.image,

    // Audio
    'mp3': Icons.audio_file,
    'wav': Icons.audio_file,
    'aac': Icons.audio_file,
    'm4a': Icons.audio_file,
    'ogg': Icons.audio_file,

    // Video
    'mp4': Icons.video_file,
    'mov': Icons.video_file,
    'avi': Icons.video_file,
    'mkv': Icons.video_file,
    'wmv': Icons.video_file,

    // Archives
    'zip': Icons.folder_zip,
    'rar': Icons.folder_zip,
    '7z': Icons.folder_zip,
    'tar': Icons.folder_zip,
    'gz': Icons.folder_zip,

    // Code
    'html': Icons.code,
    'css': Icons.code,
    'js': Icons.code,
    'json': Icons.code,
    'xml': Icons.code,
    'py': Icons.code,
    'java': Icons.code,
    'cpp': Icons.code,

    // Others
    'exe': Icons.run_circle_outlined,
    'apk': Icons.android,
    'iso': Icons.disc_full,
    'torrent': Icons.download,
  };

  // File type to color mapping
  static final Map<String, Color> _fileColorMap = {
    // Documents - Blue shades
    'pdf': AppFileColors.video,
    'doc': AppFileColors.document,
    'docx': AppFileColors.document,
    'txt': AppFileColors.document,
    'rtf': AppFileColors.document,

    // Spreadsheets - Green shades
    'xls': AppFileColors.spreadsheet,
    'xlsx': AppFileColors.spreadsheet,
    'csv': AppFileColors.spreadsheet,

    // Images - Purple shades
    'jpg': AppFileColors.image,
    'jpeg': AppFileColors.image,
    'png': AppFileColors.image,
    'gif': AppFileColors.image,
    'svg': AppFileColors.image,
    'webp': AppFileColors.image,
    'bmp': AppFileColors.image,

    // Audio - Orange shades
    'mp3': AppFileColors.audio,
    'wav': AppFileColors.audio,
    'aac': AppFileColors.audio,
    'm4a': AppFileColors.audio,
    'ogg': AppFileColors.audio,

    // Video - Red shades
    'mp4': AppFileColors.video,
    'mov': AppFileColors.video,
    'avi': AppFileColors.video,
    'mkv': AppFileColors.video,
    'wmv': AppFileColors.video,

    // Archives - Brown shades
    'zip': AppFileColors.archive,
    'rar': AppFileColors.archive,
    '7z': AppFileColors.archive,
    'tar': AppFileColors.archive,
    'gz': AppFileColors.archive,

    // Code - Grey shades
    'html': AppFileColors.code,
    'css': AppFileColors.code,
    'js': AppFileColors.code,
    'json': AppFileColors.code,
    'xml': AppFileColors.code,
    'py': AppFileColors.code,
    'java': AppFileColors.code,
    'cpp': AppFileColors.code,
  };
}
