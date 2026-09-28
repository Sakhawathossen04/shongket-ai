import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shongket_ai/core/services/sentence_builder.dart';
import 'package:shongket_ai/core/services/stt_service.dart';
import 'package:shongket_ai/core/services/tts_service.dart';
import 'package:shongket_ai/core/providers/app_providers.dart';
import 'package:shongket_ai/core/services/pose_classifier.dart';
import 'package:shongket_ai/shared/models/models.dart';

void main() {
  group('parseVocab', () {
    test('parses signs array and preserves fields', () {
      final raw = jsonEncode({
        'signs': [
          {
            'id': 's001',
            'gloss': 'DOKTAR',
            'bn': 'ডাক্তার',
            'category': 'hospital',
          },
        ],
      });
      final entries = parseVocab(raw);
      expect(entries, hasLength(1));
      expect(entries.first.gloss, 'DOKTAR');
      expect(entries.first.bn, 'ডাক্তার');
      expect(entries.first.category, 'hospital');
    });

    test('rejects malformed vocab', () {
      expect(() => parseVocab('{"nope": 1}'), throwsFormatException);
    });
  });

  group('SentenceBuilder', () {
    VocabEntry entry(String gloss, String bn,
            {String category = 'general', String? template}) =>
        VocabEntry(id: gloss, gloss: gloss, bn: bn, category: category,
            template: template);

    test('joins confident signs into a sentence', () {
      final sb = SentenceBuilder(mode: ServiceMode.hospital);
      final build = sb.build([
        CapturedSign(entry: entry('DOKTAR', 'ডাক্তার'), confidence: 0.95),
        CapturedSign(
            entry: entry('BYATHA', 'ব্যথা', template: 'ব্যথা করছে'),
            confidence: 0.9),
      ]);
      expect(build.text, 'ডাক্তার ব্যথা করছে');
      expect(build.hadUncertain, isFalse);
    });

    test('flags uncertain signs with a hedge', () {
      final sb = SentenceBuilder(mode: ServiceMode.hospital);
      final build = sb.build([
        CapturedSign(entry: entry('OSHUDH', 'ওষুধ'), confidence: 0.5),
      ]);
      expect(build.hadUncertain, isTrue);
      expect(build.text, contains('~ওষুধ'));
    });

    test('mode-aware unsure prompt', () {
      final sb = SentenceBuilder(mode: ServiceMode.emergency);
      expect(sb.unsurePrompt(), contains('জরুরি'));
    });
  });

  group('ModelBundle', () {
    test('placeholder yields uniform probabilities', () {
      const bundle = ModelBundle(
        version: 'template-placeholder',
        labels: ['A', 'B', 'unknown'],
        windowFrames: 30,
        stride: 5,
        mean: [],
        std: [],
        weights: [],
        bias: [],
      );
      final probs = bundle.predict(List.filled(10, 0.1));
      expect(probs, hasLength(3));
      for (final p in probs) {
        expect(p, closeTo(1 / 3, 1e-6));
      }
    });

    test('trained weights order candidates by score', () {
      final bundle = ModelBundle(
        version: 'test',
        labels: ['AMI', 'TUMI', 'unknown'],
        windowFrames: 30,
        stride: 5,
        mean: const [],
        std: const [],
        weights: [
          [1.0, 0.0],
          [0.0, 1.0],
          [0.0, 0.0],
        ],
        bias: const [0.1, 0.0, -1.0],
      );
      final probs = bundle.predict([2.0, 0.5]);
      expect(probs[0], greaterThan(probs[1]));
      expect(probs[0], greaterThan(probs[2]));
    });
  });

  group('ConversationController', () {
    test('addSign + commit produces a sentence', () {
      final conv = ConversationController(
        tts: _FakeTts(),
        stt: _FakeStt(),
      );
      final entry = const VocabEntry(
        id: 's003',
        gloss: 'DOKTAR',
        bn: 'ডাক্তার',
        category: 'hospital',
      );
      conv.addSign(entry, 0.9);
      expect(conv.currentSigns, hasLength(1));
      final build = conv.commitSentence();
      expect(build.text, 'ডাক্তার');
      expect(conv.history, isNotEmpty);
      expect(conv.currentSigns, isEmpty);
    });
  });
}

class _FakeTts implements TtsService {
  @override
  Future<void> init() async {}
  @override
  bool get banglaVoiceAvailable => true;
  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> stop() async {}
}

class _FakeStt implements SttService {
  @override
  Future<bool> init() async => true;
  @override
  bool get isListening => false;
  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onText,
    String localeId = 'bn_BD',
  }) async {}
  @override
  Future<void> stop() async {}
}
