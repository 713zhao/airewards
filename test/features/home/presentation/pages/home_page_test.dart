import 'package:flutter_test/flutter_test.dart';

/// This test file previously exercised a legacy `HomePage` widget and its BLoC.
/// That implementation was removed during the move to the consolidated
/// `MainAppScreen`, so the old tests triggered hundreds of analyzer errors.
///
/// For now we keep a placeholder test to document the gap and keep the test
/// target registered. Once the new Home tab widgets expose testable APIs we can
/// add focused widget tests that mirror the current experience.

void main() {
  test('home dashboard placeholder', () {
    expect(true, isTrue);
  });
}