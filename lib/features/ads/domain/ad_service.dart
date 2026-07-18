enum AdPlacement {
  medicationDashboardBanner,
  inventoryUpdateInterstitial,
}

abstract interface class AdService {
  Future<void> initialize();

  Future<bool> loadBanner(AdPlacement placement);

  Future<bool> showInterstitial(AdPlacement placement);

  Future<void> dispose();
}
