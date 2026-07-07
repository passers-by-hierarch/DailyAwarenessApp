import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/state/app_store.dart';

/// 我的页面 - 对齐 ProfilePage.tsx
/// 用户头像卡 + 菜单列表(3组11项)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final completedCount = store.agendaItems.where((a) => a.status == AgendaStatus.completed).length;
    final totalCount = store.agendaItems.length;
    final rate = totalCount > 0 ? (completedCount * 100 ~/ totalCount) : 0;

    return Container(
      color: AppColors.bgPrimary,
      child: Column(
        children: [
          // 顶部标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.bgSecondary,
            child: const Row(
              children: [
                Text('我的', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 用户头像卡
                _buildUserCard(rate),
                const SizedBox(height: 16),
                // 菜单列表
                ...MockData.mockMenuItems.map((group) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildMenuGroup(group),
                )),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(int rate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.accent, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('用户昵称', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('已连续使用 128 天', style: TextStyle(fontSize: 14, color: AppColors.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(MenuGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12, top: 12),
          child: Text(
            group.group.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary)
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: group.items.map((item) => _buildMenuItem(item, group.items.last.id == item.id)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(MenuItem item, bool isLast) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pushNamed(context, item.route),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Row(
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.title, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
