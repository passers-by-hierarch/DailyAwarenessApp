import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';

/// 偏好设置页 - 对齐原型 PreferencesPage
class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  int _themeMode = 0; // 0:浅色 1:深色 2:跟随系统
  int _fontSize = 1; // 0:小 1:中 2:大 3:特大
  double _volume = 70;
  int _startPage = 0; // 0:首页 1:事程 2:时间线

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: '偏好设置',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('显示设置', [
            _buildSubTitle('主题模式'),
            const SizedBox(height: 8),
            _buildSegmentedControl(['浅色', '深色', '跟随系统'], _themeMode, (i) => setState(() => _themeMode = i)),
            const SizedBox(height: 16),
            _buildSubTitle('字体大小'),
            const SizedBox(height: 8),
            _buildSegmentedControl(['小', '中', '大', '特大'], _fontSize, (i) => setState(() => _fontSize = i)),
          ]),
          const SizedBox(height: 16),
          _buildSection('声音设置', [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_up, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      const Text('提醒音量', style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('${_volume.round()}%', style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Slider(
                    value: _volume,
                    min: 0,
                    max: 100,
                    activeColor: AppColors.accent,
                    onChanged: (v) => setState(() => _volume = v),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('语言与地区', [
            _arrowTile('语言', '简体中文', Icons.language),
            _divider(),
            _arrowTile('时间格式', '24小时制', Icons.access_time),
            _divider(),
            _arrowTile('日期格式', 'YYYY-MM-DD', Icons.calendar_today_outlined),
          ]),
          const SizedBox(height: 16),
          _buildSection('提醒偏好', [
            _arrowTile('默认提前时间', '5 分钟', Icons.timer_outlined),
            _divider(),
            _arrowTile('重复间隔', '5 分钟', Icons.repeat),
            _divider(),
            _arrowTile('提醒铃声', '默认铃声', Icons.music_note),
          ]),
          const SizedBox(height: 16),
          _buildSection('起始页设置', [
            const SizedBox(height: 8),
            _buildSegmentedControl(['首页', '事程', '时间线'], _startPage, (i) => setState(() => _startPage = i)),
          ]),
          const SizedBox(height: 24),
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    );
  }

  Widget _buildSegmentedControl(List<String> options, int selected, ValueChanged<int> onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: options.asMap().entries.map((entry) {
          final idx = entry.key;
          final label = entry.value;
          final isSel = selected == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(idx),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSel ? AppColors.bgSecondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSel ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _arrowTile(String title, String value, IconData icon) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            ),
            Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16);
  }
}
