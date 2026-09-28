import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../app/root_app.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/pose_classifier.dart';

/// Deaf → Hearing screen: camera stream → pose landmarks → sign
/// recognition → sentence → TTS. Shows top-3 candidates and an explicit
/// uncertainty state so the app never silently guesses.
class SignToSpeechScreen extends StatefulWidget {
  const SignToSpeechScreen({super.key});

  @override
  State<SignToSpeechScreen> createState() => _SignToSpeechScreenState();
}

class _SignToSpeechScreenState extends State<SignToSpeechScreen>
    with WidgetsBindingObserver {
  SignRecognitionController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller?.resume();
    } else if (state == AppLifecycleState.paused) {
      _controller?.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = AppScope.assets;
    final controller = _controller ??= SignRecognitionController(
      assets: assets,
      conversation: AppScope.conversation,
      onCommitted: _showCommitted,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([controller, assets]),
      builder: (context, _) {
        if (!assets.loaded || assets.vocab == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            const ScreenHeader(
              title: 'Sign → বাংলা',
              subtitle: 'ক্যামেরার সামনে sign করুন — অ্যাপ বাংলায় পড়ে শোনাবে',
            ),
            Expanded(
              child: controller.cameraReady
                  ? AspectRatio(
                      aspectRatio: controller.aspectRatio,
                      child: CameraPreview(controller.cameraController!),
                    )
                  : _CameraStartCard(controller: controller),
            ),
            _RecognitionBar(controller: controller),
          ],
        );
      },
    );
  }

  void _showCommitted(String sentence, bool uncertain) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sentence.isEmpty ? 'কিছু বোঝা যায়নি' : sentence),
        backgroundColor: uncertain ? Colors.orange.shade800 : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _CameraStartCard extends StatelessWidget {
  const _CameraStartCard({required this.controller});

  final SignRecognitionController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              controller.cameraError ?? 'Sign শুরু করতে ক্যামেরা চালু করুন',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.startCamera,
              icon: const Icon(Icons.play_arrow),
              label: const Text('ক্যামেরা চালু করুন'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom strip: current signs, top-3 candidates, commit / clear buttons.
class _RecognitionBar extends StatelessWidget {
  const _RecognitionBar({required this.controller});

  final SignRecognitionController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conversation = controller.conversation;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    conversation.currentSigns.isEmpty
                        ? 'Sign ধরা পড়লে এখানে দেখা যাবে…'
                        : conversation.currentSigns
                            .map((s) => s.entry.bn)
                            .join(' · '),
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'মুছে ফেলুন',
                  onPressed: conversation.clearCurrent,
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _CandidateRow(controller: controller),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.commit,
                    icon: const Icon(Icons.record_voice_over),
                    label: const Text('বাংলায় বলুন'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        conversation.tts.speak(conversation.lastSentence),
                    icon: const Icon(Icons.replay),
                    label: const Text('আবার'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.controller});

  final SignRecognitionController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = controller.lastResult;

    if (last == null) {
      return Text(
        'ক্যামেরা sign দেখছে…',
        style: theme.textTheme.bodySmall,
      );
    }

    final unsure = !last.confident;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unsure)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: theme.colorScheme.error),
                const SizedBox(width: 6),
                Text(
                  controller.sentence.unsurePrompt(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
            ),
          ),
        Row(
          children: [
            for (final c in last.candidates.take(3))
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.entry.bn} ${(c.confidence * 100).round()}%',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      LinearProgressIndicator(
                        value: c.confidence,
                        minHeight: 5,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
