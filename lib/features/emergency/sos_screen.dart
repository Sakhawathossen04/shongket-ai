import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/root_app.dart';
import '../../core/providers/app_providers.dart';

/// Emergency SOS screen: one-tap phrases the Deaf user can show or play
/// aloud, with confidence-free, pre-written Bangla sentences only —
/// nothing ambiguous in an emergency.
class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  static const _phrases = <String>[
    'আমি বধির। আমি কথা শুনতে পারি না।',
    'আমার চিকিৎসা প্রয়োজন।',
    'অ্যাম্বুলেন্স ডাকুন।',
    'আমার পরিবারের সাথে যোগাযোগ করুন।',
    'আমার ওষুধ দরকার।',
    'আমি ব্যথায় আছি।',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const ScreenHeader(
          title: 'জরুরি কার্ড',
          subtitle: 'এক ট্যাপে বড় করে দেখান বা বাংলায় শোনান',
        ),
        for (final phrase in _phrases)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Card(
              child: ListTile(
                title: Text(
                  phrase,
                  style: theme.textTheme.titleMedium,
                ),
                trailing: const Icon(Icons.volume_up),
                onTap: () => AppScope.tts.speak(phrase),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.emergencyRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              const all = 'আমি বধির। আমার চিকিৎসা প্রয়োজন। অনুগ্রহ করে সাহায্য করুন।';
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text(
                    'আমি বধির — সাহায্য দরকার',
                    style: TextStyle(fontSize: 24),
                  ),
                  content: const Text(
                    'আমি কথা শুনতে পারি না। অনুগ্রহ করে লিখে বা ইশারায় বলুন।',
                    style: TextStyle(fontSize: 20),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('বন্ধ করুন'),
                    ),
                  ],
                ),
              );
              AppScope.tts.speak('আমি বধির। আমার চিকিৎসা প্রয়োজন। অনুগ্রহ করে সাহায্য করুন।');
            },
            icon: const Icon(Icons.emergency, size: 28),
            label: const Text(
              'সর্বোচ্চ জরুরি বার্তা দেখান',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}
