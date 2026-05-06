import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../providers/qr_scanner_provider.dart';
import '../widgets/qr_result_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/scan_line.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QrScannerProvider>().initController();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<QrScannerProvider>().disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<QrScannerProvider>();
    final controller = provider.controller;
    if (controller == null) return;
    if (state == AppLifecycleState.resumed) {
      controller.start();
    } else if (state == AppLifecycleState.paused) {
      controller.stop();
    }
  }

  Future<void> _pickFromGallery(
      BuildContext context, QrScannerProvider provider) async {
    final error = await provider.pickFromGallery();
    if (error == 'no_qr' && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.noQrFound),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.scannerTitle),
        actions: [
          Consumer<QrScannerProvider>(
            builder: (context, provider, _) => Row(
              children: [
                IconButton(
                  icon: Icon(
                    provider.torchEnabled
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: provider.torchEnabled
                        ? AppColors.warning
                        : AppColors.textSecondary,
                  ),
                  onPressed: provider.state == ScanState.scanning
                      ? provider.toggleTorch
                      : null,
                  tooltip: provider.torchEnabled
                      ? AppStrings.torchOff
                      : AppStrings.torchOn,
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_android_rounded),
                  onPressed: provider.state == ScanState.scanning
                      ? provider.flipCamera
                      : null,
                  tooltip: AppStrings.flipCamera,
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library_rounded),
                  onPressed: provider.state == ScanState.scanning
                      ? () => _pickFromGallery(context, provider)
                      : null,
                  tooltip: AppStrings.scanFromGallery,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<QrScannerProvider>(
        builder: (context, provider, _) {
          if (provider.state == ScanState.result &&
              provider.lastResult != null) {
            return _ResultView(provider: provider);
          }
          return _ScannerView(provider: provider);
        },
      ),
    );
  }
}

// ─── Scanner view ────────────────────────────────────────────────────────────
class _ScannerView extends StatelessWidget {
  final QrScannerProvider provider;
  const _ScannerView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final controller = provider.controller;
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Stack(
      children: [
        // 카메라 피드 + 권한/에러 처리
        MobileScanner(
          controller: controller,
          onDetect: provider.onBarcodeDetected,
          errorBuilder: (context, error, _) {
            if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
              return const _PermissionDeniedView();
            }
            return _CameraErrorView(
              message: error.errorDetails?.message ?? AppStrings.errorOccurred,
            );
          },
        ),

        // 어두운 오버레이 (중앙 투명 컷아웃)
        CustomPaint(
          painter: _ScannerOverlayPainter(),
          child: const SizedBox.expand(),
        ),

        // 코너 프레임
        const Center(child: _ScanFrame()),

        // 실시간 스캔 라인 애니메이션
        const Center(child: AnimatedScanLine()),

        // 하단 힌트 텍스트
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                AppStrings.scannerHint,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Scanner frame corners ────────────────────────────────────────────────────
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    const size = 240.0;
    const cornerLen = 28.0;
    const cornerWidth = 4.0;
    const radius = 12.0;
    const color = AppColors.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Top-left
          Positioned(
            top: 0,
            left: 0,
            child: _Corner(cornerLen, cornerWidth, radius, color,
                topLeft: true),
          ),
          // Top-right
          Positioned(
            top: 0,
            right: 0,
            child: _Corner(cornerLen, cornerWidth, radius, color,
                topRight: true),
          ),
          // Bottom-left
          Positioned(
            bottom: 0,
            left: 0,
            child: _Corner(cornerLen, cornerWidth, radius, color,
                bottomLeft: true),
          ),
          // Bottom-right
          Positioned(
            bottom: 0,
            right: 0,
            child: _Corner(cornerLen, cornerWidth, radius, color,
                bottomRight: true),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final double len;
  final double width;
  final double radius;
  final Color color;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _Corner(this.len, this.width, this.radius, this.color,
      {this.topLeft = false,
      this.topRight = false,
      this.bottomLeft = false,
      this.bottomRight = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: len,
      height: len,
      child: CustomPaint(
        painter: _CornerPainter(
          width: width,
          radius: radius,
          color: color,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double width;
  final double radius;
  final Color color;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  _CornerPainter({
    required this.width,
    required this.radius,
    required this.color,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final r = radius;
    final w = size.width;
    final h = size.height;

    if (topLeft) {
      path.moveTo(0, h);
      path.lineTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
      path.lineTo(w, 0);
    } else if (topRight) {
      path.moveTo(0, 0);
      path.lineTo(w - r, 0);
      path.quadraticBezierTo(w, 0, w, r);
      path.lineTo(w, h);
    } else if (bottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, h - r);
      path.quadraticBezierTo(0, h, r, h);
      path.lineTo(w, h);
    } else if (bottomRight) {
      path.moveTo(0, h);
      path.lineTo(w - r, h);
      path.quadraticBezierTo(w, h, w, h - r);
      path.lineTo(w, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Dark overlay painter ────────────────────────────────────────────────────
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cutoutSize = 240.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final cutout = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: cutoutSize,
        height: cutoutSize,
      ),
      const Radius.circular(12),
    );

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(cutout)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withAlpha(160),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Result view ─────────────────────────────────────────────────────────────
class _ResultView extends StatefulWidget {
  final QrScannerProvider provider;
  const _ResultView({required this.provider});

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 성공 아이콘 (스케일 애니메이션)
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.success.withAlpha(120), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withAlpha(60),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.success, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.scanResult,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              QrResultCard(result: widget.provider.lastResult!),
              const SizedBox(height: 28),
              GradientButton(
                label: AppStrings.scanAgain,
                icon: Icons.qr_code_scanner_rounded,
                width: double.infinity,
                onPressed: widget.provider.resetScan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 카메라 권한 거부 UI ─────────────────────────────────────────────────────
class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.error.withAlpha(80), width: 2),
                ),
                child: const Icon(Icons.no_photography_rounded,
                    color: AppColors.error, size: 44),
              ),
              const SizedBox(height: 24),
              const Text(
                '카메라 권한 필요',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'QR 코드를 스캔하려면 카메라 접근 권한이 필요합니다.\n\n설정 앱에서 이 앱의 카메라 권한을 허용해 주세요.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // 설정 안내 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepRow(step: '1', text: '기기 설정 앱 열기'),
                    SizedBox(height: 8),
                    _StepRow(step: '2', text: '앱 → QR Scanner 선택'),
                    SizedBox(height: 8),
                    _StepRow(step: '3', text: '권한 → 카메라 허용'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String step;
  final String text;

  const _StepRow({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(40),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withAlpha(100)),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ─── 카메라 일반 에러 UI ─────────────────────────────────────────────────────
class _CameraErrorView extends StatelessWidget {
  final String message;

  const _CameraErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.videocam_off_rounded,
                    color: AppColors.error, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                '카메라를 시작할 수 없습니다',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
