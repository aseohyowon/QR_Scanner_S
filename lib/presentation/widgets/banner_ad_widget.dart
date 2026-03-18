import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/ad_constants.dart';
import '../../core/constants/app_colors.dart';

enum _BannerState { loading, loaded, failed }

/// 배너 광고 위젯 — 자체 생명주기 관리 (로드·표시·해제).
/// 로드 중에는 로딩 인디케이터, 실패 시 0 높이로 자동 숨김.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  _BannerState _state = _BannerState.loading;
  AdSize _adSize = AdSize.banner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 위젯 트리에서 처음 마운트될 때 한 번만 로드
    if (_bannerAd == null && _state == _BannerState.loading) {
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    // 화면 너비에 맞춘 adaptive 배너 크기 요청
    final width = MediaQuery.of(context).size.width.truncate();
    final adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted) return;

    final size = adaptiveSize ?? AdSize.banner;
    setState(() => _adSize = size);

    final ad = BannerAd(
      adUnitId: AdConstants.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _state = _BannerState.loaded);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _state = _BannerState.failed;
          });
        },
      ),
    )..load();

    if (mounted) setState(() => _bannerAd = ad);
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _BannerState.failed => const SizedBox.shrink(),
      _BannerState.loading => _BannerShimmer(height: _adSize.height.toDouble()),
      _BannerState.loaded => _LoadedBanner(
          ad: _bannerAd!,
          height: _adSize.height.toDouble(),
        ),
    };
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────────────────

class _LoadedBanner extends StatelessWidget {
  final BannerAd ad;
  final double height;

  const _LoadedBanner({required this.ad, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: AdWidget(ad: ad),
    );
  }
}

class _BannerShimmer extends StatefulWidget {
  final double height;

  const _BannerShimmer({required this.height});

  @override
  State<_BannerShimmer> createState() => _BannerShimmerState();
}

class _BannerShimmerState extends State<_BannerShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: widget.height,
        color: AppColors.cardBackground,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
