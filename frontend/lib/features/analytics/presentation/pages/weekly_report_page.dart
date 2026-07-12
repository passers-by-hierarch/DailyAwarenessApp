import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/state/app_store.dart';

/// 周报页 - 基于真实数据分析
class WeeklyReportPage extends StatelessWidget {
  const WeeklyReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final stats = store.computeStats('week');
    final agendaStats = store.getAgendaCompletionStats('week');
    final inventoryHabits = store.getInventoryHabits();
    final timelineAnalysis = store.getTimelineAnalysis('week');

    // 计算评分（综合完成率+行为规律性）
    final completionRate = stats.completionRate;
    final regularCount = stats.topRegular.length;
    final score = ((completionRate * 0.6 + regularCount * 8).clamp(0, 100)).round();

    // 每日完成趋势（最近7天）
    final dailyData = _computeDailyTrend(store);

    // 生成亮点
    final highlights = _generateHighlights(stats, agendaStats, inventoryHabits, timelineAnalysis, store);

    // 生成改进建议
    final suggestions = _generateReportSuggestions(stats, agendaStats, inventoryHabits, timelineAnalysis, store);

    return SecondaryScaffold(
      title: '周报',
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: AppColors.accent, size: 20),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('分享链接已生成'), duration: Duration(seconds: 1)),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildScoreCard(score, completionRate, agendaStats, timelineAnalysis),
          const SizedBox(height: 16),
          _buildDailyTrend(dailyData),
          const SizedBox(height: 16),
          _buildAgendaCompletion(agendaStats),
          const SizedBox(height: 16),
          _buildBehaviorRanking(stats),
          const SizedBox(height: 16),
          _buildTimeDistribution(timelineAnalysis),
          const SizedBox(height: 16),
          _buildInventorySummary(inventoryHabits),
          const SizedBox(height: 16),
          _buildHighlights(highlights),
          const SizedBox(height: 16),
          _buildSuggestions(suggestions),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 计算每日完成趋势
  List<Map<String, dynamic>> _computeDailyTrend(AppStore store) {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    final dayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayRecords = store.timelineRecords.where((r) => r.date == dateStr).length;
      final dayAgendas = store.agendaItems.where((a) => a.date == dateStr).length;
      final dayCompleted = store.agendaItems.where((a) => a.date == dateStr && a.status == AgendaStatus.completed).length;
      final rate = dayAgendas > 0 ? dayCompleted / dayAgendas : 0.0;
      result.add({
        'label': dayLabels[date.weekday - 1],
        'rate': rate,
        'records': dayRecords,
        'agendas': dayAgendas,
        'completed': dayCompleted,
      });
    }
    return result;
  }

  /// 生成亮点
  List<String> _generateHighlights(StatsData stats, Map<String, int> agendaStats, Map<String, dynamic> inventory, Map<String, dynamic> timeline, AppStore store) {
    final highlights = <String>[];

    // 完成率亮点
    if (stats.completionRate >= 80) {
      highlights.add('本周完成率达到 ${stats.completionRate}%，表现优秀');
    } else if (stats.completionRate >= 60) {
      highlights.add('本周完成率 ${stats.completionRate}%，仍有提升空间');
    }

    // 事程完成亮点
    final completed = agendaStats['completed'] ?? 0;
    if (completed >= 10) {
      highlights.add('本周共完成 $completed 件事程');
    }

    // 连续记录亮点
    final totalRecords = timeline['total'] ?? 0;
    if (totalRecords >= 20) {
      highlights.add('本周记录了 $totalRecords 条行为，记录习惯良好');
    }

    // 规律行为亮点
    if (stats.topRegular.isNotEmpty) {
      final r = stats.topRegular.first;
      highlights.add('"${r.name}" 保持最规律，本周记录 ${r.count} 次');
    }

    // 连续打卡亮点
    final streakAgendas = store.agendaItems.where((a) => a.streak >= 3).toList();
    if (streakAgendas.isNotEmpty) {
      final maxStreak = streakAgendas.reduce((a, b) => a.streak > b.streak ? a : b);
      highlights.add('"${maxStreak.content}" 连续完成 ${maxStreak.streak} 天');
    }

    if (highlights.isEmpty) {
      highlights.add('开始记录您的生活数据，获取更多个性化分析');
    }

    return highlights;
  }

  /// 生成改进建议
  List<Map<String, dynamic>> _generateReportSuggestions(StatsData stats, Map<String, int> agendaStats, Map<String, dynamic> inventory, Map<String, dynamic> timeline, AppStore store) {
    final suggestions = <Map<String, dynamic>>[];

    // 完成率建议
    final total = agendaStats['total'] ?? 0;
    final completed = agendaStats['completed'] ?? 0;
    final expired = agendaStats['expired'] ?? 0;
    final skipped = agendaStats['skipped'] ?? 0;

    if (total > 0) {
      final rate = ((completed / total) * 100).round();
      if (rate < 60) {
        suggestions.add({
          'text': '事程完成率仅 $rate%，建议减少事程数量，优先完成重要事项',
          'priority': 'high',
        });
      } else if (rate < 80) {
        suggestions.add({
          'text': '事程完成率 $rate%，可以尝试将重要事项设为必做级别',
          'priority': 'medium',
        });
      }
    }

    if (expired >= 3) {
      suggestions.add({
        'text': '本周有 $expired 件事程过期，建议检查时间安排是否合理',
        'priority': 'high',
      });
    }

    if (skipped >= 2) {
      suggestions.add({
        'text': '本周跳过了 $skipped 件事程，建议精简不必要的事程',
        'priority': 'medium',
      });
    }

    // 行为建议
    if (stats.topMissed.isNotEmpty) {
      final missed = stats.topMissed.first;
      suggestions.add({
        'text': '"${missed.name}" 是最常遗漏的行为，建议设为必做并开启提醒',
        'priority': 'high',
      });
    }

    // 物品建议
    final expiringSoon = inventory['expiringSoon'] as List;
    if (expiringSoon.isNotEmpty) {
      suggestions.add({
        'text': '${expiringSoon.length}件物品即将过期，请优先使用',
        'priority': 'high',
      });
    }

    final lowStock = inventory['lowStock'] as List;
    if (lowStock.isNotEmpty) {
      suggestions.add({
        'text': '${lowStock.length}件物品库存不足，建议及时补充',
        'priority': 'medium',
      });
    }

    final medicines = inventory['medicines'] as List;
    if (medicines.isNotEmpty) {
      suggestions.add({
        'text': '库存中有${medicines.length}种药品，不建议长期自行服用，请定期复诊',
        'priority': 'high',
      });
    }

    // 时段建议
    final nightCount = timeline['night'] ?? 0;
    final morningCount = timeline['morning'] ?? 0;
    if (nightCount > morningCount && nightCount > 0) {
      suggestions.add({
        'text': '夜间活动较多，建议调整作息，早睡早起',
        'priority': 'medium',
      });
    }

    // 购买习惯建议
    final topPurchased = timeline['topPurchased'] as List;
    if (topPurchased.isNotEmpty && topPurchased.length >= 2) {
      final item = topPurchased.first;
      suggestions.add({
        'text': '"${item.name}" 购买频率较高（${item.count}次），建议设置定期采购提醒',
        'priority': 'low',
      });
    }

    if (suggestions.isEmpty) {
      suggestions.add({
        'text': '继续保持良好的生活习惯！',
        'priority': 'low',
      });
    }

    suggestions.sort((a, b) {
      final order = {'high': 0, 'medium': 1, 'low': 2};
      return order[a['priority']]!.compareTo(order[b['priority']]!);
    });

    return suggestions;
  }

  Widget _buildScoreCard(int score, int completionRate, Map<String, int> agendaStats, Map<String, dynamic> timeline) {
    final completed = agendaStats['completed'] ?? 0;
    final totalRecords = timeline['total'] ?? 0;
    final totalAgendas = agendaStats['total'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('本周评分', style: TextStyle(fontSize: 13, color: Colors.white70)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(score >= 80 ? Icons.arrow_upward : Icons.trending_flat, size: 12, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(score >= 80 ? '表现优秀' : '继续努力',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$score', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(width: 4),
              const Text('分', style: TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildScoreStat('完成率', '$completionRate%')),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(child: _buildScoreStat('已完成', '$completed')),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(child: _buildScoreStat('行为记录', '$totalRecords')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildDailyTrend(List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('每日完成趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.asMap().entries.map((entry) {
                final v = entry.value['rate'] as double;
                final label = entry.value['label'] as String;
                final records = entry.value['records'] as int;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${(v * 100).round()}%',
                            style: TextStyle(fontSize: 10, color: records > 0 ? AppColors.textSecondary : AppColors.textTertiary)),
                        const SizedBox(height: 4),
                        Container(
                          height: v > 0 ? v * 70 : 2,
                          decoration: BoxDecoration(
                            color: v >= 0.9
                                ? AppColors.success
                                : (v >= 0.5 ? AppColors.accent : (v > 0 ? AppColors.warning : AppColors.bgTertiary)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
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

  Widget _buildAgendaCompletion(Map<String, int> stats) {
    final completed = stats['completed'] ?? 0;
    final expired = stats['expired'] ?? 0;
    final skipped = stats['skipped'] ?? 0;
    final postponed = stats['postponed'] ?? 0;
    final pending = stats['pending'] ?? 0;

    final items = [
      {'label': '已完成', 'value': completed, 'color': AppColors.success, 'bg': AppColors.successLight},
      {'label': '已过期', 'value': expired, 'color': AppColors.danger, 'bg': AppColors.dangerLight},
      {'label': '已延后', 'value': postponed, 'color': AppColors.warning, 'bg': AppColors.warningLight},
      {'label': '已跳过', 'value': skipped, 'color': AppColors.textSecondary, 'bg': AppColors.bgTertiary},
      {'label': '待进行', 'value': pending, 'color': AppColors.info, 'bg': AppColors.infoLight},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('事程完成情况', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: s['bg'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text('${s['value']}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: s['color'] as Color)),
                    const SizedBox(height: 2),
                    Text(s['label'] as String,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorRanking(StatsData stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('习惯排行', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          if (stats.topRegular.isEmpty)
            const Text('暂无数据', style: TextStyle(fontSize: 13, color: AppColors.textTertiary))
          else
            ...stats.topRegular.take(5).toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: idx == 0 ? AppColors.warning : (idx == 1 ? Colors.grey[400]! : Colors.orange[300]!),
                        shape: BoxShape.circle,
                      ),
                      child: Text('${idx + 1}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.name, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                    ),
                    Text('${item.count}次', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }),
          if (stats.topMissed.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('需改善', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.danger)),
            const SizedBox(height: 8),
            ...stats.topMissed.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${item.name}（未记录）', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeDistribution(Map<String, dynamic> timeline) {
    final morning = timeline['morning'] ?? 0;
    final afternoon = timeline['afternoon'] ?? 0;
    final evening = timeline['evening'] ?? 0;
    final night = timeline['night'] ?? 0;
    final total = morning + afternoon + evening + night;

    final periods = [
      {'label': '上午', 'desc': '6:00-12:00', 'count': morning, 'color': AppColors.accent},
      {'label': '下午', 'desc': '12:00-18:00', 'count': afternoon, 'color': AppColors.info},
      {'label': '晚上', 'desc': '18:00-23:00', 'count': evening, 'color': AppColors.purple},
      {'label': '夜间', 'desc': '23:00-6:00', 'count': night, 'color': AppColors.danger},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('时段分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...periods.map((p) {
            final count = p['count'] as int;
            final rate = total > 0 ? count / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${p['label']} ${p['desc']}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('$count条',
                          style: TextStyle(fontSize: 13, color: p['color'] as Color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 6,
                      backgroundColor: AppColors.bgTertiary,
                      valueColor: AlwaysStoppedAnimation<Color>(p['color'] as Color),
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

  Widget _buildInventorySummary(Map<String, dynamic> inventory) {
    final total = inventory['total'] ?? 0;
    final expiringSoon = inventory['expiringSoon'] as List;
    final expired = inventory['expired'] as List;
    final medicines = inventory['medicines'] as List;
    final foods = inventory['foods'] as List;
    final lowStock = inventory['lowStock'] as List;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('物品概况', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInvStat('总物品', '$total', AppColors.accent)),
              Expanded(child: _buildInvStat('食品', '${foods.length}', AppColors.success)),
              Expanded(child: _buildInvStat('药品', '${medicines.length}', AppColors.danger)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInvStat('即将过期', '${expiringSoon.length}', AppColors.warning)),
              Expanded(child: _buildInvStat('已过期', '${expired.length}', AppColors.danger)),
              Expanded(child: _buildInvStat('库存不足', '${lowStock.length}', AppColors.info)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildHighlights(List<String> highlights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, size: 18, color: AppColors.warning),
              SizedBox(width: 6),
              Text('本周亮点', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ...highlights.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•', style: TextStyle(fontSize: 14, color: AppColors.warning, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(h, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSuggestions(List<Map<String, dynamic>> suggestions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: AppColors.info),
              SizedBox(width: 6),
              Text('优化建议', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final priority = s['priority'] as String;
            final color = priority == 'high' ? AppColors.danger : (priority == 'medium' ? AppColors.warning : AppColors.info);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Text('${idx + 1}',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s['text'] as String,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
