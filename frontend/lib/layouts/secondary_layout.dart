import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 二级页面布局 - 对齐 SecondaryLayout.tsx
/// 顶部固定返回栏 + 标题 + 右侧操作，无底部导航
class SecondaryLayout extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? child;
  final List<Widget>? actions;
  final bool showBack;
  final Color? backgroundColor;

  const SecondaryLayout({
    super.key,
    required this.title,
    this.child,
    this.actions,
    this.showBack = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            Container(
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.bgSecondary,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  if (showBack)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(
                        width: 44,
                        height: 48,
                        child: Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 24),
                      ),
                    )
                  else
                    const SizedBox(width: 44),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions ?? [],
                    ),
                  ),
                ],
              ),
            ),
            // 内容区
            Expanded(
              child: child ?? const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

/// 便捷封装：二级页面 Scaffold
class SecondaryScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBack;

  const SecondaryScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.bgSecondary,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  if (showBack)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(
                        width: 44,
                        height: 48,
                        child: Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 24),
                      ),
                    )
                  else
                    const SizedBox(width: 44),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions ?? [],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
