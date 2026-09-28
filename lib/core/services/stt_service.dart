import 'package:speech_to_text/speech_to_text.dart';

/// Listens to Bangla speech and returns the recognised text so the Deaf
/// user can read it. Uses the platform recognizer (works offline on most
/// Android 10+ devices once the language pack is downloaded).
class SttService {
  final SpeechToText _stt = SpeechToText();
  bool _available = false;

  Future<bool> init() async {
    if (_available) return true;
    try {
      _available = await _stt.initialize();
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  bool get isListening => _stt.isListening;

  /// Starts listening; results arrive through [onText] (final and partial).
  Future<void> listen({
    required void Function(String text, bool isFinal) onText,
    String localeId = 'bn_BD',
  }) async {
    if (!_available) {
      final ok = await init();
      if (!ok) {
        onText('শোনা শুরু করা যায়নি — মাইক্রোফোন অনুমতি দিন', true);
        return;
      }
    }
    await _stt.listen(
      onResult: (r) => onText(r.recognizedWords, r.finalResult),
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (_) {}
  }
}
