import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../providers/qr_generator_provider.dart';
import '../widgets/gradient_button.dart';

// ─── QR 입력 타입 ─────────────────────────────────────────────────────────────
enum QrInputType {
  text('텍스트', Icons.text_fields_rounded, '입력할 텍스트를 작성하세요'),
  url('URL', Icons.link_rounded, 'https://example.com'),
  email('이메일', Icons.email_outlined, 'user@example.com'),
  phone('전화', Icons.phone_rounded, '+82 10-1234-5678');

  final String label;
  final IconData icon;
  final String hint;

  const QrInputType(this.label, this.icon, this.hint);
}

// ─── Page ────────────────────────────────────────────────────────────────────
class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  late final TextEditingController _textController;
  final GlobalKey _qrKey = GlobalKey();
  QrInputType _selectedType = QrInputType.text;
  bool _isSaving = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ── QR 위젯을 PNG 바이트로 캡처 ─────────────────────────────────────────
  Future<Uint8List?> _captureQr() async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  // ── 갤러리 저장 ──────────────────────────────────────────────────────────
  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _captureQr();
      if (bytes == null || !mounted) return;

      // 갤러리 권한 확인 및 저장
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putImageBytes(
        bytes,
        name: 'qr_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        _showSnackBar(
          context,
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
          message: '갤러리에 저장되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          context,
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          message: '저장 실패: 권한을 확인해 주세요',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── 이미지 파일로 공유 ───────────────────────────────────────────────────
  Future<void> _shareImage() async {
    setState(() => _isSharing = true);
    try {
      final bytes = await _captureQr();
      if (bytes == null || !mounted) return;

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'QR Code',
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          context,
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          message: '공유 실패: 다시 시도해 주세요',
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _showSnackBar(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.generatorTitle)),
      body: Consumer<QrGeneratorProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 타입 선택 칩 ──
                _TypeChips(
                  selected: _selectedType,
                  onSelect: (type) => setState(() => _selectedType = type),
                ),
                const SizedBox(height: 20),

                // ── 입력 필드 ──
                _InputField(
                  controller: _textController,
                  provider: provider,
                  hintText: _selectedType.hint,
                  onClear: () {
                    _textController.clear();
                    provider.clear();
                  },
                ),
                const SizedBox(height: 20),

                // ── 생성 버튼 ──
                GradientButton(
                  label: AppStrings.generate,
                  icon: Icons.auto_awesome_rounded,
                  onPressed: _textController.text.trim().isNotEmpty
                      ? () {
                          FocusScope.of(context).unfocus();
                          provider.generate();
                        }
                      : null,
                ),

                // ── QR 결과 카드 ──
                if (provider.hasQr) ...[
                  const SizedBox(height: 32),
                  _QrResultCard(
                    qrKey: _qrKey,
                    qrData: provider.qrData,
                    type: _selectedType,
                    isSaving: _isSaving,
                    isSharing: _isSharing,
                    onSave: _saveImage,
                    onShareImage: _shareImage,
                    onCopyText: () {
                      Clipboard.setData(
                          ClipboardData(text: provider.qrData));
                      _showSnackBar(
                        context,
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.success,
                        message: AppStrings.copiedToClipboard,
                      );
                    },
                    onShareText: () => Share.share(provider.qrData),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── 타입 선택 칩 ─────────────────────────────────────────────────────────────
class _TypeChips extends StatelessWidget {
  final QrInputType selected;
  final ValueChanged<QrInputType> onSelect;

  const _TypeChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: QrInputType.values.map((type) {
          final isSelected = selected == type;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onSelect(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withAlpha(40)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 16,
                      color: isSelected
                          ? AppColors.primaryLight
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.textHint,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── 입력 필드 ────────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final QrGeneratorProvider provider;
  final String hintText;
  final VoidCallback onClear;

  const _InputField({
    required this.controller,
    required this.provider,
    required this.hintText,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppStrings.enterText,
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (controller.text.isNotEmpty)
              Text(
                '${controller.text.length}자',
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          onChanged: (v) {
            provider.updateInput(v);
            // 리빌드로 글자 수 갱신
            (context as Element).markNeedsBuild();
          },
          minLines: 3,
          maxLines: 6,
          style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: AppColors.textHint, size: 20),
                    onPressed: onClear,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// ─── QR 결과 카드 ─────────────────────────────────────────────────────────────
class _QrResultCard extends StatefulWidget {
  final GlobalKey qrKey;
  final String qrData;
  final QrInputType type;
  final bool isSaving;
  final bool isSharing;
  final VoidCallback onSave;
  final VoidCallback onShareImage;
  final VoidCallback onCopyText;
  final VoidCallback onShareText;

  const _QrResultCard({
    required this.qrKey,
    required this.qrData,
    required this.type,
    required this.isSaving,
    required this.isSharing,
    required this.onSave,
    required this.onShareImage,
    required this.onCopyText,
    required this.onShareText,
  });

  @override
  State<_QrResultCard> createState() => _QrResultCardState();
}

class _QrResultCardState extends State<_QrResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: AppColors.primary.withAlpha(80), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(30),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── 헤더 ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.qrGenerated,
                      style: Theme.of(context).textTheme.titleMedium),
                  _TypeBadge(type: widget.type),
                ],
              ),
              const SizedBox(height: 20),

              // ── QR 코드 (RepaintBoundary로 캡처 가능) ──
              RepaintBoundary(
                key: widget.qrKey,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: widget.qrData,
                    version: QrVersions.auto,
                    size: 210,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0A0A14),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0A0A14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── 내용 미리보기 ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder.withAlpha(100),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.qrData,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // ── 이미지 액션 버튼 행 ──
              Row(
                children: [
                  Expanded(
                    child: _ImageActionButton(
                      icon: widget.isSaving
                          ? null
                          : Icons.download_rounded,
                      label: widget.isSaving ? '저장 중...' : '이미지 저장',
                      gradientColors: const [
                        Color(0xFF7C4DFF),
                        Color(0xFF5C2DE0),
                      ],
                      isLoading: widget.isSaving,
                      onTap:
                          widget.isSaving ? null : widget.onSave,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImageActionButton(
                      icon: widget.isSharing
                          ? null
                          : Icons.share_rounded,
                      label:
                          widget.isSharing ? '공유 중...' : '이미지 공유',
                      gradientColors: const [
                        Color(0xFF00B8CC),
                        Color(0xFF00E5FF),
                      ],
                      isLoading: widget.isSharing,
                      onTap:
                          widget.isSharing ? null : widget.onShareImage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── 텍스트 액션 버튼 행 (보조) ──
              Row(
                children: [
                  Expanded(
                    child: _TextActionButton(
                      icon: Icons.copy_rounded,
                      label: '텍스트 복사',
                      onTap: widget.onCopyText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TextActionButton(
                      icon: Icons.ios_share_rounded,
                      label: '텍스트 공유',
                      onTap: widget.onShareText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 타입 배지 ────────────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final QrInputType type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 13, color: AppColors.primaryLight),
          const SizedBox(width: 5),
          Text(
            type.label,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 이미지 액션 버튼 (그라디언트) ───────────────────────────────────────────
class _ImageActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final List<Color> gradientColors;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ImageActionButton({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [const Color(0xFF3A3A4A), const Color(0xFF2A2A3A)]
                : gradientColors,
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: gradientColors.first.withAlpha(70),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              )
            else if (icon != null)
              Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 텍스트 액션 버튼 (보조) ─────────────────────────────────────────────────
class _TextActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TextActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.cardBorder.withAlpha(100),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

