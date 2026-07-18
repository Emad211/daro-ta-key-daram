import 'package:daro_ta_key_daram/features/ads/domain/ad_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdPolicy', () {
    final DateTime now = DateTime.utc(2026, 7, 18, 12);

    test('blocks ads in critical health context', () {
      final bool allowed = AdPolicy.isInterstitialAllowed(
        meaningfulActionsSinceLastAd: 10,
        lastInterstitialAt: null,
        interstitialsShownToday: 0,
        isCriticalHealthContext: true,
        now: now,
      );

      expect(allowed, isFalse);
    });

    test('allows ad when all frequency rules are satisfied', () {
      final bool allowed = AdPolicy.isInterstitialAllowed(
        meaningfulActionsSinceLastAd: 4,
        lastInterstitialAt: now.subtract(const Duration(minutes: 15)),
        interstitialsShownToday: 1,
        isCriticalHealthContext: false,
        now: now,
      );

      expect(allowed, isTrue);
    });

    test('blocks ad when daily cap is reached', () {
      final bool allowed = AdPolicy.isInterstitialAllowed(
        meaningfulActionsSinceLastAd: 10,
        lastInterstitialAt: null,
        interstitialsShownToday: 3,
        isCriticalHealthContext: false,
        now: now,
      );

      expect(allowed, isFalse);
    });
  });
}
