import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_store.dart';

/// 时间线列表项 - 对齐设计文档 2.3.6
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
              // 时间列 - 对齐设计文档 2.3.6：宽度 48px，字号 14px Mono 字体，居中对齐
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
                    // 标签行 - 对齐设计文档：flex-wrap，gap 6px，margin-bottom 6px
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
                    // 主内容文字 - 对齐设计文档：字号 15px，字重 500，颜色 `--text-primary`
                    Text(
                      record.content,
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

  Widget _buildTagChip(TagDef? tag, String tagId) {
    // 标签项 - 对齐设计文档：padding 2px 8px，圆角 4px，字号 12px，带图标
    if (tag == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.tag, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 2),
            const Text(
              '已删除',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary, decoration: TextDecoration.lineThrough),
            ),
          ],
        ),
      );
    }
    final colorSet = AppColors.tagColors[tag.color] ?? AppColors.tagColors['gray']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorSet.bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getTagIcon(tag.id, tag.name, !tag.system, tag.icon), size: 12, color: colorSet.color),
          const SizedBox(width: 2),
          Text(
            tag.name,
            style: TextStyle(
              fontSize: 12,
              color: colorSet.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTagIcon(String tagId, String tagName, bool isCustom, String icon) {
    if (isCustom) return AppIcons.tag;
    if (tagName.contains('行为') || tagName.contains('活动')) {
      return AppIcons.activity;
    }
    if (tagName.contains('物品') || tagName.contains('位置')) {
      return AppIcons.package;
    }
    if (tagName.contains('购物')) {
      return AppIcons.shoppingCart;
    }
    if (tagName.contains('事件') || tagName.contains('日常')) {
      return AppIcons.mapPin;
    }
    return AppIcons.tag;
  }

  Widget _buildAgendaStatusChips(AppStore store) {
    final agenda = record.linkedAgendaId != null
        ? store.agendaItems.where((a) => a.id == record.linkedAgendaId).firstOrNull
        : null;

    if (agenda != null) {
      switch (agenda.status) {
        case AgendaStatus.completed:
          return _buildStatusChip('已完成', Colors.green, AppIcons.checkCircle);
        case AgendaStatus.expired:
        case AgendaStatus.skipped:
          return _buildStatusChip('已放弃', AppColors.textTertiary, AppIcons.xCircle);
        case AgendaStatus.pending:
        case AgendaStatus.postponed:
          return Wrap(
            spacing: 6,
            children: [
              _buildStatusChip('已创建', AppColors.info, AppIcons.calendar),
              _buildStatusChip('待完成', Colors.orange, AppIcons.clock),
            ],
          );
      }
    }

    return Wrap(
      spacing: 6,
      children: [
        _buildStatusChip('已创建', AppColors.info, AppIcons.calendar),
        _buildStatusChip('待完成', Colors.orange, AppIcons.clock),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
