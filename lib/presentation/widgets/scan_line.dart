import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 스캐너 뷰 안에서 위아래로 움직이는 그라디언트 스캔 라인 애니메이션
class AnimatedScanLine extends StatefulWidget {
  const AnimatedScanLine({super.key});

  @override
  State<AnimatedScanLine> createState() => _AnimatedScanLineState();
}

class _AnimatedScanLineState extends State<AnimatedScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => CustomPaint(
        painter: _ScanLinePainter(_animation.value),
        child: const SizedBox(width: 240, height: 240),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;

  const _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = 6 + (size.height - 12) * progress;

    // 메인 라인
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, y),
          Offset(size.width, y),
          [
            Colors.transparent,
            AppColors.primary.withAlpha(220),
            AppColors.secondary,
            AppColors.primary.withAlpha(220),
            Colors.transparent,
          ],
          const [0.0, 0.2, 0.5, 0.8, 1.0],
        )
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // 글로우 효과 (넓고 투명한 레이어)
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, y),
          Offset(size.width, y),
          [
            Colors.transparent,
            AppColors.primary.withAlpha(50),
            AppColors.secondary.withAlpha(70),
            AppColors.primary.withAlpha(50),
            Colors.transparent,
          ],
          const [0.0, 0.2, 0.5, 0.8, 1.0],
        )
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter old) =>
      old.progress != progress;
}
