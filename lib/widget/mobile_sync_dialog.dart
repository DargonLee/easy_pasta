import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:easy_pasta/core/sync_portal_service.dart';
import 'package:easy_pasta/model/design_tokens.dart';

class MobileSyncDialog extends StatelessWidget {
  const MobileSyncDialog({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'MobileSync',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const MobileSyncDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: AppCurves.standard),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final portalUrl = SyncPortalService.instance.portalUrl;

    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '手机同步',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: SyncPortalService.instance.isRunning,
                        builder: (context, running, _) {
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: running ? Colors.green : Colors.red,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (portalUrl != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: portalUrl,
                    version: QrVersions.auto,
                    size: 200.0,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '请使用手机扫码',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  portalUrl,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                ),
              ] else ...[
                ValueListenableBuilder<String?>(
                  valueListenable: SyncPortalService.instance.lastError,
                  builder: (context, error, _) {
                    if (error != null) {
                      return Column(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('服务启动失败',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            error,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.red),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => SyncPortalService.instance.start(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('重试服务'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      );
                    }
                    return const Column(
                      children: [
                        SizedBox(height: 40),
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('正在获取局域网地址...'),
                        SizedBox(height: 40),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '手机需与电脑连接同一 Wi-Fi',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
