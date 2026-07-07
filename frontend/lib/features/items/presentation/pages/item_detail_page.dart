import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/models/app_models.dart';

/// 物品详情页 - 对齐原型 ItemDetailPage
class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final itemId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final item = context.select<AppStore, ItemRecord?>(
      (s) => s.items.where((it) => it.id == itemId).firstOrNull,
    );

    if (item == null) {
      return const SecondaryScaffold(
        title: '物品详情',
        body: Center(child: Text('物品不存在', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    // 位置分布统计
    final Map<String, int> locationCounts = {};
    for (final h in item.history) {
      locationCounts[h.location] = (locationCounts[h.location] ?? 0) + 1;
    }
    if (locationCounts[item.location] == null) {
      locationCounts[item.location] = 1;
    }
    final totalHistory = locationCounts.values.fold(0, (a, b) => a + b);

    return SecondaryScaffold(
      title: '物品详情',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBasicCard(item),
          const SizedBox(height: 12),
          _buildLocationPattern(locationCounts, totalHistory),
          const SizedBox(height: 12),
          _buildHistoryTimeline(item.history),
          const SizedBox(height: 12),
          _buildUsageStats(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBasicCard(ItemRecord item) {
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
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(item.icon, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text('当前位置：${item.location}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPattern(Map<String, int> locationCounts, int total) {
    if (total == 0) total = 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('位置规律总结', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...locationCounts.entries.map((e) {
            final percent = (e.value / total * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      Text('$percent%', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value / total,
                      minHeight: 6,
                      backgroundColor: AppColors.bgTertiary,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryTimeline(List<LocationHistory> history) {
    final list = history.isEmpty ? <LocationHistory>[] : history;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('放置位置历史', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('暂无历史记录', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            )
          else
            ...list.asMap().entries.map((entry) {
              final idx = entry.key;
              final h = entry.value;
              final isLast = idx == list.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: idx == 0 ? AppColors.info : AppColors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.border,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.location, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            '${h.time.month}/${h.time.day} ${h.time.hour.toString().padLeft(2, '0')}:${h.time.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildUsageStats() {
    final days = [3, 5, 2, 6, 4, 7, 5];
    final maxVal = days.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('使用统计（近7天）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.asMap().entries.map((entry) {
                final idx = entry.key;
                final v = entry.value;
                final dayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$v', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Container(
                          height: (v / maxVal) * 70,
                          decoration: BoxDecoration(
                            color: idx == 5 ? AppColors.accent : AppColors.accentLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(dayLabels[idx], style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
