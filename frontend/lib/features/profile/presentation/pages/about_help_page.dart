import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';

/// 关于与帮助页 - 对齐原型 AboutHelpPage
class AboutHelpPage extends StatelessWidget {
  const AboutHelpPage({super.key});

  final List<Map<String, dynamic>> _quickHelp = const [
    {'title': '使用指南', 'icon': Icons.menu_book, 'color': AppColors.accent, 'bg': AppColors.accentLight},
    {'title': '视频教程', 'icon': Icons.play_circle_outline, 'color': AppColors.info, 'bg': AppColors.infoLight},
  ];

  final List<Map<String, String>> _faq = const [
    {'q': '如何添加事程提醒？', 'a': '进入"事程"页面，点击右上角"+"按钮，填写时间、内容和图标即可。也可以通过语音输入，系统会自动识别并创建。'},
    {'q': '如何绑定家属？', 'a': '进入"我的"-"家属管理"，点击右上角"邀请"按钮，输入家属手机号即可发送邀请。'},
    {'q': '语音识别准确率如何提高？', 'a': '在安静环境下说话，语句尽量清晰完整。系统会持续学习您的语音习惯以提高识别准确率。'},
    {'q': '数据是否安全？', 'a': '所有数据均经过加密存储，并支持本地和云端双重备份。您可以随时在"隐私与安全"中管理数据权限。'},
  ];

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: '关于与帮助',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAppInfoCard(),
          const SizedBox(height: 16),
          _buildQuickHelp(),
          const SizedBox(height: 16),
          _buildFaq(),
          const SizedBox(height: 16),
          _buildContact(),
          const SizedBox(height: 16),
          _buildLegal(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),
          const Text('生活助手', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('版本 1.0.0 (Build 20260701)',
              style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildQuickHelp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('快速帮助', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        Row(
          children: _quickHelp.map((h) {
            return Expanded(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: h['bg'] as Color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(h['icon'] as IconData, size: 28, color: h['color'] as Color),
                      const SizedBox(height: 8),
                      Text(h['title'] as String,
                          style: TextStyle(fontSize: 13, color: h['color'] as Color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFaq() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('常见问题', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: _faq.map((f) => _buildFaqItem(f['q']!, f['a']!)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(String q, String a) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Text(q, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      iconColor: AppColors.textTertiary,
      collapsedIconColor: AppColors.textTertiary,
      children: [
        Text(a, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
      ],
    );
  }

  Widget _buildContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('联系我们', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _contactTile(Icons.mail_outline, '邮件', 'support@daily-awareness.com'),
              const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
              _contactTile(Icons.chat_outlined, '在线客服', '工作日 9:00-18:00'),
              const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
              _contactTile(Icons.phone_outlined, '客服热线', '400-888-0000'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactTile(IconData icon, String title, String value) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ),
            Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildLegal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('法律信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _legalTile('隐私政策'),
              const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
              _legalTile('用户协议'),
              const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
              _legalTile('开源许可证'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legalTile(String title) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
