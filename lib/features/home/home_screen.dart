import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/root_app.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/models/models.dart';

/// Home dashboard: service mode, word of the day, quick actions.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([AppScope.mode, AppScope.assets]),
      builder: (context, _) {
        final mode = AppScope.mode.mode;
        final vocab = AppScope.assets.vocab;
        final wotd = (vocab == null || vocab.all.isEmpty)
            ? null
            : _wordOfDay(vocab.all);

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const ScreenHeader(
              title: 'শংকেট AI',
              subtitle: 'বধির ও শ্রবণশক্তি প্রতিবন্ধী যোগাযোগ সঙ্গী',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in ServiceMode.values)
                    ChoiceChip(
                      label: Text(modeMeta[m]!.label),
                      selected: mode == m,
                      onSelected: (_) => AppScope.mode.setMode(m),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (wotd != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('আজকের শব্দ',
                            style: theme.textTheme.labelMedium),
                        const SizedBox(height: 6),
                        Text(wotd.bn,
                            style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text('gloss: ${wotd.gloss} · ${wotd.category}',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.sign_language),
                      title: const Text('Sign → বাংলা কথা'),
                      subtitle: const Text('Camera-র সামনে sign করুন'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => AppScope.tabIndex.value = 1,
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.hearing),
                      title: const Text('শুনে টেক্সট দেখান'),
                      subtitle: const Text('কথা বললে বড় করে দেখাবে'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => AppScope.tabIndex.value = 2,
                    ),
                  ),
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: ListTile(
                      leading: Icon(
                        Icons.emergency,
                        color: theme.colorScheme.error,
                      ),
                      title: const Text('জরুরি কার্ড (SOS)'),
                      subtitle: const Text('এক ট্যাপে জরুরি বার্তা শোনান'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => AppScope.tabIndex.value = 3,
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

  /// Deterministic word-of-the-day from the bundled vocabulary.
  static VocabEntry _wordOfDay(List<VocabEntry> entries) {
    final day = DateTime.now()
        .toUtc()
        .difference(DateTime.utc(2026, 1, 1))
        .inDays;
    return entries[day % entries.length];
  }
}
