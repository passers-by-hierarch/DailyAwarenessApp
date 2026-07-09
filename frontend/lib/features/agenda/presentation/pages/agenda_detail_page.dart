import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/models/app_models.dart';

/// 事程详情页 - 对齐原型 AgendaDetailPage
class AgendaDetailPage extends StatefulWidget {
  const AgendaDetailPage({super.key});

  @override
  State<AgendaDetailPage> createState() => _AgendaDetailPageState();
}

class _AgendaDetailPageState extends State<AgendaDetailPage> {
  bool _reminderExpanded = false;
  bool _strategyExpanded = false;
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  Timer? _timer;
  String _currentTime = '';
  String _currentDate = '';
  String _remainingTime = '';
  AgendaLevel _currentLevel = AgendaLevel.normal;

  @override
  void dispose() {
    _contentController.dispose();
    _noteController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _initControllers(AgendaItem agenda) {
    if (_contentController.text != agenda.content) {
      _contentController.text = agenda.content;
    }
    if (_currentTime != agenda.time) {
      _currentTime = agenda.time;
    }
    if (_currentDate != agenda.date) {
      _currentDate = agenda.date;
    }
    if (_noteController.text != (agenda.note ?? '')) {
      _noteController.text = agenda.note ?? '';
    }
    if (_currentLevel != agenda.level) {
      _currentLevel = agenda.level;
    }
    _updateRemainingTime();
  }

  void _updateRemainingTime() {
    setState(() {
      _remainingTime = _calculateRemainingTime();
    });
  }

  String _calculateRemainingTime() {
    if (_currentDate != _todayStr()) {
      return '待提醒';
    }
    final parts = _currentTime.split(':');
    if (parts.length != 2) return '今日提醒';
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    final agendaTime = DateTime(now.year, now.month, now.day, h, m);
    final diff = agendaTime.difference(now);
    if (diff.isNegative) {
      return '已过期';
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '还有${hours}小时${minutes}分';
    }
    if (minutes > 0) {
      return '还有${minutes}分钟';
    }
    return '即将开始';
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final agendaId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final agenda = context.select<AppStore, AgendaItem?>(
      (s) => s.agendaItems.where((a) => a.id == agendaId).firstOrNull,
    );

    if (agenda == null) {
      return const SecondaryScaffold(
        title: '编辑事程',
        body: Center(child: Text('事程不存在', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    _initControllers(agenda);

    return SecondaryScaffold(
      title: '编辑事程',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildEditableHeaderCard(agenda),
                const SizedBox(height: 12),
                _buildEditableInfoRow(agenda),
                const SizedBox(height: 12),
                _buildReminderSection(agenda),
                const SizedBox(height: 12),
                if (agenda.isMustDo) _buildStrategySection(agenda),
                if (agenda.isMustDo) const SizedBox(height: 16),
                const SizedBox(height: 16),
              ],
            ),
          ),
          _buildBottomActions(agenda),
        ],
      ),
    );
  }

  Widget _buildEditableHeaderCard(AgendaItem agenda) {
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
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(agenda.icon, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '输入事程内容',
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _showTimePicker,
                      child: Row(
                        children: [
                          const Icon(AppIcons.clock, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            _currentTime.isNotEmpty ? _currentTime : '选择时间',
                            style: TextStyle(
                              fontSize: 13,
                              color: _currentTime.isNotEmpty ? AppColors.textSecondary : AppColors.textTertiary,
                            ),
                          ),
                          const Icon(AppIcons.chevronDown, size: 12, color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildStatusBadge(agenda.status),
              _buildLevelSelector(),
              _buildCategoryBadge(agenda.category),
              if (agenda.isHighFrequency)
                _buildBadge('高频', AppColors.purple, AppColors.purpleLight),
              if (agenda.source == AgendaSource.ai)
                _buildBadge('AI推荐', AppColors.accent, AppColors.accentLight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(AgendaItem agenda) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _datePickerTile(),
          const Divider(height: 1, color: AppColors.border),
          _infoTile('剩余时间', _remainingTime),
          const Divider(height: 1, color: AppColors.border),
          _infoTile('重复', agenda.repeat.isEmpty ? '不重复' : agenda.repeat.join('、')),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: Text('备注', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ),
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '添加备注...',
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePickerTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text('日期', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _showDatePicker,
              child: Row(
                children: [
                  const Icon(AppIcons.calendar, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    _currentDate.isNotEmpty ? _currentDate : '选择日期',
                    style: TextStyle(
                      fontSize: 14,
                      color: _currentDate.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(AppIcons.chevronDown, size: 14, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimePicker() async {
    final timeParts = _currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: timeParts.length >= 1 ? int.tryParse(timeParts[0]) ?? 12 : 12,
      minute: timeParts.length >= 2 ? int.tryParse(timeParts[1]) ?? 0 : 0,
    );
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selectedTime != null) {
      setState(() {
        _currentTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
        _updateRemainingTime();
      });
    }
  }

  void _showDatePicker() async {
    final dateParts = _currentDate.split('-');
    final initialDate = DateTime(
      dateParts.length >= 1 ? int.tryParse(dateParts[0]) ?? DateTime.now().year : DateTime.now().year,
      dateParts.length >= 2 ? int.tryParse(dateParts[1]) ?? DateTime.now().month : DateTime.now().month,
      dateParts.length >= 3 ? int.tryParse(dateParts[2]) ?? DateTime.now().day : DateTime.now().day,
    );
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selectedDate != null) {
      setState(() {
        _currentDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        _updateRemainingTime();
      });
    }
  }

  void _showPostponeDialog(AgendaItem agenda) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择推迟时间',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              padding: EdgeInsets.zero,
              children: [
                _postponeOption('5分钟', 5, agenda),
                _postponeOption('10分钟', 10, agenda),
                _postponeOption('15分钟', 15, agenda),
                _postponeOption('30分钟', 30, agenda),
                _postponeOption('1小时', 60, agenda),
                _postponeOption('自定义', -1, agenda),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('取消', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postponeOption(String label, int minutes, AgendaItem agenda) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (minutes == -1) {
          _showCustomPostpone(agenda);
        } else {
          context.read<AppStore>().postponeAgenda(agenda.id, minutes);
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }

  void _showCustomPostpone(AgendaItem agenda) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('自定义推迟时间'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '请输入推迟分钟数'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text.trim()) ?? 0;
              if (minutes > 0) {
                context.read<AppStore>().postponeAgenda(agenda.id, minutes);
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection(AgendaItem agenda) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _reminderExpanded = !_reminderExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.notifications_none, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  const Text('提醒规则', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const Spacer(),
                  Icon(_reminderExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
          if (_reminderExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _ruleTile('提前时间', '${agenda.advanceReminder ?? 5} 分钟'),
                  _ruleTile('重复间隔', '5 分钟'),
                  _ruleTile('最大提醒次数', '3 次'),
                  _ruleTile('提醒铃声', '默认铃声'),
                  _ruleTile('音量', '70%'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStrategySection(AgendaItem agenda) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _strategyExpanded = !_strategyExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  const Text('必做策略', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const Spacer(),
                  Icon(_strategyExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
          if (_strategyExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _stageTile('1', '预提醒', '提前 30 分钟', AppColors.info),
                  _stageTile('2', '首次提醒', '到点准时提醒', AppColors.accent),
                  _stageTile('3', '二次提醒', '延后 5 分钟', AppColors.warning),
                  _stageTile('4', '家属通知', '未完成时通知家属', AppColors.danger),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _ruleTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _stageTile(String idx, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(idx, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AgendaStatus status) {
    String text;
    Color color;
    Color bg;
    switch (status) {
      case AgendaStatus.pending:
        text = '待完成';
        color = AppColors.warning;
        bg = AppColors.warningLight;
        break;
      case AgendaStatus.completed:
        text = '已完成';
        color = AppColors.success;
        bg = AppColors.successLight;
        break;
      case AgendaStatus.skipped:
        text = '已跳过';
        color = AppColors.textSecondary;
        bg = AppColors.bgTertiary;
        break;
      case AgendaStatus.postponed:
        text = '已推迟';
        color = AppColors.info;
        bg = AppColors.infoLight;
        break;
      case AgendaStatus.expired:
        text = '已过期';
        color = AppColors.danger;
        bg = AppColors.dangerLight;
        break;
    }
    return _buildBadge(text, color, bg);
  }

  Widget _buildBadge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildLevelSelector() {
    final levels = [
      {'value': AgendaLevel.normal, 'label': '普通', 'color': AppColors.info, 'bg': AppColors.infoLight},
      {'value': AgendaLevel.important, 'label': '重要', 'color': AppColors.warning, 'bg': AppColors.warningLight},
      {'value': AgendaLevel.mustDo, 'label': '必做', 'color': AppColors.danger, 'bg': AppColors.dangerLight},
    ];
    return Row(
      children: levels.map((lv) {
        final selected = _currentLevel == lv['value'] as AgendaLevel;
        return GestureDetector(
          onTap: () => setState(() {
            _currentLevel = lv['value'] as AgendaLevel;
          }),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? (lv['bg'] as Color) : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? (lv['color'] as Color) : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              lv['label'] as String,
              style: TextStyle(
                fontSize: 12,
                color: selected ? (lv['color'] as Color) : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryBadge(AgendaCategory category) {
    final config = {
      AgendaCategory.dailyMustDo: ('每日必做', AppColors.danger, AppColors.dangerLight),
      AgendaCategory.frequent: ('常用', AppColors.purple, AppColors.purpleLight),
      AgendaCategory.temporary: ('临时', AppColors.info, AppColors.infoLight),
      AgendaCategory.custom: ('自定义', AppColors.textSecondary, AppColors.bgTertiary),
    };
    final c = config[category]!;
    return _buildBadge(c.$1, c.$2, c.$3);
  }

  Widget _buildBottomActions(AgendaItem agenda) {
    final isPending = agenda.status == AgendaStatus.pending;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (isPending) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showPostponeDialog(agenda),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('推迟', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _saveChanges(agenda),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: AppColors.accent),
                ),
                child: const Text('保存', style: TextStyle(fontSize: 13, color: AppColors.accent)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<AppStore>().completeAgenda(agenda.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('标记完成', style: TextStyle(fontSize: 13, color: Colors.white)),
              ),
            ),
          ] else ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _saveChanges(agenda),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('保存', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<AppStore>().deleteAgenda(agenda.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dangerLight,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('删除', style: TextStyle(fontSize: 14, color: AppColors.danger)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _saveChanges(AgendaItem agenda) {
    final content = _contentController.text.trim();
    final note = _noteController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入事程内容'), duration: Duration(seconds: 1)),
      );
      return;
    }
    context.read<AppStore>().updateAgenda(
      agenda.id,
      AgendaItem(
        id: agenda.id,
        content: content,
        time: _currentTime,
        date: _currentDate,
        icon: agenda.icon,
        note: note.isEmpty ? null : note,
        isMustDo: _currentLevel == AgendaLevel.mustDo,
        level: _currentLevel,
        status: agenda.status,
        source: agenda.source,
        repeat: agenda.repeat,
        isHighFrequency: agenda.isHighFrequency,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存'), duration: Duration(seconds: 1)),
    );
  }
}
