import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/models/app_models.dart';

class InventoryDetailPage extends StatefulWidget {
  const InventoryDetailPage({super.key});

  @override
  State<InventoryDetailPage> createState() => _InventoryDetailPageState();
}

class _InventoryDetailPageState extends State<InventoryDetailPage> {
  late InventoryItem _currentItem;
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController();
  final _categoryController = TextEditingController();
  final _customSuggestionController = TextEditingController();
  final _dailyUsageController = TextEditingController();
  DateTime? _expireDate;

  @override
  void initState() {
    super.initState();
  }

  void _initData(InventoryItem item) {
    _currentItem = item;
    if (_qtyController.text != item.quantity.toString()) {
      _qtyController.text = item.quantity.toString();
    }
    if (_unitController.text != item.unit) {
      _unitController.text = item.unit;
    }
    if (_categoryController.text != item.category) {
      _categoryController.text = item.category;
    }
    if (_customSuggestionController.text != (item.customSuggestion ?? '')) {
      _customSuggestionController.text = item.customSuggestion ?? '';
    }
    if (_dailyUsageController.text != (item.dailyUsage?.toString() ?? '')) {
      _dailyUsageController.text = item.dailyUsage?.toString() ?? '';
    }
    if (_expireDate != item.expireDate) {
      _expireDate = item.expireDate;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    _customSuggestionController.dispose();
    _dailyUsageController.dispose();
    super.dispose();
  }

  String _calculateConsumptionDays() {
    final dailyUsage = _getDailyUsage(_currentItem);
    if (dailyUsage <= 0) return '无法计算';
    final days = _currentItem.quantity / dailyUsage;
    if (days < 1) return '不足1天';
    if (days < 7) return '约${days.round()}天';
    if (days < 30) return '约${(days / 7).round()}周';
    return '约${(days / 30).round()}个月';
  }

  double _getDailyUsage(InventoryItem item) {
    if (item.dailyUsage != null && item.dailyUsage! > 0) {
      return item.dailyUsage!;
    }
    if (item.category == '药品') return 1.0;
    if (item.name.contains('米') || item.name.contains('面') || item.name.contains('油')) return 0.2;
    if (item.name.contains('奶') || item.name.contains('蛋')) return 2.0;
    if (item.name.contains('水')) return 1.5;
    return 0.5;
  }

  String _getSuggestedUsage(InventoryItem item) {
    if (item.category == '药品') {
      if (item.name.contains('降压') || item.name.contains('降糖')) {
        return '建议每日1次，每次1片';
      }
      if (item.name.contains('止痛') || item.name.contains('布洛芬')) {
        return '建议每日2次，每次1-2片，疼痛时服用';
      }
      return '建议每日1-2次，遵医嘱服用';
    }
    if (item.name.contains('米') || item.name.contains('面')) {
      return '建议每日约${(_getDailyUsage(item) * 10).round()}/10${item.unit}';
    }
    if (item.name.contains('奶') || item.name.contains('蛋')) {
      return '建议每日${_getDailyUsage(item)}${item.unit}';
    }
    return '建议每日适量食用';
  }

  @override
  Widget build(BuildContext context) {
    final itemId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final item = context.select<AppStore, InventoryItem?>(
      (s) => s.inventory.where((i) => i.id == itemId).firstOrNull,
    );

    if (item == null) {
      return const SecondaryScaffold(
        title: '库存详情',
        body: Center(child: Text('物品不存在', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    _initData(item);

    return SecondaryScaffold(
      title: '库存详情',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBasicInfoCard(item),
                const SizedBox(height: 12),
                _buildSuggestionCard(item),
                const SizedBox(height: 12),
                _buildLogsCard(item),
                const SizedBox(height: 16),
              ],
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(InventoryItem item) {
    final isLow = item.quantity <= 1;
    final isMedicine = item.category == '药品' || item.name.contains('药');

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
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isMedicine ? AppColors.warningLight : AppColors.accentLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isMedicine ? Icons.medical_services_outlined : Icons.inventory_2_outlined,
                  size: 28,
                  color: isMedicine ? AppColors.warning : AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bgTertiary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.category, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLow ? AppColors.dangerLight : AppColors.successLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isLow ? '库存不足' : '库存充足',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isLow ? AppColors.danger : AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEditableRow('当前数量', TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            decoration: const InputDecoration(border: InputBorder.none),
          )),
          _buildEditableRow('单位', TextField(
            controller: _unitController,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: const InputDecoration(border: InputBorder.none),
          )),
          _buildEditableRow('分类', TextField(
            controller: _categoryController,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: const InputDecoration(border: InputBorder.none),
          )),
          _buildDateRow(item),
        ],
      ),
    );
  }

  Widget _buildEditableRow(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDateRow(InventoryItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text('过期日期', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _showDatePicker,
              child: Row(
                children: [
                  Text(
                    _expireDate != null
                        ? '${_expireDate!.year}/${_expireDate!.month}/${_expireDate!.day}'
                        : '点击设置',
                    style: TextStyle(
                      fontSize: 14,
                      color: _expireDate != null ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expireDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _expireDate = picked);
    }
  }

  Widget _buildSuggestionCard(InventoryItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              const Text('用量建议', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildSuggestionItem('建议用量', _getSuggestedUsage(item)),
          const SizedBox(height: 8),
          _buildDailyUsageRow(item),
          const SizedBox(height: 8),
          _buildSuggestionItem('预计可用', _calculateConsumptionDays()),
          if (item.expireDate != null) ...[
            const SizedBox(height: 8),
            _buildSuggestionItem('过期日期', '${item.expireDate!.year}/${item.expireDate!.month}/${item.expireDate!.day}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_getExpireWarning(item), style: const TextStyle(fontSize: 12, color: AppColors.warning)),
            ),
          ],
          if (item.aiSuggestion != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.smart_toy_outlined, size: 14, color: AppColors.purple),
                const SizedBox(width: 4),
                const Text('AI 建议', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.purple)),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.aiSuggestion!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
          const Text('自定义备注', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _customSuggestionController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: '添加自定义备注或使用建议',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyUsageRow(InventoryItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 60,
            child: Text('实际用量', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _dailyUsageController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: '每日用量',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(item.unit, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                const Text('/天', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _getExpireWarning(InventoryItem item) {
    if (item.expireDate == null) return '';
    final daysLeft = item.expireDate!.difference(DateTime.now()).inDays;
    if (daysLeft <= 7) {
      return '⚠️ 物品即将过期（剩余${daysLeft}天），请尽快使用';
    }
    if (daysLeft <= 30) {
      return '提醒：物品剩余${daysLeft}天过期';
    }
    return '物品状态良好，还有${daysLeft}天过期';
  }

  Widget _buildLogsCard(InventoryItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('变动记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          if (item.logs.isEmpty)
            const Text('暂无变动记录', style: TextStyle(fontSize: 13, color: AppColors.textTertiary))
          else
            ...item.logs.map((log) {
              final isIncrease = log.change > 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      isIncrease ? Icons.add_circle_outline : Icons.remove_circle_outline,
                      size: 16,
                      color: isIncrease ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.reason.isNotEmpty ? log.reason : (isIncrease ? '入库' : '出库'),
                            style: TextStyle(fontSize: 13, color: isIncrease ? AppColors.success : AppColors.danger),
                          ),
                          Text(
                            '${log.time.month}/${log.time.day} ${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isIncrease ? '+${log.change}' : '${log.change}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isIncrease ? AppColors.success : AppColors.danger),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
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
              onPressed: () => _showChangeDialog(-1),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Text('减少库存', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showChangeDialog(1),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: AppColors.accent),
              ),
              child: const Text('增加库存', style: TextStyle(fontSize: 14, color: AppColors.accent)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('保存', style: TextStyle(fontSize: 14, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeDialog(int type) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type > 0 ? '增加库存' : '减少库存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '数量',
                hintText: '输入${type > 0 ? '增加' : '减少'}的数量',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: '原因',
                hintText: '例如：使用、补充、购买',
              ),
              onSubmitted: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(controller.text.trim()) ?? 0;
              if (qty > 0) {
                context.read<AppStore>().updateInventory(
                  _currentItem.name,
                  type * qty,
                  _unitController.text.trim().isEmpty ? _currentItem.unit : _unitController.text.trim(),
                  reason: '手动调整',
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    final qty = double.tryParse(_qtyController.text.trim());
    if (qty == null || qty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的数量'), duration: Duration(seconds: 1)),
      );
      return;
    }

    final store = context.read<AppStore>();
    final change = qty - _currentItem.quantity;
    final dailyUsage = double.tryParse(_dailyUsageController.text.trim());

    if (change != 0) {
      store.updateInventory(
        _currentItem.name,
        change,
        _unitController.text.trim().isEmpty ? _currentItem.unit : _unitController.text.trim(),
        reason: '手动修改',
        category: _categoryController.text.trim().isEmpty ? _currentItem.category : _categoryController.text.trim(),
        customSuggestion: _customSuggestionController.text.trim().isEmpty ? null : _customSuggestionController.text.trim(),
        dailyUsage: dailyUsage,
      );
    } else {
      store.updateInventoryMetadata(
        _currentItem.id,
        unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        expireDate: _expireDate,
        customSuggestion: _customSuggestionController.text.trim().isEmpty ? null : _customSuggestionController.text.trim(),
        dailyUsage: dailyUsage,
      );
    }

    if (change != 0) {
      store.addTimelineRecord(TimelineRecord(
        id: store.genId(),
        content: '修改库存：${_currentItem.name} ${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}${_unitController.text}',
        time: DateTime.now(),
        type: TimelineType.item,
        sideEffects: SideEffects(itemUpdate: ItemUpdate(name: _currentItem.name, location: '库存')),
      ));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存'), duration: Duration(seconds: 1)),
    );
    Navigator.pop(context);
  }
}
