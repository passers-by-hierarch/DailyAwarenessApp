import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';

/// 事程列表项 - 对齐设计文档 2.3.5
/// 本身不包含滑动删除逻辑，由外层 SwipeDeleteWrapper 包裹
class AgendaItemWidget extends StatefulWidget {
  final AgendaItem item;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onPostpone;
  final ValueChanged<bool>? onCheckboxChanged;

  const AgendaItemWidget({
    super.key,
    required this.item,
    this.onTap,
    this.onComplete,
    this.onPostpone,
    this.onCheckboxChanged,
  });

  @override
  State<AgendaItemWidget> createState() => _AgendaItemWidgetState();
}

class _AgendaItemWidgetState extends State<AgendaItemWidget> {
  Timer? _timer;
  String _remainingTime = '';

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateRemainingTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemainingTime() {
    setState(() {
      _remainingTime = _calculateRemainingTime(widget.item);
    });
  }

  String _calculateRemainingTime(AgendaItem item) {
    if (item.remainingTime != null && item.remainingTime!.contains('推迟')) {
      return item.remainingTime!;
    }
    if (item.date != _calcTodayStr()) {
      return '待提醒';
    }
    final parts = item.time.split(':');
    if (parts.length != 2) return '今日提醒';
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    final agendaTime = DateTime(now.year, now.month, now.day, h, m);
    final diff = agendaTime.difference(now);
    if (diff.isNegative) {
      return '已过期';
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '还有${hours}小时${minutes}分';
    }
    if (minutes > 0) {
      return '还有${minutes}分钟';
    }
    return '即将开始';
  }

  String _calcTodayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = _getEffectiveStatus(widget.item);
    final levelColor = _getLevelColor(widget.item.level);
    final isPending = status == AgendaStatus.pending;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.itemShadow,
        ),
        child: Row(
          children: [
            // 级别颜色条
            Container(
              width: 6,
              height: 80,
              decoration: BoxDecoration(
                color: levelColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 勾选框
            Checkbox(
              value: status == AgendaStatus.completed,
              onChanged: (v) {
                if (v == true && widget.onComplete != null) {
                  widget.onComplete!();
                }
                if (widget.onCheckboxChanged != null) {
                  widget.onCheckboxChanged!(v ?? false);
                }
              },
              activeColor: AppColors.success,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              side: BorderSide(color: AppColors.border, width: 2),
            ),
            const SizedBox(width: 8),
            // 时间
            SizedBox(
              width: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.time,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (isPending)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _remainingTime,
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 图标
            Text(widget.item.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.content,
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
                  if (widget.item.note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.item.note!,
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
                        _buildStatusBadge(status),
                        _buildLevelBadge(widget.item.level),
                        _buildCategoryBadge(widget.item.category),
                        if (widget.item.isHighFrequency)
                          _buildBadge('高频', AppColors.purple, AppColors.purpleLight),
                        if (widget.item.source == AgendaSource.ai)
                          _buildBadge('AI', AppColors.accent, AppColors.accentLight),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 操作按钮 - 只在待进行状态显示
            if (isPending)
              Row(
                children: [
                  Tooltip(
                    message: '推迟',
                    child: GestureDetector(
                      onTap: widget.onPostpone,
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
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: '完成',
                    child: GestureDetector(
                      onTap: widget.onComplete,
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
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(AgendaLevel level) {
    switch (level) {
      case AgendaLevel.mustDo:
        return AppColors.danger;
      case AgendaLevel.important:
        return AppColors.warning;
      case AgendaLevel.normal:
      default:
        return AppColors.accent;
    }
  }

  Widget _buildLevelBadge(AgendaLevel level) {
    final config = {
      AgendaLevel.mustDo: ('必做', AppColors.danger, AppColors.dangerLight),
      AgendaLevel.important: ('重要', AppColors.warning, AppColors.warningLight),
      AgendaLevel.normal: ('普通', AppColors.accent, AppColors.accentLight),
    };
    final c = config[level]!;
    return _buildBadge(c.$1, c.$2, c.$3);
  }

  AgendaStatus _getEffectiveStatus(AgendaItem item) {
    if (item.status == AgendaStatus.pending && item.date == _calcTodayStr()) {
      final parts = item.time.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final now = DateTime.now();
      if (h * 60 + m < now.hour * 60 + now.minute) return AgendaStatus.expired;
    }
    return item.status;
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

  Widget _buildCategoryBadge(AgendaCategory category) {
    final config = {
      AgendaCategory.dailyMustDo: ('每日必做', AppColors.danger, AppColors.dangerLight),
      AgendaCategory.frequent: ('常用', AppColors.purple, AppColors.purpleLight),
      AgendaCategory.temporary: ('临时', AppColors.info, AppColors.infoLight),
      AgendaCategory.custom: ('自定义', AppColors.textSecondary, AppColors.bgTertiary),
    };
    final c = config[category]!;
    return _buildBadge(c.$1, c.$2, c.$3);
  }
}
