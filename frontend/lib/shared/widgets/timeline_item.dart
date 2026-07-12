import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_store.dart';

class TimelineItemWidget extends StatelessWidget {
  final TimelineRecord record;
  final VoidCallback? onTap;

  const TimelineItemWidget({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final allTags = record.tags;
    final matchedAgenda = record.matchedAgenda;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(minHeight: 72),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppColors.itemShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  record.timeStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (allTags.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: allTags.map((tagId) {
                          final tag = store.getTagDef(tagId);
                          return _buildTagChip(tag, tagId);
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      record.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (matchedAgenda != null) ...[
                      const SizedBox(height: 8),
                      _buildAgendaStatusChips(store),
                    ],
                    if (record.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(AppIcons.messageSquare, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            '${record.notes.length}条补充',
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaStatusChips(AppStore store) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.link, size: 12, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            record.matchedAgenda ?? '关联事程',
            style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(TagDef? tag, String tagId) {
    if (tag == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.tag, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 3),
            const Text(
              '已删除',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary, decoration: TextDecoration.lineThrough),
            ),
          ],
        ),
      );
    }
    final colorSet = AppColors.tagColors[tag.color] ?? AppColors.tagColors['gray']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorSet.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorSet.color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          tag.system
              ? Icon(_getSystemTagIcon(tag.id), size: 13, color: colorSet.color)
              : Text(tag.icon == '#' ? '🏷' : tag.icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            tag.name,
            style: TextStyle(
              fontSize: 12,
              color: colorSet.color,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSystemTagIcon(String tagId) {
    switch (tagId) {
      case 'behavior': return AppIcons.activity;
      case 'item': return AppIcons.package;
      case 'shopping': return AppIcons.shoppingCart;
      case 'event': return AppIcons.mapPin;
      default: return AppIcons.tag;
    }
  }
}