import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:easy_pasta/tool/code_detector.dart';

class SourceCodeContent extends StatelessWidget {
  final String code;
  final bool isSelected;
  final VoidCallback? onTap;

  const SourceCodeContent({
    Key? key,
    required this.code,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final language = LanguageDetector.detectLanguage(code);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      child: HighlightView(
        code,
        language: language,
        theme: githubTheme,
        padding: const EdgeInsets.all(12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
