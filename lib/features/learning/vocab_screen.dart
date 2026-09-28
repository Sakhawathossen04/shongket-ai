import 'package:flutter/material.dart';

import '../../app/root_app.dart';
import '../../core/providers/app_providers.dart';

/// Vocabulary browser: all bundled BdSL signs grouped by service mode with
/// search. Educational + lets demo audiences see the supported vocabulary.
class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final assets = AppScope.assets;
    return AnimatedBuilder(
      animation: assets,
      builder: (context, _) {
        final vocab = assets.vocab;
        if (!assets.loaded || vocab == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = vocab.all
            .where((e) =>
                _query.isEmpty ||
                e.bn.contains(_query) ||
                e.gloss.toLowerCase().contains(_query.toLowerCase()))
            .toList(growable: false);

        return Column(
          children: [
            ScreenHeader(
              title: 'শব্দকোষ',
              subtitle: 'অ্যাপে থাকা BdSL sign গুলো দেখুন (${vocab.all.length}টি)',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'বাংলা বা gloss দিয়ে খুঁজুন',
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(modeIconFor(e.category)),
                    ),
                    title: Text(e.bn, style: const TextStyle(fontSize: 18)),
                    subtitle: Text('${e.gloss} · ${e.category}'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Maps a vocab category to an icon for list display.
IconData modeIconFor(String category) {
  switch (category) {
    case 'hospital':
      return Icons.local_hospital;
    case 'emergency':
      return Icons.emergency;
    case 'government':
      return Icons.account_balance;
    case 'emergency_phrase':
      return Icons.emergency;
    default:
      return Icons.chat_bubble_outline;
  }
}
