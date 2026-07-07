import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
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
  String _range = 'week'; // week/month/all

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final stats = store.computeStats(_range);

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
                    // TODO: 跳转周报详情页
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
                const SizedBox(height: 16),
                // 核心指标卡
                _buildCompletionCard(stats.completionRate),
                // 热力图
                _buildHeatmap(stats.heatmap),
                // 行为排行
                _buildBehaviorRanking(stats.topRegular, stats.topMissed),
                // 标签集锦
                _buildTagShowcase(),
                // 策略优化建议
                _buildSuggestions(),
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
          _rangeBtn('本周', 'week'),
          const SizedBox(width: 16),
          _rangeBtn('本月', 'month'),
          const SizedBox(width: 16),
          _rangeBtn('自定义', 'custom'),
        ],
      ),
    );
  }

  Widget _rangeBtn(String label, String key) {
    final active = _range == key;
    return GestureDetector(
      onTap: () => setState(() => _range = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
            Container(
              height: 2,
              width: active ? 24 : 0,
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

  String _rangeLabel() {
    switch (_range) {
      case 'week': return '本周';
      case 'month': return '本月';
      case 'custom': return '自定义';
      default: return '本周';
    }
  }

  String _compareLabel() {
    switch (_range) {
      case 'week': return '较上周提升5个百分点';
      case 'month': return '较上月提升5个百分点';
      case 'custom': return '自定义时间段完成情况';
      default: return '较上周提升5个百分点';
    }
  }

  // 核心指标卡（4.3.3）
  Widget _buildCompletionCard(int rate) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${_rangeLabel()}完成率',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$rate%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_upward, size: 16, color: AppColors.success),
              const SizedBox(width: 4),
              const Text(
                '5%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _compareLabel(),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _heatmapTitle() {
    switch (_range) {
      case 'week': return '近7天完成热力图';
      case 'month': return '近30天完成热力图';
      case 'custom': return '自定义时间段热力图';
      default: return '近7天完成热力图';
    }
  }

  // 热力图（4.3.4）
  Widget _buildHeatmap(List<List<int>> heatmap) {
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
              Text(
                _heatmapTitle(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 星期表头
          Row(
            children: [
              SizedBox(width: 56), // 行为标签宽度
              ...MockData.heatmapDays.map((d) =>
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ).toList(),
            ],
          ),
          const SizedBox(height: 8),
          // 热力图网格
          ...List.generate(heatmap.length, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  // 行为标签（宽度56px）
                  SizedBox(
                    width: 56,
                    child: Text(
                      MockData.heatmapLabels[row < MockData.heatmapLabels.length ? row : 0],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // 热力格子（宽度36px，高度24px）
                  ...List.generate(7, (col) {
                    final done = heatmap[row][col] == 1;
                    return Expanded(
                      child: Container(
                        height: 24,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: done ? AppColors.success : AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 行为排行（4.3.5）
  Widget _buildBehaviorRanking(List<NameCount> topRegular, List<NameCount> topMissed) {
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
                '行为排行',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 最规律
          if (topRegular.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('暂无数据', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            )
          else
            ...topRegular.map((b) => _buildRankItem(b, true)),
          const SizedBox(height: 12),
          // 最易遗漏
          if (topMissed.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('暂无遗漏，太棒了！', style: TextStyle(fontSize: 12, color: AppColors.success)),
            )
          else
            ...topMissed.map((b) => _buildRankItem(b, false)),
        ],
      ),
    );
  }

  Widget _buildRankItem(NameCount item, bool isRegular) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRegular ? '最规律行为' : '最易遗漏',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // 统计数据
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isRegular ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.count}/7天',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: isRegular ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isRegular ? Icons.check : Icons.warning_amber_rounded,
                  size: 14,
                  color: isRegular ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  // 标签集锦（4.3.6）
  Widget _buildTagShowcase() {
    final store = context.watch<AppStore>();
    final allTags = store.allTags;
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
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
                  // TODO: 跳转标签管理页
                },
                child: Icon(Icons.settings, size: 16, color: AppColors.textTertiary),
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
          // 标签网格
          if (allTags.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('暂无标签，记录时添加标签即可生成', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTags.map((tag) {
                final count = store.getTagUsageCount(tag.id);
                final colorSet = AppColors.tagColors[tag.color] ?? AppColors.tagColors['gray']!;
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 96) / 4,
                  height: 92,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: colorSet.bg,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              tag.icon.isNotEmpty && tag.icon != '#' ? tag.icon : '#',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tag.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
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

  // 策略优化建议（4.3.7）
  Widget _buildSuggestions() {
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
                '策略优化建议',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 建议卡片列表
          ...MockData.mockSuggestions.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 发现文字（带💡图标）
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.text.split('\n')[0].replaceFirst('发现：', ''),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 建议文字
                if (s.text.split('\n').length > 1)
                  Text(
                    s.text.split('\n')[1].replaceFirst('建议：', ''),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                const SizedBox(height: 12),
                // 按钮组
                Row(
                  children: [
                    // 接受按钮
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: 接受建议
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 16),
                            SizedBox(width: 4),
                            Text('接受'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 忽略按钮
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: 忽略建议
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bgTertiary,
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            Text('忽略'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
