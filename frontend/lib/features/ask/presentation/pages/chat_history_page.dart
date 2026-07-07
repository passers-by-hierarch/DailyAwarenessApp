import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';

/// 历史对话页 - 对齐原型 ChatHistoryPage
class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final _searchCtrl = TextEditingController();
  int _selectedCategory = 0;

  final List<Map<String, dynamic>> _categories = [
    {'label': '全部', 'color': AppColors.accent},
    {'label': '健康管理', 'color': AppColors.danger},
    {'label': '日程查询', 'color': AppColors.info},
    {'label': '提醒设置', 'color': AppColors.warning},
    {'label': '日常咨询', 'color': AppColors.accent},
    {'label': '计划调整', 'color': AppColors.purple},
    {'label': '数据查询', 'color': AppColors.info},
    {'label': '物品管理', 'color': AppColors.success},
  ];

  final List<Map<String, dynamic>> _conversations = [
    {
      'title': '钥匙放在哪里了？',
      'category': '物品管理',
      'categoryIdx': 7,
      'preview': '根据您6月20日的记录，您把钥匙放在了门口鞋柜第二个抽屉里。',
      'time': '今天 14:30',
      'msgCount': 4,
    },
    {
      'title': '上周三我做了什么？',
      'category': '日程查询',
      'categoryIdx': 2,
      'preview': '上周三（6月18日）您做了以下事情：07:30吃早饭、08:00吃降压药、10:30社区医院复诊...',
      'time': '今天 10:15',
      'msgCount': 6,
    },
    {
      'title': '运动提醒可以改到下午吗？',
      'category': '提醒设置',
      'categoryIdx': 3,
      'preview': '已为您将运动提醒调整到下午18:30，您可以在事程页面查看修改后的提醒。',
      'time': '昨天 19:20',
      'msgCount': 8,
    },
    {
      'title': '本周血压数据如何？',
      'category': '数据查询',
      'categoryIdx': 6,
      'preview': '本周您共测量血压7次，平均值为118/76，整体控制良好，较上周下降3mmHg。',
      'time': '06-28 09:00',
      'msgCount': 5,
    },
    {
      'title': '降压药什么时候吃最好？',
      'category': '健康管理',
      'categoryIdx': 1,
      'preview': '根据医嘱，降压药建议在早晨7-8点饭后服用，每天定时以保持血药浓度稳定。',
      'time': '06-27 21:30',
      'msgCount': 3,
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _conversations.where((c) {
      if (_selectedCategory != 0 && c['categoryIdx'] != _selectedCategory) return false;
      final kw = _searchCtrl.text.trim();
      if (kw.isNotEmpty && !(c['title'] as String).contains(kw) && !(c['preview'] as String).contains(kw)) return false;
      return true;
    }).toList();

    return SecondaryScaffold(
      title: '历史对话',
      actions: [
        TextButton(
          onPressed: () => _showClearDialog(context),
          child: const Text('清空', style: TextStyle(fontSize: 14, color: AppColors.danger, fontWeight: FontWeight.w600)),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSearch(),
          ),
          _buildCategoryChips(),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('暂无对话', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) => _buildConversationCard(filtered[idx]),
                  ),
          ),
          _buildNewChatButton(),
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
                hintText: '搜索对话内容',
                hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final cat = _categories[idx];
          final selected = _selectedCategory == idx;
          final color = cat['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = idx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? color : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? color : AppColors.border),
              ),
              child: Text(
                cat['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conv) {
    final catColor = (_categories[conv['categoryIdx'] as int]['color']) as Color;
    return Dismissible(
      key: ValueKey(conv['title']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _conversations.remove(conv));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除对话'), duration: Duration(seconds: 1)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
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
                  child: Text(conv['title'] as String,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(conv['category'] as String,
                      style: TextStyle(fontSize: 11, color: catColor, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(conv['preview'] as String,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(conv['time'] as String,
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                const Spacer(),
                const Icon(Icons.chat_bubble_outline, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('${conv['msgCount']}条',
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewChatButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/ask');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
          label: const Text('开始新对话', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空历史对话'),
        content: const Text('确定要清空所有历史对话吗？此操作无法撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              setState(() => _conversations.clear());
              Navigator.pop(ctx);
            },
            child: const Text('清空', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
