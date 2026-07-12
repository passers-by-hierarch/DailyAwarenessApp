import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/models/app_models.dart';

/// 物品记录页 - 显示物品及数量（库存 + 购买记录）
class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {

  @override
  Widget build(BuildContext context) {
    final inventory = context.select<AppStore, List<InventoryItem>>((s) => s.inventory);
    final shoppingRecords = context.select<AppStore, List<ShoppingRecord>>((s) => s.shoppingRecords);
    final now = DateTime.now();
    final monthRecords = shoppingRecords.where((r) =>
        r.time.year == now.year && r.time.month == now.month).toList();
    final totalItems = monthRecords.fold<int>(0, (a, r) => a + r.items.length);

    return SecondaryScaffold(
      title: '物品记录',
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: AppColors.accent, size: 22),
          onPressed: () => _showAddDialog(context),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverview(inventory.length, totalItems),
          const SizedBox(height: 20),
          // 物品库存列表
          if (inventory.isNotEmpty) ...[
            _buildSectionHeader('物品库存', Icons.inventory_2_outlined),
            const SizedBox(height: 8),
            ...inventory.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildInventoryCard(item),
            )),
            const SizedBox(height: 20),
          ],
          // 购买记录
          if (shoppingRecords.isNotEmpty) ...[
            _buildSectionHeader('购买记录', Icons.shopping_cart_outlined),
            const SizedBox(height: 8),
            ...shoppingRecords.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRecordCard(r),
            )),
          ],
          if (inventory.isEmpty && shoppingRecords.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Text('暂无物品记录', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverview(int itemCount, int monthBuyCount) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('物品总数', itemCount, '件', AppColors.accent, AppColors.accentLight)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('本月购买', monthBuyCount, '件', AppColors.warning, AppColors.warningLight)),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, String unit, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    final isLow = item.quantity <= 1;
    final color = isLow ? AppColors.danger : AppColors.accent;
    final bg = isLow ? AppColors.dangerLight : AppColors.accentLight;
    final isMedicine = item.category == '药品' || item.name.contains('药');
    final healthWarning = isMedicine ? _getHealthWarning(item) : null;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteNames.inventoryDetail, arguments: item.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(item.category,
                                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '剩余 ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)}${item.unit}',
                        style: TextStyle(fontSize: 13, color: isLow ? AppColors.danger : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
              ],
            ),
            if (healthWarning != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.health_and_safety_outlined, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('健康助手提醒', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning)),
                          const SizedBox(height: 2),
                          Text(healthWarning, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (item.aiSuggestion != null || item.customSuggestion != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.aiSuggestion != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_outlined, size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          const Text('AI 建议', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.aiSuggestion!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    if (item.customSuggestion != null) ...[
                      if (item.aiSuggestion != null) const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.edit_note_outlined, size: 14, color: AppColors.info),
                          const SizedBox(width: 4),
                          const Text('自定义建议', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.info)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.customSuggestion!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _getHealthWarning(InventoryItem item) {
    final warnings = <String>[];
    if (item.name.contains('降压') || item.name.contains('高血压')) {
      warnings.add('长期服用降压药需定期监测血压，建议遵医嘱调整用药');
    } else if (item.name.contains('降糖') || item.name.contains('糖尿病')) {
      warnings.add('降糖药物需配合饮食控制，定期检测血糖');
    } else if (item.name.contains('止痛') || item.name.contains('布洛芬') || item.name.contains('阿司匹林')) {
      warnings.add('止痛药不建议长期连续服用，如有持续疼痛请就医');
    } else if (item.name.contains('抗生素') || item.name.contains('头孢') || item.name.contains('阿莫西林')) {
      warnings.add('抗生素需按疗程服用，不可自行延长用药时间');
    } else if (item.category == '药品') {
      warnings.add('药品请在医生指导下使用，不建议长期自行服用');
    }
    if (item.expireDate != null) {
      final daysLeft = item.expireDate!.difference(DateTime.now()).inDays;
      if (daysLeft <= 30) {
        warnings.add('药品即将过期（剩余${daysLeft}天），请注意及时处理');
      }
    }
    return warnings.isNotEmpty ? warnings.join('\n') : null;
  }

  Widget _buildRecordCard(ShoppingRecord record) {
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
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_outlined, size: 18, color: AppColors.warning),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.store,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '${record.time.month}/${record.time.day} ${record.time.hour.toString().padLeft(2, '0')}:${record.time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('共${record.items.length}件',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: record.items.map((it) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${it.name} ${it.quantity}${it.unit}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: '个');
    final categoryCtrl = TextEditingController(text: '食品');
    final storeCtrl = TextEditingController();
    final aiSuggestionCtrl = TextEditingController();
    final customSuggestionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加物品记录'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '物品名称', hintText: '例如：苹果'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '数量'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(labelText: '单位', hintText: '斤/个/瓶'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: '分类', hintText: '食品/药品/日用品'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: storeCtrl,
                decoration: const InputDecoration(labelText: '购买地点（可选）', hintText: '例如：超市'),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.auto_awesome_outlined, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  const Text('AI 智能建议', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      aiSuggestionCtrl.text = _generateAISuggestion(name, categoryCtrl.text.trim());
                    },
                    child: const Text('生成建议', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: aiSuggestionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'AI 建议内容',
                  hintText: '点击上方按钮生成，或手动输入',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.edit_note_outlined, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  const Text('自定义建议', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.info)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: customSuggestionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '自定义食用/使用建议',
                  hintText: '例如：建议每周食用2次，防止过期',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1;
              final unit = unitCtrl.text.trim().isEmpty ? '个' : unitCtrl.text.trim();
              final category = categoryCtrl.text.trim().isEmpty ? '其他' : categoryCtrl.text.trim();
              final store = storeCtrl.text.trim();
              final aiSuggestion = aiSuggestionCtrl.text.trim();
              final customSuggestion = customSuggestionCtrl.text.trim();

              final store2 = context.read<AppStore>();
              if (store.isNotEmpty) {
                // 有购买地点：创建购物记录（会自动入库）
                store2.addShoppingRecord(ShoppingRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  store: store,
                  items: [
                    ShoppingItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      quantity: qty.toInt(),
                      unit: unit,
                    ),
                  ],
                  time: DateTime.now(),
                ));
              } else {
                // 无购买地点：直接更新库存
                store2.updateInventory(name, qty, unit, reason: '手动添加', category: category, aiSuggestion: aiSuggestion.isNotEmpty ? aiSuggestion : null, customSuggestion: customSuggestion.isNotEmpty ? customSuggestion : null);
              }
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  String _generateAISuggestion(String name, String category) {
    final suggestions = {
      '食品': [
        '$name建议尽快食用，避免过期',
        '$name建议在保质期内食用完毕',
        '$name建议每周食用2-3次',
        '$name建议冷藏保存',
        '$name建议打开后24小时内食用',
      ],
      '药品': [
        '$name建议按时服用，不要间断',
        '$name建议定期检查库存，防止不足',
        '$name建议按说明书剂量服用',
        '$name建议放在阴凉干燥处保存',
        '$name建议在有效期前使用',
      ],
      '日用品': [
        '$name建议定期更换',
        '$name建议保持干燥清洁',
        '$name建议注意保质期',
        '$name建议适量购买，避免浪费',
      ],
    };
    final categorySuggestions = suggestions[category] ?? suggestions['其他'];
    if (categorySuggestions != null) {
      return categorySuggestions[DateTime.now().millisecondsSinceEpoch % categorySuggestions.length];
    }
    return '$name建议合理使用，注意保质期';
  }
}
