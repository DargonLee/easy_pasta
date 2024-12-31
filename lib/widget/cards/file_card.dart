import 'package:flutter/material.dart';

class FileContent extends StatelessWidget {
  final String filePath;
  final bool? isDirectory;
  final double iconSize;
  final int maxLines;
  final double fontSize;
  
  const FileContent({
    Key? key,
    required this.filePath,
    this.isDirectory,
    this.iconSize = 16,
    this.maxLines = 2,
    this.fontSize = 13,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildIcon(),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFileName(),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    return Icon(
      _getFileIcon(),
      size: iconSize,
      color: Colors.grey[600],
    );
  }

  Widget _buildFileName() {
    return Text(
      _getFileName(),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.2,
      ),
    );
  }

  IconData _getFileIcon() {
    if (isDirectory == true) {
      return Icons.folder;
    }
    
    // 根据文件扩展名返回对应的图标
    final extension = _getFileExtension().toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileName() {
    return filePath.split('/').last;
  }

  String _getFileExtension() {
    final fileName = _getFileName();
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last : '';
  }
}