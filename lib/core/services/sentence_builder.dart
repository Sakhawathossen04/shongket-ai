import '../../shared/models/models.dart';

/// Builds natural-ish Bangla sentences from sign sequences and decides when
/// the app should admit uncertainty instead of inventing a translation.
class SentenceBuilder {
  SentenceBuilder({required this.mode});

  ServiceMode mode;

  /// Confidence below which a sign is treated as unsure.
  static const double unsureFloor = 0.60;

  /// Builds a sentence from captured signs. Returns the spoken sentence and
  /// a flag whether any part was uncertain.
  SentenceBuild build(List<CapturedSign> signs) {
    if (signs.isEmpty) {
      return const SentenceBuild(text: '', hadUncertain: false);
    }

    final parts = <String>[];
    var hadUncertain = false;

    for (final s in signs) {
      if (s.entry.id == unknownSignId) {
        hadUncertain = true;
        continue;
      }
      if (s.confidence < unsureFloor) {
        hadUncertain = true;
        parts.add('${_hedge(s.entry.bn)}');
        continue;
      }
      parts.add(_applyTemplate(s.entry));
    }

    final text = _join(parts);
    return SentenceBuild(text: text, hadUncertain: hadUncertain);
  }

  /// The message shown when the last sign was not recognised confidently.
  String unsurePrompt() {
    switch (mode) {
      case ServiceMode.hospital:
        return 'শেষ sign-টি আমি নিশ্চিতভাবে বুঝতে পারিনি। আবার দেখান।';
      case ServiceMode.emergency:
        return 'জরুরি অবস্থায় ভুল বোঝা বিপজ্জনক — sign-টি আবার দেখান।';
      default:
        return 'শেষ sign-টি পরিষ্কার নয়, আবার দেখান।';
    }
  }

  String _hedge(String bn) => '~$bn';

  String _applyTemplate(VocabEntry e) {
    // Mode-aware politeness for government offices.
    if (mode == ServiceMode.government && e.category == 'service') {
      return e.bn;
    }
    return e.template ?? e.bn;
  }

  String _join(List<String> parts) {
    if (parts.isEmpty) return '';
    final buffer = StringBuffer(parts.first);
    for (var i = 1; i < parts.length; i++) {
      buffer.write(' ');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }
}

class SentenceBuild {
  const SentenceBuild({required this.text, required this.hadUncertain});

  final String text;
  final bool hadUncertain;
}
