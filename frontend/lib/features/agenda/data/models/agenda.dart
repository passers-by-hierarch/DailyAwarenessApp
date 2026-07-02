class Agenda {
  final String id;
  final String userId;
  final DateTime plannedTime;
  final String content;
  final String? behaviorTag;
  final String agendaType;
  final String status;
  final String? matchedTimelineId;
  final DateTime? matchedAt;
  final int remindOffset;
  final String remindLevel;
  final bool isRecurring;
  final String? recurringRule;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  Agenda({
    required this.id,
    required this.userId,
    required this.plannedTime,
    required this.content,
    this.behaviorTag,
    required this.agendaType,
    required this.status,
    this.matchedTimelineId,
    this.matchedAt,
    required this.remindOffset,
    required this.remindLevel,
    required this.isRecurring,
    this.recurringRule,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Agenda.fromJson(Map<String, dynamic> json) {
    return Agenda(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      plannedTime: DateTime.parse(json['planned_time'] ?? DateTime.now().toIso8601String()),
      content: json['content'] ?? '',
      behaviorTag: json['behavior_tag'],
      agendaType: json['agenda_type'] ?? 'fixed',
      status: json['status'] ?? 'pending',
      matchedTimelineId: json['matched_timeline_id'],
      matchedAt: json['matched_at'] != null
          ? DateTime.parse(json['matched_at'])
          : null,
      remindOffset: json['remind_offset'] ?? 5,
      remindLevel: json['remind_level'] ?? 'standard',
      isRecurring: json['is_recurring'] ?? false,
      recurringRule: json['recurring_rule'],
      source: json['source'] ?? 'manual',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'planned_time': plannedTime.toIso8601String(),
      'content': content,
      'behavior_tag': behaviorTag,
      'agenda_type': agendaType,
      'status': status,
      'matched_timeline_id': matchedTimelineId,
      'matched_at': matchedAt?.toIso8601String(),
      'remind_offset': remindOffset,
      'remind_level': remindLevel,
      'is_recurring': isRecurring,
      'recurring_rule': recurringRule,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Agenda copyWith({
    String? id,
    String? userId,
    DateTime? plannedTime,
    String? content,
    String? behaviorTag,
    String? agendaType,
    String? status,
    String? matchedTimelineId,
    DateTime? matchedAt,
    int? remindOffset,
    String? remindLevel,
    bool? isRecurring,
    String? recurringRule,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Agenda(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plannedTime: plannedTime ?? this.plannedTime,
      content: content ?? this.content,
      behaviorTag: behaviorTag ?? this.behaviorTag,
      agendaType: agendaType ?? this.agendaType,
      status: status ?? this.status,
      matchedTimelineId: matchedTimelineId ?? this.matchedTimelineId,
      matchedAt: matchedAt ?? this.matchedAt,
      remindOffset: remindOffset ?? this.remindOffset,
      remindLevel: remindLevel ?? this.remindLevel,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringRule: recurringRule ?? this.recurringRule,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BehaviorTag {
  final String key;
  final String label;
  final List<String> keywords;

  BehaviorTag({
    required this.key,
    required this.label,
    required this.keywords,
  });

  factory BehaviorTag.fromJson(Map<String, dynamic> json) {
    return BehaviorTag(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
