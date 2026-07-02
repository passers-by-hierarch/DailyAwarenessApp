import '../../domain/models/qa_source_record.dart';

/// 问答消息模型
class QaMessage {
  QaMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.sourceRecords,
    this.answerVoiceUrl,
    this.confidence = 0.0,
    this.sessionId,
    this.isProcessing = false,
  });

  factory QaMessage.user({
    required String content,
    String? sessionId,
  }) {
    return QaMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      sessionId: sessionId,
    );
  }

  factory QaMessage.assistant({
    required String content,
    List<QaSourceRecord>? sourceRecords,
    String? answerVoiceUrl,
    double confidence = 0.0,
    String? sessionId,
    bool isProcessing = false,
  }) {
    return QaMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      sourceRecords: sourceRecords,
      answerVoiceUrl: answerVoiceUrl,
      confidence: confidence,
      sessionId: sessionId,
      isProcessing: isProcessing,
    );
  }
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<QaSourceRecord>? sourceRecords;
  final String? answerVoiceUrl;
  final double confidence;
  final String? sessionId;
  final bool isProcessing;
}

/// 问答会话模型
class QaSession {
  QaSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.status = 'active',
    this.messageCount = 0,
  });

  factory QaSession.fromJson(Map<String, dynamic> json) {
    return QaSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
      messageCount: json['message_count'] as int? ?? 0,
    );
  }
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status;
  final int messageCount;
}

/// 问答历史记录模型
class QaHistory {
  QaHistory({
    required this.id,
    required this.question,
    this.questionType,
    required this.answer,
    required this.processingTime,
    required this.confidence,
    required this.createdAt,
    this.sourceRecords,
  });

  factory QaHistory.fromJson(Map<String, dynamic> json) {
    return QaHistory(
      id: json['id'] as String,
      question: json['question'] as String,
      questionType: json['question_type'] as String?,
      answer: json['answer'] as String,
      processingTime: json['processing_time'] as int? ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      sourceRecords: json['source_records'] != null
          ? (json['source_records'] as List)
              .map((e) => QaSourceRecord.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
  final String id;
  final String question;
  final String? questionType;
  final String answer;
  final int processingTime;
  final double confidence;
  final DateTime createdAt;
  final List<QaSourceRecord>? sourceRecords;
}
