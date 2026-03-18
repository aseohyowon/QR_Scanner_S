import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/scan_result.dart';

class QrResultCard extends StatelessWidget {
  final ScanResult result;
  final bool showSaveButton;

  const QrResultCard({
    super.key,
    required this.result,
    this.showSaveButton = false,
  });

  // 콘텐츠 타입에 따라 실행할 URI 생성
  String? _smartUri() {
    final c = result.content.trim();
    final lower = c.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return c;
    if (lower.startsWith('mailto:')) return c;
    if (lower.startsWith('tel:')) return c;
    if (lower.startsWith('phone:')) return c.replaceFirst(RegExp(r'^phone:', caseSensitive: false), 'tel:');
    if (lower.startsWith('sms:') || lower.startsWith('smsto:')) return c;
    if (lower.contains('@') && !lower.startsWith('begin:')) return 'mailto:$c';
    return null;
  }

  // 타입별 아이콘 / 버튼 라벨
  (IconData, String)? _smartAction() {
    switch (result.type) {
      case 'URL':
        return (Icons.open_in_browser_rounded, AppStrings.openInBrowser);
      case 'Email':
        return (Icons.email_rounded, AppStrings.sendEmail);
      case 'Phone':
        return (Icons.phone_rounded, AppStrings.callNumber);
      case 'SMS':
        return (Icons.sms_rounded, AppStrings.sendSms);
      default:
        return null;
    }
  }

  bool get _isUrl {
    final lower = result.content.toLowerCase().trim();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  Future<void> _launch(BuildContext context, String uriStr) async {
    final uri = Uri.tryParse(uriStr);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.cannotOpen)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final smartAction = _smartAction();
    final uri = _smartUri();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(80), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeBadge(type: result.type),
              const Spacer(),
              Text(
                DateFormatter.formatDateTime(result.scannedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // URL이면 파란 링크처럼 표시하고 탭 가능하게
          GestureDetector(
            onTap: (uri != null) ? () => _launch(context, uri) : null,
            child: Text(
              result.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _isUrl ? AppColors.secondary : AppColors.textPrimary,
                    height: 1.5,
                    decoration: _isUrl ? TextDecoration.underline : null,
                    decorationColor: AppColors.secondary,
                  ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),

          // 타입별 스마트 액션 버튼 (URL / Email / Phone / SMS)
          if (smartAction != null && uri != null) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _launch(context, uri),
                icon: Icon(smartAction.$1, size: 18),
                label: Text(smartAction.$2),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Copy / Share
          Row(
            children: [
              _ActionChip(
                icon: Icons.copy_rounded,
                label: AppStrings.copy,
                onTap: () => _copyToClipboard(context, result.content),
              ),
              const SizedBox(width: 10),
              _ActionChip(
                icon: Icons.share_rounded,
                label: AppStrings.share,
                onTap: () => _share(result.content),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 18),
            const SizedBox(width: 10),
            Text(AppStrings.copiedToClipboard,
                style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _share(String text) {
    Share.share(text);
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(100), width: 1),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBorder.withAlpha(120),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
