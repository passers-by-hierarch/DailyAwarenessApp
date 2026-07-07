import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/models/app_models.dart';

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
          _buildSection('备注（可选）', _buildNoteField()),
          const SizedBox(height: 24),
          _buildMustDoSwitch(),
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

  Widget _buildNoteField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _noteController,
        maxLines: 2,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: const InputDecoration(
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
          hintText: '例如：饭后服用',
          hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
        ),
      ),
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
      {'value': AgendaLevel.normal, 'label': '普通', 'color': AppColors.textSecondary, 'bg': AppColors.bgTertiary},
      {'value': AgendaLevel.important, 'label': '重要', 'color': AppColors.warning, 'bg': AppColors.warningLight},
      {'value': AgendaLevel.mustDo, 'label': '必做', 'color': AppColors.danger, 'bg': AppColors.dangerLight},
    ];
    return Row(
      children: levels.map((lv) {
        final selected = _level == lv['value'] as AgendaLevel;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _level = lv['value'] as AgendaLevel;
              if (_level == AgendaLevel.mustDo) _isMustDo = true;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
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
      }).toList(),
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
                _level = AgendaLevel.mustDo;
              } else if (_level == AgendaLevel.mustDo) {
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

  void _onSave() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入事程内容'), duration: Duration(seconds: 1)),
      );
      return;
    }
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
        isMustDo: _isMustDo,
        level: _level,
        icon: _selectedIcon,
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
      ));
    }
    Navigator.pop(context);
  }
}
