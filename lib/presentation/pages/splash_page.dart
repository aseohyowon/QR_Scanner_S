import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../core/constants/app_colors.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

/// Uses three independent AnimationControllers so each animation layer is
/// scoped to the smallest possible subtree — minimising unnecessary rebuilds
/// and avoiding jank on lower-end Android devices.
class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  // ── Entry sequence (1 500 ms, runs once) ─────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double> _iconFade;
  late final Animation<double> _iconScale;
  late final Animation<double> _taglineFade;
  late final Animation<double> _exitFade;

  // ── Pulse (900 ms, reverse-repeat, starts after icon lands) ──────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseGlowAlpha;

  // ── Glow ring (1 600 ms, repeat, starts after icon lands) ────────────────
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowRadius;
  late final Animation<double> _glowAlpha;

  @override
  void initState() {
    super.initState();

    // Remove the native splash on the first frame so Flutter's animated
    // splash (same dark bg + same icon) takes over without any visible jump.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    // ── Entry ────────────────────────────────────────────────────────────
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Fade-in: 0 → 38 %
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOut),
      ),
    );

    // Scale-in: 0 → 52 % — easeOutBack gives a single clean overshoot
    // without the multi-bounce lag of elasticOut.
    _iconScale = Tween<double>(begin: 0.30, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.52, curve: Curves.easeOutBack),
      ),
    );

    // Tagline: 48 → 72 %
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.48, 0.72, curve: Curves.easeOut),
      ),
    );

    // Exit fade-out: 80 → 100 %
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.80, 1.0, curve: Curves.easeInQuart),
      ),
    );

    // ── Pulse ────────────────────────────────────────────────────────────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Subtle scale throb: 1.0 → 1.045
    _pulseScale = Tween<double>(begin: 1.0, end: 1.045).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Glow brightness follows pulse breath
    _pulseGlowAlpha = Tween<double>(begin: 0.50, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // ── Expanding glow ring ──────────────────────────────────────────────
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _glowRadius = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut),
    );

    _glowAlpha = Tween<double>(begin: 0.75, end: 0.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut),
    );

    // Start entry; kick off atmospheric animations once icon has settled.
    // Icon entry ends at 52 % of 1500 ms = ~780 ms.
    _entryCtrl.forward().whenComplete(_navigateHome);
    Future.delayed(const Duration(milliseconds: 790), () {
      if (mounted) {
        _pulseCtrl.repeat(reverse: true);
        _glowCtrl.repeat();
      }
    });
  }

  void _navigateHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomePage(),
        // Fade-out is already handled by _exitFade; zero-duration swap avoids
        // a second transition flash.
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FadeTransition is GPU-composited: the Scaffold subtree is never rebuilt
    // during the exit fade — Flutter just tweaks the layer opacity.
    return FadeTransition(
      opacity: _exitFade,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Animated glow (completely isolated repaint boundary) ──────
            Center(
              child: RepaintBoundary(
                child: _GlowLayer(
                  entryFade: _iconFade,
                  glowRadius: _glowRadius,
                  glowAlpha: _glowAlpha,
                  pulseGlowAlpha: _pulseGlowAlpha,
                ),
              ),
            ),

            // ── Icon + tagline (isolated repaint boundary) ────────────────
            Center(
              child: RepaintBoundary(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stacked transitions: entry scale → pulse scale.
                    // Both use Flutter's built-in *Transition widgets that
                    // skip child rebuild and mutate the layer transform only.
                    FadeTransition(
                      opacity: _iconFade,
                      child: ScaleTransition(
                        scale: _iconScale,
                        child: ScaleTransition(
                          scale: _pulseScale,
                          // CustomPaint never changes → single RepaintBoundary
                          child: const RepaintBoundary(
                            child: _AppIconWidget(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // _TaglineWidget is const → zero rebuild cost
                    FadeTransition(
                      opacity: _taglineFade,
                      child: const _TaglineWidget(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Loading dots (isolated) ───────────────────────────────────
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _taglineFade,
                child: const RepaintBoundary(child: _ProgressDots()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated glow layer ──────────────────────────────────────────────────────
// All glow painting happens on the render thread via CustomPainter.
// AnimatedBuilder is scoped to this widget only — glow repaints never
// propagate upward.

class _GlowLayer extends StatelessWidget {
  final Animation<double> entryFade;
  final Animation<double> glowRadius;
  final Animation<double> glowAlpha;
  final Animation<double> pulseGlowAlpha;

  const _GlowLayer({
    required this.entryFade,
    required this.glowRadius,
    required this.glowAlpha,
    required this.pulseGlowAlpha,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([entryFade, glowRadius, glowAlpha, pulseGlowAlpha]),
      builder: (_, __) {
        return CustomPaint(
          size: const Size(320, 320),
          painter: _GlowPainter(
            entryAlpha: entryFade.value,
            ringRadius: glowRadius.value,
            ringAlpha: glowAlpha.value,
            pulseAlpha: pulseGlowAlpha.value,
          ),
        );
      },
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double entryAlpha;
  final double ringRadius;
  final double ringAlpha;
  final double pulseAlpha;

  const _GlowPainter({
    required this.entryAlpha,
    required this.ringRadius,
    required this.ringAlpha,
    required this.pulseAlpha,
  });

  static const _cyan = AppColors.secondary;
  static const _purple = AppColors.primary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // ── Static inner glow (breathes with pulse) ───────────────────────
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _cyan.withAlpha((pulseAlpha * entryAlpha * 55).round()),
          _purple.withAlpha((pulseAlpha * entryAlpha * 20).round()),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR * 0.65));
    canvas.drawCircle(center, maxR * 0.65, innerPaint);

    // ── Expanding ring wave ────────────────────────────────────────────
    final effectiveRingAlpha = ringAlpha * entryAlpha;
    if (effectiveRingAlpha > 0.005) {
      final ringR = maxR * ringRadius;
      final ringPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            _cyan.withAlpha((effectiveRingAlpha * 50).round()),
            _cyan.withAlpha((effectiveRingAlpha * 20).round()),
            Colors.transparent,
          ],
          stops: const [0.60, 0.80, 0.92, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: ringR));
      canvas.drawCircle(center, ringR, ringPaint);
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.entryAlpha != entryAlpha ||
      old.ringRadius != ringRadius ||
      old.ringAlpha != ringAlpha ||
      old.pulseAlpha != pulseAlpha;
}

// ── Static app icon ──────────────────────────────────────────────────────────
// const constructor — painted once, never rebuilt.

class _AppIconWidget extends StatelessWidget {
  const _AppIconWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF0D1117),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(70),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.primary.withAlpha(45),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const CustomPaint(painter: _IconPainter()),
    );
  }
}

class _IconPainter extends CustomPainter {
  const _IconPainter();

  static const _qrColor = AppColors.secondary;
  static const _frameColor = Color(0xFF29FFA3);

  static const _matrix = [
    [1,1,1,1,1,1,1, 0, 1,1,1,1,1],
    [1,0,0,0,0,0,1, 0, 1,0,0,0,1],
    [1,0,1,1,1,0,1, 0, 1,0,1,0,1],
    [1,0,1,1,1,0,1, 0, 1,0,1,0,1],
    [1,0,1,1,1,0,1, 0, 1,0,0,0,1],
    [1,0,0,0,0,0,1, 0, 0,0,1,0,0],
    [1,1,1,1,1,1,1, 0, 1,0,1,0,1],
    [0,0,0,0,0,0,0, 0, 0,1,0,0,0],
    [1,1,1,1,1,1,1, 1, 0,1,0,1,1],
    [1,0,0,0,0,0,1, 0, 1,0,0,0,1],
    [1,0,1,1,1,0,1, 1, 0,1,0,1,0],
    [1,0,0,0,0,0,1, 0, 1,0,1,0,1],
    [1,1,1,1,1,1,1, 0, 0,1,0,1,1],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final qrPaint = Paint()
      ..color = _qrColor
      ..style = PaintingStyle.fill;
    final framePaint = Paint()
      ..color = _frameColor
      ..style = PaintingStyle.fill;

    const cells = 13;
    final qrArea = size.width * 0.58;
    final ox = (size.width - qrArea) / 2;
    final oy = (size.height - qrArea) / 2;
    final cell = qrArea / cells;
    final gap = cell * 0.10;
    final r = Radius.circular(cell * 0.15);

    for (int row = 0; row < cells; row++) {
      for (int col = 0; col < cells; col++) {
        if (_matrix[row][col] == 1) {
          canvas.drawRRect(
            RRect.fromLTRBR(
              ox + col * cell + gap,
              oy + row * cell + gap,
              ox + col * cell + cell - gap,
              oy + row * cell + cell - gap,
              r,
            ),
            qrPaint,
          );
        }
      }
    }

    // Corner scan-frame brackets
    final margin = size.width * 0.07;
    final arm = size.width * 0.20;
    final t = size.width * 0.045;

    final corners = [
      Offset(margin, margin),
      Offset(size.width - margin, margin),
      Offset(margin, size.height - margin),
      Offset(size.width - margin, size.height - margin),
    ];
    final dirs = [
      const Offset(1, 1),
      const Offset(-1, 1),
      const Offset(1, -1),
      const Offset(-1, -1),
    ];

    for (int i = 0; i < 4; i++) {
      final c = corners[i];
      final d = dirs[i];
      canvas.drawRect(
        Rect.fromLTWH(
            d.dx > 0 ? c.dx : c.dx - arm, d.dy > 0 ? c.dy : c.dy - t, arm, t),
        framePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
            d.dx > 0 ? c.dx : c.dx - t, d.dy > 0 ? c.dy : c.dy - arm, t, arm),
        framePaint,
      );
    }
  }

  // Icon content is immutable — skip repaint entirely.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Static tagline ───────────────────────────────────────────────────────────
// const constructor → Flutter never rebuilds this widget.

class _TaglineWidget extends StatelessWidget {
  const _TaglineWidget();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'QR Scanner',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          '& Generator',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: AppColors.secondary,
            letterSpacing: 2.0,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Scan · Generate · Share',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Animated loading dots ────────────────────────────────────────────────────
// Uses its own AnimationController so the ticker is isolated from the parent.

class _ProgressDots extends StatefulWidget {
  const _ProgressDots();

  @override
  State<_ProgressDots> createState() => _ProgressDotsState();
}

class _ProgressDotsState extends State<_ProgressDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final brightness =
                (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary
                    .withAlpha((40 + brightness * 215).round()),
              ),
            );
          }),
        );
      },
    );
  }
}

