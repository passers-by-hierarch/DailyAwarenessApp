import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/models/app_models.dart';

/// 物品管理页 - 对齐原型 ItemsPage
class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  int _tabIndex = 0;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = context.select<AppStore, List<ItemRecord>>((s) => s.items);
    final records = context.select<AppStore, List<TimelineRecord>>(
      (s) => s.timelineRecords.where((r) => r.type == TimelineType.item).toList(),
    );
    final filtered = items.where((it) => it.name.contains(_searchCtrl.text)).toList();

    return SecondaryScaffold(
      title: '物品管理',
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: AppColors.accent, size: 22),
          onPressed: () => _showAddDialog(context),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSearch(),
          ),
          _buildTabs(),
          Expanded(
            child: _tabIndex == 0
                ? _buildItemsGrid(filtered)
                : _buildExtractionList(records),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                hintText: '搜索物品名称',
                hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _tabButton('物品列表', 0),
          _tabButton('语音记录抽取', 1),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int idx) {
    final selected = _tabIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.bgSecondary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsGrid(List<ItemRecord> items) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无物品', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) => SizedBox(
            width: (MediaQuery.of(context).size.width - 48) / 2,
            child: _buildItemCard(context, item),
          )).toList(),
        ),
      ],
    );
  }

  String? _getHighFreqLocation(ItemRecord item) {
    if (item.history.length < 2) return null;
    final Map<String, int> counts = {};
    for (final h in item.history) {
      counts[h.location] = (counts[h.location] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  Widget _buildItemCard(BuildContext context, ItemRecord item) {
    final highFreqLoc = _getHighFreqLocation(item);
    final latestLoc = item.location;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/items-detail', arguments: item.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(item.icon, style: const TextStyle(fontSize: 18)),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, size: 12, color: AppColors.info),
                      const SizedBox(width: 5),
                      const Text('最新',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(latestLoc,
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.star, size: 12, color: highFreqLoc != null ? AppColors.accent : AppColors.textTertiary),
                      const SizedBox(width: 5),
                      Text('高频',
                          style: TextStyle(fontSize: 11, color: highFreqLoc != null ? AppColors.textSecondary : AppColors.textTertiary, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(highFreqLoc ?? '暂无',
                            style: TextStyle(fontSize: 12, color: highFreqLoc != null ? AppColors.accent : AppColors.textTertiary, fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: item.tags.isEmpty
                  ? [const SizedBox(height: 19)]
                  : item.tags.map((t) {
                      final def = context.read<AppStore>().getTagDef(t);
                      final name = def?.name ?? t;
                      final colorSet = def != null
                          ? (AppColors.tagColors[def.color] ?? AppColors.tagColors['gray']!)
                          : AppColors.tagColors['gray']!;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: colorSet.bg, borderRadius: BorderRadius.circular(4)),
                        child: Text(name, style: TextStyle(fontSize: 11, color: colorSet.color, fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractionList(List<TimelineRecord> records) {
    if (records.isEmpty) {
      return const Center(child: Text('暂无抽取记录', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final r = records[idx];
        final itemUpdate = r.sideEffects?.itemUpdate;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.info),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.content, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                    if (itemUpdate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${itemUpdate.name} → ${itemUpdate.location}',
                            style: const TextStyle(fontSize: 12, color: AppColors.info)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${r.time.month}/${r.time.day}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  Text(r.timeStr,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加物品'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '物品名称', hintText: '例如：钥匙'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locCtrl,
              decoration: const InputDecoration(labelText: '当前位置', hintText: '例如：门口鞋柜'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final store = context.read<AppStore>();
              store.updateItemLocation(nameCtrl.text.trim(), locCtrl.text.trim().isEmpty ? '未记录' : locCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
