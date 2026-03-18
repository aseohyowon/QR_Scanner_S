import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/ad_constants.dart';

enum AdLoadState { loading, loaded, failed }

/// 전면(interstitial) 광고 생명주기 및 스캔 횟수를 관리하는 Provider.
/// 배너 광고는 [BannerAdWidget]이 자체 생명주기를 관리합니다.
class AdProvider extends ChangeNotifier {
  InterstitialAd? _interstitialAd;
  AdLoadState _interstitialState = AdLoadState.loading;
  int _scanCount = 0;

  AdLoadState get interstitialState => _interstitialState;
  int get scanCount => _scanCount;

  AdProvider() {
    _loadInterstitial();
  }

  // ── 전면 광고 로드 ───────────────────────────────────────────────────────

  void _loadInterstitial() {
    _interstitialState = AdLoadState.loading;
    InterstitialAd.load(
      adUnitId: AdConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial(); // 다음 광고 미리 로드
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial(); // 재시도
            },
          );
          _interstitialState = AdLoadState.loaded;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _interstitialState = AdLoadState.failed;
          notifyListeners();
        },
      ),
    );
  }

  // ── 스캔 카운트 증가 및 전면 광고 트리거 ───────────────────────────────

  Future<void> incrementScanCount() async {
    _scanCount++;
    notifyListeners();
    if (_scanCount % AdConstants.interstitialFrequency == 0) {
      await _showInterstitial();
    }
  }

  Future<void> _showInterstitial() async {
    if (_interstitialAd == null) {
      // 아직 로드 중이거나 실패 — 실패 상태면 재시도 예약
      if (_interstitialState == AdLoadState.failed) {
        _loadInterstitial();
      }
      return;
    }
    await _interstitialAd!.show();
    // 광고가 닫힐 때 fullScreenContentCallback에서 dispose + reload 처리
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }
}
