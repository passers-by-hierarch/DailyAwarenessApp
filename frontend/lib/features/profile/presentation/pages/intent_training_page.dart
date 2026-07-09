import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/services/intent_recognition_service.dart';
import '../../../../core/state/app_store.dart';

class IntentTrainingPage extends StatefulWidget {
  const IntentTrainingPage({super.key});

  @override
  State<IntentTrainingPage> createState() => _IntentTrainingPageState();
}

class _IntentTrainingPageState extends State<IntentTrainingPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UserPattern> _filterPatterns(List<UserPattern> patterns) {
    if (_searchQuery.isEmpty) return patterns;
    return patterns
        .where((p) => p.inputText.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Color _intentColor(IntentType type) {
    switch (type) {
      case IntentType.behavior:
        return AppColors.accent;
      case IntentType.agendaCreate:
        return AppColors.info;
      case IntentType.agendaComplete:
        return AppColors.success;
      case IntentType.itemLocation:
        return AppColors.warning;
      case IntentType.shopping:
        return AppColors.purple;
      case IntentType.inventoryConsume:
        return Colors.teal;
      case IntentType.general:
        return AppColors.textSecondary;
    }
  }

  void _showPatternDialog({UserPattern? pattern}) {
    showDialog(
      context: context,
      builder: (ctx) => _PatternDialog(
        pattern: pattern,
        onSave: (text, slots) async {
          if (pattern == null) {
            await context.read<AppStore>().addIntentPattern(text, slots);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('模式已添加'), duration: Duration(seconds: 1)),
              );
            }
          } else {
            await context.read<AppStore>().updateIntentPattern(pattern.inputText, text, slots);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('模式已更新'), duration: Duration(seconds: 1)),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmDelete(String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模式"$text"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              context.read<AppStore>().deleteIntentPattern(text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('模式已删除'), duration: Duration(seconds: 1)),
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有训练模式吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              context.read<AppStore>().clearAllIntentPatterns();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('所有模式已清空'), duration: Duration(seconds: 1)),
              );
            },
            child: const Text('清空', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _loadPresets() {
    context.read<AppStore>().loadPresetPatterns();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('预设模式已加载'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final stats = store.getIntentStats();
    final patterns = _filterPatterns(store.allIntentPatterns);
    final sortedPatterns = List<UserPattern>.from(patterns)
      ..sort((a, b) => b.count.compareTo(a.count));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.chevronLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '意图训练管理',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          _buildStatsCard(stats),
          _buildActionButtons(),
          _buildSearchBar(),
          Expanded(
            child: sortedPatterns.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedPatterns.length,
                    itemBuilder: (ctx, idx) => _buildPatternItem(sortedPatterns[idx]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPatternDialog(),
        backgroundColor: AppColors.accent,
        child: const Icon(AppIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('训练统计', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem('模式总数', '${stats['total_patterns']}', AppColors.accent),
              _buildStatItem('LLM调用', '${stats['llm_calls']}', AppColors.info),
              _buildStatItem('本地匹配', '${stats['local_matches']}', AppColors.success),
              _buildStatItem('命中率', '${stats['local_hit_rate']}%', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _loadPresets,
              icon: const Icon(AppIcons.download, size: 18),
              label: const Text('加载预设'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _confirmClearAll,
              icon: const Icon(AppIcons.trash2, size: 18),
              label: const Text('清空所有'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: '搜索模式...',
          prefixIcon: const Icon(AppIcons.search, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(AppIcons.x, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.bgSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPatternItem(UserPattern pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  pattern.inputText,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pattern.count}次',
                  style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showPatternDialog(pattern: pattern),
                child: const Icon(AppIcons.edit2, size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmDelete(pattern.inputText),
                child: const Icon(AppIcons.trash2, size: 18, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pattern.slots.map((slot) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(AppIcons.clock, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          slot.time.isNotEmpty ? slot.time : '未指定时间',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: slot.intents.map((intent) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _intentColor(intent.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _intentColor(intent.type),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                intent.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _intentColor(intent.type),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    if (slot.intents.isNotEmpty && slot.intents.first.slots.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: slot.intents.first.slots.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bgSecondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${e.key}: ${e.value}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.brain, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? '还没有训练模式' : '没有找到匹配的模式',
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? '点击右下角 + 添加新的训练模式' : '试试其他关键词',
            style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _PatternDialog extends StatefulWidget {
  final UserPattern? pattern;
  final Future<void> Function(String text, List<TimelineSlot> slots) onSave;

  const _PatternDialog({
    this.pattern,
    required this.onSave,
  });

  @override
  State<_PatternDialog> createState() => _PatternDialogState();
}

class _PatternDialogState extends State<_PatternDialog> {
  final _textCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _slotKeyCtrl = TextEditingController();
  final _slotValueCtrl = TextEditingController();
  final List<TimelineSlot> _slots = [];
  final Map<String, dynamic> _currentSlots = {};
  IntentType _selectedIntent = IntentType.behavior;

  bool get isEdit => widget.pattern != null;

  @override
  void initState() {
    super.initState();
    if (widget.pattern != null) {
      _textCtrl.text = widget.pattern!.inputText;
      _slots.addAll(widget.pattern!.slots.map((s) => TimelineSlot(
            time: s.time,
            intents: s.intents
                .map((i) => IntentItem(
                      type: i.type,
                      slots: Map<String, dynamic>.from(i.slots),
                      confidence: i.confidence,
                    ))
                .toList(),
          )));
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _timeCtrl.dispose();
    _slotKeyCtrl.dispose();
    _slotValueCtrl.dispose();
    super.dispose();
  }

  Color _intentColor(IntentType type) {
    switch (type) {
      case IntentType.behavior:
        return AppColors.accent;
      case IntentType.agendaCreate:
        return AppColors.info;
      case IntentType.agendaComplete:
        return AppColors.success;
      case IntentType.itemLocation:
        return AppColors.warning;
      case IntentType.shopping:
        return AppColors.purple;
      case IntentType.inventoryConsume:
        return Colors.teal;
      case IntentType.general:
        return AppColors.textSecondary;
    }
  }

  String _intentDisplayName(IntentType type) {
    switch (type) {
      case IntentType.behavior:
        return '行为活动';
      case IntentType.agendaCreate:
        return '创建事程';
      case IntentType.agendaComplete:
        return '完成事程';
      case IntentType.itemLocation:
        return '物品位置';
      case IntentType.shopping:
        return '购物记录';
      case IntentType.inventoryConsume:
        return '库存消耗';
      case IntentType.general:
        return '通用';
    }
  }

  Map<String, String> _getSlotLabels(IntentType type) {
    switch (type) {
      case IntentType.itemLocation:
        return {
          'item_name': '物品名称',
          'location': '存放位置',
        };
      case IntentType.shopping:
        return {
          'store': '购买地点',
          'items_text': '购买物品',
        };
      case IntentType.agendaCreate:
        return {
          'content': '事程内容',
          'is_must_do': '事程级别',
          'time': '计划时间',
          'date_offset': '日期偏移',
        };
      case IntentType.inventoryConsume:
        return {
          'item_name': '物品名称',
          'quantity': '消耗数量',
          'unit': '单位',
        };
      case IntentType.behavior:
        return {
          'keyword': '行为关键词',
          'category': '行为分类',
        };
      default:
        return {};
    }
  }

  List<String> _getSlotKeys(IntentType type) {
    switch (type) {
      case IntentType.itemLocation:
        return ['item_name', 'location'];
      case IntentType.shopping:
        return ['store', 'items_text'];
      case IntentType.agendaCreate:
        return ['content', 'time', 'date_offset', 'is_must_do'];
      case IntentType.inventoryConsume:
        return ['item_name', 'quantity', 'unit'];
      case IntentType.behavior:
        return ['keyword', 'category'];
      default:
        return [];
    }
  }

  Widget _buildSlotFields() {
    final slotKeys = _getSlotKeys(_selectedIntent);
    final slotLabels = _getSlotLabels(_selectedIntent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getSlotSectionTitle(_selectedIntent),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        ...slotKeys.map((key) {
          final label = slotLabels[key] ?? key;
          final currentValue = _currentSlots[key]?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                if (key == 'time')
                  _buildTimePickerField(key, currentValue)
                else if (key == 'is_must_do')
                  _buildLevelSelectorField(key, currentValue)
                else if (key == 'date_offset')
                  _buildDateOffsetField(key, currentValue)
                else
                  TextField(
                    onChanged: (v) {
                      _currentSlots[key] = v.trim();
                    },
                    decoration: InputDecoration(
                      hintText: _getSlotHint(key),
                      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.bgTertiary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                    controller: TextEditingController(text: currentValue),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTimePickerField(String key, String currentValue) {
    return GestureDetector(
      onTap: () async {
        final timeParts = currentValue.split(':');
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
            _currentSlots[key] = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
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
                Expanded(
                  child: Text(
                    currentValue.isNotEmpty ? currentValue : '选择时间',
                    style: TextStyle(
                      fontSize: 13,
                      color: currentValue.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                  ),
                ),
                const Icon(AppIcons.chevronDown, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelectorField(String key, String currentValue) {
    final level = currentValue.toLowerCase() == 'true' ? '必做' : currentValue.toLowerCase() == 'important' ? '重要' : '普通';
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['普通', '重要', '必做'].map((lvl) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(lvl, style: TextStyle(fontSize: 14)),
                    trailing: lvl == level ? const Icon(Icons.check, color: AppColors.accent) : null,
                    onTap: () {
                      setState(() {
                        _currentSlots[key] = lvl == '必做' ? 'true' : lvl == '重要' ? 'important' : 'false';
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        );
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
            const Icon(AppIcons.tag, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    level,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                const Icon(AppIcons.chevronDown, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOffsetField(String key, String currentValue) {
    final offset = int.tryParse(currentValue) ?? 0;
    final options = [
      {'label': '今天', 'value': 0},
      {'label': '明天', 'value': 1},
      {'label': '后天', 'value': 2},
      {'label': '大后天', 'value': 3},
    ];
    final currentLabel = options.firstWhere((o) => o['value'] == offset, orElse: () => options[0])['label'] as String;
    
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((opt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(opt['label'] as String, style: TextStyle(fontSize: 14)),
                    trailing: opt['value'] == offset ? const Icon(Icons.check, color: AppColors.accent) : null,
                    onTap: () {
                      setState(() {
                        _currentSlots[key] = '${opt['value']}';
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        );
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
                Expanded(
                  child: Text(
                    currentLabel,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                const Icon(AppIcons.chevronDown, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  String _getSlotSectionTitle(IntentType type) {
    switch (type) {
      case IntentType.itemLocation:
        return '物品信息';
      case IntentType.shopping:
        return '购物信息';
      case IntentType.agendaCreate:
        return '事程信息';
      case IntentType.inventoryConsume:
        return '消耗信息';
      case IntentType.behavior:
        return '行为信息';
      default:
        return '详细信息';
    }
  }

  String _getSlotHint(String key) {
    switch (key) {
      case 'item_name':
        return '例如：钥匙、牛奶';
      case 'location':
        return '例如：门口鞋柜、冰箱';
      case 'store':
        return '例如：超市、便利店';
      case 'items_text':
        return '例如：苹果2斤，牛奶3瓶';
      case 'content':
        return '例如：吃药、买菜';
      case 'is_must_do':
        return 'true 或 false';
      case 'quantity':
        return '例如：2、3';
      case 'unit':
        return '例如：个、斤、瓶';
      case 'keyword':
        return '例如：吃药、吃饭';
      case 'category':
        return '例如：健康、饮食';
      default:
        return '';
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    if (timeStr.isEmpty) return TimeOfDay.now();
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return TimeOfDay.now();
  }

  void _addSlot() {
    final time = _timeCtrl.text.trim();
    final existingSlotIdx = _slots.indexWhere((s) => s.time == time);

    if (existingSlotIdx >= 0) {
      final existingIntents = List<IntentItem>.from(_slots[existingSlotIdx].intents);
      existingIntents.add(IntentItem(
        type: _selectedIntent,
        slots: Map<String, dynamic>.from(_currentSlots),
        confidence: 0.95,
      ));
      _slots[existingSlotIdx] = TimelineSlot(
        time: _slots[existingSlotIdx].time,
        intents: existingIntents,
      );
    } else {
      _slots.add(TimelineSlot(
        time: time,
        intents: [
          IntentItem(
            type: _selectedIntent,
            slots: Map<String, dynamic>.from(_currentSlots),
            confidence: 0.95,
          ),
        ],
      ));
    }

    _currentSlots.clear();
    _slotKeyCtrl.clear();
    _slotValueCtrl.clear();
    setState(() {});
  }

  void _removeSlot(int idx) {
    _slots.removeAt(idx);
    setState(() {});
  }

  void _addSlotValue() {
    if (_slotKeyCtrl.text.trim().isNotEmpty && _slotValueCtrl.text.trim().isNotEmpty) {
      _currentSlots[_slotKeyCtrl.text.trim()] = _slotValueCtrl.text.trim();
      _slotKeyCtrl.clear();
      _slotValueCtrl.clear();
      setState(() {});
    }
  }

  void _removeSlotValue(String key) {
    _currentSlots.remove(key);
    setState(() {});
  }

  void _submit() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入文本'), duration: Duration(seconds: 1)),
      );
      return;
    }
    if (_slots.isEmpty) {
      _slots.add(TimelineSlot(
        time: '',
        intents: [
          IntentItem(
            type: _selectedIntent,
            slots: Map<String, dynamic>.from(_currentSlots),
            confidence: 0.95,
          ),
        ],
      ));
    }
    await widget.onSave(text, List.from(_slots));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
              child: Row(
                children: [
                  Icon(AppIcons.brain, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEdit ? '编辑训练模式' : '添加训练模式',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(AppIcons.x, size: 18, color: AppColors.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text('输入文本', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textCtrl,
                      decoration: InputDecoration(
                        hintText: '例如：8点吃的药，9点吃的早饭',
                        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.bgTertiary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    const Text('时间槽（一个时间点可以有多个意图）',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    if (_slots.isNotEmpty)
                      ..._slots.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final slot = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        onChanged: (v) {
                                          _slots[idx] = TimelineSlot(
                                            time: v.trim(),
                                            intents: slot.intents,
                                          );
                                        },
                                        decoration: InputDecoration(
                                          hintText: '时间 HH:MM',
                                          hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                                          filled: true,
                                          fillColor: AppColors.bgPrimary,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        controller: TextEditingController(text: slot.time)..selection = TextSelection.collapsed(offset: slot.time.length),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButtonFormField<IntentType>(
                                        value: slot.intents.isNotEmpty ? slot.intents.first.type : IntentType.behavior,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: AppColors.bgPrimary,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        ),
                                        items: IntentType.values.map((type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(_intentDisplayName(type), style: const TextStyle(fontSize: 13)),
                                            )).toList(),
                                        onChanged: (v) {
                                          if (v != null && slot.intents.isNotEmpty) {
                                            final newIntents = slot.intents.map((i) => IntentItem(
                                                  type: v,
                                                  slots: i.slots,
                                                  confidence: i.confidence,
                                                )).toList();
                                            _slots[idx] = TimelineSlot(
                                              time: slot.time,
                                              intents: newIntents,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _removeSlot(idx),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.danger.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(AppIcons.trash2, size: 14, color: AppColors.danger),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (slot.intents.isNotEmpty && slot.intents.first.slots.isNotEmpty)
                                  ...slot.intents.first.slots.entries.map((e) {
                                    final intentType = slot.intents.first.type;
                                    final slotLabels = _getSlotLabels(intentType);
                                    final label = slotLabels[e.key] ?? e.key;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: AppColors.bgPrimary,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text('$label: ${e.value}',
                                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              final newSlots = Map<String, dynamic>.from(slot.intents.first.slots);
                                              newSlots.remove(e.key);
                                              final newIntents = slot.intents.map((i) => IntentItem(
                                                    type: i.type,
                                                    slots: newSlots,
                                                    confidence: i.confidence,
                                                  )).toList();
                                              _slots[idx] = TimelineSlot(
                                                time: slot.time,
                                                intents: newIntents,
                                              );
                                            },
                                            child: const Icon(AppIcons.x, size: 16, color: AppColors.textTertiary),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              final selectedTime = await showTimePicker(
                                context: context,
                                initialTime: _parseTime(_timeCtrl.text),
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
                                  _timeCtrl.text = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.bgTertiary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(AppIcons.clock, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    _timeCtrl.text.isNotEmpty ? _timeCtrl.text : '选择时间',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _timeCtrl.text.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<IntentType>(
                            value: _selectedIntent,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.bgTertiary,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            ),
                            items: IntentType.values.map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(_intentDisplayName(type), style: const TextStyle(fontSize: 13)),
                                )).toList(),
                            onChanged: (v) => setState(() => _selectedIntent = v!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _addSlot,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(AppIcons.plus, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSlotFields(),
                    const SizedBox(height: 8),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('取消', style: TextStyle(color: AppColors.textTertiary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isEdit ? '保存' : '添加',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
