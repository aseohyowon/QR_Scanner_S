import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/scan_result.dart';
import '../providers/history_provider.dart';
import 'package:provider/provider.dart';
import 'history_detail_sheet.dart';

class HistoryItemCard extends StatelessWidget {
  final ScanResult result;

  const HistoryItemCard({super.key, required this.result});

  bool get _isUrl {
    final lower = result.content.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  bool get _isLaunchable {
    final lower = result.content.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('mailto:') ||
        lower.startsWith('tel:') ||
        (lower.contains('@') && !lower.startsWith('http'));
  }

  Future<void> _openContent(BuildContext context) async {
    final lower = result.content.toLowerCase();
    Uri uri;
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      uri = Uri.parse(result.content);
    } else if (lower.startsWith('mailto:')) {
      uri = Uri.parse(result.content);
    } else if (lower.contains('@')) {
      uri = Uri.parse('mailto:${result.content}');
    } else if (lower.startsWith('tel:')) {
      uri = Uri.parse(result.content);
    } else {
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(result.id),
      direction: DismissDirection.endToStart,
      background: _DismissBackground(),
      onDismissed: (_) {
        context.read<HistoryProvider>().deleteResult(result.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.deleted),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => HistoryDetailSheet.show(context, result),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _LeadingIcon(isGenerated: result.isGenerated),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _SmallBadge(
                                label: result.isGenerated ? 'Generated' : 'Scanned'),
                            const SizedBox(width: 6),
                            _SmallBadge(label: result.type),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                DateFormatter.formatDateTime(result.scannedAt),
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 빠른 링크 열기 버튼 (링크일 때만)
                  if (_isLaunchable)
                    _QuickOpenButton(onTap: () => _openContent(context)),
                  PopupMenuButton<String>(
                    color: AppColors.cardBackground,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.cardBorder)),
                    icon: const Icon(Icons.more_vert_rounded,
                        color: AppColors.textSecondary, size: 20),
                    onSelected: (value) =>
                        _onMenuSelected(context, value),
                    itemBuilder: (_) => [
                      if (_isLaunchable)
                        PopupMenuItem(
                          value: 'open',
                          child: Row(children: [
                            Icon(
                              _isUrl
                                  ? Icons.open_in_browser_rounded
                                  : Icons.launch_rounded,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 10),
                            Text(AppStrings.open,
                                style:
                                    const TextStyle(color: AppColors.secondary)),
                          ]),
                        ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(children: [
                          Icon(Icons.copy_rounded,
                              size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 10),
                          Text(AppStrings.copy,
                              style:
                                  TextStyle(color: AppColors.textPrimary)),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(children: [
                          Icon(Icons.share_rounded,
                              size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 10),
                          Text(AppStrings.share,
                              style:
                                  TextStyle(color: AppColors.textPrimary)),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 16, color: AppColors.error),
                          SizedBox(width: 10),
                          Text(AppStrings.delete,
                              style: TextStyle(color: AppColors.error)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onMenuSelected(BuildContext context, String action) {
    switch (action) {
      case 'open':
        _openContent(context);
      case 'copy':
        Clipboard.setData(ClipboardData(text: result.content));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.copiedToClipboard)),
        );
      case 'share':
        Share.share(result.content);
      case 'delete':
        context.read<HistoryProvider>().deleteResult(result.id);
    }
  }
}

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(40),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.error.withAlpha(100), width: 1),
      ),
      child: const Icon(Icons.delete_outline_rounded,
          color: AppColors.error, size: 24),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final bool isGenerated;

  const _LeadingIcon({required this.isGenerated});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isGenerated
            ? AppColors.secondary.withAlpha(30)
            : AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isGenerated ? Icons.qr_code_2_rounded : Icons.qr_code_scanner_rounded,
        color: isGenerated ? AppColors.secondary : AppColors.primary,
        size: 22,
      ),
    );
  }
}

class _QuickOpenButton extends StatelessWidget {
  final VoidCallback onTap;

  const _QuickOpenButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.secondary.withAlpha(70)),
        ),
        child: const Icon(
          Icons.open_in_new_rounded,
          size: 16,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;

  const _SmallBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardBorder.withAlpha(120),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
