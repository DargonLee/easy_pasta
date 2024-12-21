import 'package:flutter/material.dart';

class URLContent extends StatelessWidget {
  final String url;
  final int maxLines;
  final double fontSize;
  final bool showIcon;

  const URLContent({
    Key? key,
    required this.url,
    this.maxLines = 2,
    this.fontSize = 13,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.link,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
        ],
        Expanded(
          child: Text(
            url,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: fontSize,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  /// 提取URL的域名
  String? _extractDomain() {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }
}