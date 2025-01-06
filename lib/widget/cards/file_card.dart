import 'package:flutter/material.dart';

/// A widget that displays a file icon and name in a vertical layout
class FileContent extends StatelessWidget {
  final String fileName;
  final String fileUri;

  // Constants for styling
  static const double _iconSize = 56.0;
  static const double _fontSize = 13.0;

  const FileContent({
    super.key,
    required this.fileName,
    required this.fileUri,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIcon(),
        const SizedBox(height: 8),
        _buildFileName(),
      ],
    );
  }

  Widget _buildIcon() {
    return Icon(
      _getFileIcon(),
      size: _iconSize,
      color: _getIconColor(),
    );
  }

  Widget _buildFileName() {
    return Text(
      fileName,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: _fontSize,
        height: 1.2,
      ),
    );
  }

  IconData _getFileIcon() {
    if (_isDirectory()) {
      return Icons.folder;
    }
    final extension = _getFileExtension();
    return _fileIconMap[extension] ?? Icons.insert_drive_file;
  }

  Color _getIconColor() {
    if (_isDirectory()) {
      return Colors.blue[600]!;
    }
    final extension = _getFileExtension();
    return _fileColorMap[extension] ?? Colors.grey[600]!;
  }

  bool _isDirectory() {
    final cleanPath = fileUri.replaceAll(RegExp(r'[/\\]+$'), '');
    final hasExtension = cleanPath.split('/').last.contains('.');
    return !hasExtension;
  }

  String _getFileExtension() => fileUri.split('.').length > 1
      ? fileUri.split('.').last.toLowerCase()
      : '';

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
    'pdf': Colors.red[400]!,
    'doc': Colors.blue[600]!,
    'docx': Colors.blue[600]!,
    'txt': Colors.blue[400]!,
    'rtf': Colors.blue[400]!,

    // Spreadsheets - Green shades
    'xls': Colors.green[600]!,
    'xlsx': Colors.green[600]!,
    'csv': Colors.green[400]!,

    // Images - Purple shades
    'jpg': Colors.purple[400]!,
    'jpeg': Colors.purple[400]!,
    'png': Colors.purple[400]!,
    'gif': Colors.purple[500]!,
    'svg': Colors.purple[600]!,

    // Audio - Orange shades
    'mp3': Colors.orange[400]!,
    'wav': Colors.orange[400]!,
    'aac': Colors.orange[400]!,
    'm4a': Colors.orange[400]!,

    // Video - Red shades
    'mp4': Colors.red[400]!,
    'mov': Colors.red[400]!,
    'avi': Colors.red[400]!,
    'mkv': Colors.red[400]!,

    // Archives - Brown shades
    'zip': Colors.brown[400]!,
    'rar': Colors.brown[400]!,
    '7z': Colors.brown[400]!,

    // Code - Grey shades
    'html': Colors.blueGrey[400]!,
    'css': Colors.blueGrey[400]!,
    'js': Colors.blueGrey[400]!,
    'py': Colors.blueGrey[400]!,
    'java': Colors.blueGrey[400]!,
  };
}
