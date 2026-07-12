import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_store.dart';

/// 智能时间推荐弹窗
/// 检测到实际完成时间多次偏离预定时间后，建议调整
class SmartTimeSuggestionDialog extends StatelessWidget {
  final SmartTimeSuggestion suggestion;

  const SmartTimeSuggestionDialog({super.key, required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
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
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(AppIcons.clock, color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('智能时间推荐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('建议调整事程时间', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 事程信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                s.agenda.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            // 时间对比
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // 原定时间
                  Column(
                    children: [
                      Text(
                        s.scheduledTime,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 2),
                      const Text('原定', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward, size: 20, color: AppColors.accent),
                  ),
                  // 建议时间
                  Column(
                    children: [
                      Text(
                        s.suggestedTime,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent),
                      ),
                      const SizedBox(height: 2),
                      const Text('建议', style: TextStyle(fontSize: 10, color: AppColors.accent)),
                    ],
                  ),
                  const Spacer(),
                  // 偏差信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${s.deviationCount}次偏差',
                        style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '≥${s.avgDeviationMinutes}分钟',
                        style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 说明文字
            const Text(
              '检测到你多次在不同于原定时间完成该事程，建议调整到你的实际完成时间。',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            // 按钮区
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<AppStore>().acceptSmartTime(s.agenda.id, false);
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('保持原时间', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AppStore>().acceptSmartTime(s.agenda.id, true);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.accent,
                    ),
                    child: const Text('调整时间', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

Future<void> showSmartTimeSuggestionDialog({
  required BuildContext context,
  required SmartTimeSuggestion suggestion,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => SmartTimeSuggestionDialog(suggestion: suggestion),
  );
}
