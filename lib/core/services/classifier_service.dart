import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../shared/models/models.dart';
import 'pose_classifier.dart';

/// Loads the template model bundle emitted by the Kaggle training pipeline
/// (ml/train_mvp_template.py) and exposes a ready SignClassifier.
class ClassifierService {
  ClassifierService._(this.bundle, this.vocabById);

  final ModelBundle bundle;
  final Map<String, VocabEntry> vocabById;

  late final SignClassifier classifier = SignClassifier(
    bundle: bundle,
    vocabById: vocabById,
  );

  bool get isPlaceholder => bundle.version == 'template-placeholder';

  static Future<ClassifierService> load(
    Map<String, VocabEntry> vocabById,
  ) async {
    final raw = await rootBundle.loadString('assets/models/bdsl_mvp.json');
    final bundle = ModelBundle.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    return ClassifierService._(bundle, vocabById);
  }
}
