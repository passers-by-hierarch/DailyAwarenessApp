import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_store.dart';

/// 提醒规则页 - 对齐原型 ReminderRulesPage
/// 三级策略：普通/重要/必做，全部同时启用
class ReminderRulesPage extends StatelessWidget {
  const ReminderRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final rules = store.reminderRules;

    return SecondaryScaffold(
      title: '提醒规则',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPriorityHint(),
                const SizedBox(height: 16),
                _buildSectionTitle('级别策略（同时启用）'),
                const SizedBox(height: 8),
                _buildLevelCard(
                  context,
                  '普通事程',
                  AppColors.textSecondary,
                  AppColors.bgTertiary,
                  'normal',
                  rules['normal'] as Map<String, dynamic>? ?? {},
                ),
                const SizedBox(height: 12),
                _buildLevelCard(
                  context,
                  '重要事程',
                  AppColors.warning,
                  AppColors.warningLight,
                  'important',
                  rules['important'] as Map<String, dynamic>? ?? {},
                ),
                const SizedBox(height: 12),
                _buildLevelCard(
                  context,
                  '必做事程',
                  AppColors.danger,
                  AppColors.dangerLight,
                  'mustDo',
                  rules['mustDo'] as Map<String, dynamic>? ?? {},
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('必做四阶段提醒'),
                const SizedBox(height: 8),
                _buildMustDoStagesHint(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildResetButton(context),
        ],
      ),
    );
  }

  Widget _buildPriorityHint() {
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
              '优先级：自定义策略 > 级别策略 > 基础提醒方法\n所有级别策略同时生效',
              style: TextStyle(fontSize: 13, color: AppColors.info, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
  }

  Widget _buildMustDoStagesHint() {
    final stages = [
      {'offset': '提前30分钟', 'desc': '第一阶段预警'},
      {'offset': '提前10分钟', 'desc': '第二阶段提醒'},
      {'offset': '到时', 'desc': '第三阶段触发'},
      {'offset': '过后10分钟', 'desc': '第四阶段跟进'},
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Column(
        children: stages.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(s['offset']!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              Text(s['desc']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    String name,
    Color color,
    Color bg,
    String levelKey,
    Map<String, dynamic> config,
  ) {
    final enabled = config['enabled'] as bool? ?? true;
    final advanceMinutes = config['advanceMinutes'] as int? ?? 10;
    final repeatCount = config['repeatCount'] as int? ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Text(name, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
                const Spacer(),
                Switch(
                  value: enabled,
                  onChanged: (v) => _updateLevel(context, levelKey, {
                    'enabled': v,
                    'advanceMinutes': advanceMinutes,
                    'repeatCount': repeatCount,
                  }),
                  activeColor: AppColors.accent,
                ),
              ],
            ),
          ),
          if (enabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildEditableRow(
                    context,
                    '提前时间',
                    '$advanceMinutes 分钟',
                    () => _editMinutes(context, '提前时间', advanceMinutes, (v) =>
                      _updateLevel(context, levelKey, {
                        'enabled': true,
                        'advanceMinutes': v,
                        'repeatCount': repeatCount,
                      }),
                    ),
                  ),
                  _buildEditableRow(
                    context,
                    '重复次数',
                    '$repeatCount 次',
                    () => _editMinutes(context, '重复次数', repeatCount, (v) =>
                      _updateLevel(context, levelKey, {
                        'enabled': true,
                        'advanceMinutes': advanceMinutes,
                        'repeatCount': v,
                      }),
                    ),
                  ),
                  _buildStaticRow('重复间隔', levelKey == 'mustDo' ? '2 分钟' : '5 分钟'),
                  _buildStaticRow('允许推迟', levelKey == 'mustDo' ? '否' : '是'),
                  _buildStaticRow('允许跳过', levelKey == 'mustDo' ? '否' : '是'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(
    BuildContext context,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _updateLevel(BuildContext context, String levelKey, Map<String, dynamic> newConfig) {
    final store = context.read<AppStore>();
    final rules = Map<String, dynamic>.from(store.reminderRules);
    rules[levelKey] = newConfig;
    store.updateReminderRules(rules);
  }

  void _editMinutes(
    BuildContext context,
    String title,
    int current,
    Function(int) onSave,
  ) {
    final options = [1, 3, 5, 10, 15, 20, 30, 45, 60, 90];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('选择$title'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((m) {
              final selected = m == current;
              return GestureDetector(
                onTap: () {
                  onSave(m);
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$m 分钟',
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            final store = context.read<AppStore>();
            store.updateReminderRules({
              'normal': {'advanceMinutes': 10, 'repeatCount': 1, 'enabled': true},
              'important': {'advanceMinutes': 30, 'repeatCount': 3, 'enabled': true},
              'mustDo': {'advanceMinutes': 30, 'repeatCount': 5, 'enabled': true},
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已恢复默认设置'), duration: Duration(seconds: 1)),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: AppColors.border),
          ),
          child: const Text('一键复原', style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
