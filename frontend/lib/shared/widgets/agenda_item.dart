import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';

/// 事程列表项 - 对齐设计文档 2.3.5
/// 本身不包含滑动删除逻辑，由外层 SwipeDeleteWrapper 包裹
class AgendaItemWidget extends StatelessWidget {
  final AgendaItem item;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onPostpone;

  const AgendaItemWidget({
    super.key,
    required this.item,
    this.onTap,
    this.onComplete,
    this.onPostpone,
  });

  @override
  Widget build(BuildContext context) {
    final status = _getEffectiveStatus(item);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: item.level == AgendaLevel.mustDo
              ? const Border(left: BorderSide(color: AppColors.danger, width: 3))
              : item.level == AgendaLevel.important
                  ? const Border(left: BorderSide(color: AppColors.warning, width: 3))
                  : null,
          boxShadow: AppColors.itemShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 时间 - 对齐设计文档 2.3.5：宽度 48px，字号 14px Mono 字体
              SizedBox(
                width: 48,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (item.remainingTime != null && status == AgendaStatus.pending)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.remainingTime!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 图标
              Text(item.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              // 内容 - 对齐设计文档 2.3.5：事程标题 15px/字重500，描述 13px
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.content,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: status == AgendaStatus.completed
                                  ? AppColors.textTertiary
                                  : status == AgendaStatus.expired
                                      ? AppColors.textTertiary
                                      : AppColors.textPrimary,
                              decoration: status == AgendaStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.note!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    // 状态与级别标签行
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // 状态标签
                          _buildStatusBadge(status),
                          // 级别标签 - 不同级别用不同颜色区分
                          if (item.level == AgendaLevel.mustDo)
                            _buildBadge('必做', AppColors.danger, AppColors.dangerLight)
                          else if (item.level == AgendaLevel.important)
                            _buildBadge('重要', AppColors.warning, AppColors.warningLight)
                          else
                            _buildBadge('普通', AppColors.info, AppColors.infoLight),
                          // 高频标签
                          if (item.isHighFrequency)
                            _buildBadge('高频', AppColors.purple, AppColors.purpleLight),
                          // AI推荐标签
                          if (item.source == AgendaSource.ai)
                            _buildBadge('AI', AppColors.accent, AppColors.accentLight),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 操作按钮
              if (status == AgendaStatus.pending)
                Row(
                  children: [
                    GestureDetector(
                      onTap: onPostpone,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.schedule, size: 14, color: AppColors.warning),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onComplete,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 14, color: AppColors.success),
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

  AgendaStatus _getEffectiveStatus(AgendaItem item) {
    if (item.status == AgendaStatus.pending && item.date == _todayStr()) {
      final parts = item.time.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final now = DateTime.now();
      if (h * 60 + m < now.hour * 60 + now.minute) return AgendaStatus.expired;
    }
    return item.status;
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Widget _buildBadge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildStatusBadge(AgendaStatus status) {
    final config = {
      AgendaStatus.completed: ('已完成', AppColors.success, AppColors.successLight),
      AgendaStatus.postponed: ('已延后', AppColors.warning, AppColors.warningLight),
      AgendaStatus.skipped: ('已跳过', AppColors.textTertiary, AppColors.bgTertiary),
      AgendaStatus.expired: ('已过期', AppColors.danger, AppColors.dangerLight),
      AgendaStatus.pending: ('待进行', AppColors.warning, AppColors.warningLight),
    };
    final c = config[status]!;
    return _buildBadge(c.$1, c.$2, c.$3);
  }
}
