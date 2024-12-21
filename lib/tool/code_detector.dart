import 'dart:math';

class LanguageDetector {
  static final Map<String, _LanguagePattern> _languagePatterns = {
    'swift': _LanguagePattern(
      keywords: ['func', 'var', 'let', 'class', 'struct', 'enum', 'protocol', 'guard', 'if', 'else', 'switch', 'case', 'import'],
      fileExtPattern: r'\.swift$',
      syntaxPatterns: [r'@objc\b', r'override\b', r'import\s+Foundation'],
    ),
    'kotlin': _LanguagePattern(
      keywords: ['fun', 'val', 'var', 'class', 'object', 'interface', 'data', 'suspend', 'coroutine', 'companion', 'init', 'constructor'],
      fileExtPattern: r'\.kt$',
      syntaxPatterns: [r'@\w+\b', r'companion\s+object', r'data\s+class'],
    ),
    'java': _LanguagePattern(
      keywords: ['public', 'private', 'protected', 'class', 'interface', 'extends', 'implements', 'static', 'final', 'void', 'new', 'this', 'super'],
      fileExtPattern: r'\.java$',
      syntaxPatterns: [r'@Override\b', r'System\.out\.println', r'public\s+class'],
    ),
    'python': _LanguagePattern(
      keywords: ['def', 'class', 'import', 'from', 'as', 'if', 'elif', 'else', 'try', 'except', 'finally', 'with', 'lambda', 'yield'],
      fileExtPattern: r'\.py$',
      syntaxPatterns: [r'def\s+\w+\s*\([^)]*\)\s*:', r'import\s+\w+', r'print\s*\('],
    ),
    'javascript': _LanguagePattern(
      keywords: ['function', 'const', 'let', 'var', 'class', 'extends', 'import', 'export', 'default', 'async', 'await'],
      fileExtPattern: r'\.js$',
      syntaxPatterns: [r'console\.log', r'=>', r'require\('],
    ),
    'typescript': _LanguagePattern(
      keywords: ['interface', 'type', 'enum', 'implements', 'declare', 'namespace', 'module', 'abstract', 'public', 'private'],
      fileExtPattern: r'\.ts$',
      syntaxPatterns: [r':\s*\w+', r'<\w+>', r'implements\s+\w+'],
    ),
    'dart': _LanguagePattern(
      keywords: ['void', 'var', 'final', 'const', 'class', 'extends', 'implements', 'with', 'mixin', 'abstract', 'async', 'await', 'Future', 'Stream'],
      fileExtPattern: r'\.dart$',
      syntaxPatterns: [r'@override\b', r'Widget\b', r'BuildContext\b', r'=>'],
    ),
    'cpp': _LanguagePattern(
      keywords: ['class', 'struct', 'template', 'typename', 'public', 'private', 'protected', 'virtual', 'const', 'namespace', 'using'],
      fileExtPattern: r'\.(cpp|hpp|h)$',
      syntaxPatterns: [r'::\w+', r'std::', r'#include'],
    ),
    'go': _LanguagePattern(
      keywords: ['func', 'type', 'struct', 'interface', 'map', 'chan', 'go', 'defer', 'package', 'import', 'const', 'var'],
      fileExtPattern: r'\.go$',
      syntaxPatterns: [r'func\s+\(\w+\s+\*?\w+\)', r'package\s+main', r'import\s+\('],
    ),
    'rust': _LanguagePattern(
      keywords: ['fn', 'let', 'mut', 'struct', 'enum', 'trait', 'impl', 'pub', 'use', 'mod', 'match', 'unsafe', 'where'],
      fileExtPattern: r'\.rs$',
      syntaxPatterns: [r'::\w+', r'impl\s+\w+', r'fn\s+\w+'],
    ),
    'php': _LanguagePattern(
      keywords: ['class', 'function', 'public', 'private', 'protected', 'extends', 'implements', 'interface', 'namespace', 'use'],
      fileExtPattern: r'\.php$',
      syntaxPatterns: [r'<\?php', r'\$\w+', r'->\w+'],
    ),
    'ruby': _LanguagePattern(
      keywords: ['def', 'class', 'module', 'include', 'extend', 'attr_accessor', 'private', 'protected', 'public', 'require', 'gem'],
      fileExtPattern: r'\.rb$',
      syntaxPatterns: [r'def\s+\w+', r'@\w+'],
    ),
    'html': _LanguagePattern(
      keywords: ['html', 'head', 'body', 'div', 'span', 'class', 'id', 'style', 'script', 'link'],
      fileExtPattern: r'\.html?$',
      syntaxPatterns: [r'<\w+>', r'<\/\w+>', r'class="[\w\s-]+"'],
    ),
    'css': _LanguagePattern(
      keywords: ['color', 'background', 'font', 'margin', 'padding', 'border', 'display', 'width', 'height', 'position'],
      fileExtPattern: r'\.css$',
      syntaxPatterns: [r'\w+\s*:\s*[\w#\d\s]+;', r'\.\w+\s*\{', r'#\w+\s*\{'],
    ),
    'sql': _LanguagePattern(
      keywords: ['SELECT', 'FROM', 'WHERE', 'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'TABLE', 'JOIN', 'ON', 'AND', 'OR', 'NOT'],
      fileExtPattern: r'\.sql$',
      syntaxPatterns: [r'SELECT\s+\w+', r'FROM\s+\w+', r'WHERE\s+\w+'],
    ),
  };

  static String detectLanguage(String code) {
    Map<String, int> scores = {};

    for (var entry in _languagePatterns.entries) {
      final language = entry.key;
      final pattern = entry.value;
      int score = 0;

      for (final keyword in pattern.keywords) {
        if (RegExp(r'\b' + keyword + r'\b').hasMatch(code)) {
          score += 2;
        }
      }

      if (RegExp(pattern.fileExtPattern).hasMatch(code)) {
        score += 5;
      }

      for (final syntaxPattern in pattern.syntaxPatterns) {
        if (RegExp(syntaxPattern).hasMatch(code)) {
          score += 3;
        }
      }

      scores[language] = score;
    }

    if (scores.isEmpty) return 'plaintext';

    final highestScore = scores.values.reduce(max);
    if (highestScore == 0) return 'plaintext';

    return scores.entries
        .firstWhere((entry) => entry.value == highestScore)
        .key;
  }
}

class _LanguagePattern {
  final List<String> keywords;
  final String fileExtPattern;
  final List<String> syntaxPatterns;

  _LanguagePattern({
    required this.keywords,
    required this.fileExtPattern,
    required this.syntaxPatterns,
  });
}
