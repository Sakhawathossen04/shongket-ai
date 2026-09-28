import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shongket_ai/app/constants.dart';
import 'package:shongket_ai/shared/models/models.dart';

void main() {
  test('mode meta covers all service modes', () {
    for (final mode in ServiceMode.values) {
      expect(modeMeta[mode], isNotNull, reason: 'missing meta for $mode');
      expect(modeMeta[mode]!.label, isNotEmpty);
    }
  });

  testWidgets('ScreenHeader renders title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ScreenHeader(title: 'শংকেট AI')),
      ),
    );
    expect(find.text('শংকেট AI'), findsOneWidget);
  });
}
