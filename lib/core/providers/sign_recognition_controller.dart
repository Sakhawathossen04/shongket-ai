import 'dart:ui' as ui show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import '../services/pose_classifier.dart';
import '../services/pose_stream_service.dart';
import '../services/sentence_builder.dart';
import 'app_providers.dart';

/// Drives the sign recognition pipeline for the Sign→Bangla screen:
/// camera → pose landmarks → features → sliding-window classifier →
/// confidence-aware commit into the current sentence.
class SignRecognitionController extends ChangeNotifier {
  SignRecognitionController({
    required AppAssetsController assets,
    required ConversationController conversation,
    void Function(String sentence, bool uncertain)? onCommitted,
  })  : _assets = assets,
        _conversation = conversation,
        _onCommitted = onCommitted;

  final AppAssetsController _assets;
  final ConversationController _conversation;
  final void Function(String sentence, bool uncertain)? _onCommitted;

  /// Exposed for the UI (current sign queue, replay button, etc.).
  ConversationController get conversation => _conversation;

  CameraController? _camera;
  PoseStreamService? _pose;
  bool _busy = false;

  bool cameraReady = false;
  String? cameraError;
  RecognitionResult? lastResult;

  /// Mode-aware sentence builder used by the UI for unsure prompts.
  SentenceBuilder get sentence => SentenceBuilder(mode: AppScope.mode.mode);

  double get aspectRatio => _camera?.value.aspectRatio ?? 3 / 4;
  CameraController? get cameraController => _camera;

  static const int windowFrames = 30;
  static const int windowStride = 5;

  final List<List<double>> _window = <List<double>>[];
  int _framesSinceClassify = 0;
  String? _lastCommittedKey;

  /// Start the rear camera at low resolution for real-time inference.
  Future<void> startCamera() async {
    if (cameraReady) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        cameraError = 'কোনো ক্যামেরা পাওয়া যায়নি';
        notifyListeners();
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final cam = CameraController(
        back,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await cam.initialize();
      _pose ??= PoseStreamService();
      await cam.startImageStream(_onImage);
      _camera = cam;
      cameraReady = true;
      cameraError = null;
      notifyListeners();
    } catch (e) {
      cameraError = 'ক্যামেরা চালু করা যায়নি: $e';
      notifyListeners();
    }
  }

  Future<void> _onImage(CameraImage image) async {
    if (_busy) return; // skip frames while inference is in flight
    _busy = true;
    try {
      final cam = _camera;
      final pose = _pose;
      if (cam == null || pose == null) return;
      final rotation =
          InputImageRotationValue.fromRawValue(
                cam.description.sensorOrientation,
              ) ??
              InputImageRotation.rotation0deg;
      final frame = await pose.process(
        image,
        ui.Size(image.width.toDouble(), image.height.toDouble()),
        rotation,
      );
      if (frame != null) _pushFrame(frame);
    } finally {
      _busy = false;
    }
  }

  void _pushFrame(RawPoseFrame frame) {
    _window.add(extractFeatures([frame]).first);
    if (_window.length > windowFrames) _window.removeAt(0);
    _framesSinceClassify++;
    if (_window.length == windowFrames &&
        _framesSinceClassify >= windowStride) {
      _framesSinceClassify = 0;
      _classifyAndMaybeCommit();
    }
  }

  void _classifyAndMaybeCommit() {
    final clf = _assets.classifier?.classifier;
    if (clf == null) return;
    final result = clf.classify(_window);
    lastResult = result;
    if (result.confident) {
      final key = '${result.top.entry.gloss}@'
          '${(result.top.confidence * 20).round()}';
      if (key != _lastCommittedKey) {
        _lastCommittedKey = key;
        _conversation.addSign(result.top.entry, result.top.confidence);
      }
    }
    notifyListeners();
  }

  /// Manually commit the current sign queue into a spoken sentence.
  void commit() {
    final build = _conversation.commitSentence();
    _onCommitted?.call(build.text, build.hadUncertain);
    resetWindow();
  }

  void resetWindow() {
    _window.clear();
    _framesSinceClassify = 0;
    lastResult = null;
    notifyListeners();
  }

  void pause() {
    try {
      _camera?.pausePreview();
    } catch (_) {}
  }

  void resume() {
    try {
      if (cameraReady) _camera?.resumePreview();
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      _camera?.stopImageStream();
      _camera?.dispose();
    } catch (_) {}
    _pose?.close();
    super.dispose();
  }
}
