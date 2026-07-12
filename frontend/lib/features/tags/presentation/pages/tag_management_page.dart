import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/models/app_models.dart';

/// 标签管理页 - 对齐原型 TagManagementPage
class TagManagementPage extends StatelessWidget {
  const TagManagementPage({super.key});

  static const List<String> _colorChoices = [
    'accent', 'info', 'warning', 'success', 'danger', 'purple', 'gray',
  ];

  static const List<String> _iconChoices = [
    '#', '📊', '📦', '🛒', '📍', '🏃', '💊', '🍚', '💧', '📚', '🎯', '⭐',
  ];

  @override
  Widget build(BuildContext context) {
    final customTags = context.select<AppStore, List<TagDef>>((s) => s.customTags);
    final store = context.read<AppStore>();
    // 按使用次数降序排序
    final sortedCustomTags = [...customTags]..sort((a, b) =>
        store.getTagUsageCount(b.id).compareTo(store.getTagUsageCount(a.id)));
    return SecondaryScaffold(
      title: '标签管理',
      actions: [
        TextButton(
          onPressed: () => _showCreateDialog(context),
          child: const Text('新建', style: TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCountCard(customTags.length),
          const SizedBox(height: 16),
          _buildSectionTitle('系统标签'),
          const SizedBox(height: 8),
          _buildSystemTags(context),
          const SizedBox(height: 16),
          _buildSectionTitle('我的标签'),
          const SizedBox(height: 8),
          if (sortedCustomTags.isEmpty)
            _buildEmpty()
          else
            ...sortedCustomTags.asMap().entries.map((entry) {
              final idx = entry.key;
              final tag = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCustomTagItem(context, tag, idx + 1),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCountCard(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.label_outline, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text('自定义标签 $count/${AppStore.maxCustomTags}',
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
          Text('${(count / AppStore.maxCustomTags * 100).round()}%',
              style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
  }

  Widget _buildSystemTags(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TagDef.systemTags.map((t) {
        final colorSet = AppColors.tagColors[t.color] ?? AppColors.tagColors['gray']!;
        final usage = context.read<AppStore>().getTagUsageCount(t.id);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colorSet.bg, borderRadius: BorderRadius.circular(6)),
                child: _buildTagIcon(t, size: 16),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  Text('使用 $usage 次', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(4)),
                child: const Text('系统', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.label_off_outlined, size: 36, color: AppColors.textTertiary),
            SizedBox(height: 8),
            Text('暂无自定义标签', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            SizedBox(height: 4),
            Text('点击右上角"新建"创建', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTagItem(BuildContext context, TagDef tag, int rank) {
    final colorSet = AppColors.tagColors[tag.color] ?? AppColors.tagColors['gray']!;
    final usage = context.read<AppStore>().getTagUsageCount(tag.id);
    final showRankBadge = rank <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: showRankBadge ? colorSet.color.withOpacity(0.3) : AppColors.border,
          width: showRankBadge ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          // 排名徽章
          if (showRankBadge)
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: rank == 1 ? const Color(0xFFFFD700)
                     : rank == 2 ? const Color(0xFFC0C0C0)
                     : const Color(0xFFCD7F32),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$rank', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          // 图标方块（更大更醒目）
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorSet.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorSet.color.withOpacity(0.3), width: 1),
            ),
            child: _buildTagIcon(tag, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tag.name, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('使用 $usage 次', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
            onPressed: () => _showRenameDialog(context, tag),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
            onPressed: () => _showDeleteDialog(context, tag),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final store = context.read<AppStore>();
    if (store.customTags.length >= AppStore.maxCustomTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('自定义标签最多 ${AppStore.maxCustomTags} 个'), duration: const Duration(seconds: 1)),
      );
      return;
    }
    final nameCtrl = TextEditingController();
    String selectedColor = _colorChoices.first;
    String selectedIcon = _iconChoices.first;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('新建标签'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: '标签名称',
                    hintText: '最多8个字',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('颜色', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorChoices.map((c) {
                    final colorSet = AppColors.tagColors[c]!;
                    final selected = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setSt(() => selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorSet.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.textPrimary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('图标', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _iconChoices.map((icon) {
                    final selected = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setSt(() => selectedIcon = icon),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.accentLight : AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? AppColors.accent : Colors.transparent,
                          ),
                        ),
                        child: Text(icon, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }).toList(),
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
                final result = store.addCustomTag(name: name, color: selectedColor, icon: selectedIcon);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['success'] ? '已创建标签' : result['error'] as String),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, TagDef tag) {
    final nameCtrl = TextEditingController(text: tag.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名标签'),
        content: TextField(
          controller: nameCtrl,
          maxLength: 8,
          decoration: const InputDecoration(
            hintText: '请输入新名称',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final result = context.read<AppStore>().renameCustomTag(tag.id, name);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['success'] ? '已重命名' : result['error'] as String),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TagDef tag) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除标签'),
        content: Text('确定要删除标签"${tag.name}"吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              context.read<AppStore>().deleteCustomTag(tag.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTagIcon(TagDef tag, {double size = 16}) {
    if (tag.icon.isEmpty || tag.icon == '#') {
      return Icon(Icons.label_outline, size: size, color: AppColors.textSecondary);
    }
    // emoji 图标（包含非ASCII字符的视为emoji）
    if (tag.icon.runes.any((r) => r > 127)) {
      return Text(tag.icon, style: TextStyle(fontSize: size));
    }
    // Lucide 图标名称映射
    final iconMap = <String, IconData>{
      'activity': AppIcons.activity,
      'package': AppIcons.package,
      'shopping_cart': AppIcons.shoppingCart,
      'map_pin': AppIcons.mapPin,
      'tag': AppIcons.tag,
      'hash': AppIcons.hash,
      'star': AppIcons.star,
      'target': AppIcons.target,
      'heart': AppIcons.heart,
      'book': AppIcons.book,
      'droplet': AppIcons.droplet,
      'sun': AppIcons.sun,
      'moon': AppIcons.moon,
      'clock': AppIcons.clock,
      'bell': AppIcons.bell,
      'calendar': AppIcons.calendar,
      'search': AppIcons.search,
      'settings': AppIcons.settings,
      'user': AppIcons.user,
      'home': AppIcons.home,
      'message_circle': AppIcons.messageCircle,
      'trending_up': AppIcons.trendingUp,
      'sparkles': AppIcons.sparkles,
    };
    final iconData = iconMap[tag.icon];
    if (iconData != null) {
      return Icon(iconData, size: size, color: AppColors.textSecondary);
    }
    // 未知图标显示 #
    return Icon(Icons.label_outline, size: size, color: AppColors.textSecondary);
  }
}
