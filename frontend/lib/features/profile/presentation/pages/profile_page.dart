import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/state/app_store.dart';

/// 我的页面 - 对齐 ProfilePage.tsx
/// 用户头像卡 + 实时时钟 + 测试时钟 + 菜单列表(3组11项)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Timer? _realTimeTimer;
  DateTime _realTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _realTimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _realTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _realTimeTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime t) {
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    return '${t.year}年${t.month}月${t.day}日 ${weekdays[t.weekday % 7]}';
  }

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
                // 时钟管理
                _buildClockManagement(store),
                const SizedBox(height: 16),
                // 菜单列表
                ...MockData.mockMenuItems.map((group) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildMenuGroup(group),
                )),
                const SizedBox(height: 16),
                // 清除数据
                _buildClearDataButton(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 时钟管理卡片 - 显示实时时间，点击设置测试时间
  Widget _buildClockManagement(AppStore store) {
    final isTestMode = store.isTestMode;
    final currentTime = isTestMode && store.testTime != null ? store.testTime! : _realTime;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
        border: isTestMode ? Border.all(color: AppColors.warning.withOpacity(0.4), width: 1.5) : null,
      ),
      child: Column(
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('时钟管理', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: isTestMode ? AppColors.warning : AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    isTestMode ? '测试时钟' : '实时时钟',
                    style: TextStyle(fontSize: 12, color: isTestMode ? AppColors.warning : AppColors.textTertiary),
                  ),
                  if (isTestMode) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('已启用', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning)),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 时间显示
          Text(
            _formatTime(currentTime),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: isTestMode ? AppColors.warning : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(currentTime),
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          // 操作按钮
          Row(
            children: [
              // 设置测试时间
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _pickTestTime(store),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTestMode ? AppColors.warning.withOpacity(0.1) : AppColors.accent.withOpacity(0.1),
                    foregroundColor: isTestMode ? AppColors.warning : AppColors.accent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_calendar_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(isTestMode ? '修改测试时间' : '设置测试时间'),
                    ],
                  ),
                ),
              ),
              if (isTestMode) ...[
                const SizedBox(width: 12),
                // 退出测试模式
                ElevatedButton(
                  onPressed: () {
                    store.clearTestTime();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已退出测试模式'), duration: Duration(seconds: 1)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dangerLight,
                    foregroundColor: AppColors.danger,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('退出测试'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _pickTestTime(AppStore store) async {
    final now = DateTime.now();
    final initial = store.testTime ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );

    if (pickedTime == null) return;

    final testDateTime = DateTime(
      picked.year,
      picked.month,
      picked.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    store.setTestTime(testDateTime);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('测试时间已设为 ${picked.month}/${picked.day} ${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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

  Widget _buildClearDataButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('清除数据'),
              content: const Text('确定要清除所有数据并重新应用吗？此操作不可撤销。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    await context.read<AppStore>().clearAllData();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('数据已清除，应用已重置'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dangerLight,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: const Text('清除所有数据', style: TextStyle(fontSize: 15, color: AppColors.danger)),
      ),
    );
  }
}
