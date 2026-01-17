import 'package:flutter/material.dart';
import 'package:easy_pasta/model/design_tokens.dart';

enum GridDensity { compact, comfortable, spacious }

class GridDensitySpec {
  final double gridSpacing;
  final double gridPadding;
  final double minCrossAxisExtent;
  final double aspectRatio;
  final double cardPadding;
  final int maxTextLines;
  final double imageRadius;

  const GridDensitySpec({
    required this.gridSpacing,
    required this.gridPadding,
    required this.minCrossAxisExtent,
    required this.aspectRatio,
    required this.cardPadding,
    required this.maxTextLines,
    required this.imageRadius,
  });
}

extension GridDensityX on GridDensity {
  GridDensitySpec get spec {
    switch (this) {
      case GridDensity.compact:
        return const GridDensitySpec(
          gridSpacing: AppSpacing.sm,
          gridPadding: AppSpacing.md,
          minCrossAxisExtent: 220.0,
          aspectRatio: 1.28,
          cardPadding: AppSpacing.sm,
          maxTextLines: 4,
          imageRadius: AppRadius.sm,
        );
      case GridDensity.comfortable:
        return const GridDensitySpec(
          gridSpacing: AppSpacing.gridSpacing,
          gridPadding: AppSpacing.gridPadding,
          minCrossAxisExtent: 240.0,
          aspectRatio: 1.16,
          cardPadding: AppSpacing.cardPadding,
          maxTextLines: 5,
          imageRadius: AppRadius.md,
        );
      case GridDensity.spacious:
        return const GridDensitySpec(
          gridSpacing: AppSpacing.lg,
          gridPadding: AppSpacing.xl,
          minCrossAxisExtent: 260.0,
          aspectRatio: 1.05,
          cardPadding: AppSpacing.cardPaddingLarge,
          maxTextLines: 6,
          imageRadius: AppRadius.lg,
        );
    }
  }

  IconData get icon {
    switch (this) {
      case GridDensity.compact:
        return Icons.grid_on;
      case GridDensity.comfortable:
        return Icons.view_comfy;
      case GridDensity.spacious:
        return Icons.view_agenda;
    }
  }

  String get label {
    switch (this) {
      case GridDensity.compact:
        return '紧凑';
      case GridDensity.comfortable:
        return '舒适';
      case GridDensity.spacious:
        return '宽松';
    }
  }
}
