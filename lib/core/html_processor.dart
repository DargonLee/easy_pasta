class HtmlProcessor {
  /// 处理 HTML 内容
  /// - 移除背景色
  /// - 移除多余的换行和空格
  /// - 保持格式化的同时简化 HTML 结构
  static String processHtml(String html) {
    String processed = html;

    // 替换背景色
    processed = processed.replaceAll(
        'background-color: #ffffff;', 'background-color: transparent;');
    return processed;
  }

  static String processHtml2(String html) {
    // 使用正则表达式匹配每一行的内容，包括样式
    final regex =
        RegExp(r'<div><span[^>]*>([^<]*)</span>([^<]*)</div>', multiLine: true);

    // 收集所有行，保留样式信息
    var processedLines = regex.allMatches(html).map((match) {
      // 获取整行的内容
      var line = match.group(0) ?? '';
      // 将div替换为span，这样就不会产生换行
      return line
          .replaceAll('<div>', '<span class="line">')
          .replaceAll('</div>', '</span><br>');
    }).join('');

    // 包装处理后的内容
    return '''
    <pre style="margin: 0; padding: 0; line-height: 1.2;">
      <code style="display: block; font-family: monospace;">
        $processedLines
      </code>
    </pre>
  ''';
  }
}
