abstract final class AdPolicy {
  static const int minimumMeaningfulActionsBetweenInterstitials = 4;
  static const Duration minimumInterstitialInterval = Duration(minutes: 10);
  static const int maximumInterstitialsPerDay = 3;

  static bool isInterstitialAllowed({
    required int meaningfulActionsSinceLastAd,
    required DateTime? lastInterstitialAt,
    required int interstitialsShownToday,
    required bool isCriticalHealthContext,
    required DateTime now,
  }) {
    if (isCriticalHealthContext) {
      return false;
    }

    if (interstitialsShownToday >= maximumInterstitialsPerDay) {
      return false;
    }

    if (meaningfulActionsSinceLastAd <
        minimumMeaningfulActionsBetweenInterstitials) {
      return false;
    }

    if (lastInterstitialAt != null &&
        now.difference(lastInterstitialAt) < minimumInterstitialInterval) {
      return false;
    }

    return true;
  }
}
