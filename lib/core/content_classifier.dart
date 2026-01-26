import 'dart:convert';
import 'package:easy_pasta/model/content_classification.dart';
import 'package:easy_pasta/model/pasteboard_model.dart';

/// Content recognition engine for text-like clipboard items.
///
/// **Input**: ClipboardItemModel (text/html) or raw text.
/// **Output**: ContentClassification with semantic kind + optional metadata.
///
/// This classifier runs pattern matching to identify:
/// - URLs (with normalization)
/// - JSON objects/arrays
/// - Command-line snippets
/// - Plain text (fallback)
class ContentClassifier {
  ContentClassifier._();

  // ============================================================================
  // Constants
  // ============================================================================

  /// Maximum text length for JSON parsing (performance safeguard)
  static const int _maxJsonParseLength = 100000; // 100KB

  /// URL pattern: matches http/https URLs
  static final RegExp _urlRegex = RegExp(
    r'^https?://[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
  );

  /// Command patterns
  static final RegExp _commandRegex = RegExp(
    r'^(\$|>|#|~|sudo|npm|yarn|git|cd|ls|mkdir|rm|cp|mv)\s',
    caseSensitive: false,
  );

  /// JSON object pattern (quick check before parsing)
  static final RegExp _jsonObjectPattern = RegExp(r'^\s*\{[\s\S]*\}\s*$');

  /// JSON array pattern (quick check before parsing)
  static final RegExp _jsonArrayPattern = RegExp(r'^\s*\[[\s\S]*\]\s*$');

  // ============================================================================
  // Public API
  // ============================================================================

  /// Classifies a [ClipboardItemModel].
  ///
  /// This is a convenience wrapper around [classifyText].
  static Future<ContentClassification> classify(
    ClipboardItemModel item,
  ) async {
    return classifyText(item.pvalue);
  }

  /// Classifies raw text content.
  ///
  /// Returns [ContentClassification] with appropriate [ContentKind] and
  /// confidence score. May include metadata for certain types (e.g., URLs).
  ///
  /// **Classification order** (first match wins):
  /// 1. Empty text → text
  /// 2. URL → url (with normalized metadata)
  /// 3. JSON → json (with root type metadata)
  /// 4. Command → command
  /// 5. Fallback → text
  static Future<ContentClassification> classifyText(String text) async {
    final trimmed = text.trim();

    // Early exit for empty text
    if (trimmed.isEmpty) {
      return const ContentClassification(
        kind: ContentKind.text,
        confidence: 1.0,
      );
    }

    // 1. URL detection (highest priority - most specific)
    final urlResult = _classifyUrl(trimmed);
    if (urlResult != null) return urlResult;

    // 2. JSON detection
    final jsonResult = _classifyJson(trimmed);
    if (jsonResult != null) return jsonResult;

    // 3. Command detection
    final commandResult = _classifyCommand(trimmed);
    if (commandResult != null) return commandResult;

    // 4. Fallback to plain text
    return const ContentClassification(
      kind: ContentKind.text,
      confidence: 1.0,
    );
  }

  // ============================================================================
  // Private Classification Methods
  // ============================================================================

  /// Detects URLs and normalizes them.
  static ContentClassification? _classifyUrl(String text) {
    if (!_urlRegex.hasMatch(text)) return null;

    return ContentClassification(
      kind: ContentKind.url,
      confidence: 1.0,
      metadata: {'normalizedUrl': _normalizeUrl(text)},
    );
  }

  /// Normalizes URL by trimming and lowercasing protocol.
  static String _normalizeUrl(String url) {
    final trimmed = url.trim();

    // Lowercase only the protocol part
    final protocolEnd = trimmed.indexOf('://');
    if (protocolEnd == -1) return trimmed;

    return trimmed.substring(0, protocolEnd).toLowerCase() +
        trimmed.substring(protocolEnd);
  }

  /// Detects valid JSON objects or arrays.
  static ContentClassification? _classifyJson(String text) {
    // Quick pattern check first (avoids expensive parsing)
    final isObjectLike = _jsonObjectPattern.hasMatch(text);
    final isArrayLike = _jsonArrayPattern.hasMatch(text);

    if (!isObjectLike && !isArrayLike) return null;

    // Safety check: don't parse extremely large texts
    if (text.length > _maxJsonParseLength) {
      return const ContentClassification(
        kind: ContentKind.text,
        confidence: 1.0,
      );
    }

    try {
      final decoded = jsonDecode(text);
      final rootType = decoded is List ? 'array' : 'object';

      return ContentClassification(
        kind: ContentKind.json,
        confidence: 1.0,
        metadata: {'jsonRoot': rootType},
      );
    } on FormatException {
      // Not valid JSON, continue to other classifiers
      return null;
    } catch (e) {
      // Unexpected error during parsing
      return null;
    }
  }

  /// Detects command-line snippets.
  static ContentClassification? _classifyCommand(String text) {
    // Check for common command prefixes
    if (_commandRegex.hasMatch(text)) {
      return const ContentClassification(
        kind: ContentKind.command,
        confidence: 0.9,
      );
    }

    // Additional check: starts with $ or > (shell prompts)
    if (text.startsWith('\$') || text.startsWith('> ')) {
      return const ContentClassification(
        kind: ContentKind.command,
        confidence: 0.8,
      );
    }

    return null;
  }
}

// ============================================================================
// Extensions (Optional - for convenience)
// ============================================================================

extension ContentClassifierExtension on ClipboardItemModel {
  /// Convenience method to classify this clipboard item.
  Future<ContentClassification> classify() {
    return ContentClassifier.classify(this);
  }
}

extension StringClassifierExtension on String {
  /// Convenience method to classify this string.
  Future<ContentClassification> classifyContent() {
    return ContentClassifier.classifyText(this);
  }
}
