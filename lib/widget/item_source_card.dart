import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';

class ItemSourceCard extends StatelessWidget {
  final String code;
  final bool isSelected;
  final VoidCallback? onTap;

  const ItemSourceCard({
    Key? key,
    required this.code,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      child: HighlightView(
        code,
        language: 'dart',
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
