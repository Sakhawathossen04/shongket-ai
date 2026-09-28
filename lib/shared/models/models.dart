import 'dart:convert';

/// Service contexts that reorder vocabulary priority.
enum ServiceMode { hospital, emergency, government, general }

/// A single BdSL sign in the app vocabulary.
class VocabEntry {
  const VocabEntry({
    required this.id,
    required this.gloss,
    required this.bn,
    required this.category,
    this.template,
  });

  final String id;
  final String gloss;
  final String bn;
  final String category;

  /// Template used by the sentence builder, e.g. "আমার {অঙ্গ} ব্যথা" is
  /// handled by templates; null means use [bn] directly.
  final String? template;

  factory VocabEntry.fromJson(Map<String, dynamic> json) => VocabEntry(
        id: json['id'] as String,
        gloss: json['gloss'] as String,
        bn: json['bn'] as String,
        category: json['category'] as String? ?? 'general',
        template: json['template'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'gloss': gloss,
        'bn': bn,
        'category': category,
        if (template != null) 'template': template,
      };
}

/// One class output of the on-device classifier.
class RecognitionCandidate {
  const RecognitionCandidate({required this.entry, required this.confidence});

  final VocabEntry entry;
  final double confidence;

  @override
  String toString() =>
      'RecognitionCandidate(${entry.gloss}, ${confidence.toStringAsFixed(2)})';
}

/// Result of classifying one 30-frame window.
class RecognitionResult {
  const RecognitionResult({
    required this.top,
    required this.candidates,
    required this.confident,
  });

  final RecognitionCandidate top;
  final List<RecognitionCandidate> candidates;
  final bool confident;

  bool get isUnknown => top.entry.id == unknownSignId;

  @override
  String toString() => 'RecognitionResult(${top.entry.gloss}, '
      '${(top.confidence * 100).toStringAsFixed(0)}%, '
      'confident=$confident)';
}

/// The id reserved for "nothing recognised".
const String unknownSignId = 'unknown';

/// A sign captured into the current sentence, with its confidence.
class CapturedSign {
  const CapturedSign({required this.entry, required this.confidence});

  final VocabEntry entry;
  final double confidence;

  Map<String, dynamic> toJson() => {
        'gloss': entry.gloss,
        'bn': entry.bn,
        'confidence': confidence,
      };
}

/// Direction of communication.
enum CommDirection { deafToHearing, hearingToDeaf }

/// One line in the conversation history.
class ConversationTurn {
  const ConversationTurn({
    required this.text,
    required this.direction,
    required this.timestamp,
    this.confidence,
  });

  final String text;
  final CommDirection direction;
  final DateTime timestamp;
  final double? confidence;

  Map<String, dynamic> toJson() => {
        'text': text,
        'direction': direction.name,
        'timestamp': timestamp.toIso8601String(),
        if (confidence != null) 'confidence': confidence,
      };

  static ConversationTurn fromJson(Map<String, dynamic> json) =>
      ConversationTurn(
        text: json['text'] as String,
        direction: CommDirection.values.firstWhere(
          (d) => d.name == json['direction'],
          orElse: () => CommDirection.deafToHearing,
        ),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        confidence: (json['confidence'] as num?)?.toDouble(),
      );
}

/// Parses the bundled vocabulary JSON asset.
List<VocabEntry> parseVocab(String raw) {
  final decoded = json.decode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('vocab root must be an object');
  }
  final list = decoded['signs'];
  if (list is! List) {
    throw const FormatException('vocab must contain a signs array');
  }
  return list
      .map((e) => VocabEntry.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}
