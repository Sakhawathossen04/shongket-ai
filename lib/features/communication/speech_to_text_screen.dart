import 'package:flutter/material.dart';

import '../../app/root_app.dart';
import '../../core/providers/app_providers.dart';

/// Hearing → Deaf screen: captures Bangla speech and displays it in large
/// text for the Deaf user. Works with the platform recognizer.
class SpeechToTextScreen extends StatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  State<SpeechToTextScreen> createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends State<SpeechToTextScreen> {
  bool _listening = false;
  String _text = '';
  String? _error;

  Future<void> _toggle() async {
    final stt = AppScope.stt;
    if (_listening) {
      await stt.stop();
      if (_text.trim().isNotEmpty) {
        AppScope.conversation.addHeardText(_text);
      }
      setState(() => _listening = false);
      return;
    }
    final ok = await stt.init();
    if (!ok) {
      setState(() => _error = 'মাইক্রোফোন/স্পিচ সার্ভিস চালু করা যায়নি');
      return;
    }
    setState(() {
      _listening = true;
      _error = null;
      _text = '';
    });
    await stt.listen(onText: (text, isFinal) {
      if (mounted) setState(() => _text = text);
      if (isFinal && text.trim().isNotEmpty) {
        AppScope.conversation.addHeardText(text);
      }
    });
  }

  @override
  void dispose() {
    AppScope.stt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const ScreenHeader(
          title: 'শুনে টেক্সট দেখান',
          subtitle: 'কথা বললে বড় করে দেখাবে — বধির ব্যবহারকারী পড়তে পারবেন',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  _text.isEmpty
                      ? 'মাইক চালু করে কথা বলুন…'
                      : _text,
                  style: _text.isEmpty
                      ? theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)
                      : theme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _toggle,
              icon: Icon(_listening ? Icons.stop : Icons.mic),
              label: Text(_listening ? 'থামান' : 'মাইক চালু করুন'),
            ),
          ),
        ),
      ],
    );
  }
}
