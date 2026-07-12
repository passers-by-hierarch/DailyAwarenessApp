import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/models/app_models.dart';

/// 常用事程页 - 对齐原型 FrequentAgendaPage
class FrequentAgendaPage extends StatelessWidget {
  const FrequentAgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final frequent = context.select<AppStore, List<FrequentAgenda>>((s) => s.frequentAgendas);
    return SecondaryScaffold(
      title: '常用事程',
      body: frequent.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: frequent.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) => _buildCard(context, frequent[idx]),
            ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 56, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text('暂无常用事程', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, FrequentAgenda item) {
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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(item.icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('平均时间 ${item.avgTime}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.matchRate >= 80 ? AppColors.successLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '匹配率 ${item.matchRate}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: item.matchRate >= 80 ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.local_fire_department, size: 14, color: AppColors.warning),
              const SizedBox(width: 4),
              Text('连续 ${item.consecutiveDays} 天',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text('匹配率 ${item.matchRate}%',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.matchRate / 100,
              minHeight: 6,
              backgroundColor: AppColors.bgTertiary,
              valueColor: AlwaysStoppedAnimation<Color>(
                item.matchRate >= 80 ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final store = context.read<AppStore>();
                store.addAgenda(AgendaItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  content: item.content,
                  time: item.avgTime,
                  date: store.todayStr,
                  icon: item.icon,
                  status: AgendaStatus.pending,
                  remainingTime: '今日提醒',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已添加"${item.content}"到今日'), duration: const Duration(seconds: 1)),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: AppColors.accent),
              ),
              icon: const Icon(Icons.add, size: 16, color: AppColors.accent),
              label: const Text('添加为今日', style: TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}
