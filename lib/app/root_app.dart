import 'package:flutter/material.dart';

import '../core/providers/app_providers.dart';
import '../features/about/about_screen.dart';
import '../features/communication/sign_to_speech_screen.dart';
import '../features/communication/speech_to_text_screen.dart';
import '../features/emergency/sos_screen.dart';
import '../features/home/home_screen.dart';
import '../features/learning/vocab_screen.dart';
import 'theme.dart';

/// Root widget: MaterialApp + bottom-nav shell. Plain Navigator keeps the
/// dependency list small so CI builds stay fast and predictable.
class ShongketApp extends StatelessWidget {
  const ShongketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shongket AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    AppScope.tabIndex.addListener(_onTabRequest);
  }

  @override
  void dispose() {
    AppScope.tabIndex.removeListener(_onTabRequest);
    super.dispose();
  }

  void _onTabRequest() {
    setState(() => _index = AppScope.tabIndex.value);
  }

  static const _screens = <Widget>[
    HomeScreen(),
    SignToSpeechScreen(),
    SpeechToTextScreen(),
    SosScreen(),
    AboutScreen(),
  ];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'হোম',
    ),
    NavigationDestination(
      icon: Icon(Icons.sign_language_outlined),
      selectedIcon: Icon(Icons.sign_language),
      label: 'Sign→বাংলা',
    ),
    NavigationDestination(
      icon: Icon(Icons.hearing_outlined),
      selectedIcon: Icon(Icons.hearing),
      label: 'শুনে দেখান',
    ),
    NavigationDestination(
      icon: Icon(Icons.emergency_outlined),
      selectedIcon: Icon(Icons.emergency),
      label: 'SOS',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'শব্দকোষ',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}

/// Shared screen scaffold with a big Bangla title.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
