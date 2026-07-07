import 'package:flutter/material.dart';

/// 颜色定义 - 对齐 UI-Design-Detail-V2.md 设计规范
class AppColors {
  AppColors._();

  // 背景色
  static const Color bgPrimary = Color(0xFFF5F5F7);     // 页面主背景（浅灰）
  static const Color bgSecondary = Color(0xFFFFFFFF);   // 卡片背景、内容区背景
  static const Color bgTertiary = Color(0xFFF5F5F7);    // 次级背景、输入框背景、禁用态

  // 文字色
  static const Color textPrimary = Color(0xFF1D1D1F);   // 主文字、标题
  static const Color textSecondary = Color(0xFF86868B); // 次级文字、说明文字
  static const Color textTertiary = Color(0xFFC7C7CC);  // 辅助文字、占位符、禁用态

  // 边框与分割线
  static const Color border = Color(0xFFE5E5EA);        // 分割线、边框
  static const Color divider = Color(0xFFD1D1D6);

  // 品牌主色（iOS蓝）
  static const Color accent = Color(0xFF007AFF);        // 主操作按钮、导航选中态
  static const Color accentLight = Color(0xFFE8F4FD);   // 主色调浅色版，用于标签背景

  // 语音按钮渐变（蓝色系，与整体风格统一）
  static const Color voiceStart = Color(0xFF4A90D9);
  static const Color voiceEnd = Color(0xFF007AFF);

  // 功能色
  static const Color success = Color(0xFF007AFF);       // 成功/完成状态统一使用蓝色主色
  static const Color successLight = Color(0xFFE8F4FD);  // 蓝色浅色背景
  static const Color warning = Color(0xFFFF9500);       // 警告状态、待进行标记
  static const Color warningLight = Color(0xFFFFF3E0);  // 警告色浅色背景
  static const Color danger = Color(0xFFFF3B30);        // 危险操作、删除、必做事程
  static const Color dangerLight = Color(0xFFFFEBEE);   // 危险色浅色背景
  static const Color info = Color(0xFF5AC8FA);          // 信息提示、链接文字
  static const Color infoLight = Color(0xFFE3F2FD);     // 信息色浅色背景
  static const Color purple = Color(0xFF9333EA);        // 高频标签色
  static const Color purpleLight = Color(0xFFF3E8FF);   // 高频标签浅色背景

  // 渐变
  static const LinearGradient voiceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [voiceStart, voiceEnd], // 蓝色渐变
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A90D9), Color(0xFF007AFF)],
  );

  // 阴影 - 对齐设计文档
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)), // 0 2px 8px rgba(0,0,0,0.06)
  ];
  static List<BoxShadow> itemShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)), // 0 1px 3px rgba(0,0,0,0.04)
  ];
  static List<BoxShadow> buttonShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)), // 0 4px 16px rgba(0,0,0,0.08)
  ];
  static List<BoxShadow> fabShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // 标签颜色映射 - 统一蓝色系主色调
  static const Map<String, TagColorSet> tagColors = {
    'accent': TagColorSet(Color(0xFF007AFF), Color(0xFFE8F4FD)),
    'info': TagColorSet(Color(0xFF5AC8FA), Color(0xFFE3F2FD)),
    'warning': TagColorSet(Color(0xFFFF9500), Color(0xFFFFF3E0)),
    'success': TagColorSet(Color(0xFF007AFF), Color(0xFFE8F4FD)),
    'danger': TagColorSet(Color(0xFFFF3B30), Color(0xFFFFEBEE)),
    'gray': TagColorSet(Color(0xFFC7C7CC), Color(0xFFF5F5F7)),
    'purple': TagColorSet(Color(0xFF9333EA), Color(0xFFF3E8FF)),
  };
}

class TagColorSet {
  final Color color;
  final Color bg;
  const TagColorSet(this.color, this.bg);
}
