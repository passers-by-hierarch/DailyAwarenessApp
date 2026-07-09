import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_store.dart';

/// 晚下班确认弹窗
/// 当检测到用户晚下班时，列出受影响的待办事程，让用户确认是否仍执行
class LateOffWorkDialog extends StatefulWidget {
  final LateOffWorkResult result;

  const LateOffWorkDialog({super.key, required this.result});

  @override
  State<LateOffWorkDialog> createState() => _LateOffWorkDialogState();
}

class _LateOffWorkDialogState extends State<LateOffWorkDialog> {
  late List<bool> _confirmations;

  @override
  void initState() {
    super.initState();
    _confirmations = List.filled(widget.result.affectedAgendas.length, true);
  }

  void _submit() {
    final store = context.read<AppStore>();
    for (var i = 0; i < widget.result.affectedAgendas.length; i++) {
      final agenda = widget.result.affectedAgendas[i];
      store.confirmLateOffWorkAgenda(agenda.id, _confirmations[i]);
    }
    store.clearLateOffWorkResult();
    if (mounted) Navigator.of(context).pop();
  }

  void _skipAll() {
    final store = context.read<AppStore>();
    for (final agenda in widget.result.affectedAgendas) {
      store.confirmLateOffWorkAgenda(agenda.id, false);
    }
    store.clearLateOffWorkResult();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Dialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(AppIcons.alertTriangle, color: AppColors.warning, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('检测到晚下班', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('请确认今晚的事程安排', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 延迟信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.clock, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '通常下班时间 ${r.avgOffWorkTime}，现在已 ${r.currentTime}（晚了${r.delayMinutes}分钟）',
                      style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 受影响的事程列表
            const Text('受影响的事程', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ...r.affectedAgendas.asMap().entries.map((entry) {
              final idx = entry.key;
              final agenda = entry.value;
              return _buildAgendaItem(idx, agenda);
            }),
            const SizedBox(height: 20),
            // 按钮区
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skipAll,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('全部取消', style: TextStyle(color: AppColors.textTertiary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.accent,
                    ),
                    child: const Text('确认', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaItem(int idx, AgendaItem agenda) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(AppIcons.calendar, size: 18, color: AppColors.accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agenda.content, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(agenda.time, style: const TextStyle(fontSize: 10, color: AppColors.info, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _confirmations[idx] ? '仍去执行' : '已取消',
                      style: TextStyle(
                        fontSize: 10,
                        color: _confirmations[idx] ? AppColors.success : AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _confirmations[idx] = !_confirmations[idx]),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _confirmations[idx] ? AppColors.accent : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _confirmations[idx] ? AppIcons.check : AppIcons.x,
                size: 16,
                color: _confirmations[idx] ? Colors.white : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 便捷函数：弹出晚下班确认弹窗
Future<void> showLateOffWorkDialog({
  required BuildContext context,
  required LateOffWorkResult result,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => LateOffWorkDialog(result: result),
  );
}
