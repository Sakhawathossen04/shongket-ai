import 'dart:typed_data';
import 'dart:ui' as ui show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show WriteBuffer;
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'pose_classifier.dart';

/// Runs ML Kit pose detection on camera frames and yields RawPoseFrame
/// landmark vectors compatible with the classifier feature extractor.
class PoseStreamService {
  PoseStreamService({PoseDetectionModel model = PoseDetectionModel.accurate})
      : _detector = PoseDetector(options: PoseDetectorOptions(model: model));

  final PoseDetector _detector;

  /// Detects pose in a camera image and converts it to a RawPoseFrame with
  /// 33 landmarks × (x, y) normalised to [0,1].
  Future<RawPoseFrame?> process(
    CameraImage image,
    ui.Size imageSize,
    InputImageRotation rotation,
  ) async {
    final inputImage = _buildInputImage(image, imageSize, rotation);
    if (inputImage == null) return null;
    try {
      final poses = await _detector.processImage(inputImage);
      if (poses.isEmpty) return null;
      final lm = poses.first.landmarks;
      final points = List<double?>.filled(33 * 2, null);
      for (final e in lm.entries) {
        // PoseLandmarkType enum order matches MediaPipe 0..32 indices.
        final idx = e.key.index;
        points[idx * 2] = e.value.x / imageSize.width;
        points[idx * 2 + 1] = e.value.y / imageSize.height;
      }
      return RawPoseFrame(points, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      return null;
    }
  }

  InputImage? _buildInputImage(
    CameraImage image,
    ui.Size imageSize,
    InputImageRotation rotation,
  ) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // Concatenate all planes (single plane for NV21, three for YUV420).
    final WriteBuffer buffer = WriteBuffer();
    for (final plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final Uint8List bytes = buffer.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  void close() {
    _detector.close();
  }
}
