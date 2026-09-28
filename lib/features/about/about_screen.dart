import 'package:flutter/material.dart';

import '../../app/root_app.dart';
import '../../core/providers/app_providers.dart';

/// About screen: project positioning, honest model status and credits.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assets = AppScope.assets;
    return AnimatedBuilder(
      animation: assets,
      builder: (context, _) {
        final model = assets.classifier;
        final placeholder = model == null || model.isPlaceholder;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const ScreenHeader(
              title: 'সম্পর্কে',
              subtitle: 'Shongket AI — offline, confidence-aware BdSL communication',
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Model status', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                placeholder ? Icons.info_outline : Icons.verified,
                                color: placeholder
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  placeholder
                                      ? 'Template placeholder — প্রকৃত trained model Kaggle pipeline থেকে আসবে'
                                      : 'Trained model loaded (v${model.bundle.version})',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('কীভাবে কাজ করে', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          const Text(
                            'ক্যামেরা → MediaPipe/ML Kit pose landmarks → '
                            'নরমালাইজড feature (nose-centred, shoulder-scaled) → '
                            '৩০-frame sliding window classifier → sign → '
                            'confidence-aware বাংলা বাক্য → TTS। সব কিছু '
                            'ডিভাইসেই চলে, ইন্টারনেট লাগে না।',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Credits', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          const Text(
                            '• Architecture pattern inspired by KawanIsyarat (MIT)\n'
                            '• BdSL research: BdSLW401 dataset & RQE paper '
                            '(Rubaiyeat et al., 2025)\n'
                            '• Built for ZRF, Bangladesh',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
