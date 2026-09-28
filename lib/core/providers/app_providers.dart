import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/models.dart';
import '../services/classifier_service.dart';
import '../services/sentence_builder.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/vocab_service.dart';

/// Currently selected essential-service mode.
class ModeController extends ChangeNotifier {
  ServiceMode _mode = ServiceMode.hospital;

  ServiceMode get mode => _mode;

  void setMode(ServiceMode m) {
    if (m == _mode) return;
    _mode = m;
    // Keep the sentence builder's mode in sync so unsure-prompts match.
    AppScope.conversation.currentMode = m;
    notifyListeners();
  }
}

/// Loads vocab + model once at startup.
class AppAssetsController extends ChangeNotifier {
  AppAssetsController();

  VocabService? vocab;
  ClassifierService? classifier;
  bool loaded = false;
  String? error;

  Future<void> load() async {
    if (loaded) return;
    try {
      final v = await VocabService.load();
      vocab = v;
      classifier = await ClassifierService.load(
        {for (final e in v.all) e.gloss: e},
      );
      loaded = true;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }
}

/// Recognised sentence queue + conversation history.
class ConversationController extends ChangeNotifier {
  ConversationController({required this.tts, required this.stt});

  final TtsService tts;
  final SttService stt;

  final List<CapturedSign> currentSigns = [];
  final List<ConversationTurn> history = [];

  String lastSentence = '';
  bool lastHadUncertain = false;

  /// Called when the classifier commits a sign for the current sentence.
  void addSign(VocabEntry entry, double confidence) {
    currentSigns.add(CapturedSign(entry: entry, confidence: confidence));
    notifyListeners();
  }

  /// Builds the sentence, speaks it and archives the turn.
  SentenceBuild commitSentence() {
    final sb = SentenceBuilder(mode: _currentMode);
    final build = sb.build(currentSigns);
    lastSentence = build.text;
    lastHadUncertain = build.hadUncertain;
    if (build.text.isNotEmpty) {
      history.insert(
        0,
        ConversationTurn(
          text: build.text,
          direction: CommDirection.deafToHearing,
          timestamp: DateTime.now(),
        ),
      );
      tts.speak(build.text);
    }
    currentSigns.clear();
    notifyListeners();
    return build;
  }

  /// Hearing → Deaf: store the recognised speech as a readable turn.
  void addHeardText(String text) {
    if (text.trim().isEmpty) return;
    history.insert(
      0,
      ConversationTurn(
        text: text,
        direction: CommDirection.hearingToDeaf,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void clearCurrent() {
    currentSigns.clear();
    notifyListeners();
  }

  ServiceMode _currentMode = ServiceMode.hospital;
  set currentMode(ServiceMode m) {
    _currentMode = m;
  }

  /// Persists history between sessions (best-effort).
  Future<void> saveHistory() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('shongket_history',
          jsonEncode(history.take(50).map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> restoreHistory() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('shongket_history');
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      history
        ..clear()
        ..addAll(list.map((e) => ConversationTurn.fromJson(e)));
      notifyListeners();
    } catch (_) {}
  }
}

/// Tiny service locator used instead of full Riverpod to keep the
/// dependency footprint small and the CI build fast.
class AppScope {
  AppScope._();

  static final ModeController mode = ModeController();
  static final AppAssetsController assets = AppAssetsController();
  static final TtsService tts = TtsService();
  static final SttService stt = SttService();
  static late final ConversationController conversation = ConversationController(
    tts: tts,
    stt: stt,
  );

  /// Selected bottom-nav tab; screens can switch tabs without context.
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  static Future<void> bootstrap() async {
    await tts.init();
    await conversation.restoreHistory();
    await assets.load();
  }
}
