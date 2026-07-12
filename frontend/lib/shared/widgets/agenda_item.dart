import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_store.dart';
import '../../core/utils/agenda_utils.dart';

/// 事程列表项 - 精简版
/// 展示：级别色条 + 勾选框 + 时间 + 内容 + 状态文字
/// 可直接勾选完成，无需进入详情
class AgendaItemWidget extends StatefulWidget {
  final AgendaItem item;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onUncomplete;
  final VoidCallback? onPostpone;
  final VoidCallback? onSkip;
  final VoidCallback? onUnskip;

  const AgendaItemWidget({
    super.key,
    required this.item,
    this.onTap,
    this.onComplete,
    this.onUncomplete,
    this.onPostpone,
    this.onSkip,
    this.onUnskip,
  });

  @override
  State<AgendaItemWidget> createState() => _AgendaItemWidgetState();
}

class _AgendaItemWidgetState extends State<AgendaItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleComplete() {
    final store = context.read<AppStore>();
    final status = AgendaUtils.effectiveStatus(widget.item,
        isToday: widget.item.date == AgendaUtils.todayStr(now: store.now), now: store.now);
    if (status == AgendaStatus.completed) {
      if (widget.onUncomplete != null) {
        HapticFeedback.lightImpact();
        _animController.forward().then((_) => _animController.reverse());
        widget.onUncomplete!();
      }
    } else if (widget.onComplete != null) {
      HapticFeedback.mediumImpact();
      _animController.forward().then((_) => _animController.reverse());
      widget.onComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final status = AgendaUtils.effectiveStatus(widget.item,
        isToday: widget.item.date == AgendaUtils.todayStr(now: store.now), now: store.now);
    final levelColor = _getLevelColor(widget.item.level);
    final isFinished = status == AgendaStatus.completed;
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          );
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.itemShadow,
          ),
          child: Row(
            children: [
              // 级别颜色条 - 区分事程级别
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: levelColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 勾选框 - 直接完成
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleComplete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFinished ? AppColors.success : AppColors.border,
                      width: 2,
                    ),
                    color: isFinished ? AppColors.success : Colors.transparent,
                  ),
                  child: isFinished
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              // 时间
              SizedBox(
                width: 44,
                child: Text(
                  widget.item.time,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: statusColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 内容
              Expanded(
                child: Text(
                  widget.item.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isFinished ? AppColors.textTertiary : AppColors.textPrimary,
                    decoration: isFinished ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 状态图标区（延期/跳过/历史标记）
              _buildStatusIcons(),
              const SizedBox(width: 10),
              // 右侧状态文字：待进行/已完成/已过期
              _buildRightStatusText(status),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }

  /// 状态图标区：延期/延期完成历史标记
  /// 跳过状态右侧已有"已跳过"文字，无需重复图标
  Widget _buildStatusIcons() {
    final status = widget.item.status;
    final List<Widget> icons = [];

    // 当前状态：延期图标
    if (status == AgendaStatus.postponed) {
      icons.add(const Icon(Icons.schedule, size: 14, color: AppColors.warning));
    }

    // 待进行状态下的延期历史标记：曾经延期过后来取消完成
    if (status == AgendaStatus.pending && widget.item.wasPostponed) {
      icons.add(const Icon(Icons.schedule, size: 14, color: AppColors.warning));
    }

    // 过期状态下的延期历史标记：曾经延期过后来过期
    if (status == AgendaStatus.expired && widget.item.wasPostponed) {
      icons.add(const Icon(Icons.schedule, size: 14, color: AppColors.warning));
    }

    // 完成状态下的历史标记：延期完成
    if (status == AgendaStatus.completed && widget.item.wasPostponed) {
      icons.add(const Icon(Icons.schedule, size: 14, color: AppColors.warning));
    }

    if (icons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < icons.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          icons[i],
        ],
      ],
    );
  }

  /// 右侧状态文字：待进行/已完成/已过期/已跳过
  Widget _buildRightStatusText(AgendaStatus status) {
    switch (status) {
      case AgendaStatus.pending:
      case AgendaStatus.postponed:
        return const Text(
          '待进行',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        );
      case AgendaStatus.completed:
        return const Text(
          '已完成',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        );
      case AgendaStatus.expired:
        return const Text(
          '已过期',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.danger,
          ),
        );
      case AgendaStatus.skipped:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onUnskip != null)
              GestureDetector(
                onTap: widget.onUnskip,
                behavior: HitTestBehavior.opaque,
                child: const Icon(Icons.restore, size: 16, color: AppColors.accent),
              ),
            if (widget.onUnskip != null) const SizedBox(width: 4),
            const Text(
              '已跳过',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        );
    }
  }

  /// 级别颜色
  Color _getLevelColor(AgendaLevel level) {
    switch (level) {
      case AgendaLevel.mustDoShort:
      case AgendaLevel.mustDoLong:
        return AppColors.danger;
      case AgendaLevel.important:
        return AppColors.warning;
      case AgendaLevel.normal:
      default:
        return AppColors.accent;
    }
  }

  /// 状态颜色
  Color _getStatusColor(AgendaStatus status) {
    switch (status) {
      case AgendaStatus.completed:
        return AppColors.success;
      case AgendaStatus.postponed:
        return AppColors.warning;
      case AgendaStatus.skipped:
        return AppColors.textTertiary;
      case AgendaStatus.expired:
        return AppColors.danger;
      case AgendaStatus.pending:
      default:
        return AppColors.accent;
    }
  }
}
