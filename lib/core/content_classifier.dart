import 'package:easy_pasta/model/content_classification.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

/// Content recognition engine for text-like clipboard items.
/// Input: ClipboardItemModel (text/html) or raw text.
/// Output: ContentClassification with semantic kind + optional metadata.
/// Top-level function for background classification
class ContentClassifier {
  ContentClassifier._();

  /// Entry for ClipboardItemModel.
  static Future<ContentClassification> classify(ClipboardItemModel item) async {
    return const ContentClassification(kind: ContentKind.text, confidence: 1.0);
  }

  /// Entry for raw text.
  static Future<ContentClassification> classifyText(String text) async {
    return const ContentClassification(kind: ContentKind.text, confidence: 1.0);
  }
}
