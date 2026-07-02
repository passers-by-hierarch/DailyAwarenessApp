import 'package:flutter/material.dart';

/// 检索记录模型 - 用于展示生成回答的相关记忆记录
class QaSourceRecord {
  // 额外元数据

  const QaSourceRecord({
    required this.id,
    required this.timestamp,
    required this.content,
    required this.recordType,
    required this.relevanceScore,
    this.behaviorTag,
    this.sourceName,
    this.metadata,
  });

  /// 从JSON反序列化
  factory QaSourceRecord.fromJson(Map<String, dynamic> json) {
    return QaSourceRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      content: json['content'] as String,
      recordType: json['record_type'] as String,
      relevanceScore: (json['relevance_score'] as num).toDouble(),
      behaviorTag: json['behavior_tag'] as String?,
      sourceName: json['source_name'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  final String id;
  final DateTime timestamp;
  final String content;
  final String recordType; // 'timeline' | 'item' | 'knowledge' | 'agenda'
  final double relevanceScore; // 相关性评分 0-1
  final String? behaviorTag; // 行为标签（可选）
  final String? sourceName; // 来源名称
  final Map<String, dynamic>? metadata;

  /// 获取记录类型的显示名称
  String get recordTypeLabel {
    switch (recordType) {
      case 'timeline':
        return '时间线记录';
      case 'item':
        return '物品位置';
      case 'knowledge':
        return '知识条目';
      case 'agenda':
        return '计划事程';
      default:
        return '记忆记录';
    }
  }

  /// 获取相关性评分颜色
  Color get relevanceColor {
    if (relevanceScore >= 0.8) return const Color(0xFF6B9E75);
    if (relevanceScore >= 0.5) return const Color(0xFFD4A574);
    return const Color(0xFF8A8A8A);
  }

  /// 格式化时间戳
  String get formattedTimestamp {
    return '${timestamp.month}月${timestamp.day}日 ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
