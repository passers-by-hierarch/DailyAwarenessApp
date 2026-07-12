import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import 'llm_service.dart';

/// 语义匹配结果
class SemanticMatchResult {
  final bool matched;
  final String? matchedId;
  final String? matchedName;
  final String source; // 'local' | 'llm' | 'none'
  final double confidence;
  final String reason;

  const SemanticMatchResult({
    this.matched = false,
    this.matchedId,
    this.matchedName,
    this.source = 'none',
    this.confidence = 0,
    this.reason = '',
  });

  factory SemanticMatchResult.local(String id, String name, double confidence, String reason) {
    return SemanticMatchResult(
      matched: true,
      matchedId: id,
      matchedName: name,
      source: 'local',
      confidence: confidence,
      reason: reason,
    );
  }

  factory SemanticMatchResult.llm(String id, String name, double confidence, String reason) {
    return SemanticMatchResult(
      matched: true,
      matchedId: id,
      matchedName: name,
      source: 'llm',
      confidence: confidence,
      reason: reason,
    );
  }

  static const SemanticMatchResult none = SemanticMatchResult();
}

/// 本地语义规则
class LocalSemanticRule {
  final String pattern;
  final String extractField; // 提取字段名
  final RegExp? regex;

  LocalSemanticRule({required this.pattern, required this.extractField, this.regex});
}

/// 统一语义匹配服务
///
/// 策略：本地规则优先 → 本地模式匹配 → 大模型降级
/// 支持学习积累，逐步减少大模型调用
class SemanticMatchService {
  final LlmService _llm;

  // 本地学习库：记录用户输入与匹配结果的映射
  final Map<String, _LearnedMatch> _agendaLearnings = {};
  final Map<String, _LearnedMatch> _inventoryLearnings = {};
  final Map<String, _LearnedMatch> _locationLearnings = {};

  // 本地规则：常见助词/前缀/后缀
  static final RegExp _cleanPattern = RegExp(r'[了着过刚正在已经准备一下]');
  static final RegExp _prefixPattern = RegExp(r'^(刚|才|刚刚|已经|正在|准备|要|去|在|把|将|我|今天|明天|刚才)');

  // 常见动词映射
  static const Map<String, String> _verbAliases = {
    '服用': '吃',
    '服': '吃',
    '喝了': '喝',
    '吃了': '吃',
    '用了': '用',
  };

  // 物品名称常见缩写/别名
  static const Map<String, List<String>> _itemAliases = {
    '安眠药': ['安眠药', '助眠药', '睡眠药'],
    '降压药': ['降压药', '血压药'],
    '降糖药': ['降糖药', '血糖药'],
    '感冒药': ['感冒药', '感冒胶囊'],
  };

  int llmCallCount = 0;
  int localMatchCount = 0;
  int totalMatches = 0;

  // 自动发现的物品别名（从匹配记录中挖掘）
  final Map<String, Set<String>> _discoveredAliases = {};

  // 时间-行为模式：时间槽(HH) -> 事程id列表（按频次排序）
  final Map<String, List<_TimePatternEntry>> _timePatterns = {};

  SemanticMatchService(this._llm);

  bool get _llmAvailable => _llm.isConfigured;

  /// 动态模糊匹配阈值：随使用量增长而降低（越来越信任本地）
  double get _fuzzyThreshold {
    if (totalMatches < 10) return 0.85;
    if (totalMatches < 50) return 0.80;
    if (totalMatches < 200) return 0.75;
    if (totalMatches < 500) return 0.70;
    return 0.65;
  }

  /// 动态学习门槛：匹配次数达到多少才算"学会了"
  int get _learnThreshold {
    if (totalMatches < 20) return 3;
    if (totalMatches < 100) return 2;
    return 2;
  }

  // ===== 事程匹配 =====

  /// 匹配事程：本地规则优先 → 大模型降级
  Future<SemanticMatchResult> matchAgenda({
    required String recordContent,
    required List<AgendaItem> candidates,
    required DateTime recordTime,
  }) async {
    // 1. 本地学习库匹配
    final learned = _matchLearned(recordContent, _agendaLearnings);
    if (learned != null) {
      final agenda = candidates.where((a) => a.id == learned.matchedId).firstOrNull;
      if (agenda != null) {
        localMatchCount++;
        _recordTimePattern(recordTime, agenda.id, agenda.content);
        return SemanticMatchResult.local(
          agenda.id,
          agenda.content,
          learned.confidence,
          '本地学习库匹配',
        );
      }
    }

    // 2. 时间-行为模式匹配（老年人作息规律，时间槽预测准确率很高）
    final timePatternResult = _matchByTimePattern(recordTime, candidates);
    if (timePatternResult.matched) {
      localMatchCount++;
      _learn(recordContent, timePatternResult.matchedId!, timePatternResult.matchedName!,
          timePatternResult.confidence, _agendaLearnings);
      _recordTimePattern(recordTime, timePatternResult.matchedId!, timePatternResult.matchedName!);
      return timePatternResult;
    }

    // 3. 本地规则匹配
    final localResult = _localMatchAgenda(recordContent, candidates);
    if (localResult.matched) {
      localMatchCount++;
      _learn(recordContent, localResult.matchedId!, localResult.matchedName!,
          localResult.confidence, _agendaLearnings);
      _recordTimePattern(recordTime, localResult.matchedId!, localResult.matchedName!);
      return localResult;
    }

    // 4. 大模型降级
    if (_llmAvailable && candidates.isNotEmpty) {
      llmCallCount++;
      final llmResult = await _llmMatchAgenda(recordContent, candidates, recordTime);
      if (llmResult.matched) {
        _learn(recordContent, llmResult.matchedId!, llmResult.matchedName!,
            llmResult.confidence, _agendaLearnings);
        _recordTimePattern(recordTime, llmResult.matchedId!, llmResult.matchedName!);
      }
      return llmResult;
    }

    return SemanticMatchResult.none;
  }

  // ===== 库存匹配 =====

  /// 匹配库存物品：本地规则优先 → 大模型降级
  Future<SemanticMatchResult> matchInventory({
    required String recordContent,
    required List<InventoryItem> candidates,
  }) async {
    // 1. 本地学习库匹配
    final learned = _matchLearned(recordContent, _inventoryLearnings);
    if (learned != null) {
      final item = candidates.where((i) => i.id == learned.matchedId).firstOrNull;
      if (item != null) {
        localMatchCount++;
        _discoverAlias(recordContent, item.name, _inventoryLearnings);
        return SemanticMatchResult.local(
          item.id,
          item.name,
          learned.confidence,
          '本地学习库匹配',
        );
      }
    }

    // 2. 本地规则匹配
    final localResult = _localMatchInventory(recordContent, candidates);
    if (localResult.matched) {
      localMatchCount++;
      _learn(recordContent, localResult.matchedId!, localResult.matchedName!,
          localResult.confidence, _inventoryLearnings);
      _discoverAlias(recordContent, localResult.matchedName!, _inventoryLearnings);
      return localResult;
    }

    // 3. 大模型降级
    if (_llmAvailable && candidates.isNotEmpty) {
      llmCallCount++;
      final llmResult = await _llmMatchInventory(recordContent, candidates);
      if (llmResult.matched) {
        _learn(recordContent, llmResult.matchedId!, llmResult.matchedName!,
            llmResult.confidence, _inventoryLearnings);
        _discoverAlias(recordContent, llmResult.matchedName!, _inventoryLearnings);
      }
      return llmResult;
    }

    return SemanticMatchResult.none;
  }

  // ===== 物品位置匹配 =====

  /// 匹配物品位置：本地规则优先 → 大模型降级
  Future<SemanticMatchResult> matchItemLocation({
    required String recordContent,
    required List<ItemRecord> candidates,
  }) async {
    // 1. 本地学习库匹配
    final learned = _matchLearned(recordContent, _locationLearnings);
    if (learned != null) {
      final item = candidates.where((i) => i.id == learned.matchedId).firstOrNull;
      if (item != null) {
        localMatchCount++;
        _discoverAlias(recordContent, item.name, _locationLearnings);
        return SemanticMatchResult.local(
          item.id,
          item.name,
          learned.confidence,
          '本地学习库匹配',
        );
      }
    }

    // 2. 本地规则匹配
    final localResult = _localMatchLocation(recordContent, candidates);
    if (localResult.matched) {
      localMatchCount++;
      _learn(recordContent, localResult.matchedId!, localResult.matchedName!,
          localResult.confidence, _locationLearnings);
      _discoverAlias(recordContent, localResult.matchedName!, _locationLearnings);
      return localResult;
    }

    // 3. 大模型降级
    if (_llmAvailable && candidates.isNotEmpty) {
      llmCallCount++;
      final llmResult = await _llmMatchLocation(recordContent, candidates);
      if (llmResult.matched) {
        _learn(recordContent, llmResult.matchedId!, llmResult.matchedName!,
            llmResult.confidence, _locationLearnings);
        _discoverAlias(recordContent, llmResult.matchedName!, _locationLearnings);
      }
      return llmResult;
    }

    return SemanticMatchResult.none;
  }

  // ===== 本地规则匹配：事程 =====

  SemanticMatchResult _localMatchAgenda(String recordContent, List<AgendaItem> candidates) {
    final recordClean = _cleanText(recordContent);

    for (final agenda in candidates) {
      final agendaClean = _cleanText(agenda.content);

      // 直接包含匹配
      if (recordClean.contains(agendaClean) || agendaClean.contains(recordClean)) {
        return SemanticMatchResult.local(
          agenda.id,
          agenda.content,
          0.9,
          '规则匹配：内容包含',
        );
      }

      // 动词别名匹配：记录"吃了安眠药" → 事程"吃安眠药"
      for (final alias in _verbAliases.entries) {
        final recordVariant = recordClean.replaceAll(alias.key, alias.value);
        final agendaVariant = agendaClean.replaceAll(alias.key, alias.value);
        if (recordVariant.contains(agendaVariant) || agendaVariant.contains(recordVariant)) {
          return SemanticMatchResult.local(
            agenda.id,
            agenda.content,
            0.85,
            '规则匹配：动词别名',
          );
        }
      }

      // 关键词匹配：提取核心词
      final recordKeywords = _extractCoreWords(recordClean);
      final agendaKeywords = _extractCoreWords(agendaClean);
      if (agendaKeywords.isNotEmpty &&
          agendaKeywords.every((kw) => recordKeywords.any((rk) => rk.contains(kw) || kw.contains(rk)))) {
        return SemanticMatchResult.local(
          agenda.id,
          agenda.content,
          0.8,
          '规则匹配：关键词',
        );
      }
    }

    return SemanticMatchResult.none;
  }

  // ===== 本地规则匹配：库存 =====

  SemanticMatchResult _localMatchInventory(String recordContent, List<InventoryItem> candidates) {
    final recordClean = _cleanText(recordContent);

    for (final item in candidates) {
      final itemName = _cleanText(item.name);

      // 直接包含匹配
      if (recordClean.contains(itemName) || itemName.contains(recordClean)) {
        return SemanticMatchResult.local(
          item.id,
          item.name,
          0.9,
          '规则匹配：物品名包含',
        );
      }

      // 系统别名 + 自动发现的别名匹配
      final allAliases = _getAllAliases(item.name);
      for (final variant in allAliases) {
        if (recordClean.contains(variant) || variant.contains(recordClean)) {
          return SemanticMatchResult.local(
            item.id,
            item.name,
            0.85,
            '规则匹配：物品别名',
          );
        }
      }
    }

    return SemanticMatchResult.none;
  }

  // ===== 本地规则匹配：物品位置 =====

  SemanticMatchResult _localMatchLocation(String recordContent, List<ItemRecord> candidates) {
    final recordClean = _cleanText(recordContent);

    for (final item in candidates) {
      final itemName = _cleanText(item.name);

      if (recordClean.contains(itemName) || itemName.contains(recordClean)) {
        return SemanticMatchResult.local(
          item.id,
          item.name,
          0.9,
          '规则匹配：物品名包含',
        );
      }
    }

    return SemanticMatchResult.none;
  }

  // ===== 大模型匹配 =====

  Future<SemanticMatchResult> _llmMatchAgenda(
    String recordContent, List<AgendaItem> candidates, DateTime recordTime,
  ) async {
    try {
      final candidatesText = candidates.asMap().entries.map((e) {
        return '${e.key + 1}. ${e.value.date} ${e.value.time} ${e.value.content}';
      }).join('\n');

      final prompt = '''你是一个事程匹配助手，负责判断用户的语音记录是否对应某个待办事程。

## 用户记录
时间：${recordTime.hour.toString().padLeft(2, '0')}:${recordTime.minute.toString().padLeft(2, '0')}
内容：$recordContent

## 候选事程
$candidatesText

## 判断规则
1. 分析用户记录的语义，判断是否在描述完成某个事程
2. 如果匹配，返回最相似的事程序号
3. 如果没有匹配的，返回0

## 输出格式（纯数字）
只输出一个数字：匹配的事程序号（1, 2, 3...），没有匹配返回0''';

      final response = await _llm.chat([ChatMsg('user', prompt)]);
      final matchNum = int.tryParse(response.trim().replaceAll(RegExp(r'[^0-9]'), ''));

      if (matchNum != null && matchNum > 0 && matchNum <= candidates.length) {
        final matched = candidates[matchNum - 1];
        return SemanticMatchResult.llm(
          matched.id,
          matched.content,
          0.9,
          '大模型语义匹配',
        );
      }
    } catch (e) {
      debugPrint('LLM事程匹配失败: $e');
    }
    return SemanticMatchResult.none;
  }

  Future<SemanticMatchResult> _llmMatchInventory(
    String recordContent, List<InventoryItem> candidates,
  ) async {
    try {
      final candidatesText = candidates.asMap().entries.map((e) {
        return '${e.key + 1}. ${e.value.name}（库存${e.value.quantity}${e.value.unit}）';
      }).join('\n');

      final prompt = '''你是一个库存物品匹配助手，负责判断用户的记录是否在消耗某个库存物品。

## 用户记录
$recordContent

## 库存物品
$candidatesText

## 判断规则
1. 分析用户记录的语义，判断是否在消耗某个库存物品
2. 如果匹配，返回最相似的物品序号
3. 如果没有匹配的，返回0

## 输出格式（纯数字）
只输出一个数字：匹配的物品序号（1, 2, 3...），没有匹配返回0''';

      final response = await _llm.chat([ChatMsg('user', prompt)]);
      final matchNum = int.tryParse(response.trim().replaceAll(RegExp(r'[^0-9]'), ''));

      if (matchNum != null && matchNum > 0 && matchNum <= candidates.length) {
        final matched = candidates[matchNum - 1];
        return SemanticMatchResult.llm(
          matched.id,
          matched.name,
          0.85,
          '大模型语义匹配',
        );
      }
    } catch (e) {
      debugPrint('LLM库存匹配失败: $e');
    }
    return SemanticMatchResult.none;
  }

  Future<SemanticMatchResult> _llmMatchLocation(
    String recordContent, List<ItemRecord> candidates,
  ) async {
    try {
      final candidatesText = candidates.asMap().entries.map((e) {
        return '${e.key + 1}. ${e.value.name}（当前位置：${e.value.location}）';
      }).join('\n');

      final prompt = '''你是一个物品位置匹配助手，负责判断用户的记录是否在更新某个物品的位置。

## 用户记录
$recordContent

## 物品列表
$candidatesText

## 判断规则
1. 分析用户记录的语义，判断是否在更新某个物品的位置
2. 如果匹配，返回最相似的物品序号
3. 如果没有匹配的，返回0

## 输出格式（纯数字）
只输出一个数字：匹配的物品序号（1, 2, 3...），没有匹配返回0''';

      final response = await _llm.chat([ChatMsg('user', prompt)]);
      final matchNum = int.tryParse(response.trim().replaceAll(RegExp(r'[^0-9]'), ''));

      if (matchNum != null && matchNum > 0 && matchNum <= candidates.length) {
        final matched = candidates[matchNum - 1];
        return SemanticMatchResult.llm(
          matched.id,
          matched.name,
          0.85,
          '大模型语义匹配',
        );
      }
    } catch (e) {
      debugPrint('LLM物品位置匹配失败: $e');
    }
    return SemanticMatchResult.none;
  }

  // ===== 工具方法 =====

  String _cleanText(String text) {
    String result = text;
    // 移除前缀
    result = result.replaceAll(_prefixPattern, '');
    // 移除助词
    result = result.replaceAll(_cleanPattern, '');
    return result.trim();
  }

  List<String> _extractCoreWords(String text) {
    // 移除常见助词和前缀
    String clean = _cleanText(text);

    // 按常见动词分割，提取核心词
    final verbs = ['吃', '喝', '用', '服', '睡', '起', '做', '去', '到', '看', '读', '写', '练', '走', '跑', '运动'];
    for (final verb in verbs) {
      if (clean.contains(verb)) {
        final idx = clean.indexOf(verb);
        if (idx >= 0) {
          clean = clean.substring(idx);
        }
        break;
      }
    }

    return [clean.trim()];
  }

  // ===== 时间-行为模式 =====

  /// 根据时间槽匹配事程：老年人作息规律，同时间段通常做同一件事
  SemanticMatchResult _matchByTimePattern(DateTime recordTime, List<AgendaItem> candidates) {
    final hourKey = recordTime.hour.toString().padLeft(2, '0');
    final patterns = _timePatterns[hourKey];
    if (patterns == null || patterns.isEmpty) return SemanticMatchResult.none;

    // 按频次排序，取前3个高频事程
    final sorted = List<_TimePatternEntry>.from(patterns)
      ..sort((a, b) => b.count.compareTo(a.count));
    final topPatterns = sorted.take(3).toList();

    for (final pattern in topPatterns) {
      if (pattern.count < 2) continue; // 至少出现2次才认为是模式
      final candidate = candidates.where((a) => a.id == pattern.agendaId).firstOrNull;
      if (candidate != null) {
        // 时间越接近事程时间，置信度越高
        final agendaHour = int.tryParse(candidate.time.split(':')[0]) ?? recordTime.hour;
        final hourDiff = (agendaHour - recordTime.hour).abs();
        final timeBonus = hourDiff <= 1 ? 0.1 : (hourDiff <= 2 ? 0.05 : 0);
        final confidence = (0.7 + timeBonus).clamp(0.0, 0.9);
        return SemanticMatchResult.local(
          candidate.id,
          candidate.content,
          confidence,
          '时间模式匹配（${hourKey}点常见事程）',
        );
      }
    }

    return SemanticMatchResult.none;
  }

  /// 记录时间-行为模式：每次匹配成功都更新
  void _recordTimePattern(DateTime recordTime, String agendaId, String agendaContent) {
    final hourKey = recordTime.hour.toString().padLeft(2, '0');
    final patterns = _timePatterns.putIfAbsent(hourKey, () => []);

    final existing = patterns.where((p) => p.agendaId == agendaId).firstOrNull;
    if (existing != null) {
      existing.count++;
      existing.lastUsed = DateTime.now();
    } else {
      patterns.add(_TimePatternEntry(
        agendaId: agendaId,
        agendaContent: agendaContent,
        count: 1,
        lastUsed: DateTime.now(),
      ));
    }

    // 每个时间槽最多保留10个模式
    if (patterns.length > 10) {
      patterns.sort((a, b) => b.count.compareTo(a.count));
      patterns.removeRange(10, patterns.length);
    }
  }

  // ===== 物品别名自动发现 =====

  /// 从匹配记录中自动发现物品别名
  /// 当不同名称匹配到同一个物品时，记录为别名关系
  void _discoverAlias(String inputName, String canonicalName, Map<String, _LearnedMatch> learnings) {
    if (inputName == canonicalName) return;
    final cleanInput = _cleanText(inputName);
    final cleanCanonical = _cleanText(canonicalName);
    if (cleanInput == cleanCanonical) return;

    final aliases = _discoveredAliases.putIfAbsent(cleanCanonical, () => <String>{});
    if (!aliases.contains(cleanInput)) {
      aliases.add(cleanInput);
      debugPrint('发现物品别名: $cleanInput → $cleanCanonical');
    }
  }

  /// 获取某物品的所有别名（系统别名 + 自动发现的别名）
  Set<String> _getAllAliases(String itemName) {
    final result = <String>{};
    final cleanName = _cleanText(itemName);

    for (final entry in _itemAliases.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        result.addAll(entry.value);
      }
    }

    for (final entry in _discoveredAliases.entries) {
      if (entry.key.contains(cleanName) || cleanName.contains(entry.key)) {
        result.addAll(entry.value);
        result.add(entry.key);
      }
    }

    return result;
  }

  // ===== 学习积累 =====

  _LearnedMatch? _matchLearned(String input, Map<String, _LearnedMatch> learnings) {
    final threshold = _learnThreshold;
    // 完全匹配
    final exact = learnings[input];
    if (exact != null && exact.count >= threshold) {
      return exact;
    }

    // 模糊匹配（使用动态阈值）
    _LearnedMatch? bestMatch;
    double bestScore = 0;
    for (final entry in learnings.entries) {
      if (entry.value.count < threshold) continue;
      final score = _textSimilarity(input, entry.key);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = entry.value;
      }
    }
    if (bestMatch != null && bestScore >= _fuzzyThreshold) {
      return bestMatch;
    }
    return null;
  }

  void _learn(String input, String matchedId, String matchedName,
      double confidence, Map<String, _LearnedMatch> learnings) {
    totalMatches++;
    final existing = learnings[input];
    if (existing != null) {
      existing.count++;
      existing.lastUsed = DateTime.now();
    } else {
      learnings[input] = _LearnedMatch(
        matchedId: matchedId,
        matchedName: matchedName,
        confidence: confidence,
        count: 1,
        lastUsed: DateTime.now(),
      );
    }
  }

  /// 正向反馈：用户确认匹配正确，强化学习（+3次计数）
  void reinforceMatch(String input, String matchedId, String matchedName,
      Map<String, _LearnedMatch> learnings) {
    final existing = learnings[input];
    if (existing != null) {
      existing.count += 3;
      existing.confidence = (existing.confidence + 0.1).clamp(0.0, 1.0);
      existing.lastUsed = DateTime.now();
    } else {
      learnings[input] = _LearnedMatch(
        matchedId: matchedId,
        matchedName: matchedName,
        confidence: 0.95,
        count: 3,
        lastUsed: DateTime.now(),
      );
    }
  }

  /// 负向反馈：用户纠正/删除匹配，削弱（-1次计数，低于0移除）
  void weakenMatch(String input, Map<String, _LearnedMatch> learnings) {
    final existing = learnings[input];
    if (existing != null) {
      existing.count--;
      existing.confidence = (existing.confidence - 0.15).clamp(0.0, 1.0);
      if (existing.count <= 0) {
        learnings.remove(input);
      }
    }
  }

  /// 事程匹配的正向反馈入口
  void reinforceAgendaMatch(String input, String agendaId, String agendaName) {
    reinforceMatch(input, agendaId, agendaName, _agendaLearnings);
  }

  /// 事程匹配的负向反馈入口
  void weakenAgendaMatch(String input) {
    weakenMatch(input, _agendaLearnings);
  }

  /// 库存匹配的正向反馈入口
  void reinforceInventoryMatch(String input, String itemId, String itemName) {
    reinforceMatch(input, itemId, itemName, _inventoryLearnings);
  }

  /// 库存匹配的负向反馈入口
  void weakenInventoryMatch(String input) {
    weakenMatch(input, _inventoryLearnings);
  }

  /// 位置匹配的正向反馈入口
  void reinforceLocationMatch(String input, String itemId, String itemName) {
    reinforceMatch(input, itemId, itemName, _locationLearnings);
  }

  /// 位置匹配的负向反馈入口
  void weakenLocationMatch(String input) {
    weakenMatch(input, _locationLearnings);
  }

  double _textSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final aChars = a.split('');
    final bChars = b.split('');
    final common = aChars.where((c) => bChars.contains(c)).length;
    return common / (aChars.length + bChars.length) * 2;
  }

  /// 获取统计信息
  Map<String, dynamic> getStats() {
    final total = llmCallCount + localMatchCount;
    return {
      'total_matches': totalMatches,
      'llm_calls': llmCallCount,
      'local_matches': localMatchCount,
      'local_hit_rate': total > 0
          ? (localMatchCount / total * 100).round()
          : 0,
      'fuzzy_threshold': _fuzzyThreshold,
      'learn_threshold': _learnThreshold,
      'agenda_learnings': _agendaLearnings.length,
      'inventory_learnings': _inventoryLearnings.length,
      'location_learnings': _locationLearnings.length,
      'discovered_aliases': _discoveredAliases.length,
      'time_patterns': _timePatterns.length,
    };
  }
}

class _LearnedMatch {
  final String matchedId;
  final String matchedName;
  double confidence;
  int count;
  DateTime lastUsed;

  _LearnedMatch({
    required this.matchedId,
    required this.matchedName,
    required this.confidence,
    this.count = 1,
    required this.lastUsed,
  });
}

class _TimePatternEntry {
  final String agendaId;
  final String agendaContent;
  int count;
  DateTime lastUsed;

  _TimePatternEntry({
    required this.agendaId,
    required this.agendaContent,
    this.count = 1,
    required this.lastUsed,
  });
}
