import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_store.dart';

/// 免打扰时段页 - 对齐原型 QuietHoursPage
class QuietHoursPage extends StatelessWidget {
  const QuietHoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final quietHours = store.quietHours;
    final enabled = quietHours['enabled'] as bool? ?? true;
    final start = quietHours['start'] as String? ?? '22:00';
    final end = quietHours['end'] as String? ?? '08:00';

    return SecondaryScaffold(
      title: '免打扰时段',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 总开关
          _buildMasterSwitch(context, enabled),
          const SizedBox(height: 16),
          if (enabled) ...[
            _buildTimeRangeCard(context, start, end),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildEmergencyCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildMasterSwitch(BuildContext context, bool enabled) {
    final store = context.read<AppStore>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.do_not_disturb_on, size: 20, color: AppColors.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('免打扰模式',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(enabled ? '已开启' : '已关闭',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (v) {
              final qh = Map<String, dynamic>.from(store.quietHours);
              qh['enabled'] = v;
              store.updateQuietHours(qh);
            },
            activeColor: AppColors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeCard(BuildContext context, String start, String end) {
    final store = context.read<AppStore>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('免打扰时段',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('该时段内不发送任何提醒通知',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () => _pickTime(context, start, (newTime) {
                    final qh = Map<String, dynamic>.from(store.quietHours);
                    qh['start'] = newTime;
                    store.updateQuietHours(qh);
                  }),
                  child: Column(
                    children: [
                      const Text('开始', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      const SizedBox(height: 4),
                      Text(start, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                const Text('→', style: TextStyle(fontSize: 20, color: AppColors.textTertiary)),
                GestureDetector(
                  onTap: () => _pickTime(context, end, (newTime) {
                    final qh = Map<String, dynamic>.from(store.quietHours);
                    qh['end'] = newTime;
                    store.updateQuietHours(qh);
                  }),
                  child: Column(
                    children: [
                      const Text('结束', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      const SizedBox(height: 4),
                      Text(end, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 跨天提示
          if (_isCrossDay(start, end))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 12, color: AppColors.info),
                  SizedBox(width: 4),
                  Text('跨天免打扰，如夜间睡眠时段',
                      style: TextStyle(fontSize: 11, color: AppColors.info)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _isCrossDay(String start, String end) {
    final s = start.split(':');
    final e = end.split(':');
    if (s.length != 2 || e.length != 2) return false;
    final sMin = int.parse(s[0]) * 60 + int.parse(s[1]);
    final eMin = int.parse(e[0]) * 60 + int.parse(e[1]);
    return sMin > eMin;
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.info),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '免打扰时段内，所有事程提醒将被静音。\n如需要保留紧急提醒，可在下方开启"允许紧急提醒"。',
              style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active, size: 16, color: AppColors.danger),
              SizedBox(width: 6),
              Text('允许紧急提醒',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('必做事程在免打扰时段仍会提醒',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildEmergencyBadge('必做', true),
              const SizedBox(width: 8),
              _buildEmergencyBadge('重要', false),
              const SizedBox(width: 8),
              _buildEmergencyBadge('普通', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBadge(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.dangerLight : AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.block,
            size: 12,
            color: active ? AppColors.danger : AppColors.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: active ? AppColors.danger : AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  void _pickTime(BuildContext context, String current, Function(String) onSave) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 22,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onSave(newTime);
    }
  }
}
