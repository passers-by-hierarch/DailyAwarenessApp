import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/models/app_models.dart';
import '../../../../shared/widgets/voice_recorder.dart';

/// 创建/编辑事程页 - 对齐原型 EditAgendaPage
class EditAgendaPage extends StatefulWidget {
  const EditAgendaPage({super.key});

  @override
  State<EditAgendaPage> createState() => _EditAgendaPageState();
}

class _EditAgendaPageState extends State<EditAgendaPage> {
  late final TextEditingController _timeController;
  late final TextEditingController _contentController;
  late final TextEditingController _noteController;
  String _selectedIcon = '📋';
  bool _isMustDo = false;
  AgendaLevel _level = AgendaLevel.normal;
  bool _initialized = false;
  String? _chainAfterId;
  int? _advanceReminder; // 单事程提前提醒分钟数（null=使用级别默认）
  String? _voiceNote;
  Map<String, dynamic>? _customReminderConfig;
  bool _useCustomReminder = false;
  bool _isSaving = false;
  TextEditingController? _customAdvanceController;
  TextEditingController? _customRepeatCountController;
  TextEditingController? _customRepeatIntervalController;

  static const List<String> _iconChoices = [
    '📋', '💊', '🍚', '💧', '🏃', '🛏', '🛒', '📚', '☎️', '🎯',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id != null) {
      final store = context.read<AppStore>();
      final agenda = store.agendaItems.where((a) => a.id == id).firstOrNull;
      if (agenda != null) {
        _timeController = TextEditingController(text: agenda.time);
        _contentController = TextEditingController(text: agenda.content);
        _noteController = TextEditingController(text: agenda.note ?? '');
        _selectedIcon = agenda.icon;
        _isMustDo = agenda.isMustDo;
        _level = agenda.level;
        _chainAfterId = agenda.chainAfterId;
        _advanceReminder = agenda.advanceReminder;
        _voiceNote = agenda.voiceNote;
        _customReminderConfig = agenda.customReminderConfig != null
            ? Map<String, dynamic>.from(agenda.customReminderConfig!)
            : null;
        _useCustomReminder = agenda.customReminderConfig != null;
        if (_useCustomReminder) {
          _initCustomControllers();
        }
      } else {
        _timeController = TextEditingController(text: '09:00');
        _contentController = TextEditingController();
        _noteController = TextEditingController();
      }
    } else {
      _timeController = TextEditingController(text: '09:00');
      _contentController = TextEditingController();
      _noteController = TextEditingController();
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _timeController.dispose();
    _contentController.dispose();
    _noteController.dispose();
    _customAdvanceController?.dispose();
    _customRepeatCountController?.dispose();
    _customRepeatIntervalController?.dispose();
    super.dispose();
  }

  bool get _isEdit => ModalRoute.of(context)?.settings.arguments != null;

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: _isEdit ? '编辑事程' : '创建事程',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('时间', _buildTimeField()),
          const SizedBox(height: 16),
          _buildSection('事程内容', _buildContentField()),
          const SizedBox(height: 16),
          _buildSection('图标', _buildIconGrid()),
          const SizedBox(height: 16),
          _buildSection('级别', _buildLevelSelector()),
          const SizedBox(height: 16),
          _buildSection('提前提醒', _buildReminderSelector()),
          const SizedBox(height: 16),
          if (_level.isMustDo) ...[
            _buildSection('必做提醒策略', _buildMustDoStrategy()),
            const SizedBox(height: 16),
          ],
          _buildSection('备注与语音记录', _buildNoteAndVoiceSection()),
          const SizedBox(height: 24),
          _buildMustDoSwitch(),
          const SizedBox(height: 16),
          _buildSection('链式事程（可选）', _buildChainSelector()),
          const SizedBox(height: 32),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        child,
      ],
    );
  }

  Widget _buildTimeField() {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.tryParse(_timeController.text.split(':').first) ?? 9,
            minute: int.tryParse(_timeController.text.split(':').last) ?? 0,
          ),
        );
        if (picked != null) {
          setState(() {
            _timeController.text =
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _timeController,
                enabled: false,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '请选择时间',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _contentController,
        maxLines: 2,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: const InputDecoration(
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
          hintText: '例如：吃降压药、散步30分钟',
          hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildNoteAndVoiceSection() {
    return VoiceRecorder(
      initialText: _noteController.text,
      initialAudioData: _voiceNote,
      onTextChanged: (text) {
        _noteController.text = text;
      },
      onAudioChanged: (audioData) {
        _voiceNote = audioData.isEmpty ? null : audioData;
      },
    );
  }

  Widget _buildIconGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _iconChoices.length,
        itemBuilder: (context, idx) {
          final icon = _iconChoices[idx];
          final selected = icon == _selectedIcon;
          return GestureDetector(
            onTap: () => setState(() => _selectedIcon = icon),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.accentLight : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? AppColors.accent : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelSelector() {
    final levels = [
      {'value': AgendaLevel.normal, 'label': '普通', 'color': AppColors.accent, 'bg': AppColors.accentLight},
      {'value': AgendaLevel.important, 'label': '重要', 'color': AppColors.warning, 'bg': AppColors.warningLight},
      {'value': AgendaLevel.mustDoShort, 'label': '短期必做', 'color': AppColors.danger, 'bg': AppColors.dangerLight},
      {'value': AgendaLevel.mustDoLong, 'label': '长期必做', 'color': AppColors.danger, 'bg': AppColors.dangerLight},
    ];

    Widget buildItem(Map<String, dynamic> lv) {
      final selected = _level == lv['value'] as AgendaLevel;
      final level = lv['value'] as AgendaLevel;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _level = level;
            if (_level.isMustDo) _isMustDo = true;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? (lv['bg'] as Color) : AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? (lv['color'] as Color) : AppColors.border,
              ),
            ),
            child: Text(
              lv['label'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: selected ? (lv['color'] as Color) : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            buildItem(levels[0]),
            const SizedBox(width: 8),
            buildItem(levels[1]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            buildItem(levels[2]),
            const SizedBox(width: 8),
            buildItem(levels[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildReminderSelector() {
    final store = context.read<AppStore>();
    final defaultRule = store.reminderRules[_level.name];
    final defaultMin = defaultRule?['advanceMinutes'] as int? ?? 10;

    final presetOptions = <Map<String, dynamic>>[
      {'label': '使用默认（$defaultMin分钟）', 'value': null},
      {'label': '不提醒', 'value': 0},
      {'label': '提前5分钟', 'value': 5},
      {'label': '提前10分钟', 'value': 10},
      {'label': '提前15分钟', 'value': 15},
      {'label': '提前30分钟', 'value': 30},
      {'label': '提前1小时', 'value': 60},
    ];

    final isCustom = _advanceReminder != null &&
        _advanceReminder != 0 &&
        !presetOptions.where((o) => o['value'] != null).map((o) => o['value'] as int).contains(_advanceReminder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('提醒规则', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
            Text(
              _useCustomReminder ? '自定义' : '使用全局规则',
              style: TextStyle(
                fontSize: 12,
                color: _useCustomReminder ? AppColors.accent : AppColors.textTertiary,
              ),
            ),
            Switch(
              value: _useCustomReminder,
              activeColor: AppColors.accent,
              onChanged: (v) => setState(() {
                _useCustomReminder = v;
                if (v && _customReminderConfig == null) {
                  final rule = store.reminderRules[_level.name] as Map<String, dynamic>? ?? {};
                  _customReminderConfig = Map<String, dynamic>.from(rule);
                }
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_useCustomReminder)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...presetOptions.map((opt) {
                final selected = _advanceReminder == opt['value'];
                return GestureDetector(
                  onTap: () => setState(() => _advanceReminder = opt['value'] as int?),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accentLight : AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      opt['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? AppColors.accent : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: _showCustomReminderDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCustom ? AppColors.accentLight : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCustom ? AppColors.accent : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 12, color: isCustom ? AppColors.accent : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        isCustom ? '自定义（$_advanceReminder分钟）' : '自定义',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCustom ? AppColors.accent : AppColors.textSecondary,
                          fontWeight: isCustom ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        else
          _buildCustomReminderEditor(),
      ],
    );
  }

  void _initCustomControllers() {
    final config = _customReminderConfig ?? {};
    _customAdvanceController ??= TextEditingController(text: '${config['advanceMinutes'] ?? 10}');
    _customRepeatCountController ??= TextEditingController(text: '${config['repeatCount'] ?? 1}');
    _customRepeatIntervalController ??= TextEditingController(text: '${config['repeatInterval'] ?? 5}');
  }

  Widget _buildCustomReminderEditor() {
    _initCustomControllers();
    final config = _customReminderConfig ?? {};
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomNumberField(
            label: '提前时间（分钟）',
            controller: _customAdvanceController!,
            onChanged: (v) {
              _customReminderConfig = {...?_customReminderConfig, 'advanceMinutes': int.tryParse(v) ?? 10};
            },
          ),
          const SizedBox(height: 10),
          _buildCustomNumberField(
            label: '重复次数',
            controller: _customRepeatCountController!,
            onChanged: (v) {
              _customReminderConfig = {...?_customReminderConfig, 'repeatCount': int.tryParse(v) ?? 1};
            },
          ),
          const SizedBox(height: 10),
          _buildCustomNumberField(
            label: '重复间隔（分钟）',
            controller: _customRepeatIntervalController!,
            onChanged: (v) {
              _customReminderConfig = {...?_customReminderConfig, 'repeatInterval': int.tryParse(v) ?? 5};
            },
          ),
          const SizedBox(height: 10),
          _buildCustomSwitchRow(
            label: '允许推迟',
            value: (config['allowPostpone'] as bool?) ?? true,
            onChanged: (v) {
              setState(() {
                _customReminderConfig = {...?_customReminderConfig, 'allowPostpone': v};
              });
            },
          ),
          _buildCustomSwitchRow(
            label: '允许跳过',
            value: (config['allowSkip'] as bool?) ?? true,
            onChanged: (v) {
              setState(() {
                _customReminderConfig = {...?_customReminderConfig, 'allowSkip': v};
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNumberField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Switch(
            value: value,
            activeColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showCustomReminderDialog() {
    final controller = TextEditingController(text: _advanceReminder?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('自定义提前提醒'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '提前分钟数',
            hintText: '输入1-180之间的数字',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= 1 && v <= 180) {
                setState(() => _advanceReminder = v);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('请输入1-180之间的数字'), duration: Duration(seconds: 1)),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildMustDoStrategy() {
    final store = context.watch<AppStore>();
    final mustDoRule = store.reminderRules[_level.name] as Map<String, dynamic>?;
    final stagesEnabled = mustDoRule?['stagesEnabled'] as bool? ?? true;
    final stages = (mustDoRule?['stages'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [-30, -10, 0, 10];

    String formatOffset(int minutes) {
      if (minutes < 0) return '提前${-minutes}分钟';
      if (minutes == 0) return '到点提醒';
      return '延后$minutes分钟';
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.alarm, size: 18, color: AppColors.danger),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('4阶段强化提醒', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('必做事程的逐级提醒策略', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Switch(
                value: stagesEnabled,
                activeColor: AppColors.danger,
                onChanged: (v) {
                  final rules = Map<String, dynamic>.from(store.reminderRules);
                  final levelRule = Map<String, dynamic>.from(rules[_level.name] as Map? ?? {});
                  levelRule['stagesEnabled'] = v;
                  rules[_level.name] = levelRule;
                  store.updateReminderRules(rules);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (stagesEnabled)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dangerLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger.withOpacity(0.3)),
            ),
            child: Column(
              children: List.generate(stages.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(bottom: i < stages.length - 1 ? 8 : 0),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          formatOffset(stages[i]),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                      const Icon(Icons.check_circle, size: 16, color: AppColors.danger),
                    ],
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/reminder-rules'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.settings, size: 14, color: AppColors.textTertiary),
                SizedBox(width: 6),
                Text('在提醒规则中自定义4阶段时间', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                Spacer(),
                Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMustDoSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 18, color: AppColors.danger),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('必做事程', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('启用4阶段强化提醒策略', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: _isMustDo,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() {
              _isMustDo = v;
              if (v) {
                _level = AgendaLevel.mustDoShort;
              } else if (_level.isMustDo) {
                _level = AgendaLevel.normal;
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: const Text('保存', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildChainSelector() {
    final store = context.read<AppStore>();
    final currentId = ModalRoute.of(context)?.settings.arguments as String?;
    // 排除自身和已完成的事程
    final candidates = store.agendaItems.where((a) =>
      a.id != currentId &&
      a.status != AgendaStatus.completed &&
      a.status != AgendaStatus.skipped
    ).toList();
    final selectedAgenda = _chainAfterId != null
        ? candidates.where((a) => a.id == _chainAfterId).firstOrNull
        : null;

    return GestureDetector(
      onTap: () => _showChainPicker(candidates),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedAgenda != null
                    ? '完成后 → ${selectedAgenda.content}'
                    : '完成后触发关联事程',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: selectedAgenda != null ? AppColors.textPrimary : AppColors.textTertiary,
                ),
              ),
            ),
            if (_chainAfterId != null)
              GestureDetector(
                onTap: () => setState(() => _chainAfterId = null),
                child: const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
              )
            else
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showChainPicker(List<AgendaItem> candidates) {
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可选的事程'), duration: Duration(seconds: 1)),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('选择关联事程', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1, color: AppColors.border),
            ...candidates.map((a) => ListTile(
              leading: Text(a.icon, style: const TextStyle(fontSize: 20)),
              title: Text(a.content, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${a.date} ${a.time}', style: const TextStyle(fontSize: 12)),
              trailing: _chainAfterId == a.id
                  ? const Icon(Icons.check, color: AppColors.accent)
                  : null,
              onTap: () {
                setState(() => _chainAfterId = a.id);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    if (_isSaving) return;
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入事程内容'), duration: Duration(seconds: 1)),
      );
      return;
    }
    setState(() => _isSaving = true);
    final store = context.read<AppStore>();
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    final todayStr = store.todayStr;
    if (id != null) {
      store.updateAgenda(id, AgendaItem(
        id: id,
        content: content,
        time: _timeController.text,
        date: todayStr,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        voiceNote: _voiceNote,
        isMustDo: _isMustDo,
        level: _level,
        icon: _selectedIcon,
        chainAfterId: _chainAfterId,
        advanceReminder: _advanceReminder,
        customReminderConfig: _useCustomReminder ? _customReminderConfig : null,
      ));
    } else {
      store.addAgenda(AgendaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        time: _timeController.text,
        date: todayStr,
        isMustDo: _isMustDo,
        level: _level,
        icon: _selectedIcon,
        status: AgendaStatus.pending,
        remainingTime: '今日提醒',
        chainAfterId: _chainAfterId,
        advanceReminder: _advanceReminder,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        voiceNote: _voiceNote,
        customReminderConfig: _useCustomReminder ? _customReminderConfig : null,
      ));
    }
    Navigator.pop(context);
  }
}
