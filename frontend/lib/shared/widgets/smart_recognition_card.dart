import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_store.dart';

/// 通用智能识别结果卡片
/// 根据记录类型展示不同的意图识别结构化信息
/// 支持编辑和重新识别功能
class SmartRecognitionCard extends StatefulWidget {
  final TimelineRecord record;

  const SmartRecognitionCard({
    super.key,
    required this.record,
  });

  @override
  State<SmartRecognitionCard> createState() => _SmartRecognitionCardState();
}

class _SmartRecognitionCardState extends State<SmartRecognitionCard> {
  bool _isEditing = false;
  late Map<String, dynamic> _editableSlots;

  @override
  void initState() {
    super.initState();
    _editableSlots = Map<String, dynamic>.from(widget.record.sideEffects?.intentData?.slots ?? {});
  }

  @override
  Widget build(BuildContext context) {
    final tagCount = widget.record.tags.length;

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
          // 标题栏
          Row(
            children: [
              const Icon(AppIcons.brain, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                '智能识别结果（${tagCount}个标签）',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _buildActionButtons(),
            ],
          ),
          const SizedBox(height: 12),
          // 识别结果内容
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 意图类型标签
                _buildTypeBadge(),
                const SizedBox(height: 14),
                // 根据类型展示不同的识别结果
                if (_isEditing)
                  _buildEditableDetails()
                else
                  ..._buildRecognitionDetails(),
                const SizedBox(height: 12),
                // 分割线
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),
                // 操作按钮或自动保存提示
                if (_isEditing) _buildEditActions() else _buildSaveHint(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (!_isEditing) ...[
          GestureDetector(
            onTap: () => setState(() {
              _isEditing = true;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.edit2, size: 12, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text('编辑', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _reRecognize,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.refreshCw, size: 12, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text('重新识别', style: TextStyle(fontSize: 12, color: AppColors.info)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditableDetails() {
    final intentData = widget.record.sideEffects?.intentData;
    final slots = _editableSlots;

    switch (intentData?.intentType) {
      case 'shopping':
        return _buildEditableShoppingDetails();
      case 'item_location':
        return Column(
          children: [
            _buildEditableRow('物品名称', 'item_name', slots['item_name']?.toString() ?? ''),
            const SizedBox(height: 8),
            _buildEditableRow('存放位置', 'location', slots['location']?.toString() ?? ''),
          ],
        );
      case 'inventory_consume':
        return Column(
          children: [
            _buildEditableRow('物品名称', 'item_name', slots['item_name']?.toString() ?? ''),
            const SizedBox(height: 8),
            _buildEditableRow('消耗数量', 'quantity', slots['quantity']?.toString() ?? ''),
            const SizedBox(height: 8),
            _buildEditableRow('单位', 'unit', slots['unit']?.toString() ?? ''),
          ],
        );
      case 'agenda_create':
        return Column(
          children: [
            _buildEditableRow('事程内容', 'content', slots['content']?.toString() ?? ''),
            const SizedBox(height: 8),
            _buildEditableRow('计划时间', 'time', slots['time']?.toString() ?? ''),
          ],
        );
      case 'behavior':
      default:
        return Column(
          children: [
            _buildEditableRow('行为名称', 'keyword', slots['keyword']?.toString() ?? widget.record.content),
            const SizedBox(height: 8),
            _buildEditableRow('行为分类', 'category', slots['category']?.toString() ?? '其他'),
          ],
        );
    }
  }

  Widget _buildEditableShoppingDetails() {
    final shoppingRecord = widget.record.sideEffects?.shoppingRecord;
    final widgets = <Widget>[
      _buildEditableRow('购买地点', 'store', shoppingRecord?.store ?? ''),
    ];

    if (shoppingRecord != null && shoppingRecord.items.isNotEmpty) {
      widgets.add(const SizedBox(height: 10));
      widgets.add(const Text(
        '购买清单',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ));
      widgets.add(const SizedBox(height: 6));
      for (final item in shoppingRecord.items) {
        widgets.add(_buildItemRow(item));
      }
    }

    return Column(children: widgets);
  }

  Widget _buildEditableRow(String label, String key, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            onChanged: (v) => _editableSlots[key] = v,
            decoration: InputDecoration(
              hintText: '请输入$label',
              isDense: true,
              filled: true,
              fillColor: AppColors.bgSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            controller: TextEditingController(text: value),
          ),
        ),
      ],
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() => _isEditing = false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('取消', style: TextStyle(color: AppColors.textTertiary)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveEdit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('保存修改', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveHint() {
    return Row(
      children: [
        Icon(AppIcons.checkCircle, size: 14, color: AppColors.success),
        const SizedBox(width: 6),
        Text(
          _getSaveHint(),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.success,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _saveEdit() {
    final store = context.read<AppStore>();
    store.updateRecordIntentData(widget.record.id, _editableSlots);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('识别结果已更新'), duration: Duration(seconds: 1)),
    );
  }

  void _reRecognize() {
    final store = context.read<AppStore>();
    store.reRecognizeRecord(widget.record.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在重新识别...'), duration: Duration(seconds: 1)),
    );
  }

  Widget _buildTypeBadge() {
    final (label, color, icon) = _getTypeInfo();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _getTypeInfo() {
    final intentData = widget.record.sideEffects?.intentData;
    switch (intentData?.intentType) {
      case 'shopping':
        return ('购物记录', AppColors.warning, AppIcons.shoppingCart);
      case 'item_location':
        return ('物品位置', AppColors.info, AppIcons.package);
      case 'inventory_consume':
        return ('库存消耗', Colors.teal, AppIcons.droplet);
      case 'agenda_create':
        return ('创建事程', AppColors.info, AppIcons.calendar);
      case 'behavior':
      default:
        return ('行为活动', AppColors.accent, AppIcons.activity);
    }
  }

  List<Widget> _buildRecognitionDetails() {
    final intentData = widget.record.sideEffects?.intentData;
    final slots = intentData?.slots ?? {};

    switch (intentData?.intentType) {
      case 'shopping':
        return _buildShoppingDetails();
      case 'item_location':
        return [
          _buildKeyValueRow('物品名称', slots['item_name']?.toString() ?? ''),
          const SizedBox(height: 8),
          _buildKeyValueRow('存放位置', slots['location']?.toString() ?? ''),
        ];
      case 'inventory_consume':
        return [
          _buildKeyValueRow('物品名称', slots['item_name']?.toString() ?? ''),
          const SizedBox(height: 8),
          _buildKeyValueRow('消耗数量', '${slots['quantity'] ?? ''} ${slots['unit'] ?? '个'}'),
        ];
      case 'agenda_create':
        return [
          _buildKeyValueRow('事程内容', slots['content']?.toString() ?? ''),
          const SizedBox(height: 8),
          _buildKeyValueRow('计划时间', slots['time']?.toString() ?? ''),
        ];
      case 'behavior':
      default:
        return [
          _buildKeyValueRow('行为名称', slots['keyword']?.toString() ?? widget.record.content),
          const SizedBox(height: 8),
          _buildKeyValueRow('行为分类', slots['category']?.toString() ?? '其他'),
        ];
    }
  }

  List<Widget> _buildShoppingDetails() {
    final shoppingRecord = widget.record.sideEffects?.shoppingRecord;
    final widgets = <Widget>[
      _buildKeyValueRow('购买地点', shoppingRecord?.store ?? ''),
    ];

    if (shoppingRecord != null && shoppingRecord.items.isNotEmpty) {
      widgets.add(const SizedBox(height: 10));
      widgets.add(const Text(
        '购买清单',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ));
      widgets.add(const SizedBox(height: 6));
      for (final item in shoppingRecord.items) {
        widgets.add(_buildItemRow(item));
      }
    }

    return widgets;
  }

  Widget _buildKeyValueRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(ShoppingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${item.quantity}${item.unit}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getSaveHint() {
    final intentType = widget.record.sideEffects?.intentData?.intentType;
    switch (intentType) {
      case 'shopping':
        return '已自动保存到购物记录';
      case 'item_location':
        return '已自动保存到物品位置';
      case 'inventory_consume':
        return '已自动更新库存';
      case 'agenda_create':
        return '已自动创建事程';
      case 'behavior':
      default:
        return '已自动保存到行为记录';
    }
  }
}
