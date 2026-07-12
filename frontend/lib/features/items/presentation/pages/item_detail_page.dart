import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/models/app_models.dart';

enum StatsRange { sevenDays, thirtyDays, all }

class ItemDetailPage extends StatefulWidget {
  const ItemDetailPage({super.key});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  StatsRange _selectedRange = StatsRange.sevenDays;

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
          _buildUsageStats(item),
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
                Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.info),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('当前位置：${item.location}', maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ),
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
    final sortedEntries = locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topLocation = sortedEntries.isNotEmpty ? sortedEntries.first.key : '';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('位置规律总结', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              if (topLocation.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('高频：$topLocation',
                      style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...sortedEntries.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            final percent = (e.value / total * 100).round();
            final isTop = idx == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: isTop ? AppColors.accent : AppColors.textPrimary, fontWeight: isTop ? FontWeight.w600 : FontWeight.normal)),
                          ),
                          if (isTop) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.star, size: 12, color: AppColors.accent),
                          ],
                        ],
                      ),
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
                      valueColor: AlwaysStoppedAnimation<Color>(isTop ? AppColors.accent : AppColors.info),
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

  Widget _buildUsageStats(ItemRecord item) {
    final now = DateTime.now();
    final nowDay = DateTime(now.year, now.month, now.day);

    int getDays() {
      switch (_selectedRange) {
        case StatsRange.sevenDays:
          return 7;
        case StatsRange.thirtyDays:
          return 30;
        case StatsRange.all:
          if (item.history.isEmpty) return 7;
          final earliest = item.history.map((h) => h.time).reduce((a, b) => a.isBefore(b) ? a : b);
          final diff = nowDay.difference(DateTime(earliest.year, earliest.month, earliest.day)).inDays + 1;
          return diff < 7 ? 7 : diff;
      }
    }

    final totalDays = getDays();

    final days = List.generate(totalDays, (i) {
      final d = nowDay.subtract(Duration(days: totalDays - 1 - i));
      return d;
    });

    final counts = days.map((day) {
      return item.history.where((h) {
        final ht = DateTime(h.time.year, h.time.month, h.time.day);
        return ht.year == day.year && ht.month == day.month && ht.day == day.day;
      }).length;
    }).toList();

    final maxVal = counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal < 1 ? 1 : maxVal;

    String _formatDate(DateTime d) {
      return '${d.month}/${d.day}';
    }

    String _rangeLabel() {
      switch (_selectedRange) {
        case StatsRange.sevenDays:
          return '近7天';
        case StatsRange.thirtyDays:
          return '近30天';
        case StatsRange.all:
          return '全部';
      }
    }

    final shouldShowAllLabels = totalDays <= 15;
    final step = shouldShowAllLabels ? 1 : (totalDays / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('使用统计（${_rangeLabel()}）', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRangeButton(StatsRange.sevenDays, '7天'),
                    _buildRangeButton(StatsRange.thirtyDays, '30天'),
                    _buildRangeButton(StatsRange.all, '全部'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: counts.asMap().entries.map((entry) {
                final idx = entry.key;
                final v = entry.value;
                final day = days[idx];
                final isToday = day.year == nowDay.year && day.month == nowDay.month && day.day == nowDay.day;
                final showLabel = shouldShowAllLabels || idx % step == 0 || idx == counts.length - 1;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (showLabel && v > 0)
                          Text('$v', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        if (!showLabel || v == 0)
                          const SizedBox(height: 14),
                        const SizedBox(height: 4),
                        Container(
                          height: (v / safeMax) * 70,
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.accent : AppColors.accentLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          showLabel ? _formatDate(day) : '',
                          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                        ),
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

  Widget _buildRangeButton(StatsRange range, String label) {
    final isSelected = _selectedRange == range;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRange = range;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
