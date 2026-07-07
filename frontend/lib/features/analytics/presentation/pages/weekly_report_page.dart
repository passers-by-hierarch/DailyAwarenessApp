import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';

/// 周报页 - 对齐原型 WeeklyReportPage
class WeeklyReportPage extends StatelessWidget {
  const WeeklyReportPage({super.key});

  final List<double> _dailyCompletion = const [0.85, 0.92, 0.78, 1.0, 0.88, 0.95, 0.82];
  final List<String> _dayLabels = const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  final List<Map<String, dynamic>> _categories = const [
    {'name': '服药', 'rate': 0.95, 'color': AppColors.danger, 'bg': AppColors.dangerLight},
    {'name': '喝水', 'rate': 0.72, 'color': AppColors.info, 'bg': AppColors.infoLight},
    {'name': '锻炼', 'rate': 0.85, 'color': AppColors.accent, 'bg': AppColors.accentLight},
    {'name': '休息', 'rate': 0.90, 'color': AppColors.purple, 'bg': AppColors.purpleLight},
  ];

  final List<String> _highlights = const [
    '本周完成率达到92%，较上周提升5%',
    '连续7天按时服药，养成良好习惯',
    '运动频率提升，平均每日散步30分钟',
    '睡眠质量改善，平均睡眠7.5小时',
  ];

  final List<String> _suggestions = const [
    '建议将喝水提醒间隔缩短为1小时',
    '周末运动量较低，可增加户外活动',
    '22:00后减少手机使用，有助于睡眠',
  ];

  @override
  Widget build(BuildContext context) {
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
          _buildScoreCard(),
          const SizedBox(height: 16),
          _buildDailyTrend(),
          const SizedBox(height: 16),
          _buildCategoryStats(),
          const SizedBox(height: 16),
          _buildAgendaStats(),
          const SizedBox(height: 16),
          _buildHighlights(),
          const SizedBox(height: 16),
          _buildSuggestions(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward, size: 12, color: Colors.white),
                    SizedBox(width: 2),
                    Text('较上周+5', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('92', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(width: 4),
              Text('分', style: TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildScoreStat('完成率', '92%')),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(child: _buildScoreStat('已完成', '23')),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(child: _buildScoreStat('行为记录', '47')),
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

  Widget _buildDailyTrend() {
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
              children: _dailyCompletion.asMap().entries.map((entry) {
                final idx = entry.key;
                final v = entry.value;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${(v * 100).round()}%',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Container(
                          height: v * 70,
                          decoration: BoxDecoration(
                            color: v >= 0.9
                                ? AppColors.success
                                : (v >= 0.8 ? AppColors.accent : AppColors.warning),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_dayLabels[idx],
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
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

  Widget _buildCategoryStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('分类统计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._categories.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c['name'] as String,
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                        Text('${((c['rate'] as double) * 100).round()}%',
                            style: TextStyle(fontSize: 13, color: c['color'] as Color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c['rate'] as double,
                        minHeight: 8,
                        backgroundColor: AppColors.bgTertiary,
                        valueColor: AlwaysStoppedAnimation<Color>(c['color'] as Color),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAgendaStats() {
    final stats = [
      {'label': '已完成', 'value': 18, 'color': AppColors.success, 'bg': AppColors.successLight},
      {'label': '已延后', 'value': 4, 'color': AppColors.warning, 'bg': AppColors.warningLight},
      {'label': '已跳过', 'value': 1, 'color': AppColors.textSecondary, 'bg': AppColors.bgTertiary},
    ];
    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: s['bg'] as Color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text('${s['value']}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: s['color'] as Color)),
                const SizedBox(height: 4),
                Text(s['label'] as String,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHighlights() {
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
          ..._highlights.map((h) => Padding(
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

  Widget _buildSuggestions() {
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
              Text('改进建议', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ..._suggestions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.info, shape: BoxShape.circle),
                    child: Text('${entry.key + 1}',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(entry.value,
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
