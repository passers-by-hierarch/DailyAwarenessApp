import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';

/// 家属管理页 - 对齐原型 FamilyPage
class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  bool _emergencyNotify = true;

  final List<Map<String, dynamic>> _families = [
    {
      'name': '张明',
      'relation': '儿子',
      'phone': '138****8888',
      'avatar': '👨',
      'permission': 'full',
      'permissionLabel': '完全权限',
    },
    {
      'name': '张丽',
      'relation': '女儿',
      'phone': '139****6666',
      'avatar': '👩',
      'permission': 'view',
      'permissionLabel': '查看权限',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: '家属管理',
      actions: [
        TextButton(
          onPressed: () => _showInviteDialog(context),
          child: const Text('邀请', style: TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._families.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFamilyCard(f),
              )),
          const SizedBox(height: 16),
          _buildNotifySwitch(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFamilyCard(Map<String, dynamic> f) {
    final perm = f['permission'] as String;
    Color permColor;
    Color permBg;
    switch (perm) {
      case 'full':
        permColor = AppColors.success;
        permBg = AppColors.successLight;
        break;
      case 'view':
        permColor = AppColors.warning;
        permBg = AppColors.warningLight;
        break;
      default:
        permColor = AppColors.textSecondary;
        permBg = AppColors.bgTertiary;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(f['avatar'] as String, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(f['name'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(width: 6),
                    Text(f['relation'] as String,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(f['phone'] as String,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: permBg, borderRadius: BorderRadius.circular(6)),
            child: Text(f['permissionLabel'] as String,
                style: TextStyle(fontSize: 11, color: permColor, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifySwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.danger),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('异常通知', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('异常情况时通知家属', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: _emergencyNotify,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _emergencyNotify = v),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('邀请家属'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('输入家属手机号发起邀请', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '请输入手机号',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('邀请已发送'), duration: Duration(seconds: 1)),
              );
            },
            child: const Text('发送邀请'),
          ),
        ],
      ),
    );
  }
}
