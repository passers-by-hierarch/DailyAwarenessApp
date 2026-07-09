import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/state/app_store.dart';

/// 底部导航栏 - 对齐 BottomNav.tsx
/// 4 Tab：首页 → 问一问 → 习惯 → 我的
class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      height: 56,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(
              icon: AppIcons.home,
              activeIcon: AppIcons.home,
              label: '首页',
              isActive: store.activeTab == 'home',
              onTap: () => store.setActiveTab('home'),
            ),
            _NavItem(
              icon: AppIcons.messageCircle,
              activeIcon: AppIcons.messageCircle,
              label: '问一问',
              isActive: store.activeTab == 'ask',
              onTap: () => store.setActiveTab('ask'),
            ),
            _NavItem(
              icon: AppIcons.trendingUp,
              activeIcon: AppIcons.trendingUp,
              label: '习惯',
              isActive: store.activeTab == 'habits',
              onTap: () => store.setActiveTab('habits'),
            ),
            _NavItem(
              icon: AppIcons.user,
              activeIcon: AppIcons.user,
              label: '我的',
              isActive: store.activeTab == 'profile',
              onTap: () => store.setActiveTab('profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: isActive ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
