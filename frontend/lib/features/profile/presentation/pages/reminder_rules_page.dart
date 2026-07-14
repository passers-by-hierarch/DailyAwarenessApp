import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/state/app_store.dart';

/// 提醒规则页 - 对齐原型 ReminderRulesPage
/// 四级策略：普通/重要/短期必做/长期必做，全部同时启用
/// 包含事程策略配置（连续升级、失败降级、时间偏差）
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
                  '短期必做事程',
                  AppColors.danger,
                  AppColors.dangerLight,
                  'mustDoShort',
                  rules['mustDoShort'] as Map<String, dynamic>? ?? {},
                ),
                const SizedBox(height: 12),
                _buildLevelCard(
                  context,
                  '长期必做事程',
                  AppColors.danger,
                  AppColors.dangerLight,
                  'mustDoLong',
                  rules['mustDoLong'] as Map<String, dynamic>? ?? {},
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('单项事程定向设置'),
                const SizedBox(height: 8),
                _buildCustomHint(),
                const SizedBox(height: 12),
                _buildCustomReminderList(context),
                const SizedBox(height: 16),
                _buildAddCustomButton(context),
                const SizedBox(height: 24),
                _buildSectionTitle('必做事程管理'),
                const SizedBox(height: 8),
                _buildMustDoHint(),
                const SizedBox(height: 12),
                _buildMustDoSection(context, '短期必做', AgendaLevel.mustDoShort),
                const SizedBox(height: 12),
                _buildAddMustDoButton(context),
                const SizedBox(height: 16),
                _buildMustDoSection(context, '长期必做', AgendaLevel.mustDoLong),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildResetButton(context),
        ],
      ),
    );
  }

  Widget _buildCustomHint() {
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
              '针对特定事程设置独立的提醒规则，优先级高于全局规则',
              style: TextStyle(fontSize: 13, color: AppColors.info, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomReminderList(BuildContext context) {
    final store = context.watch<AppStore>();
    final customItems = store.agendaItems.where((a) => a.advanceReminder != null).toList();

    if (customItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
        ),
        child: const Center(
          child: Text(
            '暂无定向设置',
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: List.generate(customItems.length, (index) {
          final item = customItems[index];
          return Column(
            children: [
              if (index > 0) const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _buildCustomReminderItem(context, item),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCustomReminderItem(BuildContext context, AgendaItem item) {
    return InkWell(
      onTap: () => _editCustomReminder(context, item),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.time,
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontFamily: 'monospace'),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '提前${item.advanceReminder}分钟',
                          style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _deleteCustomReminder(context, item),
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCustomButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAgendaPicker(context),
        icon: const Icon(Icons.add, size: 18, color: AppColors.accent),
        label: const Text('添加定向设置', style: TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: AppColors.accent, width: 1.5),
          backgroundColor: AppColors.accentLight.withOpacity(0.3),
        ),
      ),
    );
  }

  void _showAgendaPicker(BuildContext context) {
    final store = context.read<AppStore>();
    final availableItems = store.agendaItems.where((a) => a.advanceReminder == null).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Text('选择事程', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: availableItems.isEmpty
                  ? const Center(
                      child: Text('所有事程都已设置定向提醒', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: availableItems.length,
                      itemBuilder: (_, index) {
                        final item = availableItems[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showAdvanceTimeDialog(context, item);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Text(item.icon, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.content,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.time,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvanceTimeDialog(BuildContext context, AgendaItem item) {
    int selectedMinutes = 10;
    final options = [1, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('设置「${item.content}」提前提醒'),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((m) {
                final selected = m == selectedMinutes;
                return GestureDetector(
                  onTap: () => setDialogState(() => selectedMinutes = m),
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
            TextButton(
              onPressed: () {
                final store = context.read<AppStore>();
                store.updateAgendaAdvanceReminder(item.id, selectedMinutes);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已设置定向提醒'), duration: Duration(seconds: 1)),
                );
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  void _editCustomReminder(BuildContext context, AgendaItem item) {
    int selectedMinutes = item.advanceReminder ?? 10;
    final options = [1, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('编辑「${item.content}」提前提醒'),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((m) {
                final selected = m == selectedMinutes;
                return GestureDetector(
                  onTap: () => setDialogState(() => selectedMinutes = m),
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
            TextButton(
              onPressed: () {
                final store = context.read<AppStore>();
                store.updateAgendaAdvanceReminder(item.id, selectedMinutes);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已更新定向提醒'), duration: Duration(seconds: 1)),
                );
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCustomReminder(BuildContext context, AgendaItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除定向设置'),
        content: Text('确定要删除「${item.content}」的定向提醒吗？删除后将恢复使用全局规则。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final store = context.read<AppStore>();
              store.updateAgendaAdvanceReminder(item.id, null);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已删除定向设置，恢复使用全局规则'), duration: Duration(seconds: 1)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
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

  void _editStageOffset(BuildContext context, String levelKey, int stageIndex, int current, Function(int) onSave) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('编辑第${stageIndex + 1}阶段时间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('负数=提前，0=到点，正数=延后（单位：分钟）', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '时间偏移（分钟）',
                hintText: '例如：-30 表示提前30分钟',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= -180 && v <= 180) {
                onSave(v);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('请输入-180到180之间的数字'), duration: Duration(seconds: 1)),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
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
    final repeatInterval = config['repeatInterval'] as int? ?? 5;
    final allowPostpone = config['allowPostpone'] as bool? ?? true;
    final allowSkip = config['allowSkip'] as bool? ?? true;
    final streakUpgradeDays = config['streakUpgradeDays'] as int? ?? 7;
    final failDemotionThreshold = config['failDemotionThreshold'] as int? ?? 3;
    final timeDeviationMinutes = config['timeDeviationMinutes'] as int? ?? 30;
    final isMustDo = levelKey == 'mustDoShort' || levelKey == 'mustDoLong';
    final stagesEnabled = config['stagesEnabled'] as bool? ?? true;
    final defaultStages = levelKey == 'mustDoLong' ? [-60, -30, 0, 30] : [-30, -10, 0, 10];
    final stages = (config['stages'] as List<dynamic>?)?.map((e) => e as int).toList() ?? defaultStages;
    final stageDescs = ['第一阶段预警', '第二阶段提醒', '第三阶段触发', '第四阶段跟进'];

    String formatOffset(int minutes) {
      if (minutes < 0) return '提前${-minutes}分钟';
      if (minutes == 0) return '到时';
      return '过后${minutes}分钟';
    }

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
                    'repeatInterval': repeatInterval,
                    'allowPostpone': allowPostpone,
                    'allowSkip': allowSkip,
                    'streakUpgradeDays': streakUpgradeDays,
                    'failDemotionThreshold': failDemotionThreshold,
                    'timeDeviationMinutes': timeDeviationMinutes,
                    'stagesEnabled': stagesEnabled,
                    'stages': stages,
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
                        'repeatInterval': repeatInterval,
                        'allowPostpone': allowPostpone,
                        'allowSkip': allowSkip,
                        'streakUpgradeDays': streakUpgradeDays,
                        'failDemotionThreshold': failDemotionThreshold,
                        'timeDeviationMinutes': timeDeviationMinutes,
                        'stagesEnabled': stagesEnabled,
                        'stages': stages,
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
                        'repeatInterval': repeatInterval,
                        'allowPostpone': allowPostpone,
                        'allowSkip': allowSkip,
                        'streakUpgradeDays': streakUpgradeDays,
                        'failDemotionThreshold': failDemotionThreshold,
                        'timeDeviationMinutes': timeDeviationMinutes,
                        'stagesEnabled': stagesEnabled,
                        'stages': stages,
                      }),
                    ),
                  ),
                  _buildEditableRow(
                    context,
                    '重复间隔',
                    '$repeatInterval 分钟',
                    () => _editMinutes(context, '重复间隔', repeatInterval, (v) =>
                      _updateLevel(context, levelKey, {
                        'enabled': true,
                        'advanceMinutes': advanceMinutes,
                        'repeatCount': repeatCount,
                        'repeatInterval': v,
                        'allowPostpone': allowPostpone,
                        'allowSkip': allowSkip,
                        'streakUpgradeDays': streakUpgradeDays,
                        'failDemotionThreshold': failDemotionThreshold,
                        'timeDeviationMinutes': timeDeviationMinutes,
                        'stagesEnabled': stagesEnabled,
                        'stages': stages,
                      }),
                    ),
                  ),
                  _buildSwitchRow(
                    '允许推迟',
                    allowPostpone,
                    (v) => _updateLevel(context, levelKey, {
                      'enabled': true,
                      'advanceMinutes': advanceMinutes,
                      'repeatCount': repeatCount,
                      'repeatInterval': repeatInterval,
                      'allowPostpone': v,
                      'allowSkip': allowSkip,
                      'streakUpgradeDays': streakUpgradeDays,
                      'failDemotionThreshold': failDemotionThreshold,
                      'timeDeviationMinutes': timeDeviationMinutes,
                      'stagesEnabled': stagesEnabled,
                      'stages': stages,
                    }),
                  ),
                  _buildSwitchRow(
                    '允许跳过',
                    allowSkip,
                    (v) => _updateLevel(context, levelKey, {
                      'enabled': true,
                      'advanceMinutes': advanceMinutes,
                      'repeatCount': repeatCount,
                      'repeatInterval': repeatInterval,
                      'allowPostpone': allowPostpone,
                      'allowSkip': v,
                      'streakUpgradeDays': streakUpgradeDays,
                      'failDemotionThreshold': failDemotionThreshold,
                      'timeDeviationMinutes': timeDeviationMinutes,
                      'stagesEnabled': stagesEnabled,
                      'stages': stages,
                    }),
                  ),
                  const Divider(height: 16, color: AppColors.border),
                  _buildEditableRow(
                    context,
                    '连续升级天数',
                    '$streakUpgradeDays 天',
                    () => _editMinutes(context, '连续升级天数', streakUpgradeDays, (v) =>
                      _updateLevel(context, levelKey, {
                        'enabled': true,
                        'advanceMinutes': advanceMinutes,
                        'repeatCount': repeatCount,
                        'repeatInterval': repeatInterval,
                        'allowPostpone': allowPostpone,
                        'allowSkip': allowSkip,
                        'streakUpgradeDays': v,
                        'failDemotionThreshold': failDemotionThreshold,
                        'timeDeviationMinutes': timeDeviationMinutes,
                        'stagesEnabled': stagesEnabled,
                        'stages': stages,
                      }),
                    ),
                  ),
                  _buildEditableRow(
                    context,
                    '失败降级阈值',
                    '$failDemotionThreshold 次',
                    () => _editMinutes(context, '失败降级阈值', failDemotionThreshold, (v) =>
                      _updateLevel(context, levelKey, {
                        'enabled': true,
                        'advanceMinutes': advanceMinutes,
                        'repeatCount': repeatCount,
                        'repeatInterval': repeatInterval,
                        'allowPostpone': allowPostpone,
                        'allowSkip': allowSkip,
                        'streakUpgradeDays': streakUpgradeDays,
                        'failDemotionThreshold': v,
                        'timeDeviationMinutes': timeDeviationMinutes,
                        'stagesEnabled': stagesEnabled,
                        'stages': stages,
                      }),
                    ),
                  ),
                  _buildEditableRow(
                    context,
                    '时间偏差阈值',
                    '$timeDeviationMinutes 分钟',
                    () => _editMinutes(context, '时间偏差阈值', timeDeviationMinutes, (v) =>
                      _updateLevel(context, levelKey, {
                        'enabled': true,
                        'advanceMinutes': advanceMinutes,
                        'repeatCount': repeatCount,
                        'repeatInterval': repeatInterval,
                        'allowPostpone': allowPostpone,
                        'allowSkip': allowSkip,
                        'streakUpgradeDays': streakUpgradeDays,
                        'failDemotionThreshold': failDemotionThreshold,
                        'timeDeviationMinutes': v,
                        'stagesEnabled': stagesEnabled,
                        'stages': stages,
                      }),
                    ),
                  ),
                  if (isMustDo) ...[
                    const Divider(height: 16, color: AppColors.border),
                    _buildSwitchRow(
                      '启用四阶段提醒',
                      stagesEnabled,
                      (v) => _updateLevel(context, levelKey, {
                        'enabled': true,
                        'advanceMinutes': advanceMinutes,
                        'repeatCount': repeatCount,
                        'repeatInterval': repeatInterval,
                        'allowPostpone': allowPostpone,
                        'allowSkip': allowSkip,
                        'streakUpgradeDays': streakUpgradeDays,
                        'failDemotionThreshold': failDemotionThreshold,
                        'timeDeviationMinutes': timeDeviationMinutes,
                        'stagesEnabled': v,
                        'stages': stages,
                      }),
                    ),
                    if (stagesEnabled)
                      ...List.generate(stages.length, (i) {
                        return GestureDetector(
                          onTap: () => _editStageOffset(context, levelKey, i, stages[i], (newVal) {
                            final store = context.read<AppStore>();
                            final rules = Map<String, dynamic>.from(store.reminderRules);
                            final mustDo = Map<String, dynamic>.from(rules[levelKey] as Map? ?? {});
                            final newStages = List<int>.from(stages);
                            newStages[i] = newVal;
                            mustDo['stages'] = newStages;
                            rules[levelKey] = mustDo;
                            store.updateReminderRules(rules);
                          }),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                                  child: Text('${i + 1}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(formatOffset(stages[i]), style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                                      Text(stageDescs[i], style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.edit, size: 14, color: AppColors.textTertiary),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
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

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  void _updateLevel(BuildContext context, String levelKey, Map<String, dynamic> newConfig) {
    final store = context.read<AppStore>();
    final rules = Map<String, dynamic>.from(store.reminderRules);
    if (levelKey == 'mustDoShort' || levelKey == 'mustDoLong') {
      final mustDo = rules[levelKey] as Map<String, dynamic>?;
      final defaultStages = levelKey == 'mustDoLong' ? [-60, -30, 0, 30] : [-30, -10, 0, 10];
      if (mustDo != null) {
        newConfig['stagesEnabled'] = mustDo['stagesEnabled'] ?? true;
        newConfig['stages'] = mustDo['stages'] ?? defaultStages;
      }
    }
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
    final unit = title.contains('次数') ? '次' : '分钟';
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
                    '$m $unit',
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
              'normal': {'advanceMinutes': 10, 'repeatCount': 1, 'repeatInterval': 5, 'allowPostpone': true, 'allowSkip': true, 'enabled': true, 'streakUpgradeDays': 7, 'failDemotionThreshold': 3, 'timeDeviationMinutes': 30},
              'important': {'advanceMinutes': 30, 'repeatCount': 3, 'repeatInterval': 5, 'allowPostpone': true, 'allowSkip': true, 'enabled': true, 'streakUpgradeDays': 7, 'failDemotionThreshold': 3, 'timeDeviationMinutes': 30},
              'mustDoShort': {
                'advanceMinutes': 30,
                'repeatCount': 5,
                'repeatInterval': 2,
                'allowPostpone': false,
                'allowSkip': false,
                'enabled': true,
                'stagesEnabled': true,
                'stages': [-30, -10, 0, 10],
                'streakUpgradeDays': 7,
                'failDemotionThreshold': 3,
                'timeDeviationMinutes': 30,
              },
              'mustDoLong': {
                'advanceMinutes': 60,
                'repeatCount': 3,
                'repeatInterval': 10,
                'allowPostpone': true,
                'allowSkip': false,
                'enabled': true,
                'stagesEnabled': true,
                'stages': [-60, -30, 0, 30],
                'streakUpgradeDays': 7,
                'failDemotionThreshold': 3,
                'timeDeviationMinutes': 30,
              },
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

  Widget _buildAddMustDoButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: OutlinedButton(
        onPressed: () => _showAddMustDoDialog(context),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: AppColors.accent, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.plus, size: 20, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text('添加必做事程', style: TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showAddMustDoDialog(BuildContext context) {
    final contentCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '08:00');
    AgendaLevel selectedLevel = AgendaLevel.mustDoShort;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加必做事程'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('事程名称', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: contentCtrl,
                decoration: const InputDecoration(
                  hintText: '例如：吃药、锻炼',
                  filled: true,
                  fillColor: AppColors.bgTertiary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              const Text('提醒时间', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: timeCtrl,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  hintText: 'HH:mm',
                  filled: true,
                  fillColor: AppColors.bgTertiary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              const Text('必做级别', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => selectedLevel = AgendaLevel.mustDoShort,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedLevel == AgendaLevel.mustDoShort ? AppColors.accent : AppColors.bgTertiary,
                        foregroundColor: selectedLevel == AgendaLevel.mustDoShort ? Colors.white : AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('短期必做'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => selectedLevel = AgendaLevel.mustDoLong,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedLevel == AgendaLevel.mustDoLong ? AppColors.accent : AppColors.bgTertiary,
                        foregroundColor: selectedLevel == AgendaLevel.mustDoLong ? Colors.white : AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('长期必做'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '短期必做：提前30分钟提醒，重复5次\n长期必做：提前60分钟提醒，重复3次',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final content = contentCtrl.text.trim();
              final time = timeCtrl.text.trim();
              if (content.isEmpty || time.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写完整信息'), duration: Duration(seconds: 1)),
                );
                return;
              }
              final store = context.read<AppStore>();
              final today = store.now;
              final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
              store.addAgenda(AgendaItem(
                id: '',
                content: content,
                time: time,
                date: todayStr,
                isMustDo: true,
                level: selectedLevel,
                category: AgendaCategory.custom,
                source: AgendaSource.user,
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已添加「$content」'), duration: Duration(seconds: 1)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildMustDoHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, size: 16, color: AppColors.danger),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '必做事程每天自动创建副本，连续完成达标可升级，连续失败达标需确认后降级',
              style: TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMustDoSection(BuildContext context, String title, AgendaLevel level) {
    final store = context.watch<AppStore>();
    // 优先显示原始模板（category != dailyMustDo）
    // 如果某个 content+time 没有模板但存在副本（数据不一致时），用当天副本兜底显示
    final allMustDo = store.agendaItems
        .where((a) => a.level == level && a.isMustDo)
        .toList();

    // 按 content+time 分组去重，每组优先取模板
    final uniqueMap = <String, AgendaItem>{};
    for (final a in allMustDo) {
      final key = '${a.content}_${a.time}';
      final existing = uniqueMap[key];
      if (existing == null || a.category != AgendaCategory.dailyMustDo) {
        uniqueMap[key] = a;
      }
    }
    final items = uniqueMap.values.toList();

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
              color: AppColors.dangerLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, color: AppColors.danger, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${items.length}项', style: TextStyle(fontSize: 12, color: AppColors.danger.withOpacity(0.7))),
              ],
            ),
          ),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '暂无${title}事程',
                  style: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
                ),
              ),
            )
          else
            Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                return Column(
                  children: [
                    if (index > 0) const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    _buildMustDoItem(context, item),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildMustDoItem(BuildContext context, AgendaItem item) {
    final store = context.read<AppStore>();
    final completionRate = _calculateCompletionRate(store, item);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatsBadge(
                      '🔥 ${item.streak}天',
                      item.streak >= 7 ? AppColors.success : AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    _buildStatsBadge(
                      '✅ ${completionRate}%',
                      completionRate >= 80 ? AppColors.success : completionRate >= 50 ? AppColors.warning : AppColors.danger,
                    ),
                    if (item.failCount > 0) ...[
                      const SizedBox(width: 6),
                      _buildStatsBadge(
                        '❌ ${item.failCount}次',
                        AppColors.danger,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildMustDoActionButtons(context, item),
        ],
      ),
    );
  }

  Widget _buildStatsBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildMustDoActionButtons(BuildContext context, AgendaItem item) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _togglePauseAgenda(context, item),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.level == AgendaLevel.mustDoShort || item.level == AgendaLevel.mustDoLong
                  ? Icons.pause_outlined
                  : Icons.play_arrow_outlined,
              size: 18,
              color: AppColors.warning,
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _confirmDeleteMustDo(context, item),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delete_outlined,
              size: 18,
              color: AppColors.danger,
            ),
          ),
        ),
      ],
    );
  }

  /// 计算近 30 天的完成率
  /// 通过 content+time 匹配历史副本（每日生成的 dailyMustDo 副本）
  /// 排除原始模板本身（category != dailyMustDo）
  int _calculateCompletionRate(AppStore store, AgendaItem template) {
    final now = store.now;
    final start = now.subtract(const Duration(days: 30));
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final history = store.agendaItems.where((a) =>
      a.content == template.content &&
      a.time == template.time &&
      a.date.compareTo(startStr) >= 0 &&
      a.date.compareTo(endStr) <= 0
    ).toList();

    if (history.isEmpty) return 0;
    final completed = history.where((a) => a.status == AgendaStatus.completed).length;
    return ((completed / history.length) * 100).round().clamp(0, 100);
  }

  void _togglePauseAgenda(BuildContext context, AgendaItem item) {
    final store = context.read<AppStore>();
    final isPaused = !item.isMustDo;
    // 如果当前 item 是副本，优先找到对应模板进行操作
    final target = _findMustDoTemplate(store, item);

    if (isPaused) {
      store.updateAgenda(target.id, target.copyWith(
        isMustDo: true,
        status: AgendaStatus.pending,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已恢复为必做事程'), duration: Duration(seconds: 1)),
      );
    } else {
      _showPauseOptionsDialog(context, target);
    }
  }

  /// 查找必做事程的模板。如果当前 item 是模板则返回自身；
  /// 如果是副本且存在模板则返回模板；否则将副本作为临时模板返回。
  AgendaItem _findMustDoTemplate(AppStore store, AgendaItem item) {
    if (item.category != AgendaCategory.dailyMustDo) return item;
    return store.agendaItems.firstWhereOrNull((a) =>
      a.content == item.content &&
      a.time == item.time &&
      a.category != AgendaCategory.dailyMustDo
    ) ?? item;
  }

  void _showPauseOptionsDialog(BuildContext context, AgendaItem template) {
    String? selectedAction;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('暂停必做事程'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('确定要暂停「${template.content}」吗？'),
              const SizedBox(height: 12),
              const Text(
                '暂停后，该事程将不再自动创建每日副本。\n\n请选择今日已生成副本的处理方式：',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildRadioOption('keep', '保留不变', selectedAction),
              const SizedBox(height: 8),
              _buildRadioOption('complete', '标记为已完成', selectedAction),
              const SizedBox(height: 8),
              _buildRadioOption('skip', '标记为已跳过', selectedAction),
              const SizedBox(height: 8),
              _buildRadioOption('delete', '删除今日副本', selectedAction),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _processPauseAction(context, template, selectedAction);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value, String label, String? selectedValue) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: selectedValue,
          onChanged: (v) => selectedValue = v,
          activeColor: AppColors.accent,
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  void _processPauseAction(BuildContext context, AgendaItem template, String? action) {
    final store = context.read<AppStore>();

    store.updateAgenda(template.id, template.copyWith(
      level: AgendaLevel.important,
      isMustDo: false,
      failCount: 0,
    ));

    final today = store.now;
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayCopy = store.agendaItems.firstWhereOrNull((a) =>
      a.content == template.content &&
      a.time == template.time &&
      a.date == todayStr &&
      a.category == AgendaCategory.dailyMustDo
    );

    if (todayCopy != null && action != null && action != 'keep') {
      switch (action) {
        case 'complete':
          store.completeAgenda(todayCopy.id);
          break;
        case 'skip':
          store.skipAgenda(todayCopy.id);
          break;
        case 'delete':
          store.deleteAgenda(todayCopy.id);
          break;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已暂停必做，改为重要级别'), duration: Duration(seconds: 1)),
    );
  }

  void _confirmDeleteMustDo(BuildContext context, AgendaItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除必做事程'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除「${item.content}」吗？'),
            const SizedBox(height: 8),
            const Text(
              '• 已生成的每日提醒副本会保留在历史记录中',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Text(
              '• 此操作将停止创建新的每日副本',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Text(
              '• 关联的库存记录会自动回滚',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final store = context.read<AppStore>();
              final target = _findMustDoTemplate(store, item);
              store.deleteAgenda(target.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已删除「${item.content}」，历史副本已保留'), duration: Duration(seconds: 1)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
