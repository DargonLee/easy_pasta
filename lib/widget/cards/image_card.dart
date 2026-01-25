import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';

class ImageContent extends StatelessWidget {
  final Uint8List imageBytes;
  final double borderRadius;
  final BoxFit fit;

  const ImageContent({
    super.key,
    required this.imageBytes,
    this.borderRadius = 8.0,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: isDark 
              ? AppColors.darkSecondaryBackground 
              : AppColors.lightSecondaryBackground,
        ),
        child: Image.memory(
          imageBytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: isDark 
                        ? AppColors.darkTextTertiary 
                        : AppColors.lightTextTertiary,
                    size: 48,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '图片加载失败',
                    style: TextStyle(
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.lightTextSecondary,
                      fontSize: AppFontSizes.caption,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
