import 'dart:io';

/// AdMob 광고 단위 ID 상수.
/// 현재 Google 공식 테스트 ID를 사용합니다.
/// 배포 전 실제 앱 ID와 광고 단위 ID로 교체하세요.
class AdConstants {
  AdConstants._();

  // ── App IDs (AndroidManifest.xml / Info.plist 에 별도 설정) ──────────────

  /// Interstitial 광고 단위 ID (플랫폼별 테스트)
  static String get interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  /// Banner 광고 단위 ID (플랫폼별 테스트)
  static String get bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  /// 전면 광고 노출 주기 (스캔 횟수 기준)
  static const int interstitialFrequency = 3;
}
