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
        return AppColors.accent;
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

class _SplitPart {
  final String text;
  final String type; // action, location, item, other

  const _SplitPart({required this.text, required this.type});
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
  List<_SplitPart> _splitParts = [];
  IntentType _selectedIntent = IntentType.behavior;
  bool _isSubmitting = false;
  int? _editingSlotIdx;

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
      
      // 初始化当前槽值
      if (_slots.isNotEmpty && _slots.first.intents.isNotEmpty) {
        final firstIntent = _slots.first.intents.first;
        _selectedIntent = firstIntent.type;
        _currentSlots.addAll(Map<String, dynamic>.from(firstIntent.slots));
        
        // 处理旧数据转换：items_text -> items
        if (_currentSlots.containsKey('items_text') && !_currentSlots.containsKey('items')) {
          final itemsText = _currentSlots['items_text'] as String? ?? '';
          if (itemsText.isNotEmpty) {
            final items = _parseItemsFromText(itemsText);
            if (items.isNotEmpty) {
              _currentSlots['items'] = items;
            }
          }
        }
      }
    }
  }

  List<Map<String, dynamic>> _parseItemsFromText(String text) {
    final items = <Map<String, dynamic>>[];
    final itemRegex = RegExp(
      r'(\d+(?:\.\d+)?)\s*(片|粒|盒|瓶|个|包|袋|支|颗|毫升|克|斤|公斤|箱|条|把)\s*([\u4e00-\u9fa5A-Za-z]{2,10})',
    );
    for (final m in itemRegex.allMatches(text)) {
      items.add({
        'name': m.group(3)!,
        'quantity': double.parse(m.group(1)!),
        'unit': m.group(2)!,
      });
    }
    return items;
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
        return AppColors.accent;
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
          'items': '购买物品',
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
          'quantity': '数量',
          'unit': '单位',
          'direction': '库存方向',
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
        return ['store', 'items'];
      case IntentType.agendaCreate:
        return ['content', 'time', 'date_offset', 'is_must_do'];
      case IntentType.inventoryConsume:
        return ['direction', 'item_name', 'quantity', 'unit'];
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
        _buildTextSplitField(),
        const SizedBox(height: 12),
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
                else if (key == 'items')
                  _buildShoppingItemsField()
                else if (key == 'direction')
                  _buildDirectionSelectorField(key, currentValue)
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

  Widget _buildTextSplitField() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_splitParts.isEmpty) {
      _splitParts = _splitText(text);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('文本拆分', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _splitParts = _splitText(text);
                setState(() {});
              },
              child: Text('自动拆分', style: TextStyle(fontSize: 12, color: AppColors.accent)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 4,
                children: _splitParts.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final part = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPartBackgroundColor(part.type),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _getPartBorderColor(part.type)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          part.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: _getPartTextColor(part.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        DropdownButton<String>(
                          value: part.type,
                          items: const [
                            DropdownMenuItem(value: 'action', child: Text('动作')),
                            DropdownMenuItem(value: 'location', child: Text('地点')),
                            DropdownMenuItem(value: 'item', child: Text('物品')),
                            DropdownMenuItem(value: 'consume', child: Text('消耗')),
                            DropdownMenuItem(value: 'increase', child: Text('补充')),
                            DropdownMenuItem(value: 'other', child: Text('其他')),
                          ],
                          onChanged: (v) {
                            _splitParts[idx] = _SplitPart(text: part.text, type: v!);
                            setState(() {});
                          },
                          underline: const SizedBox.shrink(),
                          style: TextStyle(fontSize: 12, color: _getPartTextColor(part.type)),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            _splitParts.removeAt(idx);
                            setState(() {});
                          },
                          child: Icon(AppIcons.x, size: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _splitParts.add(const _SplitPart(text: '', type: 'other'));
                    setState(() {});
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppIcons.plus, size: 12, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text('添加拆分块', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text('紫色=地点，蓝色=动作，绿色=物品，红色=消耗，绿色=补充', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }

  Color _getPartTextColor(String type) {
    switch (type) {
      case 'action':
        return AppColors.accent;
      case 'location':
        return AppColors.purple;
      case 'item':
        return AppColors.success;
      case 'consume':
        return AppColors.danger;
      case 'increase':
        return AppColors.success;
      default:
        return AppColors.textPrimary;
    }
  }

  Color _getPartBackgroundColor(String type) {
    switch (type) {
      case 'action':
        return AppColors.accentLight;
      case 'location':
        return AppColors.purpleLight;
      case 'item':
        return AppColors.successLight;
      case 'consume':
        return AppColors.dangerLight;
      case 'increase':
        return AppColors.successLight;
      default:
        return AppColors.bgPrimary;
    }
  }

  Color _getPartBorderColor(String type) {
    switch (type) {
      case 'action':
        return AppColors.accent.withOpacity(0.3);
      case 'location':
        return AppColors.purple.withOpacity(0.3);
      case 'item':
        return AppColors.success.withOpacity(0.3);
      case 'consume':
        return AppColors.danger.withOpacity(0.3);
      case 'increase':
        return AppColors.success.withOpacity(0.3);
      default:
        return AppColors.border;
    }
  }

  List<_SplitPart> _splitText(String text) {
    final parts = <_SplitPart>[];
    // 消耗类动词
    final consumeWords = ['吃了', '吃', '喝了', '喝', '服用了', '服用', '服了', '服', '用了', '用', '消耗了', '消耗', '使用了', '使用'];
    // 增加类动词
    final increaseWords = ['买了', '买', '购买了', '购买', '采购了', '采购', '补充了', '补充', '入库了', '入库'];
    // 其他动作
    final otherActionWords = ['去', '刚去', '到', '逛了', '逛', '拿了', '拿', '放了', '放'];
    final locationWords = ['超市', '商店', '便利店', '菜市场', '医院', '药店', '商场', '公园', '家里', '公司', '学校', '小区', '社区'];

    String remaining = text;
    while (remaining.isNotEmpty) {
      bool matched = false;

      // 优先匹配消耗类动词（带"消耗"标记）
      for (final word in consumeWords) {
        if (remaining.startsWith(word)) {
          parts.add(_SplitPart(text: word, type: 'consume'));
          remaining = remaining.substring(word.length);
          matched = true;
          break;
        }
      }
      if (matched) continue;

      // 匹配增加类动词（带"增加"标记）
      for (final word in increaseWords) {
        if (remaining.startsWith(word)) {
          parts.add(_SplitPart(text: word, type: 'increase'));
          remaining = remaining.substring(word.length);
          matched = true;
          break;
        }
      }
      if (matched) continue;

      // 其他动作
      for (final word in otherActionWords) {
        if (remaining.startsWith(word)) {
          parts.add(_SplitPart(text: word, type: 'action'));
          remaining = remaining.substring(word.length);
          matched = true;
          break;
        }
      }
      if (matched) continue;

      for (final word in locationWords) {
        if (remaining.startsWith(word)) {
          parts.add(_SplitPart(text: word, type: 'location'));
          remaining = remaining.substring(word.length);
          matched = true;
          break;
        }
      }
      if (matched) continue;

      // 匹配 数量+单位+物品名
      final itemMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(片|粒|盒|瓶|个|包|袋|支|颗|毫升|克|斤|公斤|箱|条|把|贴|滴)\s*([\u4e00-\u9fa5A-Za-z]{2,10})').firstMatch(remaining);
      if (itemMatch != null) {
        parts.add(_SplitPart(text: '${itemMatch.group(1)}${itemMatch.group(2)}${itemMatch.group(3)}', type: 'item'));
        remaining = remaining.substring(itemMatch.end);
        matched = true;
        continue;
      }

      // 匹配 物品名+数量+单位
      final itemMatch2 = RegExp(r'([\u4e00-\u9fa5A-Za-z]{2,10})\s*(\d+(?:\.\d+)?)\s*(片|粒|盒|瓶|个|包|袋|支|颗|毫升|克|斤|公斤|箱|条|把|贴|滴)').firstMatch(remaining);
      if (itemMatch2 != null) {
        parts.add(_SplitPart(text: '${itemMatch2.group(1)}${itemMatch2.group(2)}${itemMatch2.group(3)}', type: 'item'));
        remaining = remaining.substring(itemMatch2.end);
        matched = true;
        continue;
      }

      parts.add(_SplitPart(text: remaining[0], type: 'other'));
      remaining = remaining.substring(1);
    }

    return parts;
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
        return '详情信息';
    }
  }

  Widget _buildShoppingItemsField() {
    final items = _currentSlots['items'] is List 
        ? (_currentSlots['items'] as List).map((i) => Map<String, dynamic>.from(i as Map)).toList()
        : [];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '点击下方按钮添加购买物品',
                style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          onChanged: (v) {
                            items[idx]['name'] = v.trim();
                            _currentSlots['items'] = items;
                          },
                          decoration: InputDecoration(
                            hintText: '物品名称',
                            hintStyle: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          controller: TextEditingController(text: (item['name'] as String?) ?? ''),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          onChanged: (v) {
                            items[idx]['quantity'] = double.tryParse(v) ?? 1;
                            _currentSlots['items'] = items;
                          },
                          decoration: InputDecoration(
                            hintText: '数量',
                            hintStyle: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: (item['quantity'] as num?)?.toString() ?? '1'),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 45,
                        child: TextField(
                          onChanged: (v) {
                            items[idx]['unit'] = v.trim();
                            _currentSlots['items'] = items;
                          },
                          decoration: InputDecoration(
                            hintText: '单位',
                            hintStyle: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          controller: TextEditingController(text: (item['unit'] as String?) ?? '个'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          items.removeAt(idx);
                          _currentSlots['items'] = items;
                          setState(() {});
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(AppIcons.x, size: 14, color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                final newItems = items.isNotEmpty ? List.from(items) : [];
                newItems.add({'name': '', 'quantity': 1, 'unit': '个'});
                _currentSlots['items'] = newItems;
                setState(() {});
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.plus, size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text('添加商品', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                ],
              ),
            ),
          ),
        ],
      ),
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

  /// 库存方向选择器（消耗/增加）
  Widget _buildDirectionSelectorField(String key, String currentValue) {
    final direction = currentValue == 'increase' ? '增加' : currentValue == 'consume' ? '消耗' : '请选择';
    final consumeKeywords = ['吃', '喝', '服', '用', '服用', '消耗', '使用'];
    final increaseKeywords = ['买', '购买', '采购', '补充', '入库'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (ctx) => Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('选择库存方向', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    // 消耗选项
                    _buildDirectionOption(
                      ctx: ctx,
                      value: 'consume',
                      label: '消耗（减少库存）',
                      icon: AppIcons.minus,
                      color: AppColors.danger,
                      keywords: consumeKeywords,
                      isSelected: currentValue == 'consume',
                      onTap: () {
                        setState(() {
                          _currentSlots[key] = 'consume';
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 8),
                    // 增加选项
                    _buildDirectionOption(
                      ctx: ctx,
                      value: 'increase',
                      label: '补充（增加库存）',
                      icon: AppIcons.plus,
                      color: AppColors.success,
                      keywords: increaseKeywords,
                      isSelected: currentValue == 'increase',
                      onTap: () {
                        setState(() {
                          _currentSlots[key] = 'increase';
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
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
                Icon(
                  currentValue == 'increase' ? AppIcons.plus : AppIcons.minus,
                  size: 16,
                  color: currentValue == 'increase' ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    direction,
                    style: TextStyle(
                      fontSize: 13,
                      color: currentValue.isNotEmpty && currentValue != '请选择'
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                const Icon(AppIcons.chevronDown, size: 16, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 显示当前方向的关键词参考
        if (currentValue == 'consume' || currentValue == 'increase')
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (currentValue == 'consume' ? AppColors.danger : AppColors.success).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (currentValue == 'consume' ? AppColors.danger : AppColors.success).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentValue == 'consume' ? '消耗关键词（库存减少）' : '补充关键词（库存增加）',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: currentValue == 'consume' ? AppColors.danger : AppColors.success,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: (currentValue == 'consume' ? consumeKeywords : increaseKeywords).map((kw) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: (currentValue == 'consume' ? AppColors.danger : AppColors.success).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        kw,
                        style: TextStyle(
                          fontSize: 11,
                          color: currentValue == 'consume' ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDirectionOption({
    required BuildContext ctx,
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required List<String> keywords,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color.withOpacity(0.3) : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                ),
                if (isSelected) Icon(Icons.check, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: keywords.map((kw) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(kw, style: TextStyle(fontSize: 10, color: color)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
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
    final newIntent = IntentItem(
      type: _selectedIntent,
      slots: Map<String, dynamic>.from(_currentSlots),
      confidence: 0.95,
    );

    final existingSlotIdx = _slots.indexWhere((s) => s.time == time);
    int newSlotIdx;

    if (existingSlotIdx >= 0) {
      final existingIntents = List<IntentItem>.from(_slots[existingSlotIdx].intents);
      existingIntents.add(newIntent);
      _slots[existingSlotIdx] = TimelineSlot(
        time: _slots[existingSlotIdx].time,
        intents: existingIntents,
      );
      newSlotIdx = existingSlotIdx;
    } else {
      _slots.add(TimelineSlot(
        time: time,
        intents: [newIntent],
      ));
      newSlotIdx = _slots.length - 1;
    }

    _currentSlots.clear();
    _slotKeyCtrl.clear();
    _slotValueCtrl.clear();
    setState(() {
      _editingSlotIdx = newSlotIdx;
    });
  }

  void _removeSlot(int idx) {
    _slots.removeAt(idx);
    if (_editingSlotIdx == idx) {
      _editingSlotIdx = null;
      _currentSlots.clear();
    } else if (_editingSlotIdx != null && _editingSlotIdx! > idx) {
      _editingSlotIdx = _editingSlotIdx! - 1;
    }
    setState(() {});
  }

  Future<void> _smartRecognize() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入文本'), duration: Duration(seconds: 1)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final store = context.read<AppStore>();
      final intentService = store.intentService;
      if (intentService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('意图服务未初始化'), duration: Duration(seconds: 1)),
        );
        return;
      }

      final result = await intentService.recognize(text);
      if (result.timelineSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未识别到意图，请手动添加'), duration: Duration(seconds: 1)),
        );
        return;
      }

      final now = DateTime.now();
      final currentTimeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      _slots.clear();
      for (final slot in result.timelineSlots) {
        _slots.add(TimelineSlot(
          time: slot.time.isEmpty ? currentTimeStr : slot.time,
          intents: slot.intents,
        ));
      }
      _currentSlots.clear();

      if (_slots.isNotEmpty && _slots.first.intents.isNotEmpty) {
        final firstIntent = _slots.first.intents.first;
        _selectedIntent = firstIntent.type;
        _currentSlots.addAll(Map<String, dynamic>.from(firstIntent.slots));

        // inventoryConsume 自动判断方向
        if (_selectedIntent == IntentType.inventoryConsume && !_currentSlots.containsKey('direction')) {
          _currentSlots['direction'] = _detectDirection(text);
        }

        _timeCtrl.text = _slots.first.time.isEmpty ? currentTimeStr : _slots.first.time;
        _editingSlotIdx = 0;
      } else {
        _timeCtrl.text = currentTimeStr;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('识别成功，来源：${result.source}'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      debugPrint('智能识别失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('识别失败，请手动添加'), duration: Duration(seconds: 1)),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  /// 根据文本自动判断库存方向（消耗/补充）
  /// 优先匹配带时态助词的动词形式（吃了/买了），再退化为单字动词
  String _detectDirection(String text) {
    // 消耗类关键词（库存减少）- 按长度降序，优先匹配更具体的动词
    const consumeKeywords = [
      '服用了', '使用了', '消耗了', '吃了', '喝了', '服了', '用了',
      '服用', '使用', '消耗', '吃', '喝', '服', '用',
    ];
    // 增加类关键词（库存增加）
    const increaseKeywords = [
      '购买了', '采购了', '补充了', '入库了', '买了',
      '购买', '采购', '补充', '入库', '买',
    ];

    // 优先检测增加类（避免"买"被"买药吃"误判为消耗）
    for (final kw in increaseKeywords) {
      if (text.contains(kw)) return 'increase';
    }
    for (final kw in consumeKeywords) {
      if (text.contains(kw)) return 'consume';
    }
    return 'consume'; // 默认按消耗处理
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
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final text = _textCtrl.text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入文本'), duration: Duration(seconds: 1)),
        );
        return;
      }
      
      // 如果正在编辑某个 slot，先保存当前修改
      if (_editingSlotIdx != null && _editingSlotIdx! < _slots.length) {
        final idx = _editingSlotIdx!;
        final slot = _slots[idx];
        
        // 生成 items_text 向后兼容
        if (_selectedIntent == IntentType.shopping && _currentSlots['items'] is List) {
          final items = _currentSlots['items'] as List;
          final itemsText = items.map((i) {
            final item = i as Map<String, dynamic>;
            return '${item['quantity']}${item['unit']}${item['name']}';
          }).join('、');
          _currentSlots['items_text'] = itemsText;
        }
        
        final newIntents = slot.intents.map((intent) {
          return IntentItem(
            type: _selectedIntent,
            slots: Map<String, dynamic>.from(_currentSlots),
            confidence: intent.confidence,
          );
        }).toList();
        _slots[idx] = TimelineSlot(
          time: _timeCtrl.text.trim(),
          intents: newIntents,
        );
      }
      
      if (_slots.isEmpty) {
        // 如果有 items 数组，生成 items_text 作为向后兼容
        if (_selectedIntent == IntentType.shopping && _currentSlots['items'] is List) {
          final items = _currentSlots['items'] as List;
          final itemsText = items.map((i) {
            final item = i as Map<String, dynamic>;
            return '${item['quantity']}${item['unit']}${item['name']}';
          }).join('、');
          _currentSlots['items_text'] = itemsText;
        }
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
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSectionTitle(String title, IconData icon, String subtitle) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: AppColors.accent),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildResultCards() {
    if (_slots.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: Column(
            children: [
              Icon(AppIcons.list, size: 24, color: AppColors.textTertiary),
              const SizedBox(height: 8),
              Text('暂无识别结果，点击下方按钮添加', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
        ),
      ];
    }
    return _slots.asMap().entries.map((entry) {
      final idx = entry.key;
      final slot = entry.value;
      final intent = slot.intents.isNotEmpty ? slot.intents.first : null;
      final intentType = intent?.type ?? IntentType.behavior;
      final color = _intentColor(intentType);
      final isSelected = _editingSlotIdx == idx;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            if (isSelected) {
              setState(() => _editingSlotIdx = null);
            } else {
              _currentSlots.clear();
              if (intent != null) {
                _currentSlots.addAll(Map<String, dynamic>.from(intent.slots));
              }
              _selectedIntent = intentType;
              _timeCtrl.text = slot.time;
              setState(() => _editingSlotIdx = idx);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.08) : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 1.5 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 时间
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.clock, size: 13, color: color),
                          const SizedBox(width: 4),
                          Text(
                            slot.time.isEmpty ? '自动' : slot.time,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 意图类型标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgPrimary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        _intentDisplayName(intentType),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                    const Spacer(),
                    // 删除按钮
                    GestureDetector(
                      onTap: () => _removeSlot(idx),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(AppIcons.trash2, size: 14, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 槽值摘要
                if (intent != null && intent.slots.isNotEmpty)
                  _buildSlotSummary(intent, color),
                if (isSelected) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(AppIcons.edit3, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        '正在编辑，可在下方修改详情',
                        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSlotSummary(IntentItem intent, Color color) {
    final summary = _getIntentSummary(intent);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: summary.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.key, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 4),
              Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, String> _getIntentSummary(IntentItem intent) {
    final slots = intent.slots;
    switch (intent.type) {
      case IntentType.behavior:
        return {'行为': slots['keyword']?.toString() ?? '未设置'};
      case IntentType.shopping:
        final items = slots['items'] is List 
            ? (slots['items'] as List).map((i) => '${(i as Map)['quantity']}${(i as Map)['unit']}${(i as Map)['name']}').join('、')
            : (slots['items_text']?.toString() ?? '');
        return {'商店': slots['store']?.toString() ?? '未设置', '商品': items.isEmpty ? '未设置' : items};
      case IntentType.inventoryConsume:
        return {
          '物品': slots['item_name']?.toString() ?? '未设置',
          '数量': '${slots['quantity']?.toString() ?? '1'}${slots['unit']?.toString() ?? '个'}',
        };
      case IntentType.itemLocation:
        return {
          '物品': slots['item_name']?.toString() ?? '未设置',
          '位置': slots['location']?.toString() ?? '未设置',
        };
      case IntentType.agendaCreate:
        return {
          '事程': slots['content']?.toString() ?? '未设置',
          '级别': (slots['is_must_do'] == true) ? '必做' : '普通',
        };
      case IntentType.agendaComplete:
        return {'完成': slots['keyword']?.toString() ?? '未设置'};
      case IntentType.general:
        return {'内容': slots['content']?.toString() ?? '未设置'};
    }
  }

  Widget _buildAddResultButton() {
    return Row(
      children: [
        Expanded(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.clock, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _timeCtrl.text.isNotEmpty ? _timeCtrl.text : '选择时间',
                    style: TextStyle(
                      fontSize: 13,
                      color: _timeCtrl.text.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary,
                      fontWeight: _timeCtrl.text.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonFormField<IntentType>(
              value: _selectedIntent,
              decoration: InputDecoration(
                filled: false,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              ),
              items: IntentType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(_intentDisplayName(type), style: const TextStyle(fontSize: 13)),
                  )).toList(),
              onChanged: (v) => setState(() => _selectedIntent = v!),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _addSlot,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(AppIcons.plus, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final pattern = widget.pattern!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('${pattern.count}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accent)),
                const SizedBox(height: 2),
                const Text('使用次数', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.border),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${pattern.lastUsed.month}/${pattern.lastUsed.day}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.info),
                ),
                const SizedBox(height: 2),
                const Text('最后使用', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.border),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${(_slots.length)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.success),
                ),
                const SizedBox(height: 2),
                const Text('意图数', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(AppIcons.brain, size: 18, color: AppColors.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEdit ? '编辑训练模式' : '添加训练模式',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(AppIcons.x, size: 16, color: AppColors.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 输入文本
                    _buildSectionTitle('输入文本', AppIcons.messageSquare, '语音输入的原始内容'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textCtrl,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: '例如：刚去超市买了8个苹果，6个梨',
                                hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _smartRecognize,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(AppIcons.sparkles, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  const Text('智能识别', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. 识别结果（时间槽 + 意图）
                    _buildSectionTitle('识别结果', AppIcons.zap, '匹配到的时间和意图信息'),
                    const SizedBox(height: 8),
                    ..._buildResultCards(),
                    const SizedBox(height: 10),
                    _buildAddResultButton(),
                    const SizedBox(height: 16),

                    // 3. 当前编辑的意图详情
                    if (_editingSlotIdx != null) ...[
                      _buildSectionTitle('编辑意图详情', AppIcons.edit3, '修改当前选中的意图信息'),
                      const SizedBox(height: 8),
                      _buildSlotFields(),
                      const SizedBox(height: 16),
                    ],

                    // 4. 使用统计（编辑模式才显示）
                    if (isEdit && widget.pattern != null) ...[
                      _buildSectionTitle('使用统计', AppIcons.barChart2, '该模式的使用情况'),
                      const SizedBox(height: 8),
                      _buildStatsRow(),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: _isSubmitting ? AppColors.accent.withOpacity(0.6) : AppColors.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              isEdit ? '保存修改' : '添加模式',
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
