import 'package:flutter_tts/flutter_tts.dart';

/// Speaks Bangla text aloud. Works fully offline with the platform TTS
/// engine; on most Android devices Google TTS provides a bn-BD voice.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _bnVoiceAvailable = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      final langs = await _tts.getLanguages;
      final list = (langs is List) ? langs.map((e) => e.toString()).toList() : <String>[];
      _bnVoiceAvailable =
          list.contains('bn-BD') || list.contains('bn_IN') || list.contains('bn');
      await _tts.setLanguage(_bnVoiceAvailable ? 'bn-BD' : 'en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  bool get banglaVoiceAvailable => _bnVoiceAvailable;

  Future<void> speak(String text) async {
    if (!_ready) await init();
    if (text.trim().isEmpty) return;
    try {
      await _tts.setLanguage(_bnVoiceAvailable ? 'bn-BD' : 'en-US');
      await _tts.speak(text);
    } catch (_) {
      // TTS failures must never crash the conversation flow.
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
