import '../domain/ad_service.dart';

class NoopAdService implements AdService {
  const NoopAdService();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> loadBanner(AdPlacement placement) async => false;

  @override
  Future<bool> showInterstitial(AdPlacement placement) async => false;
}
