import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'llm_service.dart';

enum IntentType {
  behavior,
  agendaCreate,
  agendaComplete,
  itemLocation,
  shopping,
  inventoryConsume,
  general,
}

class IntentItem {
  final IntentType type;
  final Map<String, dynamic> slots;
  final double confidence;

  const IntentItem({
    required this.type,
    required this.slots,
    this.confidence = 0.8,
  });

  factory IntentItem.fromJson(Map<String, dynamic> json) {
    return IntentItem(
      type: _parseIntentType(json['intent'] as String? ?? 'general'),
      slots: json['slots'] as Map<String, dynamic>? ?? {},
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
    );
  }

  String get label {
    switch (type) {
      case IntentType.behavior: return 'behavior';
      case IntentType.agendaCreate: return 'agenda_create';
      case IntentType.agendaComplete: return 'agenda_complete';
      case IntentType.itemLocation: return 'item_location';
      case IntentType.shopping: return 'shopping';
      case IntentType.inventoryConsume: return 'inventory_consume';
      case IntentType.general: return 'general';
    }
  }

  String get displayName {
    switch (type) {
      case IntentType.behavior: return '行为';
      case IntentType.agendaCreate: return '创建事程';
      case IntentType.agendaComplete: return '完成事程';
      case IntentType.itemLocation: return '物品位置';
      case IntentType.shopping: return '购物';
      case IntentType.inventoryConsume: return '库存消耗';
      case IntentType.general: return '通用';
    }
  }

  static IntentType _parseIntentType(String s) {
    switch (s.toLowerCase()) {
      case 'behavior': return IntentType.behavior;
      case 'agenda_create': return IntentType.agendaCreate;
      case 'agenda_complete': return IntentType.agendaComplete;
      case 'item_location': return IntentType.itemLocation;
      case 'shopping': return IntentType.shopping;
      case 'inventory_consume': return IntentType.inventoryConsume;
      default: return IntentType.general;
    }
  }
}

class TimelineSlot {
  final String time;
  final List<IntentItem> intents;

  const TimelineSlot({
    required this.time,
    required this.intents,
  });

  factory TimelineSlot.fromJson(Map<String, dynamic> json) {
    final intentsList = <IntentItem>[];
    if (json['intents'] is List) {
      for (final e in json['intents']) {
        intentsList.add(IntentItem.fromJson(e));
      }
    }
    return TimelineSlot(
      time: json['time'] as String? ?? '',
      intents: intentsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'intents': intents.map((i) => {
            'intent': i.label,
            'slots': i.slots,
            'confidence': i.confidence,
          }).toList(),
    };
  }
}

class IntentResult {
  final List<TimelineSlot> timelineSlots;
  final String source;
  final String? reason;

  const IntentResult({
    required this.timelineSlots,
    required this.source,
    this.reason,
  });

  List<IntentItem> get allIntents {
    return timelineSlots.expand((slot) => slot.intents).toList();
  }

  IntentItem get primary {
    return timelineSlots.isNotEmpty && timelineSlots.first.intents.isNotEmpty
        ? timelineSlots.first.intents.first
        : const IntentItem(type: IntentType.general, slots: {});
  }

  IntentType get primaryIntent => primary.type;

  Map<String, dynamic> get primarySlots => primary.slots;

  factory IntentResult.single(IntentType type, Map<String, dynamic> slots, double conf, String source, [String? reason]) {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return IntentResult(
      timelineSlots: [
        TimelineSlot(
          time: time,
          intents: [IntentItem(type: type, slots: slots, confidence: conf)],
        ),
      ],
      source: source,
      reason: reason,
    );
  }

  factory IntentResult.fromJson(Map<String, dynamic> json) {
    final slots = <TimelineSlot>[];

    if (json['timelineSlots'] is List) {
      for (final e in json['timelineSlots']) {
        slots.add(TimelineSlot.fromJson(e));
      }
    } else if (json['intents'] is List) {
      final intentsList = <IntentItem>[];
      for (final e in json['intents']) {
        intentsList.add(IntentItem.fromJson(e));
      }
      final time = json['time'] as String? ?? '';
      slots.add(TimelineSlot(time: time, intents: intentsList));
    } else if (json['intent'] != null) {
      final intent = IntentItem.fromJson(json);
      final time = intent.slots['time'] as String? ?? '';
      slots.add(TimelineSlot(time: time, intents: [intent]));
    }

    if (slots.isEmpty) {
      final now = DateTime.now();
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      slots.add(TimelineSlot(time: time, intents: [const IntentItem(type: IntentType.general, slots: {})]));
    }

    return IntentResult(
      timelineSlots: slots,
      source: json['source'] as String? ?? 'llm',
      reason: json['reason'] as String?,
    );
  }
}

class UserPattern {
  final String inputText;
  List<TimelineSlot> slots;
  int count;
  DateTime lastUsed;

  UserPattern({
    required this.inputText,
    required this.slots,
    this.count = 1,
    required this.lastUsed,
  });

  Map<String, dynamic> toJson() => {
        'inputText': inputText,
        'slots': slots.map((s) => s.toJson()).toList(),
        'count': count,
        'lastUsed': lastUsed.toIso8601String(),
      };

  factory UserPattern.fromJson(Map<String, dynamic> json) {
    final slotsList = <TimelineSlot>[];
    if (json['slots'] is List) {
      for (final e in json['slots']) {
        slotsList.add(TimelineSlot.fromJson(e));
      }
    }
    if (slotsList.isEmpty && json['intents'] is List) {
      final intentsList = <IntentItem>[];
      for (final e in json['intents']) {
        intentsList.add(IntentItem.fromJson(e));
      }
      slotsList.add(TimelineSlot(time: '', intents: intentsList));
    }
    if (slotsList.isEmpty && json['intent'] != null) {
      final intent = IntentItem.fromJson(json);
      slotsList.add(TimelineSlot(time: '', intents: [intent]));
    }
    return UserPattern(
      inputText: json['inputText'] as String? ?? '',
      slots: slotsList,
      count: json['count'] as int? ?? 1,
      lastUsed: DateTime.tryParse(json['lastUsed'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class IntentRecognitionService {
  static const String _patternsKey = 'intent_patterns';
  static const String _presetLoadedKey = 'intent_preset_loaded';
  static const double _localConfidenceThreshold = 0.82;
  static const int _maxPatterns = 500;

  final LlmService _llm;
  SharedPreferences? _prefs;
  List<UserPattern> _patterns = [];
  Map<String, List<UserPattern>> _invertedIndex = {};

  int llmCallCount = 0;
  int localMatchCount = 0;

  IntentRecognitionService(this._llm);

  // ===== 基础工具方法 =====

  List<String> _segmentText(String text) {
    final results = <String>[];
    final words = text.split(RegExp(r'[\s,，。！？；;：:、]')).where((w) => w.isNotEmpty).toList();
    for (final word in words) {
      for (var i = 0; i < word.length; i++) {
        results.add(word[i]);
      }
      for (var i = 0; i < word.length - 1; i++) {
        results.add(word.substring(i, i + 2));
      }
    }
    return results;
  }

  double _textSimilarity(String a, String b) {
    final segA = _segmentText(a);
    final segB = _segmentText(b);

    if (segA.isEmpty || segB.isEmpty) {
      return a == b ? 1.0 : 0.0;
    }

    final vocabulary = <String>{};
    vocabulary.addAll(segA);
    vocabulary.addAll(segB);

    final vectorA = vocabulary.map((w) => segA.where((s) => s == w).length).toList();
    final vectorB = vocabulary.map((w) => segB.where((s) => s == w).length).toList();

    final cosine = _cosineSimilarity(vectorA, vectorB);
    final overlap = _wordOverlap(segA, segB);

    return (cosine * 0.6 + overlap * 0.4).clamp(0.0, 1.0);
  }

  double _cosineSimilarity(List<int> vectorA, List<int> vectorB) {
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (var i = 0; i < vectorA.length; i++) {
      dot += vectorA[i] * vectorB[i];
      normA += vectorA[i] * vectorA[i];
      normB += vectorB[i] * vectorB[i];
    }

    normA = normA > 0 ? _sqrt(normA) : 0;
    normB = normB > 0 ? _sqrt(normB) : 0;

    return normA > 0 && normB > 0 ? dot / (normA * normB) : 0.0;
  }

  double _wordOverlap(List<String> a, List<String> b) {
    final aSet = Set<String>.from(a);
    final bSet = Set<String>.from(b);
    final intersection = aSet.intersection(bSet);
    final union = aSet.union(bSet);
    return union.isNotEmpty ? intersection.length / union.length : 0.0;
  }

  double _fallbackSimilarity(String a, String b) {
    final aChars = a.split('');
    final bChars = b.split('');
    final common = aChars.where((c) => bChars.contains(c)).length;
    final overlap = common / (aChars.length + bChars.length) * 2;

    final dist = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    final distanceScore = 1.0 - (dist / maxLen);

    return (overlap * 0.4 + distanceScore * 0.6).clamp(0.0, 1.0);
  }

  double _sqrt(double value) {
    return value > 0 ? pow(value, 0.5) as double : 0;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      b.length + 1,
      (i) => List.generate(a.length + 1, (j) => 0),
    );

    for (var i = 0; i <= a.length; i++) matrix[0][i] = i;
    for (var j = 0; j <= b.length; j++) matrix[j][0] = j;

    for (var j = 1; j <= b.length; j++) {
      for (var i = 1; i <= a.length; i++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[j][i] = [
          matrix[j - 1][i] + 1,
          matrix[j][i - 1] + 1,
          matrix[j - 1][i - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
    }

    return matrix[b.length][a.length];
  }

  double _calculatePatternScore(UserPattern p) {
    final now = DateTime.now();
    final daysSinceUsed = now.difference(p.lastUsed).inDays;
    final recencyScore = daysSinceUsed <= 1 ? 1.0 : daysSinceUsed <= 7 ? 0.8 : daysSinceUsed <= 30 ? 0.5 : 0.3;
    final frequencyScore = p.count >= 10 ? 1.0 : p.count >= 5 ? 0.8 : p.count >= 2 ? 0.6 : 0.4;
    return recencyScore * 0.5 + frequencyScore * 0.5;
  }

  void _buildIndex() {
    _invertedIndex.clear();
    for (final pattern in _patterns) {
      final segments = _segmentText(pattern.inputText);
      for (final seg in segments) {
        for (var i = 0; i < seg.length; i++) {
          final char = seg[i];
          _invertedIndex.putIfAbsent(char, () => []).add(pattern);
        }
      }
    }

    final newIndex = <String, List<UserPattern>>{};
    for (final entry in _invertedIndex.entries) {
      newIndex[entry.key] = entry.value.toSet().toList();
    }
    _invertedIndex = newIndex;
  }

  List<UserPattern> _findCandidates(String text) {
    final candidates = <UserPattern>{};
    final segments = _segmentText(text);

    for (final seg in segments) {
      for (var i = 0; i < seg.length; i++) {
        final char = seg[i];
        if (_invertedIndex.containsKey(char)) {
          candidates.addAll(_invertedIndex[char]!);
        }
      }
    }

    return candidates.toList();
  }

  // ===== 时间和日期提取方法 =====

  List<Map<String, dynamic>> _extractAllTimePoints(String text) {
    final results = <Map<String, dynamic>>[];

    final fuzzyTimePatterns = [
      {'pattern': '清晨', 'time': '06:00'},
      {'pattern': '早上', 'time': '07:00'},
      {'pattern': '早晨', 'time': '07:00'},
      {'pattern': '上午', 'time': '09:00'},
      {'pattern': '中午', 'time': '12:00'},
      {'pattern': '正午', 'time': '12:00'},
      {'pattern': '下午', 'time': '14:00'},
      {'pattern': '傍晚', 'time': '17:00'},
      {'pattern': '晚上', 'time': '19:00'},
      {'pattern': '晚间', 'time': '19:00'},
      {'pattern': '睡前', 'time': '21:00'},
      {'pattern': '睡觉前', 'time': '21:00'},
    ];

    for (final ft in fuzzyTimePatterns) {
      final idx = text.indexOf(ft['pattern'] as String);
      if (idx >= 0) {
        results.add({
          'time': ft['time'],
          'start': idx,
          'end': idx + (ft['pattern'] as String).length,
          'fuzzy': true,
        });
      }
    }

    final matches = RegExp(r'(\d{1,2})(?:点|时)(\d{1,2})?(?:分|半)?').allMatches(text);
    for (final match in matches) {
      final hour = int.tryParse(match.group(1) ?? '') ?? 0;
      final minute = int.tryParse(match.group(2) ?? '') ?? 0;
      String timeStr;
      if (match.group(0)!.contains('半') && match.group(2) == null) {
        timeStr = '${hour.toString().padLeft(2, '0')}:30';
      } else {
        timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
      results.add({
        'time': timeStr,
        'start': match.start,
        'end': match.end,
        'fuzzy': false,
      });
    }

    results.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));
    return results;
  }

  int _extractDateOffset(String text) {
    if (text.contains('大后天')) return 3;
    if (text.contains('后天')) return 2;
    if (text.contains('明天')) return 1;
    if (text.contains('今天') || text.contains('今日')) return 0;
    return 0;
  }

  List<int> _extractAllDateOffsets(String text) {
    final offsets = <int>{};

    if (text.contains('大后天')) offsets.add(3);
    if (text.contains('后天')) offsets.add(2);
    if (text.contains('明天')) offsets.add(1);
    if (text.contains('今天') || text.contains('今日')) offsets.add(0);

    return offsets.isEmpty ? [0] : offsets.toList()..sort();
  }

  String _purifyAgendaContent(String text) {
    var result = text;

    final timeWords = ['今天', '今日', '明天', '后天', '大后天', '昨天', '前天',
      '清晨', '早上', '早晨', '上午', '中午', '正午', '下午', '傍晚', '晚上', '晚间', '睡前', '睡觉前'];
    for (final word in timeWords) {
      result = result.replaceAll(word, '');
    }

    result = result
        .replaceAll(RegExp(r'\d+点\d*分?'), '')
        .replaceAll(RegExp(r'\d+时\d*分?'), '');

    result = result
        .replaceAll('我准备', '')
        .replaceAll('准备', '')
        .replaceAll('要', '')
        .replaceAll('需要', '')
        .replaceAll('得', '')
        .replaceAll('记得', '')
        .replaceAll('别忘了', '')
        .replaceAll('提醒我', '')
        .replaceAll('一会', '')
        .replaceAll('待会儿', '')
        .replaceAll('等一下', '')
        .replaceAll('回头', '')
        .trim();

    final connectives = ['都', '和', '与', '及'];
    for (final c in connectives) {
      result = result.replaceAll(c, '');
    }

    final tailModifiers = ['喝', '吃', '吧', '啊', '呀', '哦', '呢'];
    var changed = true;
    while (changed && result.isNotEmpty) {
      changed = false;
      for (final m in tailModifiers) {
        if (result.endsWith(m)) {
          result = result.substring(0, result.length - m.length);
          changed = true;
        }
      }
    }

    result = result.replaceAll(RegExp(r'^[，,。.\s]+'), '');
    result = result.replaceAll(RegExp(r'[，,。.\s]+$'), '');

    if (result.isEmpty) {
      result = text;
      for (final word in timeWords) {
        result = result.replaceAll(word, '');
      }
      result = result
          .replaceAll('我准备', '')
          .replaceAll('准备', '')
          .replaceAll('要', '')
          .replaceAll('需要', '')
          .replaceAll('得', '')
          .replaceAll('记得', '')
          .replaceAll('别忘了', '')
          .replaceAll('提醒我', '')
          .replaceAll('一会', '')
          .replaceAll('待会儿', '')
          .replaceAll('等一下', '')
          .replaceAll('回头', '')
          .trim();
      for (final c in connectives) {
        result = result.replaceAll(c, '');
      }
      changed = true;
      while (changed && result.isNotEmpty) {
        changed = false;
        for (final m in tailModifiers) {
          if (result.endsWith(m)) {
            result = result.substring(0, result.length - m.length);
            changed = true;
          }
        }
      }
    }

    return result.trim();
  }

  bool _containsActionVerb(String text) {
    const actionVerbs = ['煮', '做', '吃', '喝', '洗', '打扫', '整理', '买', '跑', '走', '散', '运', '睡', '起', '烧', '蒸', '煮', '炒', '煎', '炖', '烤', '晾', '收', '寄', '取'];
    return actionVerbs.any((v) => text.contains(v));
  }

  List<IntentItem> _recognizeSingleClause(String clause, String timeStr) {
    final intents = <IntentItem>[];
    if (clause.isEmpty) return intents;

    final itemMatch = RegExp(
      r'(?:把|将)?\s*([\u4e00-\u9fa5A-Za-z]{1,8}?)\s*(?:放|搁|塞)(?:在|到)?(?:了)?\s*([\u4e00-\u9fa5A-Za-z]+)',
    ).firstMatch(clause);
    if (itemMatch != null && itemMatch.groupCount >= 2) {
      intents.add(IntentItem(
        type: IntentType.itemLocation,
        slots: {
          'item_name': itemMatch.group(1)!.trim(),
          'location': itemMatch.group(2)!
              .trim()
              .replaceAll(RegExp(r'^(在|到)'), '')
              .replaceAll(RegExp(r'(中|里|上|下|内)$'), ''),
        },
        confidence: 0.8,
      ));
    }

    final buyMatch = RegExp(r'(?:刚去|去|到|在)?(.+?)(?:买了|买)(.+)').firstMatch(clause);
    if (buyMatch != null) {
      var store = buyMatch.group(1)!.trim();
      store = store
          .replaceAll(RegExp(r'^(刚去|去|到|在)'), '')
          .trim();
      final itemsText = buyMatch.group(2)!.trim();

      final items = <Map<String, dynamic>>[];
      final itemMatches = RegExp(
        r'(\d+(?:\.\d+)?)\s*(片|粒|盒|瓶|个|包|袋|支|颗|毫升|克|斤|公斤|箱|条|把)\s*([\u4e00-\u9fa5A-Za-z]{2,10})'
      ).allMatches(itemsText);
      for (final m in itemMatches) {
        items.add({
          'name': m.group(3)!,
          'quantity': double.parse(m.group(1)!),
          'unit': m.group(2)!,
        });
      }

      if (items.isEmpty) {
        final itemMatches2 = RegExp(
          r'([\u4e00-\u9fa5A-Za-z]{2,10})\s*(\d+(?:\.\d+)?)\s*(片|粒|盒|瓶|个|包|袋|支|颗|毫升|克|斤|公斤|箱|条|把)'
        ).allMatches(itemsText);
        for (final m in itemMatches2) {
          items.add({
            'name': m.group(1)!,
            'quantity': double.parse(m.group(2)!),
            'unit': m.group(3)!,
          });
        }
      }

      final slots = <String, dynamic>{
        'store': store,
        'items_text': itemsText,
      };
      if (items.isNotEmpty) {
        slots['items'] = items;
      }

      intents.add(IntentItem(
        type: IntentType.shopping,
        slots: slots,
        confidence: 0.8,
      ));
    }

    final reminderKeywords = ['记得', '别忘了', '提醒我', '要记得', '一定要', '需要', '要做', '得去', '准备', '一会', '待会儿', '等一下', '回头'];
    final futureTimeKeywords = ['明天', '下周', '下次', '以后'];
    final dateOffset = _extractDateOffset(clause);
    final isAgenda = reminderKeywords.any((kw) => clause.contains(kw)) ||
        futureTimeKeywords.any((kw) => clause.contains(kw)) ||
        dateOffset > 0 ||
        (intents.isEmpty && timeStr.isNotEmpty && _containsActionVerb(clause));
    if (isAgenda) {
      final content = _purifyAgendaContent(clause);
      final slots = <String, dynamic>{'content': content.isNotEmpty ? content : clause};
      if (dateOffset > 0) {
        slots['date_offset'] = dateOffset;
      }
      if (timeStr.isNotEmpty) {
        slots['time'] = timeStr;
      }
      intents.add(IntentItem(
        type: IntentType.agendaCreate,
        slots: slots,
        confidence: 0.75,
      ));
    }

    final completedKeywords = ['刚', '刚刚', '已经', '过了', '完了', '吃完了', '喝完了', '吃过了', '做完了'];
    final pastSuffixes = ['完了', '过了', '好了'];
    bool isCompleted = completedKeywords.any((kw) => clause.contains(kw)) ||
        pastSuffixes.any((kw) => clause.endsWith(kw));
    if (isCompleted && intents.isEmpty) {
      intents.add(IntentItem(
        type: IntentType.agendaComplete,
        slots: {'keyword': clause},
        confidence: 0.7,
      ));
    }

    final consumeMatches = RegExp(
      r'(?:吃了|吃|喝了|喝|用了|用|服用|服)\s*([\u4e00-\u9fa5A-Za-z]{2,10})(?:\s+(\d+(?:\.\d+)?)\s*(片|粒|盒|瓶|个|包|袋|支|颗|毫升|克))?',
    ).allMatches(clause);
    for (final consumeMatch in consumeMatches) {
      var itemName = consumeMatch.group(1)!.trim();
      itemName = itemName
          .replaceAll(RegExp(r'^(完|过|了|刚|刚刚)'), '')
          .replaceAll(RegExp(r'(完|过|了)$'), '');
      if (itemName.isEmpty) continue;
      intents.add(IntentItem(
        type: IntentType.inventoryConsume,
        slots: {
          'item_name': itemName,
          'quantity': double.tryParse(consumeMatch.group(2) ?? '1') ?? 1.0,
          'unit': consumeMatch.group(3) ?? '个',
        },
        confidence: 0.7,
      ));
    }

    final behaviorKeywords = ['吃', '喝', '睡', '运动', '散步', '跑步', '洗澡', '洗漱', '起床', '吃药', '吃饭', '午饭', '早饭', '晚饭', '喝水', '聊天'];
    if (behaviorKeywords.any((kw) => clause.contains(kw)) && intents.isEmpty) {
      intents.add(IntentItem(
        type: IntentType.behavior,
        slots: {'keyword': clause},
        confidence: 0.7,
      ));
    }

    if (intents.isEmpty) {
      intents.add(const IntentItem(type: IntentType.general, slots: {}, confidence: 0.5));
    }

    return intents;
  }

  IntentResult _ruleBasedRecognize(String t) {
    final now = DateTime.now();
    final defaultTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final dateOffsets = _extractAllDateOffsets(t);
    final timePoints = _extractAllTimePoints(t);

    // 提取核心时间和内容
    String primaryTime = defaultTime;
    if (timePoints.isNotEmpty) {
      primaryTime = timePoints.first['time'] as String;
    }

    // 净化内容，提取核心动作
    final purifiedContent = _purifyAgendaContent(t);
    String coreContent = purifiedContent.isNotEmpty ? purifiedContent : t;

    // 检查是否包含事程关键词
    final reminderKeywords = ['记得', '别忘了', '提醒我', '要记得', '一定要', '需要', '要做', '得去', '准备', '一会', '待会儿', '等一下', '回头'];
    final futureTimeKeywords = ['明天', '下周', '下次', '以后'];
    bool isAgendaCreate = reminderKeywords.any((kw) => t.contains(kw)) ||
        futureTimeKeywords.any((kw) => t.contains(kw));

    // 多日期拆分：为每个日期创建一个意图
    if (dateOffsets.length > 1) {
      final expandedSlots = <TimelineSlot>[];
      for (final offset in dateOffsets) {
        final slots = <String, dynamic>{
          'content': coreContent,
          'date_offset': offset,
        };
        if (primaryTime != defaultTime) {
          slots['time'] = primaryTime;
        }

        expandedSlots.add(TimelineSlot(
          time: primaryTime,
          intents: [IntentItem(
            type: IntentType.agendaCreate,
            slots: slots,
            confidence: 0.75,
          )],
        ));
      }
      return IntentResult(
        timelineSlots: expandedSlots,
        source: 'rule',
        reason: '规则匹配(多日期拆分)',
      );
    }

    // 单日期情况
    if (isAgendaCreate) {
      final slots = <String, dynamic>{'content': coreContent};
      if (dateOffsets.isNotEmpty && dateOffsets[0] > 0) {
        slots['date_offset'] = dateOffsets[0];
      }
      if (primaryTime != defaultTime) {
        slots['time'] = primaryTime;
      }
      return IntentResult(
        timelineSlots: [TimelineSlot(
          time: primaryTime,
          intents: [IntentItem(
            type: IntentType.agendaCreate,
            slots: slots,
            confidence: 0.75,
          )],
        )],
        source: 'rule',
        reason: '规则匹配(事程创建)',
      );
    }

    // 其他意图类型：使用原有的片段识别逻辑
    final baseSlots = <TimelineSlot>[];

    if (timePoints.isEmpty) {
      final intents = _recognizeSingleClause(t, defaultTime);
      baseSlots.add(TimelineSlot(time: defaultTime, intents: intents));
    } else {
      for (var i = 0; i < timePoints.length; i++) {
        final timePoint = timePoints[i];
        final timeStr = timePoint['time'] as String;
        final start = timePoint['start'] as int;

        final nextStart = i + 1 < timePoints.length
            ? timePoints[i + 1]['start'] as int
            : t.length;

        final clause = t.substring(start, nextStart).trim();

        if (clause.isEmpty) continue;

        final intents = _recognizeSingleClause(clause, timeStr);
        if (intents.isNotEmpty) {
          baseSlots.add(TimelineSlot(time: timeStr, intents: intents));
        }
      }

      final firstStart = timePoints.first['start'] as int;
      if (firstStart > 0) {
        final headClause = t.substring(0, firstStart).trim();
        if (headClause.isNotEmpty) {
          final firstTime = timePoints.first['time'] as String;
          final headIntents = _recognizeSingleClause(headClause, firstTime);
          if (headIntents.isNotEmpty) {
            baseSlots.insert(0, TimelineSlot(time: firstTime, intents: headIntents));
          }
        }
      }

      final lastTimeEnd = timePoints.last['end'] as int;
      if (lastTimeEnd < t.length) {
        final tailClause = t.substring(lastTimeEnd).trim();
        if (tailClause.isNotEmpty) {
          final tailIntents = _recognizeSingleClause(tailClause, defaultTime);
          if (tailIntents.isNotEmpty) {
            baseSlots.add(TimelineSlot(time: defaultTime, intents: tailIntents));
          }
        }
      }
    }

    if (baseSlots.isEmpty) {
      final intents = _recognizeSingleClause(t, defaultTime);
      baseSlots.add(TimelineSlot(time: defaultTime, intents: intents));
    }

    return IntentResult(
      timelineSlots: baseSlots,
      source: 'rule',
      reason: '规则匹配(单日期)',
    );
  }

  // ===== 初始化和存储 =====

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPatterns();
    _buildIndex();
    await _ensurePresetLoaded();
  }

  Future<void> _ensurePresetLoaded() async {
    final loaded = _prefs?.getBool(_presetLoadedKey) ?? false;
    if (!loaded || _patterns.isEmpty) {
      await loadPresetPatterns();
      await _prefs?.setBool(_presetLoadedKey, true);
    }
  }

  void _loadPatterns() {
    final jsonStr = _prefs?.getString(_patternsKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List;
        _patterns = list
            .map((e) => UserPattern.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('意图模式加载失败: $e');
        _patterns = [];
      }
    }
  }

  Future<void> _savePatterns() async {
    final jsonStr = jsonEncode(_patterns.map((p) => p.toJson()).toList());
    await _prefs?.setString(_patternsKey, jsonStr);
    _buildIndex();
  }

  // ===== 识别主入口 =====

  Future<IntentResult> recognize(String text) async {
    final t = text.trim();
    if (t.isEmpty) {
      return IntentResult.single(IntentType.general, {}, 0, 'rule', '空输入');
    }

    final localResult = _matchLocalPattern(t);
    if (localResult != null) {
      final maxConf = localResult.allIntents.fold(0.0, (m, i) => i.confidence > m ? i.confidence : m);
      if (maxConf >= _localConfidenceThreshold) {
        localMatchCount++;
        return localResult;
      }
    }

    if (!_llm.isConfigured) {
      return _ruleBasedRecognize(t);
    }

    llmCallCount++;
    final llmResult = await _llmRecognize(t);

    _learnPattern(t, llmResult);

    return llmResult;
  }

  // ===== 本地模式匹配 =====

  IntentResult? _matchLocalPattern(String text) {
    if (_patterns.isEmpty) return null;

    for (final p in _patterns) {
      if (p.inputText == text) {
        final score = _calculatePatternScore(p);
        if (score >= 1.0) {
          return IntentResult(
            timelineSlots: p.slots,
            source: 'local',
            reason: '历史模式匹配(完全匹配，出现${p.count}次)',
          );
        }
      }
    }

    final candidates = _findCandidates(text);
    if (candidates.isEmpty) return null;

    UserPattern? bestMatch;
    double bestWeightedScore = 0;
    double bestSimilarity = 0;

    for (final p in candidates) {
      final patternScore = _calculatePatternScore(p);
      if (patternScore < 0.5) continue;

      final similarity = _textSimilarity(text, p.inputText);
      if (similarity < 0.5) continue;

      final weightedScore = similarity * (0.6 + patternScore * 0.4);

      if (weightedScore > bestWeightedScore) {
        bestWeightedScore = weightedScore;
        bestSimilarity = similarity;
        bestMatch = p;
      }
    }

    if (bestMatch != null && bestWeightedScore >= 0.65) {
      final extractedSlots = bestMatch.slots.map((slot) {
        final newIntents = slot.intents.map((intent) {
          final patternScore = _calculatePatternScore(bestMatch!);
          final adjustedConfidence = (intent.confidence * 0.5 + bestSimilarity * 0.3 + patternScore * 0.2).clamp(0.0, 1.0);
          return IntentItem(
            type: intent.type,
            slots: intent.slots,
            confidence: adjustedConfidence,
          );
        }).toList();
        return TimelineSlot(time: slot.time, intents: newIntents);
      }).toList();

      return IntentResult(
        timelineSlots: extractedSlots,
        source: 'local',
        reason: '历史模式匹配(相似度${(bestSimilarity * 100).round()}%)',
      );
    }

    return null;
  }

  // ===== LLM 意图识别 =====

  Future<IntentResult> _llmRecognize(String text) async {
    final prompt = '''你是一个用户意图识别助手，负责分析老年人的日常语音/文字输入，将输入拆分为多个时间点，每个时间点对应一个或多个意图。

## 意图类型：
1. **behavior** - 行为记录：用户正在做或已经做了某事（吃饭、睡觉、运动、洗漱等）
2. **agenda_create** - 创建事程：用户要记得/计划做某事（含"记得"、"别忘了"、"明天"、"准备"、"一会"、"待会儿"等）
3. **agenda_complete** - 完成事程：用户完成了某个计划的事程（含"完了"、"过了"、"好了"等完成词）
4. **item_location** - 物品位置：用户放置了某物在某处（含"放"、"搁"、"塞"等动词）
5. **shopping** - 购物记录：用户在某处购买了物品
6. **inventory_consume** - 库存消耗：用户消耗了某物品（含"吃了"、"喝了"、"用了"等）
7. **general** - 通用：不属于以上任何类型

## 时间-意图映射规则（非常重要）：
- **一个时间多个意图**：例如"8点吃了药和早饭" → 时间08:00有两个意图（inventory_consume + behavior）
- **多个时间多个意图**：例如"8点吃的药，9点吃的早饭，9点半吃了饭后药" → 三个时间槽，每个一个意图
- **多个时间一个意图**：例如"昨天和今天都吃了药" → 两个时间槽，每个一个inventory_consume意图
- **无时间指定**：如果用户没有说具体时间，根据内容估测（如"吃早饭"→08:00，"吃晚饭"→18:00）

## 槽值提取规则：
- **item_location**: 提取 item_name(物品名), location(位置)
- **shopping**: 提取 store(商店名，去掉"去"、"刚去"、"到"等前缀动词), items(商品数组，每个包含name/quantity/unit), items_text(商品文本摘要)
- **agenda_create**: 提取 content(事程内容), is_must_do(是否必做，布尔), date_offset(日期偏移天数，今天=0，明天=1，后天=2，大后天=3，没有则0)
- **agenda_complete**: 提取 keyword(完成的事程关键词)
- **inventory_consume**: 提取 item_name(物品名), quantity(数量), unit(单位)
- **behavior**: 提取 keyword(行为关键词)

## 注意事项：
- 物品位置优先级高于行为记录
- "准备"、"一会"、"待会儿"、"等一下"表示未来计划 → agenda_create
- "完了"、"过了"、"好了"表示已完成 → agenda_complete
- 位置名去掉"中"、"里"、"上"、"下"、"内"等方位词
- 商店名去掉"去"、"刚去"、"到"、"去了"等前缀动词，只保留场所名称
- 时间格式统一为 HH:MM
- 购物记录中的商品数量和单位必须精确提取，不能默认1个

## 用户输入：$text

## 输出格式（严格JSON，不要其他内容）：
{
  "timelineSlots": [
    {
      "time": "08:00",
      "intents": [
        {"intent": "inventory_consume", "slots": {"item_name": "药", "quantity": 1, "unit": "片"}, "confidence": 0.95},
        {"intent": "behavior", "slots": {"keyword": "吃早饭"}, "confidence": 0.9}
      ]
    },
    {
      "time": "15:00",
      "intents": [
        {"intent": "shopping", "slots": {
          "store": "超市",
          "items": [
            {"name": "苹果", "quantity": 8, "unit": "个"},
            {"name": "梨", "quantity": 6, "unit": "个"}
          ],
          "items_text": "8个苹果、6个梨"
        }, "confidence": 0.95}
      ]
    }
  ],
  "reason": "简短说明判断理由"
}''';

    try {
      final body = jsonEncode({
        'model': _llm.config.model,
        'messages': [
          {'role': 'system', 'content': '你是一个精确的意图识别助手，只输出JSON格式结果，不要输出其他内容'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.1,
        'max_tokens': 800,
      });

      final uri = Uri.parse('${_llm.config.baseUrl}/chat/completions');
      final response = await http
          .post(uri, headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_llm.config.apiKey}',
          }, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'] as String;
        try {
          final result = jsonDecode(content);
          if (result is Map<String, dynamic>) {
            return IntentResult.fromJson({
              ...result,
              'source': 'llm',
            });
          }
        } catch (e) {
          debugPrint('LLM 返回解析失败: $e');
        }
      }
    } catch (e) {
      debugPrint('LLM 意图识别请求失败: $e');
    }

    return _ruleBasedRecognize(text);
  }

  // ===== 本地学习 =====

  void _learnPattern(String text, IntentResult result) {
    final template = _generatePatternTemplate(text, result);
    final semanticExisting = _patterns.where((p) => _isSemanticallySame(p, UserPattern(
      inputText: template,
      slots: result.timelineSlots,
      count: 1,
      lastUsed: DateTime.now(),
    ))).firstOrNull;

    final existing = _patterns.where((p) => p.inputText == template).firstOrNull ?? semanticExisting;

    if (existing != null) {
      existing.count++;
      existing.lastUsed = DateTime.now();

      if (_shouldUpdateIntent(existing.slots, result.timelineSlots)) {
        existing.slots = result.timelineSlots;
      }
    } else {
      _patterns.add(UserPattern(
        inputText: template,
        slots: result.timelineSlots,
        count: 1,
        lastUsed: DateTime.now(),
      ));

      if (_patterns.length > _maxPatterns) {
        _patterns.sort((a, b) {
          final scoreA = _calculatePatternScore(a);
          final scoreB = _calculatePatternScore(b);
          return scoreB.compareTo(scoreA);
        });
        _patterns.removeRange(0, _patterns.length - _maxPatterns);
      }
    }

    _savePatterns();
  }

  String _generatePatternTemplate(String text, IntentResult result) {
    final timePoints = _extractAllTimePoints(text);
    final dateOffsets = _extractAllDateOffsets(text);

    String timeStr = '';
    if (timePoints.isNotEmpty) {
      timeStr = timePoints.map((tp) => tp['time']).join(',');
    }

    String dateStr = '';
    if (dateOffsets.length > 1) {
      dateStr = dateOffsets.join(',');
    } else if (dateOffsets.isNotEmpty && dateOffsets[0] > 0) {
      dateStr = dateOffsets[0].toString();
    }

    var content = '';
    if (result.timelineSlots.isNotEmpty &&
        result.timelineSlots.first.intents.isNotEmpty) {
      final intent = result.timelineSlots.first.intents.first;
      content = intent.slots['content']?.toString() ?? '';
      if (content.isEmpty) {
        content = intent.slots['keyword']?.toString() ?? '';
      }
    }

    if (content.isEmpty) {
      content = _purifyAgendaContent(text);
    }

    if (content.isEmpty) {
      return text;
    }

    final parts = <String>[];
    if (dateStr.isNotEmpty) parts.add(dateStr);
    if (timeStr.isNotEmpty) parts.add(timeStr);
    parts.add(content);

    return parts.join('|');
  }

  bool _shouldUpdateIntent(List<TimelineSlot> existing, List<TimelineSlot> newSlots) {
    if (existing.isEmpty || newSlots.isEmpty) return true;

    final existingTypes = existing.expand((s) => s.intents.map((i) => i.type)).toSet();
    final newTypes = newSlots.expand((s) => s.intents.map((i) => i.type)).toSet();

    if (existingTypes != newTypes) return true;

    for (var i = 0; i < existing.length && i < newSlots.length; i++) {
      for (var j = 0; j < existing[i].intents.length && j < newSlots[i].intents.length; j++) {
        final existingIntent = existing[i].intents[j];
        final newIntent = newSlots[i].intents[j];
        if (existingIntent.type != newIntent.type) return true;
        final existingSlots = existingIntent.slots;
        final newSlotsMap = newIntent.slots;
        if (existingSlots.length != newSlotsMap.length) return true;
        for (final key in existingSlots.keys) {
          if (newSlotsMap[key] != existingSlots[key]) return true;
        }
      }
    }

    return false;
  }

  // ===== 语义合并 =====

  bool _isSemanticallySame(UserPattern p1, UserPattern p2) {
    if (p1.inputText == p2.inputText) return true;

    final type1 = _getPrimaryIntentType(p1);
    final type2 = _getPrimaryIntentType(p2);
    if (type1 != type2) return false;

    final content1 = _getPatternContent(p1);
    final content2 = _getPatternContent(p2);

    if (content1.isNotEmpty && content2.isNotEmpty) {
      if (content1 == content2) return true;
      final contentSim = _textSimilarity(content1, content2);
      if (contentSim >= 0.6) return true;
    }

    String t1 = _purifyAgendaContent(p1.inputText);
    String t2 = _purifyAgendaContent(p2.inputText);
    if (t1.isNotEmpty && t2.isNotEmpty) {
      if (t1 == t2) return true;
      final purifySim = _textSimilarity(t1, t2);
      if (purifySim >= 0.6) return true;
    }

    final textSim = _textSimilarity(p1.inputText, p2.inputText);
    return textSim >= 0.7;
  }

  String _getPatternContent(UserPattern p) {
    if (p.slots.isEmpty) return '';
    final contents = <String>[];
    for (final slot in p.slots) {
      for (final intent in slot.intents) {
        final c = intent.slots['content']?.toString() ??
            intent.slots['keyword']?.toString() ??
            intent.slots['item_name']?.toString() ??
            '';
        if (c.isNotEmpty) contents.add(c);
      }
    }
    return contents.join('|');
  }

  IntentType _getPrimaryIntentType(UserPattern p) {
    if (p.slots.isEmpty) return IntentType.general;
    final firstSlot = p.slots.first;
    if (firstSlot.intents.isEmpty) return IntentType.general;
    return firstSlot.intents.first.type;
  }

  // ===== 模式管理 API =====

  List<UserPattern> get allPatterns => List.unmodifiable(_patterns);

  List<UserPattern> getAllPatterns() => allPatterns;

  Future<void> addPattern(String text, List<TimelineSlot> slots) async {
    final existing = _patterns.where((p) => p.inputText == text).firstOrNull;

    if (existing != null) {
      existing.slots = slots;
      existing.count++;
      existing.lastUsed = DateTime.now();
    } else {
      final semanticMatch = _patterns.where((p) => _isSemanticallySame(p, UserPattern(
        inputText: text,
        slots: slots,
        count: 1,
        lastUsed: DateTime.now(),
      ))).firstOrNull;

      if (semanticMatch != null) {
        semanticMatch.count++;
        semanticMatch.lastUsed = DateTime.now();
      } else {
        _patterns.add(UserPattern(
          inputText: text,
          slots: slots,
          count: 3,
          lastUsed: DateTime.now(),
        ));
      }
    }
    await _savePatterns();
  }

  Future<void> updatePattern(String oldText, String newText, List<TimelineSlot> slots) async {
    final existingIdx = _patterns.indexWhere((p) => p.inputText == oldText);
    if (existingIdx < 0) return;
    final existing = _patterns[existingIdx];

    if (oldText != newText) {
      final newIdx = _patterns.indexWhere((p) => p.inputText == newText);
      if (newIdx >= 0) {
        _patterns[newIdx].slots = slots;
        _patterns[newIdx].count = (_patterns[newIdx].count + existing.count).clamp(1, 999);
        _patterns[newIdx].lastUsed = DateTime.now();
        _patterns.removeAt(existingIdx);
      } else {
        _patterns[existingIdx] = UserPattern(
          inputText: newText,
          slots: slots,
          count: existing.count,
          lastUsed: DateTime.now(),
        );
      }
    } else {
      _patterns[existingIdx].slots = slots;
      _patterns[existingIdx].lastUsed = DateTime.now();
    }
    await _savePatterns();
  }

  Future<void> deletePattern(String text) async {
    _patterns.removeWhere((p) => p.inputText == text);
    await _savePatterns();
  }

  List<List<UserPattern>> findSemanticDuplicates() {
    final duplicates = <List<UserPattern>>[];
    final visited = <String>{};

    for (final p1 in _patterns) {
      if (visited.contains(p1.inputText)) continue;

      final group = <UserPattern>[p1];
      for (final p2 in _patterns) {
        if (p1.inputText == p2.inputText) continue;
        if (visited.contains(p2.inputText)) continue;
        if (_isSemanticallySame(p1, p2)) {
          group.add(p2);
        }
      }

      if (group.length > 1) {
        duplicates.add(group);
        for (final p in group) {
          visited.add(p.inputText);
        }
      }
    }

    return duplicates;
  }

  Future<void> mergeSemanticPatterns([List<String>? patternTexts]) async {
    if (patternTexts == null || patternTexts.isEmpty) {
      final duplicates = findSemanticDuplicates();
      for (final group in duplicates) {
        final texts = group.map((p) => p.inputText).toList();
        await _mergeSemanticPatternGroup(texts);
      }
      return;
    }

    if (patternTexts.length < 2) return;
    await _mergeSemanticPatternGroup(patternTexts);
  }

  Future<void> _mergeSemanticPatternGroup(List<String> patternTexts) async {
    final patternsToMerge = _patterns.where((p) => patternTexts.contains(p.inputText)).toList();
    if (patternsToMerge.length < 2) return;

    final mergedSlots = patternsToMerge.expand((p) => p.slots).toList();
    final totalCount = patternsToMerge.fold(0, (sum, p) => sum + p.count);

    final mergedPattern = UserPattern(
      inputText: patternsToMerge.first.inputText,
      slots: mergedSlots,
      count: totalCount,
      lastUsed: DateTime.now(),
    );

    for (final p in patternsToMerge) {
      _patterns.remove(p);
    }
    _patterns.add(mergedPattern);
    await _savePatterns();
  }

  // ===== 统计信息 =====

  Map<String, dynamic> getStats() {
    final sorted = List<UserPattern>.from(_patterns)
      ..sort((a, b) => b.count.compareTo(a.count));
    return {
      'total_patterns': _patterns.length,
      'llm_calls': llmCallCount,
      'local_matches': localMatchCount,
      'local_hit_rate': llmCallCount + localMatchCount > 0
          ? (localMatchCount / (llmCallCount + localMatchCount) * 100).round()
          : 0,
      'top_patterns': sorted
          .take(10)
          .map((p) => {
                'text': p.inputText,
                'slots': p.slots.map((s) => {
                      'time': s.time,
                      'intents': s.intents.map((i) => i.label).toList(),
                    }).toList(),
                'count': p.count,
              })
          .toList(),
    };
  }

  Future<void> clearPatterns() async {
    _patterns = [];
    await _savePatterns();
  }

  Future<void> loadPresetPatterns() async {
    final presets = <UserPattern>[
      UserPattern(
        inputText: '钥匙放在门口鞋柜',
        slots: [
          TimelineSlot(
            time: '',
            intents: [const IntentItem(type: IntentType.itemLocation, slots: {'item_name': '钥匙', 'location': '门口鞋柜'}, confidence: 0.95)],
          ),
        ],
        count: 3,
        lastUsed: DateTime.now(),
      ),
      UserPattern(
        inputText: '在超市买了牛奶',
        slots: [
          TimelineSlot(
            time: '',
            intents: [const IntentItem(type: IntentType.shopping, slots: {'store': '超市', 'items_text': '牛奶'}, confidence: 0.95)],
          ),
        ],
        count: 3,
        lastUsed: DateTime.now(),
      ),
      UserPattern(
        inputText: '记得吃药',
        slots: [
          TimelineSlot(
            time: '08:00',
            intents: [const IntentItem(type: IntentType.agendaCreate, slots: {'content': '吃药', 'is_must_do': true}, confidence: 0.9)],
          ),
        ],
        count: 3,
        lastUsed: DateTime.now(),
      ),
      UserPattern(
        inputText: '起床，洗漱',
        slots: [
          TimelineSlot(
            time: '',
            intents: [const IntentItem(type: IntentType.behavior, slots: {'keyword': '起床洗漱'}, confidence: 0.9)],
          ),
        ],
        count: 3,
        lastUsed: DateTime.now(),
      ),
      UserPattern(
        inputText: '吃完早饭',
        slots: [
          TimelineSlot(
            time: '',
            intents: [const IntentItem(type: IntentType.behavior, slots: {'keyword': '吃早饭'}, confidence: 0.9)],
          ),
        ],
        count: 3,
        lastUsed: DateTime.now(),
      ),
    ];

    for (final p in presets) {
      final existing = _patterns.where((x) => x.inputText == p.inputText).firstOrNull;
      if (existing == null) {
        _patterns.add(p);
      }
    }
    await _savePatterns();
  }
}
