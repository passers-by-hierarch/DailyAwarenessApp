import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/utils/agenda_utils.dart';
import '../../../../shared/widgets/voice_recorder.dart';

class AgendaDetailPage extends StatefulWidget {
  const AgendaDetailPage({super.key});

  @override
  State<AgendaDetailPage> createState() => _AgendaDetailPageState();
}

class _AgendaDetailPageState extends State<AgendaDetailPage> {
  bool _reminderExpanded = false;
  bool _chainExpanded = false;
  String? _chainAfterId;
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _currentTime = '';
  String _currentDate = '';
  AgendaLevel _currentLevel = AgendaLevel.normal;
  int? _advanceReminder;
  String _currentIcon = '📋';
  int _repeatCount = 0;
  int _repeatInterval = 0;
  String? _voiceNote;
  Timer? _statusTimer;
  bool _initialized = false;

  bool get _isHistorical {
    final today = DateTime.now();
    final agendaDate = DateTime.tryParse(_currentDate);
    if (agendaDate == null) return false;
    return agendaDate.isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  void initState() {
    super.initState();
    _initialized = false;
    _startStatusTimer();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _noteController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusTimer() {
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  void _initControllers(AgendaItem agenda) {
    _contentController.text = agenda.content;
    _currentTime = agenda.time;
    _currentDate = agenda.date;
    _noteController.text = agenda.note ?? '';
    _currentLevel = agenda.level;
    _advanceReminder = agenda.advanceReminder;
    _currentIcon = agenda.icon;
    _chainAfterId = agenda.chainAfterId;
    _voiceNote = agenda.voiceNote;
  }

  @override
  Widget build(BuildContext context) {
    final agendaId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final agenda = context.select<AppStore, AgendaItem?>(
      (s) => s.agendaItems.where((a) => a.id == agendaId).firstOrNull,
    );

    if (agenda == null) {
      return const SecondaryScaffold(
        title: '事程详情',
        body: Center(child: Text('事程不存在', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    if (!_initialized) {
      _initControllers(agenda);
      _initialized = true;
    }

    return SecondaryScaffold(
      title: '事程详情',
      body: Column(
        children: [
          if (_isHistorical)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.warningLight,
              child: const Row(
                children: [
                  Icon(Icons.history, size: 16, color: AppColors.warning),
                  SizedBox(width: 6),
                  Text('历史事程记录，仅备注和语音可修改', style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBasicInfoCard(agenda),
                const SizedBox(height: 12),
                _buildNotesSection(agenda),
                const SizedBox(height: 12),
                _buildReminderSection(agenda),
                const SizedBox(height: 12),
                _buildChainSection(agenda),
                const SizedBox(height: 16),
              ],
            ),
          ),
          _buildBottomActions(agenda),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(AgendaItem agenda) {
    final store = context.read<AppStore>();
    final isToday = agenda.date == AgendaUtils.todayStr(now: store.now);
    final effectiveStatus = AgendaUtils.effectiveStatus(agenda, isToday: isToday, now: store.now);

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
              _isHistorical
                  ? Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_currentIcon, style: const TextStyle(fontSize: 24)),
                    )
                  : GestureDetector(
                      onTap: _showIconPicker,
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_currentIcon, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isHistorical
                        ? Text(
                            agenda.content,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          )
                        : TextField(
                            controller: _contentController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '输入事程内容',
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                    const SizedBox(height: 4),
                    _isHistorical
                        ? Row(
                            children: [
                              const Icon(AppIcons.clock, size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                agenda.time,
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                agenda.date,
                                style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(AppIcons.clock, size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _showTimePicker(agenda),
                                child: Row(
                                  children: [
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
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _showDatePicker(agenda),
                                child: Row(
                                  children: [
                                    Text(
                                      _currentDate,
                                      style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                                    ),
                                    const Icon(AppIcons.calendar, size: 12, color: AppColors.textTertiary),
                                  ],
                                ),
                              ),
                            ],
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
              _buildStatusBadge(effectiveStatus),
              if (_isHistorical) _buildLevelBadge(_currentLevel),
              if (agenda.isHighFrequency)
                _buildBadge('高频', AppColors.purple, AppColors.purpleLight),
              if (agenda.source == AgendaSource.ai)
                _buildBadge('AI推荐', AppColors.accent, AppColors.accentLight),
              if (agenda.streak > 0)
                _buildBadge('连续${agenda.streak}天', AppColors.warning, AppColors.warningLight),
            ],
          ),
          if (!_isHistorical) ...[
            const SizedBox(height: 16),
            _buildLevelSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(AgendaItem agenda) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildNoteInput(),
          const SizedBox(height: 16),
          _buildNoteHistory(agenda),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '输入补充内容...',
                hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              onSubmitted: (_) => _saveNote(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('语音功能需要麦克风权限'), duration: Duration(seconds: 2)),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _saveNote,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _saveNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _noteController.text = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('备注已保存'), duration: Duration(seconds: 1)),
    );
  }

  Widget _buildNoteHistory(AgendaItem agenda) {
    final hasNote = agenda.note != null && agenda.note!.isNotEmpty;
    final hasVoice = _voiceNote != null && _voiceNote!.isNotEmpty;

    if (!hasNote && !hasVoice) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (hasVoice)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.waves, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                const Text('20:04', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (hasNote)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              agenda.note!,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
      ],
    );
  }

  Widget _buildReminderSection(AgendaItem agenda) {
    final store = context.read<AppStore>();
    final defaultRule = store.reminderRules[_currentLevel.name];
    final defaultMin = defaultRule?['advanceMinutes'] as int? ?? 10;

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
                  const Icon(AppIcons.bell, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  const Text('提醒规则', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _advanceReminder == null
                          ? '默认$defaultMin分'
                          : _advanceReminder == 0
                              ? '不提醒'
                              : '提前$_advanceReminder分',
                      style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  Icon(_reminderExpanded ? AppIcons.chevronUp : AppIcons.chevronDown, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
          if (_reminderExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('当前提醒设置', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  _buildReadOnlyReminderItem('提前提醒', _advanceReminder == null
                      ? '使用默认（${defaultMin}分钟）'
                      : _advanceReminder == 0
                          ? '不提醒'
                          : '提前${_advanceReminder}分钟'),
                  _buildReadOnlyReminderItem('重复次数', _repeatCount == 0 ? '不重复' : '${_repeatCount}次'),
                  _buildReadOnlyReminderItem('重复间隔', _repeatInterval == 0 ? '未设置' : _repeatInterval < 60 ? '${_repeatInterval}分钟' : '${_repeatInterval ~/ 60}小时'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(AppIcons.info, size: 14, color: AppColors.info),
                        const SizedBox(width: 8),
                        Expanded(
                          child: const Text(
                            '提醒规则需在"我的-提醒规则"中设置，此处仅查看当前配置',
                            style: TextStyle(fontSize: 12, color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(AgendaLevel level) {
    final config = {
      AgendaLevel.normal: ('普通', AppColors.accent, AppColors.accentLight),
      AgendaLevel.important: ('重要', AppColors.warning, AppColors.warningLight),
      AgendaLevel.mustDoShort: ('短必做', AppColors.danger, AppColors.dangerLight),
      AgendaLevel.mustDoLong: ('长必做', AppColors.danger, AppColors.dangerLight),
    };
    final c = config[level]!;
    return _buildBadge(c.$1, c.$2, c.$3);
  }

  Widget _buildReadOnlyReminderItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatCountSelector() {
    final counts = [0, 1, 2, 3, 5];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: counts.map((count) {
        final selected = _repeatCount == count;
        return GestureDetector(
          onTap: () => setState(() => _repeatCount = count),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.accentLight : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              count == 0 ? '不重复' : '$count次',
              style: TextStyle(
                fontSize: 12,
                color: selected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRepeatIntervalSelector() {
    final intervals = [5, 10, 15, 30, 60];
    if (_repeatCount == 0) {
      return const Text(
        '设置重复次数后可配置间隔',
        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: intervals.map((interval) {
        final selected = _repeatInterval == interval;
        return GestureDetector(
          onTap: () => setState(() => _repeatInterval = interval),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.accentLight : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              interval < 60 ? '$interval分钟' : '${interval ~/ 60}小时',
              style: TextStyle(
                fontSize: 12,
                color: selected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChainSection(AgendaItem agenda) {
    final store = context.read<AppStore>();
    final chainAgenda = _chainAfterId != null
        ? store.agendaItems.where((a) => a.id == _chainAfterId).firstOrNull
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _chainExpanded = !_chainExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(AppIcons.link, size: 18, color: AppColors.purple),
                  const SizedBox(width: 8),
                  const Text('链式事程', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  if (chainAgenda != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.purpleLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        chainAgenda.content,
                        style: const TextStyle(fontSize: 11, color: AppColors.purple, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '无',
                        style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const Spacer(),
                  Icon(_chainExpanded ? AppIcons.chevronUp : AppIcons.chevronDown, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
          if (_chainExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('完成此事后自动触发', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showChainPicker(agenda),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          if (chainAgenda != null) ...[
                            Text(chainAgenda.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(chainAgenda.content, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text(chainAgenda.time, style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                ],
                              ),
                            ),
                          ] else ...[
                            const Text('选择事程', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
                            const Spacer(),
                            const Icon(AppIcons.chevronRight, size: 18, color: AppColors.textTertiary),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (chainAgenda != null)
                    GestureDetector(
                      onTap: () => setState(() => _chainAfterId = null),
                      child: const Text('取消链式关联', style: TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w500)),
                    ),
                  const SizedBox(height: 8),
                  _buildChainSuggestions(store, agenda),
                  const SizedBox(height: 8),
                  const Text('说明：完成此事后，会立即触发选中事程的提醒', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showChainPicker(AgendaItem agenda) {
    final store = context.read<AppStore>();
    final agendas = store.agendaItems.where((a) => a.id != agenda.id).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择触发事程',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: agendas.length,
                  itemBuilder: (ctx, index) {
                    final item = agendas[index];
                    final selected = _chainAfterId == item.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _chainAfterId = selected ? null : item.id);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.accentLight : AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? AppColors.accent : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(item.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.content, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text(item.time, style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(AppIcons.check, size: 20, color: AppColors.accent),
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
      ),
    );
  }

  void _showTimePicker(AgendaItem agenda) async {
    final timeParts = _currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 12 : 12,
      minute: timeParts.length >= 2 ? int.tryParse(timeParts[1]) ?? 0 : 0,
    );
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selectedTime != null) {
      setState(() {
        _currentTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _showDatePicker(AgendaItem agenda) async {
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
      });
    }
  }

  Widget _buildChainSuggestions(AppStore store, AgendaItem agenda) {
    final suggestions = store.getChainSuggestions(agenda.content);
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final suggestedAgendas = store.agendaItems
        .where((a) => suggestions.contains(a.content) && a.id != agenda.id)
        .toList();

    if (suggestedAgendas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.history, size: 14, color: AppColors.purple),
            const SizedBox(width: 4),
            const Text('关联记忆', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.purple)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: suggestedAgendas.map((a) {
            final alreadyChained = _chainAfterId == a.id;
            return GestureDetector(
              onTap: () {
                if (!alreadyChained) {
                  setState(() => _chainAfterId = a.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: alreadyChained ? AppColors.purpleLight : AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: alreadyChained ? AppColors.purple : AppColors.border,
                    width: alreadyChained ? 1 : 0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      a.content,
                      style: TextStyle(
                        fontSize: 12,
                        color: alreadyChained ? AppColors.purple : AppColors.textSecondary,
                        fontWeight: alreadyChained ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showIconPicker() {
    final icons = ['📋', '📝', '📅', '⏰', '🎯', '💼', '🏠', '🛒', '🍎', '💪', '📚', '🎵', '✈️', '🏃', '💊', '🔔'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择图标',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  childAspectRatio: 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: icons.length,
                itemBuilder: (ctx, index) {
                  final icon = icons[index];
                  final selected = _currentIcon == icon;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _currentIcon = icon);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accentLight : AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.accent : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildStatusBadge(AgendaStatus status) {
    String text;
    Color color;
    Color bg;
    switch (status) {
      case AgendaStatus.pending:
        text = '待进行';
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
        text = '已延后';
        color = AppColors.warning;
        bg = AppColors.warningLight;
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
      {'value': AgendaLevel.normal, 'label': '普通', 'color': AppColors.accent, 'bg': AppColors.accentLight},
      {'value': AgendaLevel.important, 'label': '重要', 'color': AppColors.warning, 'bg': AppColors.warningLight},
      {'value': AgendaLevel.mustDoShort, 'label': '短必做', 'color': AppColors.danger, 'bg': AppColors.dangerLight},
      {'value': AgendaLevel.mustDoLong, 'label': '长必做', 'color': AppColors.danger, 'bg': AppColors.dangerLight},
    ];

    Widget buildLevelItem(Map<String, dynamic> lv) {
      final selected = _currentLevel == lv['value'] as AgendaLevel;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _currentLevel = lv['value'] as AgendaLevel;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: selected ? (lv['bg'] as Color) : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? (lv['color'] as Color) : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              lv['label'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: selected ? (lv['color'] as Color) : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            buildLevelItem(levels[0]),
            const SizedBox(width: 6),
            buildLevelItem(levels[1]),
            const SizedBox(width: 6),
            buildLevelItem(levels[2]),
            const SizedBox(width: 6),
            buildLevelItem(levels[3]),
          ],
        ),
      ],
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
    final store = context.read<AppStore>();
    final isToday = agenda.date == AgendaUtils.todayStr(now: store.now);
    final effectiveStatus = AgendaUtils.effectiveStatus(agenda, isToday: isToday, now: store.now);
    final isActionable = effectiveStatus == AgendaStatus.pending ||
        effectiveStatus == AgendaStatus.postponed ||
        effectiveStatus == AgendaStatus.expired;
    final isSkipped = effectiveStatus == AgendaStatus.skipped;
    // 必做事程不允许跳过
    final isMustDo = agenda.level == AgendaLevel.mustDoShort || agenda.level == AgendaLevel.mustDoLong;

    if (_isHistorical) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _saveChanges(agenda),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: AppColors.accent),
                ),
                child: const Text('保存备注', style: TextStyle(fontSize: 14, color: AppColors.accent)),
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
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (isActionable) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showPostponeDialog(agenda),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('推迟', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
              ),
            ),
            if (!isMustDo) ...[
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<AppStore>().skipAgenda(agenda.id);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('跳过', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ),
            ],
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _saveChanges(agenda),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: AppColors.accent),
                ),
                child: const Text('保存', style: TextStyle(fontSize: 12, color: AppColors.accent)),
              ),
            ),
            const SizedBox(width: 6),
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
                child: const Text('完成', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ),
          ] else if (isSkipped) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  context.read<AppStore>().deleteAgenda(agenda.id);
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('删除', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<AppStore>().unskipAgenda(agenda.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('恢复', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<AppStore>().completeAgenda(agenda.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('完成', style: TextStyle(fontSize: 12, color: Colors.white)),
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
    
    print('[DEBUG] _saveChanges called:');
    print('[DEBUG]   agenda.id: ${agenda.id}');
    print('[DEBUG]   agenda.content: ${agenda.content}');
    print('[DEBUG]   agenda.time: ${agenda.time}');
    print('[DEBUG]   agenda.date: ${agenda.date}');
    print('[DEBUG]   agenda.status: ${agenda.status}');
    print('[DEBUG]   _contentController.text: $_contentController.text');
    print('[DEBUG]   _currentTime: $_currentTime');
    print('[DEBUG]   _currentDate: $_currentDate');
    print('[DEBUG]   _isHistorical: $_isHistorical');

    if (_isHistorical) {
      final store = context.read<AppStore>();
      store.updateAgenda(
        agenda.id,
        AgendaItem(
          id: agenda.id,
          content: agenda.content,
          time: agenda.time,
          date: agenda.date,
          icon: agenda.icon,
          note: note.isEmpty ? null : note,
          voiceNote: _voiceNote,
          isMustDo: agenda.isMustDo,
          level: agenda.level,
          status: agenda.status,
          source: agenda.source,
          repeat: agenda.repeat,
          isHighFrequency: agenda.isHighFrequency,
          category: agenda.category,
          chainAfterId: agenda.chainAfterId,
          advanceReminder: agenda.advanceReminder,
          customReminderConfig: agenda.customReminderConfig,
          streak: agenda.streak,
          failCount: agenda.failCount,
          timeDeviationCount: agenda.timeDeviationCount,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存备注'), duration: Duration(seconds: 1)),
      );
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入事程内容'), duration: Duration(seconds: 1)),
      );
      return;
    }
    final store = context.read<AppStore>();
    if (_chainAfterId != null) {
      final chainAgenda = store.agendaItems.where((a) => a.id == _chainAfterId).firstOrNull;
      if (chainAgenda != null) {
        store.recordChainAssociation(content, chainAgenda.content);
      }
    }
    store.updateAgenda(
      agenda.id,
      AgendaItem(
        id: agenda.id,
        content: content,
        time: _currentTime,
        date: _currentDate,
        icon: _currentIcon,
        note: note.isEmpty ? null : note,
        voiceNote: _voiceNote,
        isMustDo: _currentLevel.isMustDo,
        level: _currentLevel,
        status: agenda.status,
        source: agenda.source,
        repeat: agenda.repeat,
        isHighFrequency: agenda.isHighFrequency,
        category: agenda.category,
        chainAfterId: _chainAfterId,
        advanceReminder: _advanceReminder,
        customReminderConfig: agenda.customReminderConfig,
        streak: agenda.streak,
        failCount: agenda.failCount,
        timeDeviationCount: agenda.timeDeviationCount,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存'), duration: Duration(seconds: 1)),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) Navigator.pop(context);
    });
  }
}
