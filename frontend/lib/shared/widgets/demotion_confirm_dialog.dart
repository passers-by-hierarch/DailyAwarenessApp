import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_store.dart';

/// 连续失败降级确认弹窗
/// 当事程连续失败达到阈值时，让用户确认是否降级
class DemotionConfirmDialog extends StatelessWidget {
  final DemotionPendingResult result;

  const DemotionConfirmDialog({super.key, required this.result});

  String _levelLabel(AgendaLevel level) {
    switch (level) {
      case AgendaLevel.mustDoShort:
        return '短期必做';
      case AgendaLevel.mustDoLong:
        return '长期必做';
      case AgendaLevel.important:
        return '重要';
      case AgendaLevel.normal:
        return '普通';
    }
  }

  Color _levelColor(AgendaLevel level) {
    switch (level) {
      case AgendaLevel.mustDoShort:
      case AgendaLevel.mustDoLong:
        return AppColors.danger;
      case AgendaLevel.important:
        return AppColors.warning;
      case AgendaLevel.normal:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
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
                      Text('事程连续失败', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('是否降级该事程？', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 失败信息
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
                      '「${r.agenda.content}」已连续失败${r.failCount}次',
                      style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 降级方案
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  // 当前级别
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _levelColor(r.currentLevel).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _levelColor(r.currentLevel)),
                        ),
                        child: Text(
                          _levelLabel(r.currentLevel),
                          style: TextStyle(fontSize: 13, color: _levelColor(r.currentLevel), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('当前', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward, size: 20, color: AppColors.textTertiary),
                  ),
                  // 建议级别
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _levelColor(r.suggestedLevel).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _levelColor(r.suggestedLevel)),
                        ),
                        child: Text(
                          _levelLabel(r.suggestedLevel),
                          style: TextStyle(fontSize: 13, color: _levelColor(r.suggestedLevel), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('建议', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 按钮区
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<AppStore>().confirmDemotion(false);
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('保持级别', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AppStore>().confirmDemotion(true);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.warning,
                    ),
                    child: const Text('确认降级', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showDemotionConfirmDialog({
  required BuildContext context,
  required DemotionPendingResult result,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => DemotionConfirmDialog(result: result),
  );
}
