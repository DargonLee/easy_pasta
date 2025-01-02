class HtmlProcessor {
  /// 处理 HTML 内容
  /// - 移除背景色
  /// - 移除多余的换行和空格
  /// - 保持格式化的同时简化 HTML 结构
  static String processHtml(String html) {
    String processed = html;
    
    // 替换背景色
    processed = processed.replaceAll(
      'background-color: #ffffff;', 
      'background-color: transparent;'
    );
    
    // 处理 div 标签的换行
    processed = processed.replaceAll('</div><div>', '');
    
    // 移除多余的缩进空格
    processed = processed.replaceAll(RegExp(r'\s{2,}'), ' ');
    
    // 移除行首的空格
    processed = processed.replaceAll(RegExp(r'^\s+', multiLine: true), '');
    
    // 移除行尾的空格
    processed = processed.replaceAll(RegExp(r'\s+$', multiLine: true), '');
    
    // 移除多余的换行
    processed = processed.replaceAll(RegExp(r'\n+'), '');
    
    return processed;
  }
}