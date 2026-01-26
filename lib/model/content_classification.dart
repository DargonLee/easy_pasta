import 'package:flutter/foundation.dart';

/// High-level semantic category for text-like clipboard content.
enum ContentKind {
  url,
  code,
  json,
  command,
  text,
}

/// Classification result for a clipboard text payload.
@immutable
class ContentClassification {
  static const double fallbackThreshold = 0.6;

  final ContentKind kind;
  final double confidence;
  final Map<String, Object?>? metadata;

  const ContentClassification({
    required this.kind,
    required this.confidence,
    this.metadata,
  });

  ContentClassification fallbackToTextIfLowConfidence({
    double threshold = fallbackThreshold,
  }) {
    if (kind == ContentKind.text || confidence >= threshold) {
      return this;
    }
    return ContentClassification(
      kind: ContentKind.text,
      confidence: confidence,
      metadata: null,
    );
  }

  @override
  String toString() =>
      'ContentClassification(kind: $kind, confidence: $confidence, metadata: $metadata)';

  Map<String, dynamic> toMap() {
    return {
      'kind': kind.name,
      'confidence': confidence,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory ContentClassification.fromMap(Map<String, dynamic> map) {
    return ContentClassification(
      kind: ContentKind.values.firstWhere(
        (e) => e.name == map['kind'],
        orElse: () => ContentKind.text,
      ),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}
