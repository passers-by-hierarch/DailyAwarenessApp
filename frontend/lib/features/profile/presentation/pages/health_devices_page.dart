import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';

/// 健康设备页 - 对齐原型 HealthDevicesPage
class HealthDevicesPage extends StatelessWidget {
  const HealthDevicesPage({super.key});

  final List<Map<String, dynamic>> _connectedDevices = const [
    {
      'name': '华为手环7',
      'battery': 78,
      'lastSync': '刚刚',
      'types': ['步数', '心率', '睡眠', '血氧'],
    },
    {
      'name': '小米血压计',
      'battery': 45,
      'lastSync': '2小时前',
      'types': ['血压', '心率'],
    },
  ];

  final List<Map<String, dynamic>> _metrics = const [
    {'label': '步数', 'value': '6,542', 'unit': '步', 'icon': Icons.directions_walk, 'color': AppColors.accent, 'bg': AppColors.accentLight},
    {'label': '心率', 'value': '72', 'unit': 'bpm', 'icon': Icons.favorite, 'color': AppColors.danger, 'bg': AppColors.dangerLight},
    {'label': '血压', 'value': '120/80', 'unit': 'mmHg', 'icon': Icons.monitor_heart, 'color': AppColors.warning, 'bg': AppColors.warningLight},
    {'label': '睡眠', 'value': '7.5', 'unit': '小时', 'icon': Icons.bedtime, 'color': AppColors.purple, 'bg': AppColors.purpleLight},
  ];

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: '健康设备',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('已连接设备', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          ..._connectedDevices.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDeviceCard(d),
              )),
          const SizedBox(height: 16),
          const Text('可发现设备', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          _buildScanningCard(),
          const SizedBox(height: 16),
          const Text('最近同步数据', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemCount: _metrics.length,
            itemBuilder: (context, idx) => _buildMetricCard(_metrics[idx]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final battery = device['battery'] as int;
    final batteryColor = battery > 50 ? AppColors.success : (battery > 20 ? AppColors.warning : AppColors.danger);
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.watch, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device['name'] as String,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('同步于 ${device['lastSync']}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.battery_full, size: 14, color: batteryColor),
                  const SizedBox(width: 4),
                  Text('$battery%',
                      style: TextStyle(fontSize: 12, color: batteryColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (device['types'] as List<dynamic>).map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(t as String,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('正在扫描附近设备...',
                    style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                SizedBox(height: 2),
                Text('请确保设备蓝牙已开启', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('停止', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(Map<String, dynamic> m) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: m['bg'] as Color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(m['icon'] as IconData, size: 14, color: m['color'] as Color),
              const SizedBox(width: 4),
              Text(m['label'] as String,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(m['value'] as String,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: m['color'] as Color)),
              const SizedBox(width: 4),
              Text(m['unit'] as String,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
