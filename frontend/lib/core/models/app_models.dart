/// 数据模型定义 - 对齐 Web 原型 appStore.ts

enum TimelineType { behavior, item, shopping, event }

enum AgendaStatus { pending, completed, skipped, postponed, expired }

class Range {
  final int start;
  final int end;
  const Range(this.start, this.end);
}

enum AgendaLevel { normal, important, mustDo }

enum NoteType { voice, text }

enum AgendaSource { user, ai }

enum TimeSource { userSpecified, history, commonSense, current }

enum AgendaCategory { dailyMustDo, frequent, temporary, custom }

class TagDef {
  final String id;
  final String name;
  final String color; // accent/info/warning/success/danger/gray/purple
  final String icon; // emoji 或 lucide 图标名
  final bool system;

  const TagDef({
    required this.id,
    required this.name,
    required this.color,
    this.icon = '#',
    this.system = false,
  });

  static const List<TagDef> systemTags = [
    TagDef(id: 'behavior', name: '行为活动', color: 'accent', icon: 'activity', system: true),
    TagDef(id: 'item', name: '物品位置', color: 'info', icon: 'package', system: true),
    TagDef(id: 'shopping', name: '购物记录', color: 'warning', icon: 'shopping_cart', system: true),
    TagDef(id: 'event', name: '日常事件', color: 'success', icon: 'map_pin', system: true),
  ];
}

class NoteEntry {
  final String id;
  final String content;
  final DateTime time;
  final NoteType type;

  const NoteEntry({
    required this.id,
    required this.content,
    required this.time,
    this.type = NoteType.text,
  });
}

/// 意图识别后的结构化数据（用于详情页展示）
class IntentData {
  final String intentType; // behavior/shopping/item_location/agenda_create/inventory_consume
  final String displayName; // 展示名称
  final Map<String, dynamic> slots; // 槽值

  const IntentData({
    required this.intentType,
    required this.displayName,
    this.slots = const {},
  });
}

class SideEffects {
  final ShoppingRecord? shoppingRecord;
  final ItemUpdate? itemUpdate;
  final String? agenda;
  final List<String>? agendaList;
  final InventoryUpdate? inventoryUpdate;
  final IntentData? intentData; // 意图识别结构化数据

  const SideEffects({
    this.shoppingRecord,
    this.itemUpdate,
    this.agenda,
    this.agendaList,
    this.inventoryUpdate,
    this.intentData,
  });

  SideEffects copyWith({
    ShoppingRecord? shoppingRecord,
    ItemUpdate? itemUpdate,
    String? agenda,
    List<String>? agendaList,
    InventoryUpdate? inventoryUpdate,
    IntentData? intentData,
  }) {
    return SideEffects(
      shoppingRecord: shoppingRecord ?? this.shoppingRecord,
      itemUpdate: itemUpdate ?? this.itemUpdate,
      agenda: agenda ?? this.agenda,
      agendaList: agendaList ?? this.agendaList,
      inventoryUpdate: inventoryUpdate ?? this.inventoryUpdate,
      intentData: intentData ?? this.intentData,
    );
  }
}

class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final String unit;
  final double? price;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.unit = '个',
    this.price,
  });
}

class ShoppingRecord {
  final String id;
  final String store;
  final List<ShoppingItem> items;
  final DateTime time;
  final double? total;

  const ShoppingRecord({
    required this.id,
    required this.store,
    required this.items,
    required this.time,
    this.total,
  });
}

class ItemUpdate {
  final String name;
  final String location;
  const ItemUpdate({required this.name, required this.location});
}

class TimelineRecord {
  final String id;
  final String content;
  final DateTime time;
  final TimelineType type;
  final List<String> tags;
  final String? matchedAgenda;
  final String? linkedAgendaId;
  final List<NoteEntry> notes;
  final SideEffects? sideEffects;
  final bool deleted;

  // 派生：日期 key YYYY-MM-DD
  String get date =>
      '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  // 派生：时间 HH:mm
  String get timeStr =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  const TimelineRecord({
    required this.id,
    required this.content,
    required this.time,
    this.type = TimelineType.behavior,
    this.tags = const ['behavior'],
    this.matchedAgenda,
    this.linkedAgendaId,
    this.notes = const [],
    this.sideEffects,
    this.deleted = false,
  });

  TimelineRecord copyWith({
    String? id,
    String? content,
    DateTime? time,
    TimelineType? type,
    List<String>? tags,
    String? matchedAgenda,
    String? linkedAgendaId,
    List<NoteEntry>? notes,
    SideEffects? sideEffects,
    bool? deleted,
  }) {
    return TimelineRecord(
      id: id ?? this.id,
      content: content ?? this.content,
      time: time ?? this.time,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      matchedAgenda: matchedAgenda ?? this.matchedAgenda,
      linkedAgendaId: linkedAgendaId ?? this.linkedAgendaId,
      notes: notes ?? this.notes,
      sideEffects: sideEffects ?? this.sideEffects,
      deleted: deleted ?? this.deleted,
    );
  }
}

class AgendaItem {
  final String id;
  final String content;
  final String time; // HH:mm
  final String date; // YYYY-MM-DD
  final AgendaStatus status;
  final bool isMustDo;
  final AgendaLevel level;
  final String icon;
  final List<String> repeat; // ['Mon','Tue',...]
  final int? advanceReminder; // 分钟
  final bool isHighFrequency;
  final AgendaSource source;
  final String? matchedTimeline;
  final String? note;
  final String? remainingTime;
  final AgendaCategory category;

  const AgendaItem({
    required this.id,
    required this.content,
    required this.time,
    required this.date,
    this.status = AgendaStatus.pending,
    this.isMustDo = false,
    this.level = AgendaLevel.normal,
    this.icon = '📋',
    this.repeat = const [],
    this.advanceReminder,
    this.isHighFrequency = false,
    this.source = AgendaSource.user,
    this.matchedTimeline,
    this.note,
    this.remainingTime,
    this.category = AgendaCategory.custom,
  });

  AgendaItem copyWith({
    String? id,
    String? content,
    String? time,
    String? date,
    AgendaStatus? status,
    bool? isMustDo,
    AgendaLevel? level,
    String? icon,
    List<String>? repeat,
    int? advanceReminder,
    bool? isHighFrequency,
    AgendaSource? source,
    String? matchedTimeline,
    String? note,
    String? remainingTime,
    AgendaCategory? category,
  }) {
    return AgendaItem(
      id: id ?? this.id,
      content: content ?? this.content,
      time: time ?? this.time,
      date: date ?? this.date,
      status: status ?? this.status,
      isMustDo: isMustDo ?? this.isMustDo,
      level: level ?? this.level,
      icon: icon ?? this.icon,
      repeat: repeat ?? this.repeat,
      advanceReminder: advanceReminder ?? this.advanceReminder,
      isHighFrequency: isHighFrequency ?? this.isHighFrequency,
      source: source ?? this.source,
      matchedTimeline: matchedTimeline ?? this.matchedTimeline,
      note: note ?? this.note,
      remainingTime: remainingTime ?? this.remainingTime,
      category: category ?? this.category,
    );
  }
}

class AgendaRecommendation {
  final String id;
  final String content;
  final String time;
  final String source; // history / common-sense
  final int frequency;
  final String avgTime;
  final double confidence;

  const AgendaRecommendation({
    required this.id,
    required this.content,
    required this.time,
    required this.source,
    this.frequency = 0,
    this.avgTime = '',
    this.confidence = 0.5,
  });
}

class PendingAgendaItem {
  final String id;
  final String content;
  final String suggestedTime;
  final String suggestedDate;
  final TimeSource timeSource;
  final List<String>? keywords;

  const PendingAgendaItem({
    required this.id,
    required this.content,
    required this.suggestedTime,
    required this.suggestedDate,
    this.timeSource = TimeSource.current,
    this.keywords,
  });
}

class ChatMessage {
  final String id;
  final String role; // user / assistant
  final String content;
  final DateTime time;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.time,
  });
}

class QuickQuestion {
  final String id;
  final String text;
  final String? category;
  const QuickQuestion({required this.id, required this.text, this.category});
}

class StatsData {
  final int completionRate;
  final List<List<int>> heatmap; // [行为][7天]
  final List<NameCount> topRegular;
  final List<NameCount> topMissed;

  const StatsData({
    this.completionRate = 87,
    this.heatmap = const [],
    this.topRegular = const [],
    this.topMissed = const [],
  });
}

class NameCount {
  final String name;
  final int count;
  const NameCount({required this.name, required this.count});
}

class Suggestion {
  final String id;
  final String text;
  const Suggestion({required this.id, required this.text});
}

class MenuItem {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final String route;

  const MenuItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.color = 'accent',
    required this.route,
  });
}

class FrequentAgenda {
  final String id;
  final String content;
  final String avgTime;
  final int consecutiveDays;
  final int matchRate;
  final String icon;

  const FrequentAgenda({
    required this.id,
    required this.content,
    required this.avgTime,
    this.consecutiveDays = 0,
    this.matchRate = 0,
    this.icon = '📋',
  });
}

class ItemRecord {
  final String id;
  final String name;
  final String location;
  final List<String> tags;
  final String? photo;
  final List<LocationHistory> history;

  const ItemRecord({
    required this.id,
    required this.name,
    required this.location,
    this.tags = const [],
    this.photo,
    this.history = const [],
  });
}

class LocationHistory {
  final String id;
  final String location;
  final DateTime time;
  const LocationHistory({required this.id, required this.location, required this.time});
}

class InventoryItem {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final DateTime lastUpdated;
  final DateTime? expireDate;
  final List<InventoryLog> logs;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.unit = '个',
    this.category = '其他',
    required this.lastUpdated,
    this.expireDate,
    this.logs = const [],
  });

  InventoryItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    String? category,
    DateTime? lastUpdated,
    DateTime? expireDate,
    List<InventoryLog>? logs,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      expireDate: expireDate ?? this.expireDate,
      logs: logs ?? this.logs,
    );
  }
}

class InventoryLog {
  final String id;
  final double change;
  final String reason;
  final DateTime time;
  const InventoryLog({
    required this.id,
    required this.change,
    required this.reason,
    required this.time,
  });
}

class InventoryUpdate {
  final String name;
  final double quantityChange;
  final String unit;
  final String reason;
  const InventoryUpdate({
    required this.name,
    required this.quantityChange,
    required this.unit,
    this.reason = '',
  });
}

/// 用户档案（个性化建议用）
class UserProfile {
  final String name;
  final int age;
  final String gender; // 'male' / 'female'
  final List<String> healthConditions; // 健康状况：高血压、糖尿病等
  final List<String> preferences; // 偏好：温和运动、室内活动等
  final DateTime createdAt;

  const UserProfile({
    this.name = '用户',
    this.age = 65,
    this.gender = 'male',
    this.healthConditions = const ['高血压'],
    this.preferences = const ['温和运动'],
    required this.createdAt,
  });

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    List<String>? healthConditions,
    List<String>? preferences,
    DateTime? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      healthConditions: healthConditions ?? this.healthConditions,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isElderly => age >= 65;
  bool get hasHypertension => healthConditions.contains('高血压');
  bool get hasDiabetes => healthConditions.contains('糖尿病');
}

/// 计划模板
class PlanTemplate {
  final String id;
  final String name;
  final String icon;
  final List<String> steps;
  final List<String> suggestedTimes;
  final String estimatedDuration;
  final List<String> tips;
  final String category;

  const PlanTemplate({
    required this.id,
    required this.name,
    this.icon = '📋',
    required this.steps,
    required this.suggestedTimes,
    required this.estimatedDuration,
    required this.tips,
    this.category = '其他',
  });
}

/// 习惯徽章
class HabitBadge {
  final String id;
  final String name;
  final String icon;
  final int requiredDays; // 连续多少天获得
  final String description;

  const HabitBadge({
    required this.id,
    required this.name,
    required this.icon,
    required this.requiredDays,
    required this.description,
  });
}

/// 对话上下文（多轮对话用）
class ConversationContext {
  final String? currentTopic; // 当前讨论主题：plan/habit/inventory/none
  final Map<String, dynamic>? planData;
  final Map<String, dynamic>? habitData;
  final String? lastQuestion;
  final DateTime? lastUpdated;

  const ConversationContext({
    this.currentTopic,
    this.planData,
    this.habitData,
    this.lastQuestion,
    this.lastUpdated,
  });

  ConversationContext copyWith({
    String? currentTopic,
    Map<String, dynamic>? planData,
    Map<String, dynamic>? habitData,
    String? lastQuestion,
    DateTime? lastUpdated,
  }) {
    return ConversationContext(
      currentTopic: currentTopic ?? this.currentTopic,
      planData: planData ?? this.planData,
      habitData: habitData ?? this.habitData,
      lastQuestion: lastQuestion ?? this.lastQuestion,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isActive => lastUpdated != null &&
      DateTime.now().difference(lastUpdated!).inMinutes < 5;
}

/// 晚下班检测结果
class LateOffWorkResult {
  final bool isLate;
  final String avgOffWorkTime;  // 历史平均下班时间 HH:MM
  final String currentTime;     // 当前时间 HH:MM
  final int delayMinutes;       // 延迟分钟数
  final List<AgendaItem> affectedAgendas; // 受影响的待办事程

  const LateOffWorkResult({
    required this.isLate,
    required this.avgOffWorkTime,
    required this.currentTime,
    required this.delayMinutes,
    required this.affectedAgendas,
  });
}
