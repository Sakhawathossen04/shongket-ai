import 'dart:math' as math;

import '../../shared/models/models.dart';

/// Number of pose keypoints used per frame (MediaPipe/ML Kit upper-body set).
/// Must match ml/train_mvp_template.py KEYPOINT_INDICES length (17).
const int poseKeypointCount = 17;

/// Floating feature size per frame: keypoints (x2) + deriv (x2) = 76.
const int poseFeatureSize = poseKeypointCount * 4;

/// Landmark indices in MediaPipe Pose (33-point model) that we keep.
/// Upper body: nose, eyes(4), ears(2), shoulders(2), elbows(2), wrists(2),
/// pinkies(2), index fingers(2), thumbs(2).
const List<int> poseKeypointIndices = [
  0, // nose
  2, 5, // eyes
  7, 8, // ears
  11, 12, // shoulders
  13, 14, // elbows
  15, 16, // wrists
  17, 18, // pinkies
  19, 20, // index
  21, 22, // thumbs
];

/// One frame of landmarks with extraction helpers.
class RawPoseFrame {
  const RawPoseFrame(this.points, this.tMillis);

  /// x,y for every MediaPipe landmark index (length 33*2) or null if missing.
  final List<double?> points;
  final int tMillis;

  double? x(int i) => (i * 2 < points.length) ? points[i * 2] : null;
  double? y(int i) => (i * 2 + 1 < points.length) ? points[i * 2 + 1] : null;
}

/// Converts raw MediaPipe frames into the normalised 76-float feature
/// representation used by the classifier: nose-centred, shoulder-scaled,
/// with temporal derivatives, plus a visibility flag.
List<List<double>> extractFeatures(List<RawPoseFrame> frames) {
  final normalised = <List<double>>[];

  // First pass: centre + scale.
  for (final f in frames) {
    final noseX = f.x(0);
    final noseY = f.y(0);
    final lsX = f.x(11), lsY = f.y(11);
    final rsX = f.x(12), rsY = f.y(12);

    // Shoulder-centroid reference; fall back to nose if missing.
    final refX = (lsX != null && rsX != null) ? (lsX + rsX) / 2 : noseX;
    final refY = (lsY != null && rsY != null) ? (lsY + rsY) / 2 : noseY;
    final scale = (lsX != null && rsX != null && lsY != null && rsY != null)
        ? math.max(1e-4, math.sqrt(math.pow(rsX - lsX, 2) + math.pow(rsY - lsY, 2)))
        : 1.0;

    final row = List<double>.filled(poseFeatureSize, 0.0);
    for (var k = 0; k < poseKeypointCount; k++) {
      final mi = poseKeypointIndices[k];
      final px = f.x(mi), py = f.y(mi);
      if (px == null || py == null || refX == null || refY == null) {
        continue; // stays 0, invisible
      }
      row[k * 2] = (px - refX) / scale;
      row[k * 2 + 1] = (py - refY) / scale;
    }
    normalised.add(row);
  }

  // Second pass: temporal derivatives + visibility.
  final out = <List<double>>[];
  for (var i = 0; i < normalised.length; i++) {
    final prev = i > 0 ? normalised[i - 1] : normalised[i];
    final cur = normalised[i];
    final row = List<double>.filled(poseFeatureSize, 0.0);
    var anyVisible = false;
    for (var j = 0; j < poseFeatureSize; j++) {
      final v = cur[j];
      final d = (i > 0) ? v - prev[j] : 0.0;
      row[j] = v; // keep normalised value
      if (j >= poseKeypointCount * 2) {
        row[j] = d; // second half = derivative
      }
      if (v != 0.0) anyVisible = true;
    }
    if (!anyVisible) row[0] = 1e-6; // avoid all-zero rows breaking CNN
    out.add(row);
  }
  return out;
}

/// Temporary: classifier weights are emitted by the Kaggle pipeline
/// (see ml/train_mvp_template.py). This bundle is what the app loads.
class ModelBundle {
  const ModelBundle({
    required this.version,
    required this.labels,
    required this.windowFrames,
    required this.stride,
    required this.mean,
    required this.std,
    required this.weights,
    required this.bias,
  });

  final String version;
  final List<String> labels;
  final int windowFrames;
  final int stride;
  final List<double> mean;
  final List<double> std;
  final List<List<double>> weights; // [classes][features]
  final List<double> bias;

  factory ModelBundle.fromJson(Map<String, dynamic> json) => ModelBundle(
        version: json['version'] as String? ?? '0',
        labels: (json['labels'] as List).cast<String>(),
        windowFrames: json['window_frames'] as int? ?? 30,
        stride: json['stride'] as int? ?? 10,
        mean: (json['mean'] as List).cast<num>().map((e) => e.toDouble()).toList(),
        std: (json['std'] as List).cast<num>().map((e) => e.toDouble()).toList(),
        weights: (json['weights'] as List)
            .map((r) => (r as List).cast<num>().map((e) => e.toDouble()).toList())
            .toList(),
        bias: (json['bias'] as List).cast<num>().map((e) => e.toDouble()).toList(),
      );

  /// Softmax over normalised features (linear template classifier).
  /// An empty weight matrix (placeholder bundle) yields uniform
  /// probabilities, so nothing ever passes the confidence threshold
  /// until a real trained model is loaded.
  List<double> predict(List<double> features) {
    final n = weights.length;
    if (n == 0) {
      return List<double>.filled(
        labels.isEmpty ? 1 : labels.length,
        1 / (labels.isEmpty ? 1 : labels.length),
      );
    }
    final scores = List<double>.filled(n, 0.0);
    for (var c = 0; c < n; c++) {
      final w = weights[c];
      var s = bias[c];
      for (var j = 0; j < w.length && j < features.length; j++) {
        s += w[j] * features[j];
      }
      scores[c] = s;
    }
    return _softmax(scores);
  }

  static List<double> _softmax(List<double> x) {
    final m = x.reduce(math.max);
    final exps = x.map((v) => math.exp(v - m)).toList();
    final sum = exps.fold<double>(0, (a, b) => a + b);
    return exps.map((v) => v / sum).toList();
  }
}

/// Sliding-window classifier producing per-window recognition results.
class SignClassifier {
  SignClassifier({required this.bundle, required this.vocabById});

  final ModelBundle bundle;
  final Map<String, VocabEntry> vocabById;

  /// Minimum confidence to accept a sign.
  final double acceptThreshold = 0.60;

  /// Below this we explicitly say "not sure".
  final double unsureThreshold = 0.45;

  /// Classifies one window of already-extracted features.
  RecognitionResult classify(List<List<double>> windowFeatures) {
    final fDim = poseFeatureSize;
    final perFrame = List<double>.filled(fDim, 0.0);
    for (var j = 0; j < fDim; j++) {
      var sum = 0.0;
      for (final frame in windowFeatures) {
        sum += frame[j];
      }
      perFrame[j] = sum / windowFeatures.length;
    }

    // Normalise with bundle mean/std, flattened per-frame dim.
    final norm = List<double>.filled(fDim, 0.0);
    for (var j = 0; j < fDim; j++) {
      final mu = j < bundle.mean.length ? bundle.mean[j] : 0.0;
      final sd = j < bundle.std.length && bundle.std[j] > 0
          ? bundle.std[j]
          : 1.0;
      norm[j] = (perFrame[j] - mu) / sd;
    }

    final probs = bundle.predict(norm);

    // Sort candidates by probability.
    final idx = List<int>.generate(probs.length, (i) => i);
    idx.sort((a, b) => probs[b].compareTo(probs[a]));

    final candidates = <RecognitionCandidate>[];
    for (final i in idx.take(4)) {
      final label = i < bundle.labels.length ? bundle.labels[i] : unknownSignId;
      final entry = vocabById[label] ?? _unknownEntry();
      candidates.add(
        RecognitionCandidate(entry: entry, confidence: probs[i]),
      );
    }

    final top = candidates.first;
    final confident = top.confidence >= acceptThreshold && !top.isUnknown;
    return RecognitionResult(
      top: top,
      candidates: candidates,
      confident: confident,
    );
  }

  VocabEntry _unknownEntry() => const VocabEntry(
        id: unknownSignId,
        gloss: 'UNKNOWN',
        bn: 'বুঝতে পারিনি',
        category: 'system',
      );
}
