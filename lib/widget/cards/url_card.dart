import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';

class UrlContent extends StatelessWidget {
  final String urlText;
  final String? normalizedUrl;
  final int maxLines;

  const UrlContent({
    super.key,
    required this.urlText,
    this.normalizedUrl,
    this.maxLines = 2,
  });

  String _normalizeUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith(RegExp(r'https?:\/\/', caseSensitive: false))) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  Uri? _parseUrl(String input) {
    return Uri.tryParse(input);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveUrl = normalizedUrl ?? _normalizeUrl(urlText);
    final uri = _parseUrl(effectiveUrl);
    final host = (uri?.host.isNotEmpty ?? false) ? uri!.host : effectiveUrl;
    final path = uri?.path ?? '';
    final query = uri?.query ?? '';
    final displayPath =
        (path.isEmpty && query.isEmpty) ? '/' : '$path${query.isNotEmpty ? '?$query' : ''}';
    final scheme = uri?.scheme.isNotEmpty ?? false ? uri!.scheme : 'https';

    final badgeColor = isDark
        ? AppColors.darkSecondaryBackground.withValues(alpha: 0.8)
        : AppColors.lightSecondaryBackground.withValues(alpha: 0.8);
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.4)
        : AppColors.lightBorder.withValues(alpha: 0.4);
    final titleStyle =
        (isDark ? AppTypography.darkHeadline : AppTypography.lightHeadline)
            .copyWith(fontSize: 15, fontWeight: AppFontWeights.semiBold);
    final pathStyle =
        (isDark ? AppTypography.darkFootnote : AppTypography.lightFootnote)
            .copyWith(color: AppColors.primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                scheme.toUpperCase(),
                style: (isDark
                        ? AppTypography.darkCaption
                        : AppTypography.lightCaption)
                    .copyWith(
                  fontWeight: AppFontWeights.semiBold,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
            IconButton(
              tooltip: '打开链接',
              icon: const Icon(Icons.open_in_new, size: 16),
              color: AppColors.primary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: () => _openUrl(effectiveUrl),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          displayPath,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: pathStyle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          effectiveUrl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (isDark ? AppTypography.darkCaption : AppTypography.lightCaption)
              .copyWith(color: AppColors.primary.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}
