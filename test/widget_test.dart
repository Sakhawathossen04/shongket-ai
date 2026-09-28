import 'package:flutter_test/flutter_test.dart';

/// Exists so `flutter create` (CI scaffold step) does not generate a
/// broken default widget_test referencing a non-existent MyApp.
void main() {
  test('sanity', () {
    expect(1 + 1, 2);
  });
}
