import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';

/// 报告导出页 - 对齐原型 ReportExportPage
class ReportExportPage extends StatefulWidget {
  const ReportExportPage({super.key});

  @override
  State<ReportExportPage> createState() => _ReportExportPageState();
}

class _ReportExportPageState extends State<ReportExportPage> {
  int _reportType = 0; // 0:周报 1:月报 2:行为报告 3:事程报告
  int _format = 0; // 0:PDF 1:Excel 2:Word
  bool _includeCharts = true;
  bool _includeTimeline = false;
  bool _desensitize = true;

  final List<Map<String, dynamic>> _history = [
    {'type': '周报', 'date': '2026-06-28', 'size': '2.4MB', 'format': 'PDF'},
    {'type': '月报', 'date': '2026-06-30', 'size': '5.1MB', 'format': 'Excel'},
    {'type': '行为报告', 'date': '2026-06-15', 'size': '1.8MB', 'format': 'PDF'},
  ];

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: '报告导出',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection('报告类型', _buildReportTypes()),
                const SizedBox(height: 16),
                _buildSection('导出格式', _buildFormats()),
                const SizedBox(height: 16),
                _buildSection('导出选项', _buildOptions()),
                const SizedBox(height: 16),
                _buildSection('导出历史', _buildHistory()),
                const SizedBox(height: 16),
              ],
            ),
          ),
          _buildGenerateButton(),
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

  Widget _buildReportTypes() {
    final types = [
      {'label': '周报', 'icon': Icons.calendar_view_week, 'desc': '最近7天'},
      {'label': '月报', 'icon': Icons.calendar_month, 'desc': '最近30天'},
      {'label': '行为报告', 'icon': Icons.insights, 'desc': '行为习惯分析'},
      {'label': '事程报告', 'icon': Icons.checklist, 'desc': '事程完成情况'},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3.5,
      ),
      itemCount: types.length,
      itemBuilder: (context, idx) {
        final t = types[idx];
        final selected = _reportType == idx;
        return GestureDetector(
          onTap: () => setState(() => _reportType = idx),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.accentLight : AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? AppColors.accent : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(t['icon'] as IconData,
                    size: 20, color: selected ? AppColors.accent : AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t['label'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: selected ? AppColors.accent : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          )),
                      Text(t['desc'] as String,
                          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormats() {
    final formats = ['PDF', 'Excel', 'Word'];
    return Row(
      children: formats.asMap().entries.map((entry) {
        final idx = entry.key;
        final f = entry.value;
        final selected = _format == idx;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _format = idx),
            child: Container(
              margin: EdgeInsets.only(right: idx < formats.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentLight : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? AppColors.accent : AppColors.border),
              ),
              child: Text(f,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? AppColors.accent : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptions() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _switchTile('包含图表', '在报告中嵌入可视化图表', _includeCharts, (v) => setState(() => _includeCharts = v)),
          const Divider(height: 1, color: AppColors.border),
          _switchTile('包含时间线', '导出原始时间线记录', _includeTimeline, (v) => setState(() => _includeTimeline = v)),
          const Divider(height: 1, color: AppColors.border),
          _switchTile('脱敏处理', '隐藏敏感个人信息', _desensitize, (v) => setState(() => _desensitize = v)),
        ],
      ),
    );
  }

  Widget _switchTile(String title, String desc, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
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

  Widget _buildHistory() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: _history.map((h) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined, size: 16, color: AppColors.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${h['type']} · ${h['format']}',
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('${h['date']} · ${h['size']}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                const Icon(Icons.download_outlined, size: 18, color: AppColors.accent),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('报告生成中，完成后将保存到导出历史'), duration: Duration(seconds: 2)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text('生成报告', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
