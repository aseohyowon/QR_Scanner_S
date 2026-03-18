import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/scan_result.dart';
import '../providers/history_provider.dart';

/// 히스토리 항목을 탭하면 표시되는 상세 바텀시트
class HistoryDetailSheet extends StatelessWidget {
  final ScanResult result;

  const HistoryDetailSheet({super.key, required this.result});

  static Future<void> show(BuildContext context, ScanResult result) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoryDetailSheet(result: result),
    );
  }

  bool get _isUrl {
    final lower = result.content.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  bool get _isEmail {
    final lower = result.content.toLowerCase();
    return lower.startsWith('mailto:') ||
        (lower.contains('@') && !lower.startsWith('http'));
  }

  bool get _isPhone {
    final lower = result.content.toLowerCase();
    return lower.startsWith('tel:') || lower.startsWith('phone:');
  }

  Future<void> _launchContent(BuildContext context) async {
    String raw = result.content;
    late Uri uri;

    if (_isUrl) {
      uri = Uri.parse(raw);
    } else if (_isEmail) {
      final addr =
          raw.toLowerCase().startsWith('mailto:') ? raw : 'mailto:$raw';
      uri = Uri.parse(addr);
    } else if (_isPhone) {
      final number =
          raw.toLowerCase().startsWith('tel:') ? raw : 'tel:$raw';
      uri = Uri.parse(number);
    } else {
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('링크를 열 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canLaunch = _isUrl || _isEmail || _isPhone;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.88,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 1),
            ),
          ),
          child: Column(
            children: [
              // 드래그 핸들
              const _DragHandle(),

              // 스크롤 가능한 내용
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    // ── 헤더 ──
                    _SheetHeader(result: result),
                    const SizedBox(height: 20),

                    // ── 내용 전체 보기 ──
                    _ContentBox(content: result.content),
                    const SizedBox(height: 24),

                    // ── 링크 열기 (URL/이메일/전화일 때만) ──
                    if (canLaunch) ...[
                      _PrimaryActionButton(
                        icon: _isUrl
                            ? Icons.open_in_browser_rounded
                            : _isEmail
                                ? Icons.email_rounded
                                : Icons.phone_rounded,
                        label: _isUrl
                            ? '브라우저에서 열기'
                            : _isEmail
                                ? '이메일 앱에서 열기'
                                : '전화 걸기',
                        onTap: () => _launchContent(context),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── 보조 액션 그리드 ──
                    _ActionGrid(
                      result: result,
                      onDeleted: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── 드래그 핸들 ──────────────────────────────────────────────────────────────
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.cardBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ─── 시트 헤더 ────────────────────────────────────────────────────────────────
class _SheetHeader extends StatelessWidget {
  final ScanResult result;

  const _SheetHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BigIcon(isGenerated: result.isGenerated),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TypePill(type: result.type),
                  const SizedBox(width: 8),
                  _TagPill(
                    label: result.isGenerated ? '생성됨' : '스캔됨',
                    color: result.isGenerated
                        ? AppColors.secondary
                        : AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                DateFormatter.formatDateTime(result.scannedAt),
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BigIcon extends StatelessWidget {
  final bool isGenerated;

  const _BigIcon({required this.isGenerated});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isGenerated
            ? AppColors.secondary.withAlpha(30)
            : AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGenerated
              ? AppColors.secondary.withAlpha(80)
              : AppColors.primary.withAlpha(80),
        ),
      ),
      child: Icon(
        isGenerated
            ? Icons.qr_code_2_rounded
            : Icons.qr_code_scanner_rounded,
        color: isGenerated ? AppColors.secondary : AppColors.primary,
        size: 26,
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String type;

  const _TypePill({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  final Color color;

  const _TagPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── 내용 박스 ────────────────────────────────────────────────────────────────
class _ContentBox extends StatelessWidget {
  final String content;

  const _ContentBox({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        content,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.6,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ─── 주요 액션 버튼 (링크 열기) ───────────────────────────────────────────────
class _PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(70),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 보조 액션 2×2 그리드 ────────────────────────────────────────────────────
class _ActionGrid extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onDeleted;

  const _ActionGrid({required this.result, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GridAction(
                icon: Icons.copy_rounded,
                label: '복사',
                color: AppColors.primary,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: result.content));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('클립보드에 복사되었습니다')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GridAction(
                icon: Icons.share_rounded,
                label: '공유',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Share.share(result.content);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GridAction(
                icon: Icons.content_paste_rounded,
                label: '재사용',
                color: const Color(0xFF00E676),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: result.content));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('클립보드에 복사됨 — 원하는 곳에 붙여넣으세요'),
                      action: SnackBarAction(
                        label: '확인',
                        onPressed: () {},
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GridAction(
                icon: Icons.delete_outline_rounded,
                label: '삭제',
                color: AppColors.error,
                onTap: () {
                  context.read<HistoryProvider>().deleteResult(result.id);
                  onDeleted();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('삭제되었습니다')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GridAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GridAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color.withAlpha(22),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
