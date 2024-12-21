import 'dart:math' show max;

class LanguageDetector {
  /// 检测代码语言
  static String detectLanguage(String code) {
    // 按照特征明显程度排序的语言检测规则
    final languagePatterns = {
      'swift': _SwiftPatterns(),
      'kotlin': _KotlinPatterns(),
      'java': _JavaPatterns(), 
      'python': _PythonPatterns(),
      'javascript': _JavaScriptPatterns(),
      'typescript': _TypeScriptPatterns(),
      'dart': _DartPatterns(),
      'cpp': _CppPatterns(),
      'go': _GoPatterns(),
      'rust': _RustPatterns(),
      'php': _PhpPatterns(),
      'ruby': _RubyPatterns(),
      'html': _HtmlPatterns(),
      'css': _CssPatterns(),
      'sql': _SqlPatterns(),
    };

    // 计算每种语言的匹配分数
    Map<String, int> scores = {};
    
    for (var entry in languagePatterns.entries) {
      final language = entry.key;
      final patterns = entry.value;
      
      int score = 0;
      // 检查关键字
      for (var keyword in patterns.keywords) {
        if (RegExp(r'\b' + keyword + r'\b').hasMatch(code)) {
          score += 2;
        }
      }
      
      // 检查文件扩展名模式
      if (patterns.fileExtPattern.hasMatch(code)) {
        score += 5;
      }
      
      // 检查语言特定模式
      for (var pattern in patterns.syntaxPatterns) {
        if (pattern.hasMatch(code)) {
          score += 3;
        }
      }
      
      scores[language] = score;
    }

    // 返回得分最高的语言
    if (scores.isEmpty) return 'plaintext';
    
    final highestScore = scores.values.reduce(max);
    if (highestScore == 0) return 'plaintext';
    
    return scores.entries
        .firstWhere((entry) => entry.value == highestScore)
        .key;
  }
}

/// 基础语言模式类
abstract class _LanguagePatterns {
  List<String> get keywords;
  RegExp get fileExtPattern;
  List<RegExp> get syntaxPatterns;
}

/// Swift语言模式
class _SwiftPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'func', 'var', 'let', 'class', 'struct', 'enum', 'protocol',
    'guard', 'if', 'else', 'switch', 'case', 'import'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.swift$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'@objc\b'),
    RegExp(r'override\b'),
    RegExp(r'import\s+Foundation'),
  ];
}

/// Kotlin语言模式
class _KotlinPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'fun', 'val', 'var', 'class', 'object', 'interface', 'data',
    'suspend', 'coroutine', 'companion', 'init', 'constructor'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.kt$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'@\w+\b'),
    RegExp(r'companion\s+object'),
    RegExp(r'data\s+class'),
  ];
}

/// Java语言模式
class _JavaPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'public', 'private', 'protected', 'class', 'interface', 'extends',
    'implements', 'static', 'final', 'void', 'new', 'this', 'super'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.java$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'@Override\b'),
    RegExp(r'System\.out\.println'),
    RegExp(r'public\s+class'),
  ];
}

/// Python语言模式
class _PythonPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'def', 'class', 'import', 'from', 'as', 'if', 'elif', 'else',
    'try', 'except', 'finally', 'with', 'lambda', 'yield'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.py$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'def\s+\w+\s*\([^)]*\)\s*:'),
    RegExp(r'import\s+\w+'),
    RegExp(r'print\s*\('),
  ];
}

/// JavaScript语言模式
class _JavaScriptPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'function', 'const', 'let', 'var', 'class', 'extends',
    'import', 'export', 'default', 'async', 'await'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.js$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'console\.log'),
    RegExp(r'=>'),
    RegExp(r'require\('),
  ];
}

/// TypeScript语言模式
class _TypeScriptPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'interface', 'type', 'enum', 'implements', 'declare',
    'namespace', 'module', 'abstract', 'public', 'private'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.ts$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r':\s*\w+'),
    RegExp(r'<\w+>'),
    RegExp(r'implements\s+\w+'),
  ];
}

/// Dart语言模式
class _DartPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'void', 'var', 'final', 'const', 'class', 'extends', 'implements',
    'with', 'mixin', 'abstract', 'async', 'await', 'Future', 'Stream'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.dart$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'@override\b'),
    RegExp(r'Widget\b'),
    RegExp(r'BuildContext\b'),
    RegExp(r'=>'),
  ];
}

/// C++语言模式
class _CppPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'class', 'struct', 'template', 'typename', 'public', 'private',
    'protected', 'virtual', 'const', 'namespace', 'using'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.(cpp|hpp|h)$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'::\w+'),
    RegExp(r'std::'),
    RegExp(r'#include'),
  ];
}

/// Go语言模式
class _GoPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'func', 'type', 'struct', 'interface', 'map', 'chan',
    'go', 'defer', 'package', 'import', 'const', 'var'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.go$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'func\s+\(\w+\s+\*?\w+\)'),
    RegExp(r'package\s+main'),
    RegExp(r'import\s+\('),
  ];
}

/// Rust语言模式
class _RustPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'fn', 'let', 'mut', 'struct', 'enum', 'trait', 'impl',
    'pub', 'use', 'mod', 'match', 'unsafe', 'where'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.rs$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'fn\s+main'),
    RegExp(r'::\w+'),
    RegExp(r'#\[derive\('),
  ];
}

/// PHP语言模式
class _PhpPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'function', 'class', 'public', 'private', 'protected',
    'namespace', 'use', 'extends', 'implements', 'abstract'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.php$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'\$\w+'),
    RegExp(r'->\w+'),
    RegExp(r'<?php'),
  ];
}

/// Ruby语言模式
class _RubyPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'def', 'class', 'module', 'include', 'extend', 'attr_accessor',
    'private', 'protected', 'public', 'require', 'gem'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.rb$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'def\s+\w+'),
    RegExp(r'@\w+'),
  ];
}

/// HTML语言模式
class _HtmlPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'html', 'head', 'body', 'div', 'span', 'script',
    'style', 'link', 'meta', 'title', 'class', 'id'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.html$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'<[^>]+>'),
    RegExp(r'</[^>]+>'),
  ];
}

/// CSS语言模式
class _CssPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'class', 'id', 'margin', 'padding', 'border', 'color',
    'background', 'font-size', 'width', 'height', 'position'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.css$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'{\s*[^}]+}'),
    RegExp(r'#\w+'),
    RegExp(r'\.\w+'),
  ];
}

/// SQL语言模式
class _SqlPatterns extends _LanguagePatterns {
  @override
  List<String> get keywords => [
    'SELECT', 'FROM', 'WHERE', 'INSERT', 'UPDATE', 'DELETE',
    'JOIN', 'GROUP BY', 'ORDER BY', 'HAVING', 'CREATE', 'ALTER'
  ];

  @override
  RegExp get fileExtPattern => RegExp(r'\.sql$');

  @override
  List<RegExp> get syntaxPatterns => [
    RegExp(r'SELECT\s+.*\s+FROM'),
    RegExp(r'INSERT\s+INTO'),
    RegExp(r'CREATE\s+TABLE'),
  ];
}
