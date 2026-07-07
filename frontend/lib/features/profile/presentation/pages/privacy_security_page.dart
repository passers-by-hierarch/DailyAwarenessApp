import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';

/// 隐私与安全页 - 对齐原型 PrivacySecurityPage
class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  bool _fingerprintLock = true;
  bool _autoLock = true;
  bool _dataEncrypt = true;
  bool _anonymousMode = false;
  bool _cloudBackup = true;
  bool _locationShare = true;
  bool _analyticsShare = false;

  final List<Map<String, dynamic>> _logs = [
    {'action': '登录成功', 'time': '今日 09:15', 'icon': Icons.login, 'color': AppColors.success},
    {'action': '修改密码', 'time': '昨日 20:30', 'icon': Icons.lock, 'color': AppColors.warning},
    {'action': '数据导出', 'time': '06-28 14:20', 'icon': Icons.download, 'color': AppColors.info},
    {'action': '家属查看', 'time': '06-27 10:05', 'icon': Icons.visibility, 'color': AppColors.accent},
  ];

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: '隐私与安全',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildSection('生物识别与锁定', [
            _switchTile('指纹解锁', '使用指纹解锁应用', Icons.fingerprint, _fingerprintLock, (v) => setState(() => _fingerprintLock = v)),
            _divider(),
            _switchTile('自动锁定', '离开应用后自动锁定', Icons.lock_clock, _autoLock, (v) => setState(() => _autoLock = v)),
            _divider(),
            _arrowTile('修改密码', '定期修改以保护账户', Icons.password),
          ]),
          const SizedBox(height: 16),
          _buildSection('数据保护', [
            _switchTile('数据加密', '本地数据已加密存储', Icons.enhanced_encryption, _dataEncrypt, (v) => setState(() => _dataEncrypt = v)),
            _divider(),
            _switchTile('匿名模式', '使用应用时不收集个人信息', Icons.visibility_off, _anonymousMode, (v) => setState(() => _anonymousMode = v)),
            _divider(),
            _switchTile('云端备份', '每日自动备份到云端', Icons.cloud_upload_outlined, _cloudBackup, (v) => setState(() => _cloudBackup = v)),
            _divider(),
            _dangerTile('清除所有数据', '永久删除所有本地数据'),
          ]),
          const SizedBox(height: 16),
          _buildSection('隐私设置', [
            _switchTile('位置共享', '允许家属查看位置', Icons.location_on_outlined, _locationShare, (v) => setState(() => _locationShare = v)),
            _divider(),
            _switchTile('分析数据共享', '帮助改进应用', Icons.analytics_outlined, _analyticsShare, (v) => setState(() => _analyticsShare = v)),
          ]),
          const SizedBox(height: 16),
          _buildSection('安全日志', [
            _buildLogs(),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.shield, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('您的数据受到保护', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                SizedBox(height: 4),
                Text('所有安全功能均已启用', style: TextStyle(fontSize: 13, color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _switchTile(String title, String desc, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(value: value, activeColor: AppColors.accent, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _arrowTile(String title, String desc, IconData icon) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _dangerTile(String title, String desc) {
    return InkWell(
      onTap: () => _showClearDialog(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.delete_forever, size: 18, color: AppColors.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: AppColors.danger, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16);
  }

  Widget _buildLogs() {
    return Column(
      children: _logs.map((log) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: Row(
            children: [
              Icon(log['icon'] as IconData, size: 16, color: log['color'] as Color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(log['action'] as String,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              ),
              Text(log['time'] as String,
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除所有数据', style: TextStyle(color: AppColors.danger)),
        content: const Text('此操作将永久删除所有本地数据，且无法恢复。确定继续吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('操作已取消（演示）'), duration: Duration(seconds: 1)),
              );
            },
            child: const Text('确定清除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
