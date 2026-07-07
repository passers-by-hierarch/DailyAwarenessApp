import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';

/// 行为分析页 - 对齐原型 BehaviorAnalysisPage
class BehaviorAnalysisPage extends StatelessWidget {
  const BehaviorAnalysisPage({super.key});

  final List<double> _weeklyTrend = const [0.85, 0.92, 0.78, 1.0];
  final List<String> _weekLabels = const ['第1周', '第2周', '第3周', '第4周'];

  final List<Map<String, dynamic>> _timeDistribution = const [
    {'period': '早晨(6-9点)', 'count': 28, 'percent': 31, 'color': AppColors.accent},
    {'period': '上午(9-12点)', 'count': 22, 'percent': 25, 'color': AppColors.info},
    {'period': '下午(12-18点)', 'count': 24, 'percent': 27, 'color': AppColors.warning},
    {'period': '晚上(18-22点)', 'count': 12, 'percent': 13, 'color': AppColors.purple},
    {'period': '夜间(22-6点)', 'count': 3, 'percent': 4, 'color': AppColors.textSecondary},
  ];

  final List<String> _relatedAgendas = const [
    '07:30 早晨服药',
    '12:00 午餐',
    '15:00 下午服药',
    '21:00 晚间服药',
  ];

  final List<String> _suggestions = const [
    '建议保持当前的规律作息',
    '夜间活动较少，可适当增加放松活动',
    '上午完成率最高，建议安排重要事程',
  ];

  @override
  Widget build(BuildContext context) {
    final behaviorId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final behaviorName = _getBehaviorName(behaviorId);

    return SecondaryScaffold(
      title: '行为分析',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(behaviorName),
          const SizedBox(height: 16),
          _buildTrend(),
          const SizedBox(height: 16),
          _buildTimeDistribution(),
          const SizedBox(height: 16),
          _buildComparison(),
          const SizedBox(height: 16),
          _buildRelatedAgendas(),
          const SizedBox(height: 16),
          _buildSuggestions(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getBehaviorName(String id) {
    switch (id) {
      case 'medication':
        return '服药';
      case 'meal':
        return '用餐';
      case 'exercise':
        return '运动';
      case 'water':
        return '喝水';
      default:
        return '行为分析';
    }
  }

  Widget _buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5BAE94), AppColors.info],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('近30天数据分析', style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStat('总次数', '89')),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(child: _buildStat('日均', '2.97')),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(child: _buildStat('完成率', '95%')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildTrend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('变化趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyTrend.asMap().entries.map((entry) {
                final idx = entry.key;
                final v = entry.value;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${(v * 100).round()}%',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          height: v * 80,
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.3 + v * 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_weekLabels[idx],
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

  Widget _buildTimeDistribution() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('时间分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._timeDistribution.map((t) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t['period'] as String,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      Text('${t['count']}次 · ${t['percent']}%',
                          style: TextStyle(fontSize: 12, color: t['color'] as Color, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (t['percent'] as int) / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.bgTertiary,
                      valueColor: AlwaysStoppedAnimation<Color>(t['color'] as Color),
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

  Widget _buildComparison() {
    final stats = [
      {'label': '日均次数', 'value': '2.97', 'change': '+0.3', 'up': true, 'color': AppColors.accent, 'bg': AppColors.accentLight},
      {'label': '完成率', 'value': '95%', 'change': '+5%', 'up': true, 'color': AppColors.info, 'bg': AppColors.infoLight},
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['label'] as String,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(s['value'] as String,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: s['color'] as Color)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon((s['up'] as bool) ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12, color: (s['up'] as bool) ? AppColors.success : AppColors.danger),
                    const SizedBox(width: 4),
                    Text(s['change'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: (s['up'] as bool) ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(width: 4),
                    const Text('vs上周', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRelatedAgendas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('关联事程', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._relatedAgendas.map((a) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 14, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ),
                  const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                ],
              ),
            );
          }),
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
              Icon(Icons.lightbulb_outline, size: 18, color: AppColors.warning),
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
                    decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
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
