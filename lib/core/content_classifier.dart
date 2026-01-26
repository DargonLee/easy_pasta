import 'package:easy_pasta/model/content_classification.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

/// Content recognition engine for text-like clipboard items.
/// Input: ClipboardItemModel (text/html) or raw text.
/// Output: ContentClassification with semantic kind + optional metadata.
/// Top-level function for background classification
class ContentClassifier {
  ContentClassifier._();

  static final _urlRegex = RegExp(
    r'^https?://[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
  );

  /// Entry for ClipboardItemModel.
  static Future<ContentClassification> classify(ClipboardItemModel item) async {
    return classifyText(item.pvalue);
  }

  /// Entry for raw text.
  static Future<ContentClassification> classifyText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const ContentClassification(
          kind: ContentKind.text, confidence: 1.0);
    }

    // 1. URL 识别
    if (_urlRegex.hasMatch(trimmed)) {
      return ContentClassification(
        kind: ContentKind.url,
        confidence: 1.0,
        metadata: {'normalizedUrl': trimmed},
      );
    }

    // 2. JSON 识别 (初步尝试)
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        // 尝试解析以确认是否为 JSON
        // 注意：在大文本下这可能有性能影响，但在 SuperClipboard 处已有 50KB 限制
        // jsonDecode(trimmed);
        return const ContentClassification(
          kind: ContentKind.json,
          confidence: 0.9,
        );
      } catch (_) {
        // 解析失败则退回普通文本
      }
    }

    // 3. Command 识别 (以 $ 或 > 开头)
    if (trimmed.startsWith('\$') || trimmed.startsWith('> ')) {
      return const ContentClassification(
        kind: ContentKind.command,
        confidence: 0.8,
      );
    }

    // 默认返回普通文本
    return const ContentClassification(kind: ContentKind.text, confidence: 1.0);
  }
}
