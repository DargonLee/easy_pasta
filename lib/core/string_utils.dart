/// Simple utility class to replace ContentProcessor
class StringUtils {
  /// Simple HTML tag stripping
  static String stripHtmlTags(String html) {
    if (html.isEmpty) return '';
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&quot;'), '"')
        .trim();
  }

  /// Split file URI string into a list of paths
  static List<String> extractFileList(String filePathString) {
    if (filePathString.isEmpty) return [];

    final lines = filePathString.split('\n');
    final files = <String>[];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

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
    return files;
  }

  /// Extract filename from path
  static String extractFileName(String path) {
    if (path.isEmpty) return '';
    final cleanPath = path.replaceAll(RegExp(r'[/\\]+$'), '');
    final parts = cleanPath.split(RegExp(r'[/\\]'));
    return parts.isNotEmpty ? parts.last : cleanPath;
  }

  /// Rough check if path is a directory
  static bool isDirectory(String path) {
    final fileName = extractFileName(path);
    return !fileName.contains('.');
  }

  /// Get file extension
  static String getFileExtension(String path) {
    final fileName = extractFileName(path);
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return '';
  }

  /// Decode URL encoded path
  static String decodeFilePath(String path) {
    try {
      String cleanPath = path;
      if (path.startsWith('file://')) {
        cleanPath = path.substring(7);
      }
      return Uri.decodeFull(cleanPath);
    } catch (e) {
      return path;
    }
  }
}
