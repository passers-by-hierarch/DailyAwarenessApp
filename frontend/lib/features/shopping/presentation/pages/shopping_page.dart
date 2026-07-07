import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/models/app_models.dart';

/// 购物记录页 - 对齐原型 ShoppingPage
class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final records = context.select<AppStore, List<ShoppingRecord>>((s) => s.shoppingRecords);
    final now = DateTime.now();
    final monthRecords = records.where((r) =>
        r.time.year == now.year && r.time.month == now.month).toList();
    final totalItems = monthRecords.fold<int>(0, (a, r) => a + r.items.length);

    return SecondaryScaffold(
      title: '购物记录',
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: AppColors.accent, size: 22),
          onPressed: () => _showAddDialog(context),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverview(monthRecords.length, totalItems),
          const SizedBox(height: 16),
          ...records.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRecordCard(r),
              )),
        ],
      ),
    );
  }

  Widget _buildOverview(int shopCount, int itemCount) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('本月购物', shopCount, '次', AppColors.accent, AppColors.accentLight)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('商品总数', itemCount, '件', AppColors.warning, AppColors.warningLight)),
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
    final storeCtrl = TextEditingController();
    final itemsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加购物记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: storeCtrl,
              decoration: const InputDecoration(labelText: '商店', hintText: '例如：超市'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: itemsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '商品列表',
                hintText: '使用逗号分隔，例如：苹果,牛奶,面包',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (storeCtrl.text.trim().isEmpty) return;
              final names = itemsCtrl.text.split(RegExp(r'[，,、]')).where((s) => s.trim().isNotEmpty);
              final items = names
                  .map((n) => ShoppingItem(id: DateTime.now().millisecondsSinceEpoch.toString(), name: n.trim()))
                  .toList();
              context.read<AppStore>().addShoppingRecord(ShoppingRecord(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                store: storeCtrl.text.trim(),
                items: items,
                time: DateTime.now(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
