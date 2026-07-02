class TimelineRecord {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String content;
  final String? behaviorTag;
  final String? voiceFileUrl;
  final int? voiceDuration;
  final String? matchedAgendaId;
  final double? matchScore;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimelineRecord({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.content,
    this.behaviorTag,
    this.voiceFileUrl,
    this.voiceDuration,
    this.matchedAgendaId,
    this.matchScore,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimelineRecord.fromJson(Map<String, dynamic> json) {
    return TimelineRecord(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      content: json['content'] ?? '',
      behaviorTag: json['behavior_tag'],
      voiceFileUrl: json['voice_file_url'],
      voiceDuration: json['voice_duration'],
      matchedAgendaId: json['matched_agenda_id'],
      matchScore: json['match_score']?.toDouble(),
      source: json['source'] ?? 'manual',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'content': content,
      'behavior_tag': behaviorTag,
      'voice_file_url': voiceFileUrl,
      'voice_duration': voiceDuration,
      'matched_agenda_id': matchedAgendaId,
      'match_score': matchScore,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TimelineRecord copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    String? content,
    String? behaviorTag,
    String? voiceFileUrl,
    int? voiceDuration,
    String? matchedAgendaId,
    double? matchScore,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimelineRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      content: content ?? this.content,
      behaviorTag: behaviorTag ?? this.behaviorTag,
      voiceFileUrl: voiceFileUrl ?? this.voiceFileUrl,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      matchedAgendaId: matchedAgendaId ?? this.matchedAgendaId,
      matchScore: matchScore ?? this.matchScore,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ApiResponse<T> {
  final int code;
  final String? message;
  final T? data;

  ApiResponse({
    required this.code,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? dataParser) {
    return ApiResponse<T>(
      code: json['code'] ?? 0,
      message: json['message'],
      data: json['data'] != null && dataParser != null
          ? dataParser(json['data'])
          : json['data'],
    );
  }
}
