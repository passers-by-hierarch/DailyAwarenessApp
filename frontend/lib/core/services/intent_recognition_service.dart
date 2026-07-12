import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'llm_service.dart';

/// 意图类型
enum IntentType {
  behavior,        // 行为记录
  agendaCreate,    // 创建事程
  agendaComplete,  // 完成事程
  itemLocation,    // 物品位置记录
  shopping,        // 购物记录
  inventoryConsume,// 库存消耗
  general,         // 通用/其他
}

/// 单个意图项
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

/// 时间线槽位 - 一个时间点及其对应的多个意图
class TimelineSlot {
  final String time; // HH:MM 格式
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

/// 意图识别结果（支持多时间点多意图）
class IntentResult {
  final List<TimelineSlot> timelineSlots;
  final String source; // 'llm' | 'local' | 'rule'
  final String? reason;

  const IntentResult({
    required this.timelineSlots,
    required this.source,
    this.reason,
  });

  /// 所有意图的扁平化列表
  List<IntentItem> get allIntents {
    return timelineSlots.expand((slot) => slot.intents).toList();
  }

  /// 主意图（第一个时间槽的第一个意图）
  IntentItem get primary {
    return timelineSlots.isNotEmpty && timelineSlots.first.intents.isNotEmpty
        ? timelineSlots.first.intents.first
        : const IntentItem(type: IntentType.general, slots: {});
  }

  /// 主意图类型
  IntentType get primaryIntent => primary.type;

  /// 主槽值
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

/// 用户习惯模式记录
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

/// 意图识别服务 - LLM + 本地模式学习
class IntentRecognitionService {
  static const String _patternsKey = 'intent_patterns';
  static const String _presetLoadedKey = 'intent_preset_loaded';
  static const double _localConfidenceThreshold = 0.82;
  static const int _maxPatterns = 500;

  final LlmService _llm;
  SharedPreferences? _prefs;
  List<UserPattern> _patterns = [];

  int llmCallCount = 0;
  int localMatchCount = 0;

  IntentRecognitionService(this._llm);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPatterns();
    await _ensurePresetLoaded();
  }

  Future<void> _ensurePresetLoaded() async {
    final loaded = _prefs?.getBool(_presetLoadedKey) ?? false;
    // 如果从未加载过预设，或者当前模式列表为空（可能被清空了），则加载预设
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
  }

  /// 识别意图 - 主入口
  Future<IntentResult> recognize(String text) async {
    final t = text.trim();
    if (t.isEmpty) {
      return IntentResult.single(IntentType.general, {}, 0, 'rule', '空输入');
    }

    // 1. 先尝试本地模式匹配
    final localResult = _matchLocalPattern(t);
    if (localResult != null) {
      double maxConf = localResult.allIntents.fold(0.0, (m, i) => i.confidence > m ? i.confidence : m);
      if (maxConf >= _localConfidenceThreshold) {
        localMatchCount++;
        return localResult;
      }
    }

    // 2. LLM未配置 → 使用规则匹配
    if (!_llm.isConfigured) {
      return _ruleBasedRecognize(t);
    }

    // 3. 调用LLM识别
    llmCallCount++;
    final llmResult = await _llmRecognize(t);

    // 4. 保存到本地模式库（学习）
    _learnPattern(t, llmResult);

    return llmResult;
  }

  // ===== 本地模式匹配 =====

  IntentResult? _matchLocalPattern(String text) {
    if (_patterns.isEmpty) return null;

    // 完全匹配
    for (final p in _patterns) {
      if (p.inputText == text && p.count >= 2) {
        return IntentResult(
          timelineSlots: p.slots,
          source: 'local',
          reason: '历史模式匹配(完全匹配，出现${p.count}次)',
        );
      }
    }

    // 模糊匹配
    UserPattern? bestMatch;
    double bestScore = 0;

    for (final p in _patterns) {
      if (p.count < 2) continue;
      final score = _textSimilarity(text, p.inputText);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = p;
      }
    }

    if (bestMatch != null && bestScore >= 0.7) {
      final extractedSlots = bestMatch.slots.map((slot) {
        final newIntents = slot.intents.map((intent) {
          // 模糊匹配时提高置信度，避免 confidence * score 导致阈值无法通过
          final adjustedConfidence = (intent.confidence * 0.5 + bestScore * 0.5).clamp(0.0, 1.0);
          return IntentItem(
            type: intent.type,
            slots: _extractSlotsFromSimilar(text, intent),
            confidence: adjustedConfidence,
          );
        }).toList();
        return TimelineSlot(time: slot.time, intents: newIntents);
      }).toList();

      return IntentResult(
        timelineSlots: extractedSlots,
        source: 'local',
        reason: '历史模式匹配(相似度${(bestScore * 100).round()}%)',
      );
    }

    return null;
  }

  Map<String, dynamic> _extractSlotsFromSimilar(String newText, IntentItem pattern) {
    final slots = Map<String, dynamic>.from(pattern.slots);

    if (pattern.type == IntentType.itemLocation) {
      final itemMatch = RegExp(
        r'(?:把|将)?\s*([\u4e00-\u9fa5A-Za-z]{1,8}?)\s*(?:放|搁|塞)(?:在|到)?(?:了)?\s*([\u4e00-\u9fa5A-Za-z]+)',
      ).firstMatch(newText);
      if (itemMatch != null) {
        slots['item_name'] = itemMatch.group(1)!.trim();
        slots['location'] = itemMatch.group(2)!
            .trim()
            .replaceAll(RegExp(r'^(在|到)'), '')
            .replaceAll(RegExp(r'(中|里|上|下|内)$'), '');
      }
    }

    if (pattern.type == IntentType.shopping) {
      final buyMatch = RegExp(r'在?(.+?)买了(.+)').firstMatch(newText);
      if (buyMatch != null) {
        slots['store'] = buyMatch.group(1)!.trim();
        slots['items_text'] = buyMatch.group(2)!.trim();
      }
    }

    return slots;
  }

  double _textSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final aChars = a.split('');
    final bChars = b.split('');
    final common = aChars.where((c) => bChars.contains(c)).length;
    final overlap = common / (aChars.length + bChars.length) * 2;

    final dist = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    final distanceScore = 1.0 - (dist / maxLen);

    return (overlap * 0.4 + distanceScore * 0.6).clamp(0.0, 1.0);
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
        final json = jsonDecode(response.body);
        final content = json['choices']?[0]?['message']?['content'] as String?;
        if (content != null) {
          final cleanContent = content
              .replaceAll(RegExp(r'```json\s*'), '')
              .replaceAll(RegExp(r'```\s*'), '')
              .trim();
          final result = jsonDecode(cleanContent);
          return IntentResult.fromJson({
            ...result as Map<String, dynamic>,
            'source': 'llm',
          });
        }
      }
    } catch (e) {
      debugPrint('LLM 意图识别请求失败: $e');
    }

    return _ruleBasedRecognize(text);
  }

  // ===== 本地学习 =====

  void _learnPattern(String text, IntentResult result) {
    final existing = _patterns.where((p) => p.inputText == text).firstOrNull;

    if (existing != null) {
      existing.count++;
      existing.lastUsed = DateTime.now();
      existing.slots = result.timelineSlots;
    } else {
      _patterns.add(UserPattern(
        inputText: text,
        slots: result.timelineSlots,
        count: 1,
        lastUsed: DateTime.now(),
      ));

      if (_patterns.length > _maxPatterns) {
        _patterns.sort((a, b) =>
          a.count.compareTo(b.count) == 0
            ? a.lastUsed.compareTo(b.lastUsed)
            : a.count.compareTo(b.count));
        _patterns.removeRange(0, _patterns.length - _maxPatterns);
      }
    }

    _savePatterns();
  }

  /// 手动添加/更新模式（用于用户纠正）
  Future<void> addPattern(String text, List<TimelineSlot> slots) async {
    final existing = _patterns.where((p) => p.inputText == text).firstOrNull;
    if (existing != null) {
      existing.slots = slots;
      existing.count++;
      existing.lastUsed = DateTime.now();
    } else {
      _patterns.add(UserPattern(
        inputText: text,
        slots: slots,
        count: 3,
        lastUsed: DateTime.now(),
      ));
    }
    await _savePatterns();
  }

  /// 更新模式（编辑用，保留count）
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

  /// 删除模式
  Future<void> deletePattern(String text) async {
    _patterns.removeWhere((p) => p.inputText == text);
    await _savePatterns();
  }

  // ===== 规则匹配（离线兜底，支持多意图） =====

  /// 从文本中提取时间，返回 HH:MM 格式
  String? _extractTime(String text) {
    final timeMatch = RegExp(r'(\d{1,2})(?:点|时)(\d{1,2})?(?:分|半)?').firstMatch(text);
    if (timeMatch != null) {
      final hour = int.tryParse(timeMatch.group(1) ?? '') ?? 0;
      final minute = int.tryParse(timeMatch.group(2) ?? '') ?? 0;
      if (timeMatch.group(0)!.contains('半') && timeMatch.group(2) == null) {
        return '${hour.toString().padLeft(2, '0')}:30';
      }
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  IntentResult _ruleBasedRecognize(String t) {
    final now = DateTime.now();
    final defaultTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final timePoints = _extractAllTimePoints(t);
    
    if (timePoints.isEmpty) {
      final intents = _recognizeSingleClause(t, defaultTime);
      return IntentResult(
        timelineSlots: [TimelineSlot(time: defaultTime, intents: intents)],
        source: 'rule',
        reason: '规则匹配(无时间点)',
      );
    }

    final slots = <TimelineSlot>[];
    String remainingText = t;

    for (final timePoint in timePoints) {
      final timeStr = timePoint['time'] as String;
      final start = timePoint['start'] as int;
      final end = timePoint['end'] as int;

      String clause;
      if (start > 0) {
        final prevEnd = slots.isEmpty ? 0 : timePoints[slots.length - 1]['end'] as int;
        clause = remainingText.substring(prevEnd, start).trim();
      } else {
        clause = remainingText.substring(start, end).trim();
      }

      if (clause.isEmpty && start > 0) {
        final nextStart = timePoint['start'] as int;
        final prevEnd = slots.isEmpty ? 0 : timePoints[slots.length - 1]['end'] as int;
        clause = remainingText.substring(prevEnd, nextStart).trim();
      }

      if (clause.isEmpty) {
        clause = remainingText.substring(start).trim();
      }

      final intents = _recognizeSingleClause(clause, timeStr);
      if (intents.isNotEmpty) {
        slots.add(TimelineSlot(time: timeStr, intents: intents));
      }
    }

    final lastTimeEnd = timePoints.last['end'] as int;
    final lastClause = t.substring(lastTimeEnd).trim();
    if (lastClause.isNotEmpty) {
      final intents = _recognizeSingleClause(lastClause, defaultTime);
      if (intents.isNotEmpty) {
        slots.add(TimelineSlot(time: defaultTime, intents: intents));
      }
    }

    if (slots.isEmpty) {
      final intents = _recognizeSingleClause(t, defaultTime);
      slots.add(TimelineSlot(time: defaultTime, intents: intents));
    }

    return IntentResult(
      timelineSlots: slots,
      source: 'rule',
      reason: '规则匹配(多时间点拆分)',
    );
  }

  List<Map<String, dynamic>> _extractAllTimePoints(String text) {
    final matches = RegExp(r'(\d{1,2})(?:点|时)(\d{1,2})?(?:分|半)?').allMatches(text);
    final results = <Map<String, dynamic>>[];
    
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
      });
    }
    
    results.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));
    return results;
  }

  /// 从文本中提取日期偏移天数
  int _extractDateOffset(String text) {
    if (text.contains('大后天')) return 3;
    if (text.contains('后天')) return 2;
    if (text.contains('明天')) return 1;
    if (text.contains('今天') || text.contains('今日')) return 0;
    return 0;
  }

  List<IntentItem> _recognizeSingleClause(String clause, String timeStr) {
    final intents = <IntentItem>[];
    if (clause.isEmpty) return intents;

    // 物品位置
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

    // 购物
    final buyMatch = RegExp(r'(?:刚去|去|到|在)?(.+?)(?:买了|买)(.+)').firstMatch(clause);
    if (buyMatch != null) {
      var store = buyMatch.group(1)!.trim();
      store = store
          .replaceAll(RegExp(r'^(刚去|去|到|在)'), '')
          .trim();
      final itemsText = buyMatch.group(2)!.trim();
      
      // 解析商品列表：数量+单位+名称 或 名称+数量+单位
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
      
      // 另一种格式：名称+数量+单位
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

    // 事程创建关键词
    final reminderKeywords = ['记得', '别忘了', '提醒我', '要记得', '一定要', '需要', '要做', '得去', '准备', '一会', '待会儿', '等一下', '回头'];
    final futureTimeKeywords = ['明天', '下周', '下次', '以后'];
    final dateOffset = _extractDateOffset(clause);
    if (reminderKeywords.any((kw) => clause.contains(kw)) ||
        futureTimeKeywords.any((kw) => clause.contains(kw))) {
      final slots = <String, dynamic>{'content': clause};
      if (dateOffset > 0) {
        slots['date_offset'] = dateOffset;
      }
      intents.add(IntentItem(
        type: IntentType.agendaCreate,
        slots: slots,
        confidence: 0.75,
      ));
    }

    // 事程完成
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

    // 库存消耗
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

    // 行为
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

  // ===== 统计信息 =====

  List<UserPattern> get allPatterns => List.unmodifiable(_patterns);

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

  /// 加载预设常见模式（快速上手）
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
