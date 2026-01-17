import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

/// 统一的内容处理器
/// 负责从各种格式中提取、清理和格式化文本内容
class ContentProcessor {
  /// 从HTML中提取纯文本
  /// 移除所有HTML标签、样式和脚本，只保留可读文本
  static String extractTextFromHtml(String htmlContent) {
    if (htmlContent.isEmpty) return '';
    
    try {
      // 解析HTML
      final document = html_parser.parse(htmlContent);
      
      // 移除script和style标签
      document.querySelectorAll('script, style').forEach((element) {
        element.remove();
      });
      
      // 获取纯文本
      String text = document.body?.text ?? '';
      
      // 清理多余的空白字符
      text = _cleanWhitespace(text);
      
      return text;
    } catch (e) {
      // 如果解析失败，尝试简单的标签移除
      return _stripHtmlTags(htmlContent);
    }
  }
  
  /// 简单的HTML标签移除（作为备选方案）
  static String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&quot;'), '"')
        .trim();
  }
  
  /// 清理多余的空白字符
  static String _cleanWhitespace(String text) {
    return text
        // 替换多个连续空格为单个空格
        .replaceAll(RegExp(r' +'), ' ')
        // 替换多个连续换行为最多2个换行
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        // 移除每行前后的空白
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }
  
  /// 清理普通文本内容
  /// 移除多余空白，标准化换行
  static String cleanText(String text) {
    if (text.isEmpty) return '';
    return _cleanWhitespace(text);
  }
  
  /// 解码URL编码的文件路径
  /// 将 %E4%B8%AD%E6%96%87 这样的编码转换为中文
  static String decodeFilePath(String path) {
    try {
      // 移除 file:// 前缀
      String cleanPath = path;
      if (path.startsWith('file://')) {
        cleanPath = path.substring(7);
      }
      
      // URL解码
      cleanPath = Uri.decodeFull(cleanPath);
      
      return cleanPath;
    } catch (e) {
      return path;
    }
  }
  
  /// 从文件路径提取文件名
  static String extractFileName(String path) {
    final decodedPath = decodeFilePath(path);
    
    // 移除末尾的斜杠（如果是文件夹）
    final cleanPath = decodedPath.replaceAll(RegExp(r'[/\\]+$'), '');
    
    // 提取最后一个路径组件
    final parts = cleanPath.split(RegExp(r'[/\\]'));
    return parts.isNotEmpty ? parts.last : cleanPath;
  }
  
  /// 检查是否为文件夹路径
  static bool isDirectory(String path) {
    final cleanPath = path.replaceAll(RegExp(r'[/\\]+$'), '');
    final fileName = extractFileName(cleanPath);
    
    // 如果文件名不包含扩展名，可能是文件夹
    return !fileName.contains('.');
  }
  
  /// 从多文件路径字符串中提取文件列表
  /// 支持格式：多个file://路径用换行或逗号分隔
  static List<String> extractFileList(String filePathString) {
    if (filePathString.isEmpty) return [];
    
    // 按换行符分割
    final lines = filePathString.split('\n');
    final files = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        // 移除file://前缀并解码
        String path = trimmed;
        if (path.startsWith('file://')) {
          path = path.substring(7);
        }
        
        try {
          path = Uri.decodeFull(path);
          files.add(path);
        } catch (e) {
          files.add(trimmed);
        }
      }
    }
    
    return files;
  }
  
  /// 获取文件扩展名
  static String getFileExtension(String path) {
    final fileName = extractFileName(path);
    final parts = fileName.split('.');
    
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    
    return '';
  }
  
  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// 智能截断文本
  /// 保持完整的单词，避免在单词中间截断
  static String truncateText(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    
    // 尝试在单词边界处截断
    final truncated = text.substring(0, maxLength - ellipsis.length);
    final lastSpace = truncated.lastIndexOf(' ');
    
    if (lastSpace > maxLength * 0.7) {
      return '${truncated.substring(0, lastSpace)}$ellipsis';
    }
    
    return '$truncated$ellipsis';
  }
  
  /// 检测内容类型
  static ContentType detectContentType(String content) {
    if (content.isEmpty) return ContentType.empty;
    
    // 检测HTML
    if (content.contains('<html') || 
        content.contains('<!DOCTYPE') ||
        content.contains('<div') ||
        content.contains('<span')) {
      return ContentType.html;
    }
    
    // 检测URL
    if (_isUrl(content)) {
      return ContentType.url;
    }
    
    // 检测Markdown
    if (_hasMarkdownSyntax(content)) {
      return ContentType.markdown;
    }
    
    // 检测代码
    if (_hasCodeSyntax(content)) {
      return ContentType.code;
    }
    
    return ContentType.plainText;
  }
  
  /// 检测是否为URL
  static bool _isUrl(String text) {
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(text.trim());
  }
  
  /// 检测是否包含Markdown语法
  static bool _hasMarkdownSyntax(String text) {
    final markdownPatterns = [
      RegExp(r'^#{1,6}\s'),  // 标题
      RegExp(r'\*\*.*\*\*'), // 粗体
      RegExp(r'\*.*\*'),     // 斜体
      RegExp(r'\[.*\]\(.*\)'), // 链接
      RegExp(r'^[-*+]\s'),   // 列表
      RegExp(r'^>\s'),       // 引用
      RegExp(r'```'),        // 代码块
    ];
    
    for (final pattern in markdownPatterns) {
      if (pattern.hasMatch(text)) return true;
    }
    
    return false;
  }
  
  /// 检测是否包含代码语法
  static bool _hasCodeSyntax(String text) {
    final codePatterns = [
      RegExp(r'function\s+\w+\s*\('),
      RegExp(r'class\s+\w+'),
      RegExp(r'import\s+'),
      RegExp(r'export\s+'),
      RegExp(r'const\s+\w+\s*='),
      RegExp(r'let\s+\w+\s*='),
      RegExp(r'var\s+\w+\s*='),
      RegExp(r'def\s+\w+\s*\('),
      RegExp(r'public\s+(class|static)'),
    ];
    
    int matchCount = 0;
    for (final pattern in codePatterns) {
      if (pattern.hasMatch(text)) matchCount++;
    }
    
    return matchCount >= 2; // 至少匹配2个模式才认为是代码
  }
}

/// 内容类型枚举
enum ContentType {
  plainText,
  html,
  markdown,
  code,
  url,
  empty,
}
