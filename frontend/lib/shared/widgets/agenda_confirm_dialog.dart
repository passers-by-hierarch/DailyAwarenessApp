import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/mock/mock_data.dart';
import '../../core/models/app_models.dart';
import '../../core/services/intent_recognition_service.dart';
import '../../core/state/app_store.dart';

/// 智能事程确认弹窗
/// - 显示 3-5 秒倒计时（可调整）
/// - 倒计时结束后无操作 → 自动确认
/// - 用户可以点击「编辑」修改时间/内容
/// - 用户的修改会作为模式学习
class SmartAgendaConfirmDialog extends StatefulWidget {
  /// 原始输入文本
  final String originalText;
  /// 意图识别结果
  final IntentResult intentResult;
  /// 待确认事程列表
  final List<PendingAgendaItem> pendingAgendas;
  /// 倒计时时长（秒）
  final int countdownSeconds;
  /// 用户主动触发（非自动弹出）
  final bool isManualTrigger;

  const SmartAgendaConfirmDialog({
    super.key,
    required this.originalText,
    required this.intentResult,
    required this.pendingAgendas,
    this.countdownSeconds = 4,
    this.isManualTrigger = false,
  });

  @override
  State<SmartAgendaConfirmDialog> createState() => _SmartAgendaConfirmDialogState();
}

class _SmartAgendaConfirmDialogState extends State<SmartAgendaConfirmDialog> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isEditing = false;
  late List<_EditableAgenda> _editableAgendas;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;
    _editableAgendas = widget.pendingAgendas
        .map((p) => _EditableAgenda(
              id: p.id,
              content: p.content,
              time: p.suggestedTime,
              date: p.suggestedDate,
              level: AgendaLevel.normal,
            ))
        .toList();
    if (!widget.isManualTrigger) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        t.cancel();
        _autoConfirm();
      }
    });
  }

  void _autoConfirm() {
    if (!mounted) return;
    _confirmAgendas();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _confirmAgendas() {
    final store = context.read<AppStore>();
    final ids = _editableAgendas.map((e) => e.id).toList();
    store.confirmPendingAgenda(ids);

    // 学习模式：用户接受了原样
    _learnPattern(_editableAgendas, isEdited: false);

    if (mounted) {
      Navigator.of(context).pop(_editableAgendas.length);
    }
  }

  void _cancelAndLearn() {
    final store = context.read<AppStore>();
    final ids = _editableAgendas.map((e) => e.id).toList();
    store.rejectPendingAgenda(ids);
    if (mounted) {
      Navigator.of(context).pop(0);
    }
  }

  void _saveEdit() {
    final store = context.read<AppStore>();

    // 记录原始匹配键用于后续关联时间线
    final originalMatchKeys = <String, String>{};
    for (final p in widget.pendingAgendas) {
      originalMatchKeys[p.id] = '${p.suggestedTime}${p.content}';
    }

    // 先取消原待确认事程
    final originalIds = widget.pendingAgendas.map((p) => p.id).toList();
    store.rejectPendingAgenda(originalIds);

    // 用编辑后的内容创建新的事程
    for (final editable in _editableAgendas) {
      final newId = DateTime.now().millisecondsSinceEpoch.toString() + editable.id;
      store.addAgenda(AgendaItem(
        id: newId,
        content: editable.content,
        time: editable.time,
        date: editable.date,
        isMustDo: editable.level.isMustDo,
        level: editable.level,
        status: AgendaStatus.pending,
        remainingTime: editable.date == MockData.todayStr ? '今日提醒' : '待提醒',
        icon: store.autoDetectIcon(editable.content),
        source: AgendaSource.user,
      ));
      // 关联时间线记录
      final matchKey = originalMatchKeys[editable.id];
      if (matchKey != null) {
        store.linkTimelineToAgenda(matchKey, newId);
      }
    }

    // 学习模式：用户修改了内容
    _learnPattern(_editableAgendas, isEdited: true);

    if (mounted) {
      Navigator.of(context).pop(_editableAgendas.length);
    }
  }

  void _learnPattern(List<_EditableAgenda> agendas, {required bool isEdited}) {
    final store = context.read<AppStore>();

    // 将编辑后的结果转换为 TimelineSlot
    final slots = <TimelineSlot>[];
    for (final agenda in agendas) {
      slots.add(TimelineSlot(
        time: agenda.time,
        intents: [
          IntentItem(
            type: IntentType.agendaCreate,
            slots: {
              'content': agenda.content,
              'is_must_do': agenda.level.isMustDo,
              'time': agenda.time,
              'date_offset': MockData.dateOffset(0) == agenda.date
                  ? 0
                  : (agenda.date.compareTo(MockData.todayStr) > 0 ? 1 : 0),
            },
            confidence: 1.0,
          ),
        ],
      ));
    }

    // 用户编辑的权重更高（count=5），接受的权重较低（count=2）
    final weight = isEdited ? 5 : 2;
    for (var i = 0; i < weight; i++) {
      store.addIntentPattern(widget.originalText, slots);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return _buildEditView();
    }
    return _buildPreviewView();
  }

  Widget _buildPreviewView() {
    return Dialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(AppIcons.brain, color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI 识别到事程', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('请确认是否创建', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                if (!widget.isManualTrigger) _buildCountdownBadge(),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.quote, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.originalText,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _editableAgendas.asMap().entries.map((entry) => _buildAgendaCard(entry.value)).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _timer?.cancel();
                      _remainingSeconds = 999; // 编辑期间暂停倒计时
                      setState(() => _isEditing = true);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('编辑修改', style: TextStyle(color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelAndLearn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('忽略', style: TextStyle(color: AppColors.textTertiary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _timer?.cancel();
                      _confirmAgendas();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.accent,
                    ),
                    child: const Text('确认创建', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.timer, size: 14, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            '$_remainingSeconds秒后自动创建',
            style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaCard(_EditableAgenda agenda) {
    final dateLabel = agenda.date == MockData.todayStr
        ? '今天'
        : agenda.date == MockData.dateOffset(1)
            ? '明天'
            : agenda.date;

    final levelInfo = _getLevelInfo(agenda.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: levelInfo.$2.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(levelInfo.$3, size: 18, color: levelInfo.$2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(agenda.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: levelInfo.$2.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(levelInfo.$1, style: TextStyle(fontSize: 10, color: levelInfo.$2, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(dateLabel, style: const TextStyle(fontSize: 10, color: AppColors.info, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 6),
                    Text(agenda.time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _getLevelInfo(AgendaLevel level) {
    switch (level) {
      case AgendaLevel.mustDoShort:
        return ('短期必做', AppColors.danger, AppIcons.star);
      case AgendaLevel.mustDoLong:
        return ('长期必做', AppColors.danger, AppIcons.star);
      case AgendaLevel.important:
        return ('重要', AppColors.warning, AppIcons.alertCircle);
      case AgendaLevel.normal:
      default:
        return ('普通', AppColors.accent, AppIcons.circle);
    }
  }

  Widget _buildEditView() {
    return Dialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(AppIcons.edit2, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Text('编辑事程', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _isEditing = false);
                    if (!widget.isManualTrigger) _startCountdown();
                  },
                  child: const Icon(AppIcons.x, size: 20, color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _editableAgendas.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final agenda = entry.value;
                    return _buildEditableCard(idx, agenda);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelAndLearn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('取消', style: TextStyle(color: AppColors.textTertiary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveEdit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.accent,
                    ),
                    child: const Text('保存修改', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableCard(int idx, _EditableAgenda agenda) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('事程 #${idx + 1}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: agenda.content),
            decoration: const InputDecoration(
              labelText: '内容',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => agenda.content = v,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final timeParts = agenda.time.split(':');
                    final initialTime = TimeOfDay(
                      hour: timeParts.length >= 1 ? int.tryParse(timeParts[0]) ?? 12 : 12,
                      minute: timeParts.length >= 2 ? int.tryParse(timeParts[1]) ?? 0 : 0,
                    );
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: initialTime,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.accent,
                              onPrimary: Colors.white,
                              surface: AppColors.bgSecondary,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (selectedTime != null) {
                      setState(() {
                        agenda.time = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(AppIcons.clock, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          agenda.time.isNotEmpty ? agenda.time : '选择时间',
                          style: TextStyle(
                            fontSize: 13,
                            color: agenda.time.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(AppIcons.chevronDown, size: 16, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final dateParts = agenda.date.split('-');
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
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.accent,
                              onPrimary: Colors.white,
                              surface: AppColors.bgSecondary,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (selectedDate != null) {
                      setState(() {
                        agenda.date = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(AppIcons.calendar, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          agenda.date.isNotEmpty ? agenda.date : '选择日期',
                          style: TextStyle(
                            fontSize: 13,
                            color: agenda.date.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(AppIcons.chevronDown, size: 16, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<AgendaLevel>(
                  value: agenda.level,
                  decoration: const InputDecoration(
                    labelText: '事程级别',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: AgendaLevel.normal, child: Text('普通')),
                    DropdownMenuItem(value: AgendaLevel.important, child: Text('重要')),
                    DropdownMenuItem(value: AgendaLevel.mustDoShort, child: Text('短期必做')),
                    DropdownMenuItem(value: AgendaLevel.mustDoLong, child: Text('长期必做')),
                  ],
                  onChanged: (v) => setState(() => agenda.level = v!),
                ),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              if (_editableAgendas.length > 1)
                GestureDetector(
                  onTap: () => setState(() => _editableAgendas.removeAt(idx)),
                  child: const Icon(AppIcons.trash2, size: 20, color: AppColors.danger),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditableAgenda {
  String id;
  String content;
  String time;
  String date;
  AgendaLevel level;

  _EditableAgenda({
    required this.id,
    required this.content,
    required this.time,
    required this.date,
    this.level = AgendaLevel.normal,
  });
}

/// 便捷函数：弹出智能确认弹窗
/// 返回确认创建的事程数量，0 表示用户取消
Future<int> showSmartAgendaConfirmDialog({
  required BuildContext context,
  required String originalText,
  required IntentResult intentResult,
  required List<PendingAgendaItem> pendingAgendas,
  int countdownSeconds = 4,
  bool isManualTrigger = false,
}) async {
  final result = await showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => SmartAgendaConfirmDialog(
      originalText: originalText,
      intentResult: intentResult,
      pendingAgendas: pendingAgendas,
      countdownSeconds: countdownSeconds,
      isManualTrigger: isManualTrigger,
    ),
  );
  return result ?? 0;
}