import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';

/// 紧急设置页 - 对齐原型 EmergencySettingsPage
class EmergencySettingsPage extends StatefulWidget {
  const EmergencySettingsPage({super.key});

  @override
  State<EmergencySettingsPage> createState() => _EmergencySettingsPageState();
}

class _EmergencySettingsPageState extends State<EmergencySettingsPage> {
  bool _fallDetection = true;
  bool _inactivityAlert = true;
  bool _geofenceAlert = false;

  final List<Map<String, dynamic>> _contacts = [
    {'name': '张明', 'relation': '儿子', 'phone': '138****8888', 'priority': 1},
    {'name': '张丽', 'relation': '女儿', 'phone': '139****6666', 'priority': 2},
    {'name': '社区医院', 'relation': '急救', 'phone': '120', 'priority': 3},
  ];

  final List<Map<String, dynamic>> _geofences = [
    {'name': '家', 'address': '阳光小区3栋', 'radius': 200},
    {'name': '社区医院', 'address': '人民路120号', 'radius': 500},
  ];

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: '紧急设置',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('SOS紧急联系人优先级', _buildContactsList()),
          const SizedBox(height: 16),
          _buildSection('安全围栏', _buildGeofenceList()),
          const SizedBox(height: 16),
          _buildTestButton(),
          const SizedBox(height: 16),
          _buildSection('自动报警条件', _buildAutoAlerts()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        child,
      ],
    );
  }

  Widget _buildContactsList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: _contacts.map((c) {
          final priority = c['priority'] as int;
          Color color = priority == 1 ? AppColors.danger : (priority == 2 ? AppColors.warning : AppColors.info);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Text('${priority}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(c['name'] as String,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(width: 6),
                          Text(c['relation'] as String,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(c['phone'] as String,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.drag_handle, size: 18, color: AppColors.textTertiary),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGeofenceList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: _geofences.map((g) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: AppColors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g['name'] as String,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('${g['address']} · 半径${g['radius']}米',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已发送测试求助信号'), duration: Duration(seconds: 1)),
          );
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: AppColors.danger),
        ),
        icon: const Icon(Icons.sos, size: 18, color: AppColors.danger),
        label: const Text('一键求助测试', style: TextStyle(fontSize: 14, color: AppColors.danger, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildAutoAlerts() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _buildAlertSwitch('跌倒检测', '检测到跌倒时自动通知', Icons.accessibility_new, _fallDetection, (v) => setState(() => _fallDetection = v)),
          const Divider(height: 1, color: AppColors.border),
          _buildAlertSwitch('长时间未活动', '超过6小时无活动自动通知', Icons.hourglass_empty, _inactivityAlert, (v) => setState(() => _inactivityAlert = v)),
          const Divider(height: 1, color: AppColors.border),
          _buildAlertSwitch('离开围栏', '离开安全围栏范围时通知', Icons.location_searching, _geofenceAlert, (v) => setState(() => _geofenceAlert = v)),
        ],
      ),
    );
  }

  Widget _buildAlertSwitch(String title, String desc, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
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
}
