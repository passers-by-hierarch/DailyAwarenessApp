import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../mock/mock_data.dart';

/// 本地数据持久化服务
/// 使用 SharedPreferences 存储 JSON 字符串
class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  SharedPreferences? _prefs;

  // 存储键
  static const _kTimeline = 'timeline_records';
  static const _kAgenda = 'agenda_items';
  static const _kShopping = 'shopping_records';
  static const _kItems = 'item_records';
  static const _kInventory = 'inventory_items';
  static const _kCustomTags = 'custom_tags';
  static const _kChatMessages = 'chat_messages';
  static const _kEarnedBadges = 'earned_badges';
  static const _kUserProfile = 'user_profile';
  static const _kReminderRules = 'reminder_rules';
  static const _kQuietHours = 'quiet_hours';
  static const _kInitialized = 'initialized';
  static const _kQuestionFrequency = 'question_frequency';
  static const _kTimePatterns = 'time_patterns';
  static const _kPendingAgenda = 'pending_agenda';
  static const _kDisabledHighFreq = 'disabled_high_freq';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('StorageService 未初始化，请先调用 init()');
    }
    return _prefs!;
  }

  bool get isInitialized => prefs.getBool(_kInitialized) ?? false;

  /// 标记已初始化
  Future<void> markInitialized() async {
    await prefs.setBool(_kInitialized, true);
  }

  /// 保存时间线记录
  Future<void> saveTimeline(List<TimelineRecord> records) async {
    final jsonList = records.map(_timelineToJson).toList();
    await prefs.setString(_kTimeline, jsonEncode(jsonList));
  }

  List<TimelineRecord> loadTimeline() {
    final str = prefs.getString(_kTimeline);
    if (str == null) return MockData.mockTimelineRecords;
    try {
      final list = jsonDecode(str) as List;
      final results = <TimelineRecord>[];
      for (final j in list) {
        try {
          results.add(_timelineFromJson(j as Map<String, dynamic>));
        } catch (_) {
          // 跳过损坏的单条记录，保留其余
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// 保存事程
  Future<void> saveAgenda(List<AgendaItem> items) async {
    final jsonList = items.map(_agendaToJson).toList();
    await prefs.setString(_kAgenda, jsonEncode(jsonList));
  }

  List<AgendaItem> loadAgenda() {
    final str = prefs.getString(_kAgenda);
    if (str == null) return MockData.mockAgendaItems;
    try {
      final list = jsonDecode(str) as List;
      final results = <AgendaItem>[];
      for (final j in list) {
        try {
          results.add(_agendaFromJson(j as Map<String, dynamic>));
        } catch (_) {
          // 跳过损坏的单条记录
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// 保存购物记录
  Future<void> saveShopping(List<ShoppingRecord> records) async {
    final jsonList = records.map(_shoppingToJson).toList();
    await prefs.setString(_kShopping, jsonEncode(jsonList));
  }

  List<ShoppingRecord> loadShopping() {
    final str = prefs.getString(_kShopping);
    if (str == null) return MockData.mockShoppingRecords;
    try {
      final list = jsonDecode(str) as List;
      final results = <ShoppingRecord>[];
      for (final j in list) {
        try {
          results.add(_shoppingFromJson(j as Map<String, dynamic>));
        } catch (_) {}
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// 保存物品记录
  Future<void> saveItems(List<ItemRecord> items) async {
    final jsonList = items.map(_itemToJson).toList();
    await prefs.setString(_kItems, jsonEncode(jsonList));
  }

  List<ItemRecord> loadItems() {
    final str = prefs.getString(_kItems);
    if (str == null) return MockData.mockItems;
    try {
      final list = jsonDecode(str) as List;
      final results = <ItemRecord>[];
      for (final j in list) {
        try {
          results.add(_itemFromJson(j as Map<String, dynamic>));
        } catch (_) {}
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// 保存库存
  Future<void> saveInventory(List<InventoryItem> items) async {
    final jsonList = items.map(_inventoryToJson).toList();
    await prefs.setString(_kInventory, jsonEncode(jsonList));
  }

  List<InventoryItem> loadInventory() {
    final str = prefs.getString(_kInventory);
    if (str == null) return MockData.mockInventory;
    try {
      final list = jsonDecode(str) as List;
      final results = <InventoryItem>[];
      for (final j in list) {
        try {
          results.add(_inventoryFromJson(j as Map<String, dynamic>));
        } catch (_) {}
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// 保存自定义标签
  Future<void> saveCustomTags(List<TagDef> tags) async {
    final jsonList = tags.map(_tagToJson).toList();
    await prefs.setString(_kCustomTags, jsonEncode(jsonList));
  }

  List<TagDef> loadCustomTags() {
    final str = prefs.getString(_kCustomTags);
    if (str == null) return MockData.mockCustomTags;
    try {
      final list = jsonDecode(str) as List;
      final results = <TagDef>[];
      for (final j in list) {
        try {
          results.add(_tagFromJson(j as Map<String, dynamic>));
        } catch (_) {}
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// 保存聊天记录
  Future<void> saveChatMessages(List<ChatMessage> messages) async {
    final jsonList = messages.map(_chatMessageToJson).toList();
    await prefs.setString(_kChatMessages, jsonEncode(jsonList));
  }

  List<ChatMessage> loadChatMessages() {
    final str = prefs.getString(_kChatMessages);
    if (str == null) return MockData.mockChatMessages;
    try {
      final list = jsonDecode(str) as List;
      final results = <ChatMessage>[];
      for (final j in list) {
        try {
          results.add(_chatMessageFromJson(j as Map<String, dynamic>));
        } catch (_) {}
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// 保存已获得徽章
  Future<void> saveEarnedBadges(List<String> badgeIds) async {
    await prefs.setStringList(_kEarnedBadges, badgeIds);
  }

  List<String> loadEarnedBadges() {
    return prefs.getStringList(_kEarnedBadges) ?? [];
  }

  /// 保存用户档案
  Future<void> saveUserProfile(UserProfile profile) async {
    await prefs.setString(_kUserProfile, jsonEncode(_userProfileToJson(profile)));
  }

  UserProfile loadUserProfile() {
    final str = prefs.getString(_kUserProfile);
    if (str == null) return MockData.mockUserProfile;
    try {
      return _userProfileFromJson(jsonDecode(str) as Map<String, dynamic>);
    } catch (_) {
      return MockData.mockUserProfile;
    }
  }

  // 注：UserProfile 为单对象，解析失败时返回 Mock 是安全的（不会覆盖，
  // 因为下次保存时会写入正确的数据）。列表类型则改为返回空列表。

  /// 保存提醒规则
  Future<void> saveReminderRules(Map<String, dynamic> rules) async {
    await prefs.setString(_kReminderRules, jsonEncode(rules));
  }

  Map<String, dynamic> loadReminderRules() {
    final str = prefs.getString(_kReminderRules);
    if (str == null) return _defaultReminderRules();
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return _defaultReminderRules();
    }
  }

  Map<String, dynamic> _defaultReminderRules() {
    return {
      'normal': {'advanceMinutes': 10, 'repeatCount': 1, 'repeatInterval': 5, 'allowPostpone': true, 'allowSkip': true, 'enabled': true, 'streakUpgradeDays': 7, 'failDemotionThreshold': 3, 'timeDeviationMinutes': 30},
      'important': {'advanceMinutes': 30, 'repeatCount': 3, 'repeatInterval': 5, 'allowPostpone': true, 'allowSkip': true, 'enabled': true, 'streakUpgradeDays': 7, 'failDemotionThreshold': 3, 'timeDeviationMinutes': 30},
      'mustDoShort': {
        'advanceMinutes': 30,
        'repeatCount': 5,
        'repeatInterval': 2,
        'allowPostpone': false,
        'allowSkip': false,
        'enabled': true,
        'stagesEnabled': true,
        'stages': [-30, -10, 0, 10],
        'streakUpgradeDays': 7,
        'failDemotionThreshold': 3,
        'timeDeviationMinutes': 30,
      },
      'mustDoLong': {
        'advanceMinutes': 60,
        'repeatCount': 3,
        'repeatInterval': 10,
        'allowPostpone': true,
        'allowSkip': false,
        'enabled': true,
        'stagesEnabled': true,
        'stages': [-60, -30, 0, 30],
        'streakUpgradeDays': 7,
        'failDemotionThreshold': 3,
        'timeDeviationMinutes': 30,
      },
    };
  }

  /// 保存免打扰时段
  Future<void> saveQuietHours(Map<String, dynamic> hours) async {
    await prefs.setString(_kQuietHours, jsonEncode(hours));
  }

  Map<String, dynamic> loadQuietHours() {
    final str = prefs.getString(_kQuietHours);
    if (str == null) return {'enabled': true, 'start': '22:00', 'end': '08:00'};
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return {'enabled': true, 'start': '22:00', 'end': '08:00'};
    }
  }

  /// 保存问题频率统计
  Future<void> saveQuestionFrequency(Map<String, int> frequency) async {
    await prefs.setString(_kQuestionFrequency, jsonEncode(frequency));
  }

  /// 加载问题频率统计
  Map<String, dynamic>? loadQuestionFrequency() {
    final str = prefs.getString(_kQuestionFrequency);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 清空所有数据
  Future<void> clearAll() async {
    await prefs.remove(_kTimeline);
    await prefs.remove(_kAgenda);
    await prefs.remove(_kShopping);
    await prefs.remove(_kItems);
    await prefs.remove(_kInventory);
    await prefs.remove(_kCustomTags);
    await prefs.remove(_kChatMessages);
    await prefs.remove(_kEarnedBadges);
    await prefs.remove(_kUserProfile);
    await prefs.remove(_kReminderRules);
    await prefs.remove(_kQuietHours);
    await prefs.remove(_kInitialized);
    await prefs.remove(_kTimePatterns);
    await prefs.remove(_kPendingAgenda);
    await prefs.remove(_kDisabledHighFreq);
  }

  /// 保存时间模式（用于晚下班检测等）
  Future<void> saveTimePatterns(Map<String, List<String>> patterns) async {
    final jsonMap = patterns.map((k, v) => MapEntry(k, v));
    await prefs.setString(_kTimePatterns, jsonEncode(jsonMap));
  }

  Map<String, List<String>> loadTimePatterns() {
    final str = prefs.getString(_kTimePatterns);
    if (str == null) return {};
    try {
      final decoded = jsonDecode(str) as Map<String, dynamic>;
      return decoded.map((k, v) =>
          MapEntry(k, List<String>.from(v as List)));
    } catch (_) {
      return {};
    }
  }

  /// 保存待确认事程
  Future<void> savePendingAgenda(List<dynamic> items) async {
    final jsonList = items.map((item) {
      if (item is PendingAgendaItem) {
        return {
          'id': item.id,
          'content': item.content,
          'suggestedTime': item.suggestedTime,
          'suggestedDate': item.suggestedDate,
          'timeSource': item.timeSource.name,
          'keywords': item.keywords,
        };
      }
      return item;
    }).toList();
    await prefs.setString(_kPendingAgenda, jsonEncode(jsonList));
  }

  List<dynamic> loadPendingAgenda() {
    final str = prefs.getString(_kPendingAgenda);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List;
      return list.map((j) => PendingAgendaItem(
        id: j['id'] ?? '',
        content: j['content'] ?? '',
        suggestedTime: j['suggestedTime'] ?? '',
        suggestedDate: j['suggestedDate'] ?? '',
        timeSource: TimeSource.values.firstWhere(
          (t) => t.name == j['timeSource'],
          orElse: () => TimeSource.current,
        ),
        keywords: j['keywords'] != null ? List<String>.from(j['keywords']) : null,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  /// 保存禁用的高频事程
  Future<void> saveDisabledHighFreq(List<String> items) async {
    await prefs.setStringList(_kDisabledHighFreq, items);
  }

  List<String> loadDisabledHighFreq() {
    return prefs.getStringList(_kDisabledHighFreq) ?? [];
  }

  // ===== JSON 转换工具方法 =====
  Map<String, dynamic> _timelineToJson(TimelineRecord r) => {
    'id': r.id,
    'time': r.time.toIso8601String(),
    'content': r.content,
    'type': r.type.name,
    'tags': r.tags,
    'matchedAgenda': r.matchedAgenda,
    'notes': r.notes.map((n) => {
      'id': n.id, 'content': n.content, 'time': n.time.toIso8601String(),
      'type': n.type.name,
    }).toList(),
    'deleted': r.deleted,
    'sideEffects': _sideEffectsToJson(r.sideEffects),
  };

  Map<String, dynamic>? _sideEffectsToJson(SideEffects? se) {
    if (se == null) return null;
    return {
      'shoppingRecord': se.shoppingRecord != null ? _shoppingRecordToJson(se.shoppingRecord!) : null,
      'itemUpdate': se.itemUpdate != null ? {
        'name': se.itemUpdate!.name,
        'location': se.itemUpdate!.location,
      } : null,
      'agenda': se.agenda,
      'agendaList': se.agendaList,
      'inventoryUpdate': se.inventoryUpdate != null ? {
        'name': se.inventoryUpdate!.name,
        'quantityChange': se.inventoryUpdate!.quantityChange,
        'unit': se.inventoryUpdate!.unit,
        'reason': se.inventoryUpdate!.reason,
      } : null,
    };
  }

  Map<String, dynamic> _shoppingRecordToJson(ShoppingRecord r) => {
    'id': r.id,
    'store': r.store,
    'items': r.items.map((i) => {
      'id': i.id,
      'name': i.name,
      'quantity': i.quantity,
      'unit': i.unit,
      'price': i.price,
    }).toList(),
    'time': r.time.toIso8601String(),
    'total': r.total,
  };

  TimelineRecord _timelineFromJson(Map<String, dynamic> j) => TimelineRecord(
    id: j['id'] ?? '',
    content: j['content'] ?? '',
    time: j['time'] != null ? DateTime.parse(j['time']) : DateTime.now(),
    type: TimelineType.values.firstWhere(
      (t) => t.name == j['type'],
      orElse: () => TimelineType.behavior,
    ),
    tags: List<String>.from(j['tags'] ?? const ['behavior']),
    matchedAgenda: j['matchedAgenda'],
    notes: (j['notes'] as List?)?.map((n) => NoteEntry(
      id: n['id'] ?? '',
      content: n['content'] ?? '',
      time: n['time'] != null ? DateTime.parse(n['time']) : DateTime.now(),
      type: NoteType.values.firstWhere(
        (t) => t.name == n['type'],
        orElse: () => NoteType.text,
      ),
    )).toList() ?? const [],
    deleted: j['deleted'] ?? false,
    sideEffects: _sideEffectsFromJson(j['sideEffects']),
  );

  SideEffects? _sideEffectsFromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    return SideEffects(
      shoppingRecord: j['shoppingRecord'] != null ? _shoppingRecordFromJson(j['shoppingRecord']) : null,
      itemUpdate: j['itemUpdate'] != null ? ItemUpdate(
        name: j['itemUpdate']['name'] ?? '',
        location: j['itemUpdate']['location'] ?? '',
      ) : null,
      agenda: j['agenda'],
      agendaList: j['agendaList'] != null ? List<String>.from(j['agendaList']) : null,
      inventoryUpdate: j['inventoryUpdate'] != null ? InventoryUpdate(
        name: j['inventoryUpdate']['name'] ?? '',
        quantityChange: (j['inventoryUpdate']['quantityChange'] as num?)?.toDouble() ?? 0,
        unit: j['inventoryUpdate']['unit'] ?? '个',
        reason: j['inventoryUpdate']['reason'],
      ) : null,
    );
  }

  ShoppingRecord _shoppingRecordFromJson(Map<String, dynamic> j) => ShoppingRecord(
    id: j['id'] ?? '',
    store: j['store'] ?? '',
    items: (j['items'] as List?)?.map((i) => ShoppingItem(
      id: i['id'] ?? '',
      name: i['name'] ?? '',
      quantity: i['quantity'] ?? 1,
      unit: i['unit'] ?? '个',
      price: i['price'],
    )).toList() ?? [],
    time: j['time'] != null ? DateTime.parse(j['time']) : DateTime.now(),
    total: j['total'],
  );

  Map<String, dynamic> _agendaToJson(AgendaItem a) => {
    'id': a.id, 'date': a.date, 'time': a.time, 'content': a.content,
    'note': a.note, 'voiceNote': a.voiceNote, 'isMustDo': a.isMustDo, 'status': a.status.name,
    'level': a.level.name, 'icon': a.icon,
    'isHighFrequency': a.isHighFrequency,
    'source': a.source.name,
    'remainingTime': a.remainingTime,
    'category': a.category.name,
    'streak': a.streak,
    'lastCompletedDate': a.lastCompletedDate?.toIso8601String(),
    'failCount': a.failCount,
    'lastFailedDate': a.lastFailedDate?.toIso8601String(),
    'chainAfterId': a.chainAfterId,
    'timeDeviationCount': a.timeDeviationCount,
    'lastActualTime': a.lastActualTime,
    'suggestedTime': a.suggestedTime,
    'customReminderConfig': a.customReminderConfig,
    'wasPostponed': a.wasPostponed,
    'wasSkipped': a.wasSkipped,
  };

  AgendaItem _agendaFromJson(Map<String, dynamic> j) => AgendaItem(
    id: j['id'] ?? '',
    date: j['date'] ?? '',
    time: j['time'] ?? '',
    content: j['content'] ?? '',
    note: j['note'],
    voiceNote: j['voiceNote'],
    isMustDo: j['isMustDo'] ?? false,
    status: AgendaStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => AgendaStatus.pending,
    ),
    level: AgendaLevel.values.firstWhere(
      (l) => l.name == j['level'],
      orElse: () => j['level'] == 'mustDo' ? AgendaLevel.mustDoShort : AgendaLevel.normal,
    ),
    icon: j['icon'] ?? '📋',
    isHighFrequency: j['isHighFrequency'] ?? false,
    source: AgendaSource.values.firstWhere(
      (s) => s.name == j['source'],
      orElse: () => AgendaSource.user,
    ),
    remainingTime: j['remainingTime'],
    category: AgendaCategory.values.firstWhere(
      (c) => c.name == j['category'],
      orElse: () => AgendaCategory.custom,
    ),
    streak: j['streak'] ?? 0,
    lastCompletedDate: j['lastCompletedDate'] != null
        ? DateTime.tryParse(j['lastCompletedDate'] as String)
        : null,
    failCount: j['failCount'] ?? 0,
    lastFailedDate: j['lastFailedDate'] != null
        ? DateTime.tryParse(j['lastFailedDate'] as String)
        : null,
    chainAfterId: j['chainAfterId'],
    timeDeviationCount: j['timeDeviationCount'] ?? 0,
    lastActualTime: j['lastActualTime'],
    suggestedTime: j['suggestedTime'],
    customReminderConfig: j['customReminderConfig'] != null
        ? Map<String, dynamic>.from(j['customReminderConfig'] as Map)
        : null,
    wasPostponed: j['wasPostponed'] ?? false,
    wasSkipped: j['wasSkipped'] ?? false,
  );

  Map<String, dynamic> _shoppingToJson(ShoppingRecord r) => {
    'id': r.id,
    'time': r.time.toIso8601String(),
    'store': r.store,
    'items': r.items.map((i) => {
      'id': i.id, 'name': i.name, 'quantity': i.quantity, 'unit': i.unit,
      'price': i.price,
    }).toList(),
  };

  ShoppingRecord _shoppingFromJson(Map<String, dynamic> j) => ShoppingRecord(
    id: j['id'] ?? '',
    store: j['store'] ?? '',
    items: (j['items'] as List? ?? []).map((i) => ShoppingItem(
      id: i['id'] ?? '',
      name: i['name'] ?? '',
      quantity: i['quantity'] ?? 1,
      unit: i['unit'] ?? '个',
      price: i['price']?.toDouble(),
    )).toList(),
    time: j['time'] != null ? DateTime.parse(j['time']) : DateTime.now(),
  );

  Map<String, dynamic> _itemToJson(ItemRecord it) => {
    'id': it.id, 'name': it.name, 'location': it.location,
    'tags': it.tags, 'photo': it.photo,
    'history': it.history.map((h) => {
      'id': h.id, 'location': h.location, 'time': h.time.toIso8601String(),
    }).toList(),
  };

  ItemRecord _itemFromJson(Map<String, dynamic> j) => ItemRecord(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    location: j['location'] ?? '',
    tags: List<String>.from(j['tags'] ?? const []),
    photo: j['photo'],
    history: (j['history'] as List? ?? []).map((h) => LocationHistory(
      id: h['id'] ?? '',
      location: h['location'] ?? '',
      time: h['time'] != null ? DateTime.parse(h['time']) : DateTime.now(),
    )).toList(),
  );

  Map<String, dynamic> _inventoryToJson(InventoryItem i) => {
    'id': i.id, 'name': i.name, 'quantity': i.quantity, 'unit': i.unit,
    'category': i.category, 'lastUpdated': i.lastUpdated.toIso8601String(),
    'expireDate': i.expireDate?.toIso8601String(),
    'logs': i.logs.map((l) => {
      'id': l.id, 'change': l.change, 'reason': l.reason,
      'time': l.time.toIso8601String(),
    }).toList(),
    'aiSuggestion': i.aiSuggestion,
    'customSuggestion': i.customSuggestion,
  };

  InventoryItem _inventoryFromJson(Map<String, dynamic> j) => InventoryItem(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
    unit: j['unit'] ?? '个',
    category: j['category'] ?? '其他',
    lastUpdated: j['lastUpdated'] != null
        ? DateTime.parse(j['lastUpdated']) : DateTime.now(),
    expireDate: j['expireDate'] != null
        ? DateTime.parse(j['expireDate']) : null,
    logs: (j['logs'] as List? ?? []).map((l) => InventoryLog(
      id: l['id'] ?? '',
      change: (l['change'] as num?)?.toDouble() ?? 0,
      reason: l['reason'] ?? '',
      time: l['time'] != null ? DateTime.parse(l['time']) : DateTime.now(),
    )).toList(),
    aiSuggestion: j['aiSuggestion'],
    customSuggestion: j['customSuggestion'],
  );

  Map<String, dynamic> _tagToJson(TagDef t) => {
    'id': t.id, 'name': t.name, 'color': t.color, 'icon': t.icon,
    'system': t.system,
  };

  TagDef _tagFromJson(Map<String, dynamic> j) => TagDef(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    color: j['color'] ?? 'accent',
    icon: j['icon'] ?? '#',
    system: j['system'] ?? false,
  );

  Map<String, dynamic> _chatMessageToJson(ChatMessage m) => {
    'id': m.id, 'role': m.role, 'content': m.content,
    'time': m.time.toIso8601String(),
  };

  ChatMessage _chatMessageFromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] ?? '',
    role: j['role'] ?? 'user',
    content: j['content'] ?? '',
    time: j['time'] != null ? DateTime.parse(j['time']) : DateTime.now(),
  );

  Map<String, dynamic> _userProfileToJson(UserProfile p) => {
    'name': p.name, 'age': p.age, 'gender': p.gender,
    'healthConditions': p.healthConditions,
    'preferences': p.preferences,
    'createdAt': p.createdAt.toIso8601String(),
  };

  UserProfile _userProfileFromJson(Map<String, dynamic> j) => UserProfile(
    name: j['name'] ?? '用户',
    age: j['age'] ?? 65,
    gender: j['gender'] ?? 'male',
    healthConditions: List<String>.from(j['healthConditions'] ?? const []),
    preferences: List<String>.from(j['preferences'] ?? const []),
    createdAt: j['createdAt'] != null
        ? DateTime.parse(j['createdAt']) : DateTime.now(),
  );
}
