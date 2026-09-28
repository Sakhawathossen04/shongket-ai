import 'package:flutter/services.dart' show rootBundle;

import '../../shared/models/models.dart';

/// Loads and indexes the BdSL vocabulary bundled with the app.
class VocabService {
  VocabService._(this._entries, this._byGloss);

  final List<VocabEntry> _entries;
  final Map<String, VocabEntry> _byGloss;

  List<VocabEntry> get all => List.unmodifiable(_entries);
  int get size => _entries.length;

  VocabEntry? byGloss(String gloss) => _byGloss[gloss];

  /// Vocabulary filtered by service mode priority (mode first).
  List<VocabEntry> forMode(ServiceMode mode) {
    final tag = switch (mode) {
      ServiceMode.hospital => 'hospital',
      ServiceMode.emergency => 'emergency',
      ServiceMode.government => 'government',
      ServiceMode.general => 'general',
    };
    final primary =
        _entries.where((e) => e.category == tag).toList(growable: false);
    final rest =
        _entries.where((e) => e.category != tag).toList(growable: false);
    return [...primary, ...rest];
  }

  /// Emergency card phrases (category == emergency_phrase).
  List<VocabEntry> get emergencyPhrases => _entries
      .where((e) => e.category == 'emergency_phrase')
      .toList(growable: false);

  static Future<VocabService> load() async {
    final raw = await rootBundle.loadString('assets/vocab/bdsl_vocab.json');
    final entries = parseVocab(raw);
    final byGloss = <String, VocabEntry>{
      for (final e in entries) e.gloss: e,
    };
    return VocabService._(entries, byGloss);
  }
}
