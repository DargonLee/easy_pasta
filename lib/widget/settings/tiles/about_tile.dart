import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_pasta/model/settings_model.dart';
import 'package:easy_pasta/model/settings_constants.dart';
import 'package:easy_pasta/model/design_tokens.dart';
import 'package:easy_pasta/model/app_typography.dart';
import 'package:easy_pasta/widget/settings/base_setting_tile.dart';

class AboutTile extends StatelessWidget {
  final SettingItem item;

  const AboutTile({
    super.key,
    required this.item,
  });

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(SettingsConstants.githubUrl);
    try {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to launch url: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BaseSettingTile(
      item: item,
      customSubtitle: Text(
        '当前版本：${SettingsConstants.appVersion}',
        style:
            isDark ? AppTypography.darkFootnote : AppTypography.lightFootnote,
      ),
      trailing: const Icon(
        Icons.open_in_new,
        size: 16,
        color: AppColors.primary,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        _launchUrl();
      },
    );
  }
}
