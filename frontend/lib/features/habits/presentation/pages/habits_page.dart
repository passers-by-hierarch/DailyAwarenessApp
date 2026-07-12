import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/state/app_store.dart';

/// 习惯页面 - 对齐 HabitsPage.tsx
/// 完成率 + 热力图 + 行为排行 + 标签集锦 + 策略建议
class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  String _range = 'week'; // today/week/month/custom
  AgendaLevel? _selectedLevel; // null = 全部
  DateTime? _customStart;
  DateTime? _customEnd;
  final Set<String> _dismissedSuggestions = {}; // 已忽略的建议ID
  final Set<String> _acceptedSuggestions = {}; // 已采纳的建议ID

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final stats = _computeStats(store);

    return Container(
      color: AppColors.bgPrimary,
      child: Column(
        children: [
          // 顶部标题（4.3.1）
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.bgPrimary,
            child: Row(
              children: [
                const Text(
                  '习惯',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(RouteNames.weeklyReport);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.description, size: 16, color: AppColors.accent),
                      const SizedBox(width: 4),
                      const Text(
                        '周报详情',
                        style: TextStyle(fontSize: 14, color: AppColors.accent),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                // 时间范围切换
                _buildRangeSelector(),
                const SizedBox(height: 12),
                // 用户画像卡片
                _buildUserProfileCard(store),
                const SizedBox(height: 12),
                // 核心指标卡
                _buildCompletionCard(stats.completionRate, store),
                const SizedBox(height: 12),
                // 完成趋势
                _buildCompletionTrend(store),
                const SizedBox(height: 12),
                // 事程排行
                _buildBehaviorRanking(store),
                const SizedBox(height: 12),
                // 最佳时间推荐
                _buildBestTimeSuggestions(store),
                const SizedBox(height: 12),
                // 习惯链推荐
                _buildHabitChainSuggestions(store),
                const SizedBox(height: 12),
                // 标签集锦
                _buildTagShowcase(),
                const SizedBox(height: 12),
                // 策略优化建议
                _buildSuggestions(store),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 时间范围切换（4.3.2）
  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.bgPrimary,
      child: Row(
        children: [
          _rangeBtn('今日', 'today'),
          const SizedBox(width: 16),
          _rangeBtn('本周', 'week'),
          const SizedBox(width: 16),
          _rangeBtn('本月', 'month'),
          const SizedBox(width: 16),
          _buildCustomRangeBtn(),
        ],
      ),
    );
  }

  Widget _buildCustomRangeBtn() {
    final active = _range == 'custom';
    final hasRange = _customStart != null && _customEnd != null;
    final label = hasRange
        ? '${_customStart!.month}/${_customStart!.day}-${_customEnd!.month}/${_customEnd!.day}'
        : '自定义';

    return GestureDetector(
      onTap: _showCustomDatePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: active ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.edit_calendar, size: 12, color: active ? AppColors.accent : AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 2),
            Container(
              height: 2,
              width: active ? 36 : 0,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeBtn(String label, String key) {
    final active = _range == key;
    final now = DateTime.now();
    String? subLabel;

    if (key == 'today') {
      subLabel = '${now.month}/${now.day}';
    } else if (key == 'week') {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      subLabel = '${weekStart.month}/${weekStart.day}-${weekEnd.month}/${weekEnd.day}';
    } else if (key == 'month') {
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      subLabel = '${monthStart.month}/${monthStart.day}-${monthEnd.month}/${monthEnd.day}';
    }

    return GestureDetector(
      onTap: () {
        if (key == 'custom') {
          _showCustomDatePicker();
        } else {
          setState(() => _range = key);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: active ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            if (subLabel != null)
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: active ? AppColors.accent.withOpacity(0.7) : AppColors.textTertiary,
                ),
              ),
            const SizedBox(height: 2),
            Container(
              height: 2,
              width: active ? 28 : 0,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDatePicker() async {
    final now = DateTime.now();
    final initialStart = _customStart ?? now.subtract(const Duration(days: 7));
    final initialEnd = _customEnd ?? now;

    final pickedStart = await showDatePicker(
      context: context,
      initialDate: initialStart,
      firstDate: DateTime(2024),
      lastDate: now,
      helpText: '选择开始日期',
    );
    if (pickedStart == null) return;

    final pickedEnd = await showDatePicker(
      context: context,
      initialDate: initialEnd.isAfter(pickedStart) ? initialEnd : pickedStart,
      firstDate: pickedStart,
      lastDate: now,
      helpText: '选择结束日期',
    );
    if (pickedEnd == null) return;

    setState(() {
      _range = 'custom';
      _customStart = pickedStart;
      _customEnd = pickedEnd;
    });
  }

  StatsData _computeStats(AppStore store) {
    if (_range == 'custom' && _customStart != null && _customEnd != null) {
      return store.computeStatsForDateRange(_customStart!, _customEnd!, level: _selectedLevel);
    }
    return store.computeStats(_range, level: _selectedLevel);
  }

  String _rangeLabel() {
    switch (_range) {
      case 'today': return '今日';
      case 'week': return '本周';
      case 'month': return '本月';
      case 'custom':
        if (_customStart != null && _customEnd != null) {
          return '${_customStart!.month}/${_customStart!.day}-${_customEnd!.month}/${_customEnd!.day}';
        }
        return '自定义';
      default: return '本周';
    }
  }

  String _compareLabel() {
    switch (_range) {
      case 'today': return '今日完成情况';
      case 'week': return '本周完成情况';
      case 'month': return '本月完成情况';
      case 'custom': return '自定义时间段完成情况';
      default: return '本周完成情况';
    }
  }

  // 核心指标卡（4.3.3）
  Widget _buildCompletionCard(int rate, AppStore store) {
    final trendData = store.getCompletionTrend(_range, customStart: _customStart, customEnd: _customEnd, level: _selectedLevel);
    final displayData = trendData.length > 7 ? trendData.sublist(trendData.length - 7) : trendData;
    final displayLabels = displayData.map((d) => d['label'] as String).toList();

    // 5种状态配置（从上到下显示）
    final statusConfigs = [
      {'key': 'pending', 'label': '待进行', 'color': AppColors.bgTertiary, 'textColor': AppColors.textSecondary},
      {'key': 'completed', 'label': '已完成', 'color': AppColors.success, 'textColor': AppColors.success},
      {'key': 'skipped', 'label': '已跳过', 'color': AppColors.textTertiary, 'textColor': AppColors.textTertiary},
      {'key': 'postponed', 'label': '已延后', 'color': AppColors.warning, 'textColor': AppColors.warning},
      {'key': 'expired', 'label': '已过期', 'color': AppColors.danger, 'textColor': AppColors.danger},
    ];

    // 完成细分统计：按时完成 / 延期完成 / 跳过后完成
    int totalOnTime = 0;
    int totalPostponed = 0;
    int totalAfterSkip = 0;
    for (final day in displayData) {
      totalOnTime += day['completedOnTime'] as int;
      totalPostponed += day['completedPostponed'] as int;
      totalAfterSkip += day['completedAfterSkip'] as int;
    }
    final totalCompleted = totalOnTime + totalPostponed + totalAfterSkip;

    // 找出每日每个状态的最大值，用于颜色深浅计算
    int maxCount = 1;
    for (final day in displayData) {
      for (final cfg in statusConfigs) {
        final c = day[cfg['key']] as int;
        if (c > maxCount) maxCount = c;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：左侧完成率，右侧级别筛选
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_rangeLabel()}完成率',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$rate%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_upward, size: 12, color: AppColors.success),
                        const SizedBox(width: 2),
                        const Text(
                          '5%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildLevelSelector(),
            ],
          ),
          const SizedBox(height: 16),
          // 第二部分：事程热力图
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '事程热力图',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              // 图例放在右上
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: statusConfigs.map((cfg) => _buildLegendItem(
                  cfg['color'] as Color, cfg['label'] as String,
                )).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 网格热力图：纵轴5种状态，横轴日期
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth - 48;
              final columnCount = displayLabels.length;
              final columnWidth = columnCount > 0 ? availableWidth / columnCount : 0;
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    child: Column(
                      children: statusConfigs.map((cfg) {
                        return SizedBox(
                          height: 24,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              cfg['label'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: cfg['textColor'] as Color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: displayLabels.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final label = entry.value;
                        final dayData = displayData[idx];
                        return Expanded(
                          child: Container(
                            margin: idx < columnCount - 1 ? const EdgeInsets.only(right: 2) : null,
                            child: Column(
                              children: [
                                ...statusConfigs.map((cfg) {
                                  final count = dayData[cfg['key']] as int;
                                  final baseColor = cfg['color'] as Color;
                                  final cellColor = count > 0
                                      ? baseColor
                                      : AppColors.bgTertiary.withOpacity(0.3);
                                  return Tooltip(
                                    message: '${cfg['label']}: $count',
                                    child: Container(
                                      height: 20,
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: cellColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: count > 0
                                          ? Center(
                                              child: Text(
                                                '$count',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: _needsLightText(baseColor)
                                                      ? Colors.white
                                                      : AppColors.textPrimary,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 2),
                                Text(
                                  label,
                                  style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
          // 完成细分统计：按时完成 / 延期完成 / 跳过后完成
          if (totalCompleted > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '完成质量',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // 按时完成
                      Expanded(
                        child: _buildCompletionQualityItem(
                          '按时完成',
                          totalOnTime,
                          totalCompleted,
                          AppColors.success,
                        ),
                      ),
                      // 延期完成
                      Expanded(
                        child: _buildCompletionQualityItem(
                          '延期完成',
                          totalPostponed,
                          totalCompleted,
                          AppColors.warning,
                        ),
                      ),
                      // 跳过后完成
                      Expanded(
                        child: _buildCompletionQualityItem(
                          '跳过后完成',
                          totalAfterSkip,
                          totalCompleted,
                          AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 完成质量细分项
  Widget _buildCompletionQualityItem(String label, int count, int total, Color color) {
    final percent = total > 0 ? (count / total * 100).round() : 0;
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 4),
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 判断颜色是否偏深，需要用白色文字
  bool _needsLightText(Color color) {
    return color == AppColors.success ||
        color == AppColors.danger ||
        color == AppColors.warning;
  }

  Widget _buildLevelSelector() {
    final levels = [
      {'value': null, 'label': '全部', 'color': AppColors.textPrimary},
      {'value': AgendaLevel.normal, 'label': '普通', 'color': AppColors.accent},
      {'value': AgendaLevel.mustDoShort, 'label': '短必做', 'color': AppColors.danger},
      {'value': AgendaLevel.mustDoLong, 'label': '长必做', 'color': AppColors.warning},
    ];
    return Wrap(
      spacing: 4,
      alignment: WrapAlignment.center,
      children: levels.map((lv) {
        final selected = _selectedLevel == lv['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedLevel = lv['value'] as AgendaLevel?),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? (lv['color'] as Color).withOpacity(0.1) : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? (lv['color'] as Color) : AppColors.border,
              ),
            ),
            child: Text(
              lv['label'] as String,
              style: TextStyle(
                fontSize: 11,
                color: selected ? (lv['color'] as Color) : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _heatmapTitle() {
    switch (_range) {
      case 'today': return '今日事程热力图';
      case 'week': return '近7天事程热力图';
      case 'month': return '近30天事程热力图';
      case 'custom': return '自定义时间段事程热力图';
      default: return '近7天事程热力图';
    }
  }

  Color _getLevelColor(AgendaLevel level) {
    switch (level) {
      case AgendaLevel.mustDoLong:
      case AgendaLevel.mustDoShort:
        return AppColors.danger;
      case AgendaLevel.important:
        return AppColors.warning;
      case AgendaLevel.normal:
        return AppColors.accent;
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case -1: return Colors.transparent;
      case 0: return AppColors.bgTertiary;
      case 1: return AppColors.success;
      case 2: return AppColors.textTertiary;
      case 3: return AppColors.warning;
      case 4: return AppColors.danger;
      default: return AppColors.bgTertiary;
    }
  }

  String _getStatusLabel(int status) {
    switch (status) {
      case -1: return '无事程';
      case 0: return '待进行';
      case 1: return '已完成';
      case 2: return '已跳过';
      case 3: return '已延后';
      case 4: return '已过期';
      default: return '未知';
    }
  }

  // 事程热力图（4.3.4）- 按级别分组，行高根据事程数量调整
  Widget _buildHeatmap(AppStore store) {
    final heatmapData = store.getAgendaHeatmap(_range, customStart: _customStart, customEnd: _customEnd, level: _selectedLevel);
    final labels = heatmapData['labels'] as List<String>;
    final data = heatmapData['data'] as List<List<int>>;
    final levels = heatmapData['levels'] as List<AgendaLevel>;
    final counts = heatmapData['counts'] as List<int>;
    final dayCount = heatmapData['dayCount'] as int;

    final cellSize = dayCount <= 7 ? 28.0 : (dayCount <= 14 ? 22.0 : 16.0);
    final fontSize = dayCount <= 7 ? 12.0 : (dayCount <= 14 ? 10.0 : 9.0);
    const labelColumnWidth = 100.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '事程热力图',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(AppColors.bgTertiary, '待进行'),
              const SizedBox(width: 12),
              _buildLegendItem(AppColors.success, '已完成'),
              const SizedBox(width: 12),
              _buildLegendItem(AppColors.textTertiary, '已跳过'),
              const SizedBox(width: 12),
              _buildLegendItem(AppColors.warning, '已延后'),
              const SizedBox(width: 12),
              _buildLegendItem(AppColors.danger, '已过期'),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: labelColumnWidth,
                  child: Column(
                    children: [
                      SizedBox(height: fontSize + 4),
                      ...List.generate(levels.length, (index) {
                        final level = levels[index];
                        final count = counts[index];
                        final levelColor = _getLevelColor(level);
                        final levelLabel = _getLevelLabel(level);
                        final rowHeight = (cellSize + 4) * (count > 0 ? count : 1);
                        return SizedBox(
                          height: rowHeight,
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: rowHeight * 0.6,
                                decoration: BoxDecoration(
                                  color: levelColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      levelLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: fontSize - 1,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$count项',
                                      style: TextStyle(
                                        fontSize: fontSize - 2,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: fontSize + 4,
                      child: Row(
                        children: labels.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final label = entry.value;
                          final shouldShow = dayCount <= 7 ||
                              (dayCount <= 14 && idx % 2 == 0) ||
                              (dayCount > 14 && (idx % 5 == 0 || idx == labels.length - 1));
                          return SizedBox(
                            width: cellSize,
                            child: Center(
                              child: Text(
                                shouldShow ? label : '',
                                style: TextStyle(
                                  fontSize: fontSize - 2,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    ...List.generate(levels.length, (row) {
                      final count = counts[row];
                      final rowHeight = (cellSize + 4) * (count > 0 ? count : 1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: List.generate(dayCount, (col) {
                            final status = data[row][col];
                            final statusColor = _getStatusColor(status);
                            return Tooltip(
                              message: _getStatusLabel(status),
                              child: Container(
                                width: cellSize,
                                height: rowHeight,
                                padding: const EdgeInsets.all(1.5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  String? _findAgendaIdByContent(AppStore store, String content) {
    try {
      final agenda = store.agendaItems.firstWhere((a) => a.content == content);
      return agenda.id;
    } catch (_) {
      return null;
    }
  }

  Widget _buildRankingItem(Map<String, dynamic> item, AppStore store) {
    final content = item['content'] as String;
    final streak = item['streak'] as int;
    final rate = item['rate'] as int;
    final completed = item['completed'] as int;
    final total = item['total'] as int;

    return GestureDetector(
      onTap: () {
        final agendaId = _findAgendaIdByContent(store, content);
        if (agendaId != null) {
          Navigator.pushNamed(context, RouteNames.agendaDetail, arguments: agendaId);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 2),
                      Text(
                        '$streak天',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$rate%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$completed/$total',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  // 事程排行（4.3.5）- 按级别分组
  Widget _buildBehaviorRanking(AppStore store) {
    final rankingByLevel = store.getAgendaRankingByLevel(_range, customStart: _customStart, customEnd: _customEnd);

    final levelConfigs = [
      {'key': 'mustDoLong', 'label': '长期必做', 'color': AppColors.danger},
      {'key': 'mustDoShort', 'label': '短期必做', 'color': AppColors.danger},
      {'key': 'important', 'label': '重要', 'color': AppColors.warning},
      {'key': 'normal', 'label': '普通', 'color': AppColors.accent},
    ];

    final hasAnyData = levelConfigs.any((config) {
      final list = rankingByLevel[config['key']] as List?;
      return list != null && list.isNotEmpty;
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '事程排行',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasAnyData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '添加事程开始培养习惯吧',
                  style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                ),
              ),
            )
          else
            ...levelConfigs.where((config) {
              final list = rankingByLevel[config['key']] as List?;
              return list != null && list.isNotEmpty;
            }).map((config) {
              final key = config['key'] as String;
              final label = config['label'] as String;
              final color = config['color'] as Color;
              final list = (rankingByLevel[key] as List).cast<Map<String, dynamic>>();
              final top3 = list.take(3).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  ...top3.map((item) => _buildRankingItem(item, store)),
                  const SizedBox(height: 4),
                ],
              );
            }),
        ],
      ),
    );
  }

  Color _getTrendBarColor(int rate) {
    if (_selectedLevel != null) {
      return _getLevelColor(_selectedLevel!);
    }
    if (rate >= 90) return AppColors.success;
    if (rate >= 60) return AppColors.accent;
    return AppColors.warning;
  }

  // 完成趋势 - 完成率曲线图
  Widget _buildCompletionTrend(AppStore store) {
    final trendData = store.getCompletionTrend(_range, customStart: _customStart, customEnd: _customEnd, level: _selectedLevel);
    const chartHeight = 140.0;
    const labelHeight = 30.0;
    final dayCount = trendData.length;
    final useScroll = dayCount > 14;
    final barWidth = useScroll ? 32.0 : (MediaQuery.of(context).size.width - 64) / dayCount;

    // 计算每天的完成率
    final rates = trendData.map((d) {
      final total = d['total'] as int;
      final completed = d['completed'] as int;
      return total > 0 ? (completed / total * 100).round() : 0;
    }).toList();

    // 生成曲线路径
    Path generateLinePath(double width, double height, List<int> values) {
      final path = Path();
      if (values.isEmpty) return path;

      final stepX = width / (values.length > 1 ? values.length - 1 : 1);
      for (int i = 0; i < values.length; i++) {
        final x = stepX * i;
        final y = height - (values[i] / 100) * height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          // 使用贝塞尔曲线平滑
          final prevX = stepX * (i - 1);
          final prevY = height - (values[i - 1] / 100) * height;
          final cpx = (prevX + x) / 2;
          path.cubicTo(cpx, prevY, cpx, y, x, y);
        }
      }
      return path;
    }

    // 生成渐变填充路径
    Path generateFillPath(double width, double height, List<int> values) {
      final linePath = generateLinePath(width, height, values);
      final fillPath = Path.from(linePath);
      if (values.isNotEmpty) {
        final stepX = width / (values.length > 1 ? values.length - 1 : 1);
        final lastX = stepX * (values.length - 1);
        fillPath.lineTo(lastX, height);
        fillPath.lineTo(0, height);
        fillPath.close();
      }
      return fillPath;
    }

    Widget _buildChart() {
      final totalWidth = useScroll ? (dayCount * barWidth) : double.infinity;
      return SizedBox(
        height: chartHeight + labelHeight,
        child: CustomPaint(
          size: Size(totalWidth, chartHeight + labelHeight),
          painter: _TrendChartPainter(
            rates: rates,
            labels: trendData.map((d) => d['label'] as String).toList(),
            chartHeight: chartHeight,
            barWidth: barWidth,
            useScroll: useScroll,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '完成趋势',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // 图例：完成率曲线
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 2,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '完成率',
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          useScroll
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildChart(),
                )
              : _buildChart(),
        ],
      ),
    );
  }

  String _getLevelLabel(AgendaLevel level) {
    switch (level) {
      case AgendaLevel.mustDoLong:
        return '长期必做';
      case AgendaLevel.mustDoShort:
        return '短期必做';
      case AgendaLevel.important:
        return '重要';
      case AgendaLevel.normal:
        return '普通';
    }
  }

  List<Map<String, dynamic>> _computeBestTimeSuggestions(AppStore store) {
    final suggestions = <Map<String, dynamic>>[];
    final records = store.timelineRecords;
    final agendaItems = store.agendaItems;

    final agendaTimeMap = <String, List<int>>{};

    for (final record in records) {
      if (record.linkedAgendaId != null && record.linkedAgendaId!.isNotEmpty) {
        final agendaId = record.linkedAgendaId!;
        final minutes = record.time.hour * 60 + record.time.minute;
        if (!agendaTimeMap.containsKey(agendaId)) {
          agendaTimeMap[agendaId] = [];
        }
        agendaTimeMap[agendaId]!.add(minutes);
      }
    }

    for (final agenda in agendaItems) {
      final times = agendaTimeMap[agenda.id];
      if (times == null || times.length < 3) continue;

      times.sort();
      final mid = times.length ~/ 2;
      int medianMinutes;
      if (times.length % 2 == 1) {
        medianMinutes = times[mid];
      } else {
        medianMinutes = ((times[mid - 1] + times[mid]) / 2).round();
      }

      final scheduledParts = agenda.time.split(':');
      final scheduledMinutes = (int.tryParse(scheduledParts[0]) ?? 0) * 60 +
          (int.tryParse(scheduledParts[1]) ?? 0);
      final diff = (medianMinutes - scheduledMinutes).abs();

      if (diff >= 15) {
        final bestHour = (medianMinutes ~/ 60).toString().padLeft(2, '0');
        final bestMinute = (medianMinutes % 60).toString().padLeft(2, '0');
        final bestTime = '$bestHour:$bestMinute';

        suggestions.add({
          'agendaId': agenda.id,
          'content': agenda.content,
          'currentTime': agenda.time,
          'suggestedTime': bestTime,
          'sampleCount': times.length,
        });
      }
    }

    suggestions.sort((a, b) => (b['sampleCount'] as int).compareTo(a['sampleCount'] as int));
    return suggestions.take(5).toList();
  }

  void _adjustAgendaTime(String agendaId, String newTime, AppStore store) {
    final agenda = store.agendaItems.firstWhere((a) => a.id == agendaId);
    store.updateAgenda(agendaId, agenda.copyWith(time: newTime));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已将「${agenda.content}」调整至 $newTime'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 最佳时间推荐
  Widget _buildBestTimeSuggestions(AppStore store) {
    final suggestions = _computeBestTimeSuggestions(store);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '最佳时间推荐',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.schedule, size: 14, color: AppColors.accent),
                  SizedBox(width: 4),
                  Text('AI 分析', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (suggestions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '暂无时间推荐，继续记录吧',
                  style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                ),
              ),
            )
          else
            ...suggestions.map((s) {
              final content = s['content'] as String;
              final currentTime = s['currentTime'] as String;
              final suggestedTime = s['suggestedTime'] as String;
              final sampleCount = s['sampleCount'] as int;
              final agendaId = s['agendaId'] as String;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                currentTime,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 12, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Icon(Icons.access_time, size: 12, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                suggestedTime,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '($sampleCount次)',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => _adjustAgendaTime(agendaId, suggestedTime, store),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '调整时间',
                          style: TextStyle(fontSize: 12),
                        ),
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

  void _addHabitChainSuggestion(Map<String, dynamic> suggestion, AppStore store) {
    final content = suggestion['content'] as String;
    final time = suggestion['time'] as String;
    final level = suggestion['level'] as AgendaLevel;

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final icon = store.autoDetectIcon(content);

    store.addAgenda(AgendaItem(
      id: '',
      content: content,
      time: time,
      date: todayStr,
      icon: icon,
      isMustDo: level.isMustDo,
      level: level,
      source: AgendaSource.ai,
      category: AgendaCategory.custom,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加事程：$content ($time)'), duration: const Duration(seconds: 2)),
    );
  }

  // 习惯链推荐
  Widget _buildHabitChainSuggestions(AppStore store) {
    final suggestions = store.getHabitChainSuggestions();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '习惯链推荐',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.link, size: 14, color: AppColors.accent),
                  SizedBox(width: 4),
                  Text('AI 推荐', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (suggestions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '暂无推荐，继续培养好习惯吧',
                  style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                ),
              ),
            )
          else
            ...suggestions.map((s) {
              final content = s['content'] as String;
              final time = s['time'] as String;
              final level = s['level'] as AgendaLevel;
              final reason = s['reason'] as String;
              final trigger = s['trigger'] as String;
              final levelColor = _getLevelColor(level);
              final levelLabel = _getLevelLabel(level);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: levelColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            levelLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: levelColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '来自「$trigger」',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _addHabitChainSuggestion(s, store),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add, size: 16),
                            SizedBox(width: 4),
                            Text('添加', style: TextStyle(fontSize: 13)),
                          ],
                        ),
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

  // 标签集锦（4.3.6）
  Widget _buildTagShowcase() {
    final store = context.watch<AppStore>();
    final allTags = store.allTags;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 区块标题：左侧圆点 + 管理按钮
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '标签集锦',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/tag-management');
                },
                child: const Text('管理', style: TextStyle(fontSize: 12, color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 时间范围切换（本周/本月/全部）
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tagRangeBtn('本周', 'week'),
                _tagRangeBtn('本月', 'month'),
                _tagRangeBtn('全部', 'all'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 标签使用统计图表
          if (allTags.isNotEmpty)
            _buildTagChart(store, allTags),
          const SizedBox(height: 16),
          // 标签网格
          if (allTags.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('暂无标签，记录时添加标签即可生成', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            )
          else
            Builder(
              builder: (context) {
                // 按使用次数排序
                final sortedTags = [...allTags]
                  ..sort((a, b) => store.getTagUsageCount(b.id).compareTo(store.getTagUsageCount(a.id)));
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sortedTags.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final tag = entry.value;
                    final count = store.getTagUsageCount(tag.id);
                    final colorSet = AppColors.tagColors[tag.color] ?? AppColors.tagColors['gray']!;
                    final isTop3 = idx < 3 && count > 0;
                    return GestureDetector(
                      onTap: () => _showTagDetail(context, tag, store),
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 96) / 4,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.bgSecondary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppColors.cardShadow,
                          border: isTop3 ? Border.all(color: colorSet.color.withOpacity(0.4), width: 1.5) : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colorSet.bg,
                                shape: BoxShape.circle,
                                border: Border.all(color: colorSet.color.withOpacity(0.2)),
                              ),
                              child: Center(
                                child: _buildTagIcon(tag),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tag.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorSet.bg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: colorSet.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTagChart(AppStore store, List<TagDef> tags) {
    final sortedTags = [...tags]
      ..sort((a, b) => store.getTagUsageCount(b.id).compareTo(store.getTagUsageCount(a.id)));
    final topTags = sortedTags.take(4).toList();
    final maxCount = topTags.isEmpty ? 1 : topTags.map((t) => store.getTagUsageCount(t.id)).reduce((a, b) => a > b ? a : b);
    final safeMax = maxCount < 1 ? 1 : maxCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('使用分布', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          ...topTags.map((tag) {
            final count = store.getTagUsageCount(tag.id);
            final colorSet = AppColors.tagColors[tag.color] ?? AppColors.tagColors['gray']!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorSet.bg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(child: _buildTagIcon(tag, size: 14)),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Text(tag.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: count / safeMax,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(colorSet.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$count',
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: colorSet.color)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTagIcon(TagDef tag, {double size = 16}) {
    if (tag.icon.isEmpty || tag.icon == '#') {
      return Icon(Icons.label_outline, size: size, color: AppColors.textSecondary);
    }
    // emoji 图标（包含非ASCII字符的视为emoji）
    if (tag.icon.runes.any((r) => r > 127)) {
      return Text(tag.icon, style: TextStyle(fontSize: size));
    }
    // Lucide 图标名称映射
    final iconMap = <String, IconData>{
      'activity': AppIcons.activity,
      'package': AppIcons.package,
      'shopping_cart': AppIcons.shoppingCart,
      'map_pin': AppIcons.mapPin,
      'tag': AppIcons.tag,
      'hash': AppIcons.hash,
      'star': AppIcons.star,
      'target': AppIcons.target,
      'heart': AppIcons.heart,
      'book': AppIcons.book,
      'droplet': AppIcons.droplet,
      'sun': AppIcons.sun,
      'moon': AppIcons.moon,
      'clock': AppIcons.clock,
      'bell': AppIcons.bell,
      'calendar': AppIcons.calendar,
      'search': AppIcons.search,
      'settings': AppIcons.settings,
      'user': AppIcons.user,
      'home': AppIcons.home,
      'message_circle': AppIcons.messageCircle,
      'trending_up': AppIcons.trendingUp,
      'sparkles': AppIcons.sparkles,
    };
    final iconData = iconMap[tag.icon];
    if (iconData != null) {
      return Icon(iconData, size: size, color: AppColors.textSecondary);
    }
    // 未知图标显示 #
    return Icon(Icons.label_outline, size: size, color: AppColors.textSecondary);
  }

  void _showTagDetail(BuildContext context, TagDef tag, AppStore store) {
    final records = store.getRecordsByTag(tag.id);
    final colorSet = AppColors.tagColors[tag.color] ?? AppColors.tagColors['gray']!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorSet.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorSet.color.withOpacity(0.2)),
                  ),
                  child: Center(child: _buildTagIcon(tag, size: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tag.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('共 ${records.length} 条记录', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text('相关记录', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('暂无相关记录', style: TextStyle(fontSize: 13, color: AppColors.textTertiary))),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length > 20 ? 20 : records.length,
                  itemBuilder: (ctx, i) {
                    final r = records[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.content, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(
                            '${r.date} ${r.time}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (records.length > 20) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '仅显示最近20条，更多请在时间线中查看',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _tagRange = 'week';
  
  Widget _tagRangeBtn(String label, String key) {
    final active = _tagRange == key;
    return GestureDetector(
      onTap: () => setState(() => _tagRange = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.bgSecondary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // 用户画像卡片
  Widget _buildUserProfileCard(AppStore store) {
    final profile = store.userProfile;
    final totalRecords = store.timelineRecords.length;
    final totalAgendas = store.agendaItems.length;
    final completedAgendas = store.agendaItems.where((a) => a.status == AgendaStatus.completed).length;

    String persona = '';
    List<String> tags = [];
    if (profile.isElderly) {
      persona = '健康生活达人';
      tags = ['注重健康', '作息规律', '坚持运动'];
    } else {
      persona = '效率提升者';
      tags = ['高效', '自律', '目标导向'];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withOpacity(0.15), AppColors.info.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_outline, size: 28, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      persona,
                      style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Lv.${(totalRecords / 10).floor() + 1}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 标签
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 统计数据
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('$totalRecords', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    const Text('时间线记录', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              Expanded(
                child: Column(
                  children: [
                    Text('$completedAgendas/$totalAgendas', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    const Text('事程完成', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              Expanded(
                child: Column(
                  children: [
                    Text('${store.earnedBadges.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    const Text('获得徽章', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 策略优化建议（4.3.7）- 智能推荐版本
  Widget _buildSuggestions(AppStore store) {
    final suggestions = _generateSmartSuggestions(store);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 区块标题：左侧圆点
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '智能优化建议',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.auto_awesome, size: 14, color: AppColors.accent),
                  SizedBox(width: 4),
                  Text('AI 推荐', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 建议卡片列表
          ...suggestions.map((s) {
            final type = s['type'] as String;
            final isWarning = type == 'warning';
            final isAgenda = type == 'agenda';
            final iconColor = isWarning ? AppColors.danger : (isAgenda ? AppColors.success : AppColors.accent);
            final icon = isWarning ? Icons.warning_amber_rounded : (isAgenda ? Icons.event_available : Icons.lightbulb_outline);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.cardShadow,
                border: isWarning
                    ? Border.all(color: AppColors.danger.withOpacity(0.3), width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 发现文字（带图标）
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 16, color: iconColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s['finding'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: isWarning ? AppColors.danger : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 建议文字
                  Text(
                    s['suggestion'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 按钮组
                  Row(
                    children: [
                      // 接受/采纳按钮
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptSuggestion(s, store),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAgenda ? AppColors.success : AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isAgenda ? Icons.add : Icons.check, size: 16),
                              const SizedBox(width: 4),
                              Text(s['actionText'] as String? ?? '采纳', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 忽略按钮
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _dismissSuggestion(s['id'] as String),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bgTertiary,
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close, size: 16),
                              SizedBox(width: 4),
                              Text('忽略', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          if (suggestions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                  SizedBox(height: 12),
                  Text('暂无新建议，继续保持！', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateSmartSuggestions(AppStore store) {
    final profile = store.userProfile;
    final stats = _computeStats(store);
    final agendaStats = store.getAgendaCompletionStats(_range);
    final inventoryHabits = store.getInventoryHabits();
    final timelineAnalysis = store.getTimelineAnalysis(_range);
    final suggestions = <Map<String, dynamic>>[];

    // ===== 1. 基于事程完成情况分析 =====

    final totalAgendas = agendaStats['total'] ?? 0;
    final completed = agendaStats['completed'] ?? 0;
    final expired = agendaStats['expired'] ?? 0;
    final skipped = agendaStats['skipped'] ?? 0;
    final postponed = agendaStats['postponed'] ?? 0;

    // 完成率分析
    if (totalAgendas > 0) {
      final rate = ((completed / totalAgendas) * 100).round();
      if (rate < 50) {
        suggestions.add({
          'id': 'agenda_low_completion',
          'finding': 'AI分析：${_rangeLabel()}事程完成率仅 $rate%（$completed/$totalAgendas）',
          'suggestion': '完成率偏低，建议：1）减少事程数量 2）将重要事项设为必做 3）合理安排时间间隔',
          'priority': 'high',
          'type': 'tip',
          'actionText': '我知道了',
        });
      } else if (rate >= 90) {
        suggestions.add({
          'id': 'agenda_high_completion',
          'finding': 'AI分析：${_rangeLabel()}事程完成率 $rate%，表现优秀！',
          'suggestion': '保持良好节奏，可以尝试增加一些新的健康习惯',
          'priority': 'low',
          'type': 'tip',
          'actionText': '继续加油',
        });
      }
    }

    // 过期/跳过分析
    if (expired >= 3) {
      suggestions.add({
        'id': 'agenda_expired',
        'finding': 'AI分析：${_rangeLabel()}有 $expired 件事程过期未完成',
        'suggestion': '建议检查事程时间安排是否合理，避免设置过多事程；重要事项可设为必做级别',
        'priority': 'high',
        'type': 'tip',
        'actionText': '去调整',
      });
    }

    if (skipped >= 2) {
      suggestions.add({
        'id': 'agenda_skipped',
        'finding': 'AI分析：${_rangeLabel()}跳过了 $skipped 件事程',
        'suggestion': '频繁跳过事程可能影响习惯养成，建议减少不必要的事程或调整难度',
        'priority': 'medium',
        'type': 'tip',
        'actionText': '我知道了',
      });
    }

    if (postponed >= 3) {
      suggestions.add({
        'id': 'agenda_postponed',
        'finding': 'AI分析：${_rangeLabel()}延后了 $postponed 件事程',
        'suggestion': '频繁延后事程说明时间安排需要优化，建议预留缓冲时间',
        'priority': 'medium',
        'type': 'tip',
        'actionText': '我知道了',
      });
    }

    // ===== 2. 基于时间线行为分析 =====

    final totalRecords = timelineAnalysis['total'] ?? 0;
    final morningCount = timelineAnalysis['morning'] ?? 0;
    final eveningCount = timelineAnalysis['evening'] ?? 0;
    final nightCount = timelineAnalysis['night'] ?? 0;

    // 活跃时段分析
    if (nightCount > morningCount && nightCount > 0) {
      suggestions.add({
        'id': 'timeline_night_active',
        'finding': 'AI分析：您夜间（23:00-6:00）记录较多（$nightCount条），作息可能偏晚',
        'suggestion': '建议调整作息，减少夜间活动，保证充足睡眠',
        'priority': 'medium',
        'type': 'agenda',
        'agendaContent': '准备睡觉',
        'agendaTime': '21:30',
        'agendaLevel': 'normal',
        'actionText': '添加事程',
      });
    }

    // 行为规律性分析
    if (stats.topRegular.isNotEmpty) {
      final regular = stats.topRegular.first;
      suggestions.add({
        'id': 'regular_${regular.name}',
        'finding': 'AI分析：您在"${regular.name}"方面最规律（${regular.count}次记录）',
        'suggestion': '保持良好习惯！可尝试将这种规律性扩展到其他方面',
        'priority': 'low',
        'type': 'tip',
        'actionText': '太棒了',
      });
    }

    if (stats.topMissed.isNotEmpty) {
      final missed = stats.topMissed.first;
      suggestions.add({
        'id': 'missed_${missed.name}',
        'finding': 'AI分析："${missed.name}" 是您最常遗漏的行为',
        'suggestion': '建议为此行为创建定时事程，设为必做级别并开启多阶段提醒',
        'priority': 'high',
        'type': 'agenda',
        'agendaContent': missed.name,
        'agendaTime': '09:00',
        'agendaLevel': 'important',
        'actionText': '添加事程',
      });
    }

    // 购买习惯分析
    final topPurchased = timelineAnalysis['topPurchased'] as List;
    if (topPurchased.isNotEmpty && topPurchased.length >= 2) {
      final item = topPurchased.first;
      suggestions.add({
        'id': 'purchase_habit',
        'finding': 'AI分析：您近期最常购买"${item.name}"（${item.count}次）',
        'suggestion': '该物品消耗较快，建议设置定期采购提醒，避免断货',
        'priority': 'low',
        'type': 'tip',
        'actionText': '好的',
      });
    }

    // ===== 3. 基于物品使用习惯分析 =====

    final expiringSoon = inventoryHabits['expiringSoon'] as List;
    final expiredItems = inventoryHabits['expired'] as List;
    final lowStock = inventoryHabits['lowStock'] as List;
    final medicines = inventoryHabits['medicines'] as List;

    // 即将过期提醒
    if (expiringSoon.isNotEmpty) {
      final names = expiringSoon.take(3).map((i) => (i as InventoryItem).name).join('、');
      suggestions.add({
        'id': 'inventory_expiring',
        'finding': 'AI分析：$names 等${expiringSoon.length}件物品即将过期',
        'suggestion': '建议优先使用即将过期的物品，避免浪费',
        'priority': 'high',
        'type': 'warning',
        'actionText': '去查看',
      });
    }

    // 已过期提醒
    if (expiredItems.isNotEmpty) {
      suggestions.add({
        'id': 'inventory_expired',
        'finding': 'AI分析：您有${expiredItems.length}件物品已过期',
        'suggestion': '⚠️ 请及时清理过期物品，特别是药品和食品',
        'priority': 'high',
        'type': 'warning',
        'actionText': '去清理',
      });
    }

    // 低库存提醒
    if (lowStock.isNotEmpty) {
      final names = lowStock.take(3).map((i) => (i as InventoryItem).name).join('、');
      suggestions.add({
        'id': 'inventory_low_stock',
        'finding': 'AI分析：$names 等${lowStock.length}件物品库存不足',
        'suggestion': '建议及时补充，可添加购物提醒',
        'priority': 'medium',
        'type': 'tip',
        'actionText': '去补充',
      });
    }

    // 药品使用习惯分析
    if (medicines.isNotEmpty) {
      suggestions.add({
        'id': 'medicine_usage_warn',
        'finding': 'AI分析：您库存中有${medicines.length}种药品',
        'suggestion': '⚠️ 不建议长期自行服用药物，请定期复诊，遵医嘱调整用药方案',
        'priority': 'high',
        'type': 'warning',
        'actionText': '我知道了',
      });
    }

    // ===== 4. 基于健康状况的建议 =====

    if (profile.hasHypertension) {
      suggestions.add({
        'id': 'health_bp_measure',
        'finding': 'AI分析：您有高血压健康管理需求',
        'suggestion': '建议每天固定时间测量血压并记录，保持低盐饮食',
        'priority': 'high',
        'type': 'agenda',
        'agendaContent': '测量血压',
        'agendaTime': '08:00',
        'agendaLevel': 'important',
        'actionText': '添加事程',
      });
    }

    if (profile.hasDiabetes) {
      suggestions.add({
        'id': 'health_blood_sugar',
        'finding': 'AI分析：您有糖尿病健康管理需求',
        'suggestion': '建议每天监测血糖，控制碳水摄入',
        'priority': 'high',
        'type': 'agenda',
        'agendaContent': '测血糖',
        'agendaTime': '07:30',
        'agendaLevel': 'important',
        'actionText': '添加事程',
      });
    }

    // ===== 5. 通用生活习惯建议 =====

    if (profile.isElderly) {
      suggestions.add({
        'id': 'health_walk',
        'finding': 'AI分析：适量运动对您的健康非常重要',
        'suggestion': '建议每天散步30分钟，促进血液循环和心肺功能',
        'priority': 'medium',
        'type': 'agenda',
        'agendaContent': '散步30分钟',
        'agendaTime': '16:00',
        'agendaLevel': 'normal',
        'actionText': '添加事程',
      });
    }

    // 过滤掉已忽略和已采纳的建议
    suggestions.removeWhere((s) =>
        _dismissedSuggestions.contains(s['id']) ||
        _acceptedSuggestions.contains(s['id']));

    // 按优先级排序，取前6条
    final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
    suggestions.sort((a, b) => priorityOrder[a['priority']]!.compareTo(priorityOrder[b['priority']]!));
    return suggestions.take(6).toList();
  }

  void _acceptSuggestion(Map<String, dynamic> suggestion, AppStore store) {
    final id = suggestion['id'] as String;
    final type = suggestion['type'] as String;

    if (type == 'agenda') {
      // 添加事程
      final content = suggestion['agendaContent'] as String;
      final time = suggestion['agendaTime'] as String;
      final levelStr = suggestion['agendaLevel'] as String;
      AgendaLevel level = AgendaLevel.normal;
      switch (levelStr) {
        case 'important': level = AgendaLevel.important; break;
        case 'mustDo': level = AgendaLevel.mustDoShort; break;
      }

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final icon = store.autoDetectIcon(content);

      store.addAgenda(AgendaItem(
        id: '',
        content: content,
        time: time,
        date: todayStr,
        icon: icon,
        isMustDo: level.isMustDo,
        level: level,
        source: AgendaSource.ai,
        category: AgendaCategory.custom,
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加事程：$content ($time)'), duration: const Duration(seconds: 2)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已采纳建议'), duration: Duration(seconds: 1)),
      );
    }

    setState(() {
      _acceptedSuggestions.add(id);
    });
  }

  void _dismissSuggestion(String id) {
    setState(() {
      _dismissedSuggestions.add(id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已忽略'), duration: Duration(seconds: 1)),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<int> rates;
  final List<String> labels;
  final double chartHeight;
  final double barWidth;
  final bool useScroll;

  _TrendChartPainter({
    required this.rates,
    required this.labels,
    required this.chartHeight,
    required this.barWidth,
    required this.useScroll,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = rates.length;
    if (count == 0) return;

    final chartWidth = useScroll ? (count * barWidth) : size.width;
    final stepX = chartWidth / (count > 1 ? count - 1 : 1);

    // 1. 横向参考线
    final gridPaint = Paint()
      ..color = AppColors.bgTertiary
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final y = chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // 2. 渐变填充区域
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withOpacity(0.25),
          AppColors.accent.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));

    final fillPath = Path();
    final linePath = Path();
    for (int i = 0; i < count; i++) {
      final x = stepX * i;
      final y = chartHeight - (rates[i] / 100) * chartHeight;
      if (i == 0) {
        fillPath.moveTo(x, y);
        linePath.moveTo(x, y);
      } else {
        final prevX = stepX * (i - 1);
        final prevY = chartHeight - (rates[i - 1] / 100) * chartHeight;
        final cpx = (prevX + x) / 2;
        fillPath.cubicTo(cpx, prevY, cpx, y, x, y);
        linePath.cubicTo(cpx, prevY, cpx, y, x, y);
      }
    }
    final lastX = stepX * (count - 1);
    fillPath.lineTo(lastX, chartHeight);
    fillPath.lineTo(0, chartHeight);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // 3. 曲线
    final linePaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // 4. 数据点
    final dotPaint = Paint()..color = AppColors.accent;
    final dotBgPaint = Paint()..color = Colors.white;
    for (int i = 0; i < count; i++) {
      final x = stepX * i;
      final y = chartHeight - (rates[i] / 100) * chartHeight;
      canvas.drawCircle(Offset(x, y), 3.5, dotBgPaint);
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }

    // 5. 日期标签
    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    for (int i = 0; i < count; i++) {
      final x = stepX * i;
      labelPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(x - labelPainter.width / 2, chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return rates != oldDelegate.rates || labels != oldDelegate.labels;
  }
}
