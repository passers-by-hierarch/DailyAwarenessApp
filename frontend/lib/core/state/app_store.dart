import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../models/question_types.dart';
import '../mock/mock_data.dart';
import '../services/llm_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/intent_recognition_service.dart';
import '../services/semantic_match_service.dart';

/// 全局应用状态 - 对齐 web-prototype/src/store/appStore.ts
/// 使用 Provider + ChangeNotifier 实现 Zustand 单 Store 模式
class AppStore extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notification = NotificationService();
  final LlmService _llm = LlmService();
  late final SemanticMatchService _semanticMatch;
  IntentRecognitionService? _intentService;
  final Completer<void> _initCompleter = Completer<void>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ===== 测试时钟 =====
  DateTime? _testTime;
  bool _testMode = false;
  Timer? _testTimer;
  Timer? _expiryCheckTimer;

  bool get isTestMode => _testMode;
  DateTime? get testTime => _testTime;

  /// 统一时间入口：测试模式返回测试时间，否则返回真实时间
  DateTime get now => _testMode && _testTime != null ? _testTime! : DateTime.now();

  /// 设置测试时间并启用测试模式
  void setTestTime(DateTime time) {
    _testTime = time;
    _testMode = true;
    _startTestTimer();
    _checkExpiredAgendas();
    notifyListeners();
  }

  /// 清除测试时间，恢复真实时间
  void clearTestTime() {
    _testMode = false;
    _testTime = null;
    _testTimer?.cancel();
    _testTimer = null;
    _checkExpiredAgendas();
    notifyListeners();
  }

  void _startTestTimer() {
    _testTimer?.cancel();
    _testTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_testTime != null) {
        _testTime = _testTime!.add(const Duration(seconds: 1));
        _checkExpiredAgendas();
        notifyListeners();
      }
    });
  }

  /// 首页是否有覆盖层弹窗打开（创建事程、日历、提醒等），用于控制底部输入栏显示
  bool _isHomeOverlayOpen = false;
  bool get isHomeOverlayOpen => _isHomeOverlayOpen;
  void setHomeOverlayOpen(bool value) {
    _isHomeOverlayOpen = value;
    notifyListeners();
  }

  // 提醒规则与免打扰时段
  Map<String, dynamic> _reminderRules = {
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
  Map<String, dynamic> get reminderRules => _reminderRules;
  void updateReminderRules(Map<String, dynamic> rules) {
    _reminderRules = rules;
    _storage.saveReminderRules(rules);
    notifyListeners();
  }

  Map<String, dynamic> _quietHours = {'enabled': true, 'start': '22:00', 'end': '08:00'};
  Map<String, dynamic> get quietHours => _quietHours;
  void updateQuietHours(Map<String, dynamic> hours) {
    _quietHours = hours;
    _storage.saveQuietHours(hours);
    notifyListeners();
  }

  AppStore() {
    _initApp();
  }

  Future<void> _initApp() async {
    await _storage.init();
    _loadFromStorage();
    await _initLlm();
    _intentService = IntentRecognitionService(_llm);
    await _intentService!.init();
    _initCompleter.complete();
  }

  Future<void> _initLlm() async {
    await _llm.init();
    _semanticMatch = SemanticMatchService(_llm);
    notifyListeners();
  }

  LlmConfig get llmConfig => _llm.config;
  bool get llmEnabled => _llm.isConfigured;

  int _llmContextLength = 6;
  int get llmContextLength => _llmContextLength;

  bool _llmStreamOutput = true;
  bool get llmStreamOutput => _llmStreamOutput;

  bool _llmAutoTts = false;
  bool get llmAutoTts => _llmAutoTts;

  bool _llmFallbackToRules = true;
  bool get llmFallbackToRules => _llmFallbackToRules;

  /// 连续完成多少天后自动升级为必做事程（默认21天，可自定义）
  int _streakUpgradeDays = 21;
  int get streakUpgradeDays => _streakUpgradeDays;
  set streakUpgradeDays(int v) {
    _streakUpgradeDays = v;
    _storage.prefs?.setInt('streak_upgrade_days', v);
    notifyListeners();
  }

  /// 连续失败多少次后触发降级确认（默认3次，可自定义）
  int _failDemotionThreshold = 3;
  int get failDemotionThreshold => _failDemotionThreshold;
  set failDemotionThreshold(int v) {
    _failDemotionThreshold = v;
    _storage.prefs?.setInt('fail_demotion_threshold', v);
    notifyListeners();
  }

  /// 智能时间推荐：偏差多少分钟算显著（默认30分钟）
  int _timeDeviationMinutes = 30;
  int get timeDeviationMinutes => _timeDeviationMinutes;
  set timeDeviationMinutes(int v) {
    _timeDeviationMinutes = v;
    _storage.prefs?.setInt('time_deviation_minutes', v);
    notifyListeners();
  }

  Future<void> saveLlmConfig(LlmConfig config) async {
    await _llm.saveConfig(config);
    notifyListeners();
  }

  Future<void> saveLlmEnhancedSettings({
    required int contextLength,
    required bool streamOutput,
    required bool autoTts,
    required bool fallbackToRules,
  }) async {
    _llmContextLength = contextLength;
    _llmStreamOutput = streamOutput;
    _llmAutoTts = autoTts;
    _llmFallbackToRules = fallbackToRules;
    await _storage.prefs.setInt('llm_context_length', contextLength);
    await _storage.prefs.setBool('llm_stream_output', streamOutput);
    await _storage.prefs.setBool('llm_auto_tts', autoTts);
    await _storage.prefs.setBool('llm_fallback_to_rules', fallbackToRules);
    notifyListeners();
  }

  void _loadLlmEnhancedSettings() async {
    if (_storage.prefs != null) {
      _llmContextLength = _storage.prefs!.getInt('llm_context_length') ?? 6;
      _llmStreamOutput = _storage.prefs!.getBool('llm_stream_output') ?? true;
      _llmAutoTts = _storage.prefs!.getBool('llm_auto_tts') ?? false;
      _llmFallbackToRules = _storage.prefs!.getBool('llm_fallback_to_rules') ?? true;
      _streakUpgradeDays = _storage.prefs!.getInt('streak_upgrade_days') ?? 21;
      _failDemotionThreshold = _storage.prefs!.getInt('fail_demotion_threshold') ?? 3;
      _timeDeviationMinutes = _storage.prefs!.getInt('time_deviation_minutes') ?? 30;
    }
  }

  /// 从本地存储加载数据
  void _loadFromStorage() {
    _timelineRecords = _storage.loadTimeline();
    _agendaItems = _storage.loadAgenda();
    // 购物记录从时间线抽取，无需单独加载
    // shoppingRecords = _storage.loadShopping();
    // 物品记录从时间线抽取，无需单独加载
    // _items = _storage.loadItems();
    _inventory = _storage.loadInventory();
    _customTags = _storage.loadCustomTags();
    _chatMessages = _storage.loadChatMessages();
    _earnedBadges = _storage.loadEarnedBadges();
    _userProfile = _storage.loadUserProfile();
    _reminderRules = _storage.loadReminderRules();
    _quietHours = _storage.loadQuietHours();
    _frequentAgendas = MockData.mockFrequentAgendas;
    _timePatterns = _storage.loadTimePatterns();
    _pendingAgendaConfirm = _storage.loadPendingAgenda().cast<PendingAgendaItem>();
    _disabledHighFreqAgendas = _storage.loadDisabledHighFreq();
    _loadQuestionFrequency();
    _generateAgendaRecommendations();
    _deduplicateAgendaIds(); // 修复已存在的重复ID
    _autoAddDailyMustDoAgendas(); // 必做事程每日自动添加
    _checkExpiredAgendas(); // 检测过期事程并记录失败
    _loadLlmEnhancedSettings();
    _startExpiryCheckTimer();
  }

  void _deduplicateAgendaIds() {
    final idCounts = <String, int>{};
    for (final a in _agendaItems) {
      if (a.id.isNotEmpty) {
        idCounts[a.id] = (idCounts[a.id] ?? 0) + 1;
      }
    }

    final duplicateIds = idCounts.entries.where((e) => e.value > 1).map((e) => e.key).toList();
    if (duplicateIds.isEmpty) return;

    print('[WARNING] Found ${duplicateIds.length} duplicate agenda IDs on startup');
    for (final id in duplicateIds) {
      final duplicates = _agendaItems.where((a) => a.id == id).toList();
      print('[WARNING] Duplicate ID $id: ${duplicates.map((a) => a.content).join(', ')}');
    }

    final seenIds = <String>{};
    _agendaItems = _agendaItems.map((agenda) {
      if (agenda.id.isEmpty) {
        final newId = _genId();
        seenIds.add(newId);
        print('[INFO] Assigning new ID $newId to agenda: ${agenda.content}');
        return agenda.copyWith(id: newId);
      }

      if (!seenIds.contains(agenda.id)) {
        seenIds.add(agenda.id);
        return agenda;
      }

      final newId = _genId();
      print('[INFO] Assigning new ID $newId to duplicate agenda: ${agenda.content}');
      return agenda.copyWith(id: newId);
    }).toList();

    _storage.saveAgenda(_agendaItems);
    print('[INFO] Duplicate IDs fixed and saved to storage');
  }

  void _startExpiryCheckTimer() {
    _expiryCheckTimer?.cancel();
    _expiryCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkExpiredAgendas();
    });
  }

  Future<void> clearAllData() async {
    // 清除业务数据
    await _storage.clearAll();
    // 清除 LLM 配置（API Key、接口地址等）
    await _llm.saveConfig(const LlmConfig());
    // 重新加载默认数据
    _loadFromStorage();
    notifyListeners();
  }

  /// 检测今日已过期但仍为 pending 的事程，标记为 expired 并记录失败
  void _checkExpiredAgendas() {
    final now = this.now;
    bool changed = false;
    final toExpire = <String>[];

    for (final agenda in _agendaItems) {
      if (agenda.status != AgendaStatus.pending && agenda.status != AgendaStatus.postponed) continue;
      bool isExpired = false;
      final parts = agenda.date.split('-');
      final timeParts = agenda.time.split(':');
      if (parts.length == 3 && timeParts.length == 2) {
        try {
          final scheduled = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
          if (now.isAfter(scheduled.add(const Duration(hours: 1)))) {
            isExpired = true;
          }
        } catch (_) {}
      }
      if (isExpired) {
        toExpire.add(agenda.id);
      }
    }

    if (toExpire.isNotEmpty) {
      _agendaItems = _agendaItems.map((a) {
        if (toExpire.contains(a.id)) {
          return a.copyWith(
            status: AgendaStatus.expired,
            remainingTime: '已过期',
          );
        }
        return a;
      }).toList();
      for (final id in toExpire) {
        final agenda = _agendaItems.firstWhere((a) => a.id == id);
        _recordAgendaFailure(agenda, suppressNotify: true);
      }
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// 必做事程策略：每日自动添加必做事程副本
  /// 查找所有标记为 isMustDo 的事程，如果今日还没有对应副本则自动创建
  void _autoAddDailyMustDoAgendas() {
    final today = _ymd(now);
    // 找出所有必做事程（排除自动生成的每日副本，避免无限循环）
    final mustDoAgendas = _agendaItems.where((a) =>
      a.isMustDo && a.category != AgendaCategory.dailyMustDo
    ).toList();
    if (mustDoAgendas.isEmpty) return;

    final todayAgendaContents = _agendaItems
        .where((a) => a.date == today)
        .map((a) => '${a.content}|${a.time}')
        .toSet();

    for (final src in mustDoAgendas) {
      final key = '${src.content}|${src.time}';
      if (todayAgendaContents.contains(key)) continue;

      final newAgenda = AgendaItem(
        id: '',
        content: src.content,
        time: src.time,
        date: today,
        status: AgendaStatus.pending,
        isMustDo: true,
        level: src.level,
        icon: src.icon,
        source: AgendaSource.user,
        category: AgendaCategory.dailyMustDo,
        note: src.note,
        remainingTime: '今日提醒',
      );
      _agendaItems = [..._agendaItems, newAgenda.copyWith(id: _genId())];
      _scheduleReminderForAgenda(_agendaItems.last);
    }
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 持久化全部数据到本地
  void _persistAll() {
    _storage.saveTimeline(_timelineRecords);
    _storage.saveAgenda(_agendaItems);
    // 购物记录从时间线抽取，无需单独保存
    // _storage.saveShopping(shoppingRecords);
    // 物品记录从时间线抽取，无需单独保存
    // _storage.saveItems(_items);
    _storage.saveInventory(_inventory);
    _storage.saveCustomTags(_customTags);
    _storage.saveChatMessages(_chatMessages);
    _storage.saveEarnedBadges(_earnedBadges);
    _storage.saveUserProfile(_userProfile);
    _storage.saveReminderRules(_reminderRules);
    _storage.saveQuietHours(_quietHours);
    _storage.saveTimePatterns(_timePatterns);
    _storage.savePendingAgenda(_pendingAgendaConfirm);
    _storage.saveDisabledHighFreq(_disabledHighFreqAgendas);
    _saveQuestionFrequency();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _schedulePersist();
  }

  Timer? _persistTimer;
  bool _persistScheduled = false;

  void _schedulePersist() {
    if (_persistScheduled) return;
    _persistScheduled = true;
    _persistTimer = Timer(const Duration(milliseconds: 500), () {
      _persistAll();
      _persistScheduled = false;
    });
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _expiryCheckTimer?.cancel();
    _persistTimer?.cancel();
    // 确保数据持久化
    if (_persistScheduled) {
      _persistAll();
      _persistScheduled = false;
    }
    _notification.dispose();
    super.dispose();
  }

  // ===== 导航 =====
  String _activeTab = 'home';
  String get activeTab => _activeTab;
  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  String _habitsActiveTab = 'agenda';
  String get habitsActiveTab => _habitsActiveTab;
  void setHabitsActiveTab(String tab) {
    _habitsActiveTab = tab;
    notifyListeners();
  }

  // ===== 事程 =====
  List<AgendaItem> _agendaItems = [];
  List<AgendaItem> get agendaItems => _agendaItems;

  List<TimelineRecord> get agendaTimelineRecords {
    return _timelineRecords
        .where((r) => r.matchedAgenda != null && r.matchedAgenda!.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _agendaConflictWarning;
  Map<String, dynamic>? get agendaConflictWarning => _agendaConflictWarning;

  void clearAgendaConflictWarning() {
    _agendaConflictWarning = null;
    notifyListeners();
  }

  /// 检测事程冲突
  List<AgendaItem> detectAgendaConflicts(AgendaItem newAgenda) {
    return _agendaItems.where((a) => 
      a.date == newAgenda.date && 
      a.time == newAgenda.time && 
      a.status != AgendaStatus.completed &&
      a.id != newAgenda.id
    ).toList();
  }

  void addAgenda(AgendaItem agenda) {
    // 冲突检测
    final conflicts = detectAgendaConflicts(agenda);
    if (conflicts.isNotEmpty) {
      _agendaConflictWarning = {
        'newAgenda': agenda,
        'conflicts': conflicts,
      };
    }

    // ID重复检测：如果传入的事程已有ID，检查是否与现有事程重复
    String finalId = agenda.id;
    if (finalId.isNotEmpty && _agendaItems.any((a) => a.id == finalId)) {
      print('[WARNING] Agenda ID collision detected: $finalId, generating new ID');
      finalId = _genId();
    }
    final finalAgenda = agenda.copyWith(id: finalId.isEmpty ? _genId() : finalId);
    _agendaItems = [..._agendaItems, finalAgenda];
    _scheduleReminderForAgenda(finalAgenda);
    notifyListeners();
  }

  void updateAgenda(String id, AgendaItem patch) {
    print('[DEBUG] updateAgenda called:');
    print('[DEBUG]   id: $id');
    print('[DEBUG]   patch.content: ${patch.content}');
    print('[DEBUG]   patch.time: ${patch.time}');
    print('[DEBUG]   patch.date: ${patch.date}');
    print('[DEBUG]   patch.status: ${patch.status}');
    
    _agendaItems = _agendaItems.map((a) {
      if (a.id != id) return a;
      // 只有 pending/postponed/expired 状态在修改时间后重算状态
      // completed/skipped 状态不受时间修改影响
      AgendaStatus newStatus = a.status;
      if (a.status != AgendaStatus.completed && a.status != AgendaStatus.skipped &&
          (patch.date != a.date || patch.time != a.time)) {
        final now = this.now;
        final patchDate = DateTime.parse(patch.date);
        final isToday = patchDate.year == now.year && patchDate.month == now.month && patchDate.day == now.day;
        if (isToday) {
          final parts = patch.time.split(':');
          if (parts.length == 2) {
            final h = int.tryParse(parts[0]) ?? 0;
            final m = int.tryParse(parts[1]) ?? 0;
            final scheduled = DateTime(now.year, now.month, now.day, h, m);
            newStatus = now.isAfter(scheduled) ? AgendaStatus.expired : AgendaStatus.pending;
          }
        } else {
          newStatus = AgendaStatus.pending;
        }
      }
      return a.copyWith(
        content: patch.content,
        time: patch.time,
        date: patch.date,
        note: patch.note,
        voiceNote: patch.voiceNote,
        isMustDo: patch.isMustDo,
        level: patch.level,
        icon: patch.icon,
        category: patch.category,
        chainAfterId: patch.chainAfterId,
        advanceReminder: patch.advanceReminder,
        customReminderConfig: patch.customReminderConfig,
        status: newStatus,
        remainingTime: newStatus == AgendaStatus.pending ? '今日提醒' : a.remainingTime,
      );
    }).toList();
    // 重新调度提醒
    final updated = _agendaItems.firstWhere((a) => a.id == id);
    _notification.cancelReminder(id);
    _scheduleReminderForAgenda(updated);
    notifyListeners();
  }

  void updateAgendaAdvanceReminder(String id, int? advanceReminder) {
    _agendaItems = _agendaItems.map((a) {
      if (a.id != id) return a;
      return AgendaItem(
        id: a.id,
        content: a.content,
        time: a.time,
        date: a.date,
        status: a.status,
        isMustDo: a.isMustDo,
        level: a.level,
        icon: a.icon,
        repeat: a.repeat,
        advanceReminder: advanceReminder,
        isHighFrequency: a.isHighFrequency,
        source: a.source,
        matchedTimeline: a.matchedTimeline,
        note: a.note,
        voiceNote: a.voiceNote,
        remainingTime: a.remainingTime,
        category: a.category,
        streak: a.streak,
        lastCompletedDate: a.lastCompletedDate,
        failCount: a.failCount,
        lastFailedDate: a.lastFailedDate,
        chainAfterId: a.chainAfterId,
        timeDeviationCount: a.timeDeviationCount,
        lastActualTime: a.lastActualTime,
        suggestedTime: a.suggestedTime,
        customReminderConfig: a.customReminderConfig,
      );
    }).toList();
    final updated = _agendaItems.firstWhere((a) => a.id == id);
    _notification.cancelReminder(id);
    _scheduleReminderForAgenda(updated);
    notifyListeners();
  }

  void completeAgenda(String id, {bool addRecord = true}) {
    final agenda = _agendaItems.firstWhere((a) => a.id == id, orElse: () => AgendaItem(id: '', content: '', time: '', date: ''));
    if (agenda.id.isEmpty) return;
    if (agenda.status == AgendaStatus.completed) return;
    final now = this.now;

    // 计算连续完成天数
    int newStreak = 1;
    if (agenda.lastCompletedDate != null) {
      final lastDate = agenda.lastCompletedDate!;
      final todayDate = DateTime(now.year, now.month, now.day);
      final lastDateOnly = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final diffDays = todayDate.difference(lastDateOnly).inDays;
      if (diffDays == 1) {
        newStreak = agenda.streak + 1;
      } else if (diffDays == 0) {
        newStreak = agenda.streak;
      } else {
        newStreak = 1;
      }
    }

    // 检查是否达到升级阈值（使用当前级别配置）
    final levelRule = _reminderRules[agenda.level.name] as Map<String, dynamic>? ?? {};
    final upgradeThreshold = levelRule['streakUpgradeDays'] as int? ?? _streakUpgradeDays;
    bool upgraded = false;
    bool newIsMustDo = agenda.isMustDo;
    AgendaLevel newLevel = agenda.level;

    if (!agenda.isMustDo && newStreak >= upgradeThreshold) {
      newIsMustDo = true;
      newLevel = AgendaLevel.mustDoShort;
      upgraded = true;
    }

    // 策略4：智能时间推荐 - 检测实际完成时间偏差
    int newTimeDeviationCount = agenda.timeDeviationCount;
    String? newLastActualTime = agenda.lastActualTime;
    String? newSuggestedTime = agenda.suggestedTime;
    bool shouldSuggestTime = false;
    final timeParts = agenda.time.split(':');
    if (timeParts.length == 2) {
      final scheduledMin = (int.tryParse(timeParts[0]) ?? 0) * 60 + (int.tryParse(timeParts[1]) ?? 0);
      final actualMin = now.hour * 60 + now.minute;
      final deviation = (actualMin - scheduledMin).abs();
      final deviationThreshold = levelRule['timeDeviationMinutes'] as int? ?? _timeDeviationMinutes;
      final actualTimeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      newLastActualTime = actualTimeStr;
      if (deviation >= deviationThreshold) {
        newTimeDeviationCount = agenda.timeDeviationCount + 1;
        // 连续3次偏差，生成时间推荐
        if (newTimeDeviationCount >= 3) {
          newSuggestedTime = actualTimeStr;
          shouldSuggestTime = true;
        }
      } else {
        // 准时完成，重置偏差计数
        newTimeDeviationCount = 0;
      }
    }

    _agendaItems = _agendaItems.map((a) =>
      a.id == id ? a.copyWith(
        status: AgendaStatus.completed,
        remainingTime: null,
        streak: newStreak,
        lastCompletedDate: now,
        isMustDo: newIsMustDo,
        level: newLevel,
        timeDeviationCount: newTimeDeviationCount,
        lastActualTime: newLastActualTime,
        suggestedTime: newSuggestedTime,
      ) : a
    ).toList();
    _notification.cancelReminder(id);

    // 事程完成时自动消耗关联库存
    _processAgendaInventoryConsumption(agenda, id);

    // 策略5：链式事程 - 完成后检查关联事程
    _checkChainReminders(agenda.id);

    if (addRecord) {
      addTimelineRecord(TimelineRecord(
        id: '',
        content: upgraded
            ? '🎉 已完成「${agenda.content}」！连续${newStreak}天，已升级为必做事程'
            : '已完成：${agenda.content}',
        time: now,
        type: TimelineType.behavior,
        tags: ['behavior'],
        matchedAgenda: '${agenda.time}${agenda.content}',
        linkedAgendaId: agenda.id,
      ));
      // 确保 _agendaItems 变更一定触发 UI 刷新
      // （addTimelineRecord 可能因去重直接 return，不调用 notifyListeners）
      notifyListeners();
    } else {
      notifyListeners();
    }

    // 策略4：如果需要推荐时间，触发弹窗
    if (shouldSuggestTime && _smartTimeSuggestion == null) {
      final updatedAgenda = _agendaItems.firstWhere((a) => a.id == id);
      _smartTimeSuggestion = SmartTimeSuggestion(
        agenda: updatedAgenda,
        scheduledTime: agenda.time,
        suggestedTime: newSuggestedTime!,
        deviationCount: newTimeDeviationCount,
        avgDeviationMinutes: _timeDeviationMinutes,
      );
      notifyListeners();
    }
  }

  /// 策略3：记录事程失败（过期/跳过），递增 failCount，达标触发降级弹窗
  void _recordAgendaFailure(AgendaItem agenda, {bool suppressNotify = false}) {
    final now = this.now;
    int newFailCount = agenda.failCount + 1;

    // 更新 failCount 和 lastFailedDate
    _agendaItems = _agendaItems.map((a) =>
      a.id == agenda.id ? a.copyWith(
        failCount: newFailCount,
        lastFailedDate: now,
      ) : a
    ).toList();

    // 检查是否达到降级阈值（仅对 important/mustDo 级别）
    final levelRule = _reminderRules[agenda.level.name] as Map<String, dynamic>? ?? {};
    final demotionThreshold = levelRule['failDemotionThreshold'] as int? ?? _failDemotionThreshold;
    if (newFailCount >= demotionThreshold &&
        _demotionPendingResult == null &&
        (agenda.level.isMustDo || agenda.level == AgendaLevel.important)) {
      final suggestedLevel = agenda.level.isMustDo
          ? AgendaLevel.important
          : AgendaLevel.normal;
      final updatedAgenda = _agendaItems.firstWhere((a) => a.id == agenda.id);
      _demotionPendingResult = DemotionPendingResult(
        agenda: updatedAgenda,
        currentLevel: agenda.level,
        suggestedLevel: suggestedLevel,
        failCount: newFailCount,
      );
    }

    if (!suppressNotify) notifyListeners();
  }

  /// 取消完成事程（恢复待进行）
  /// 如果是今天完成的，清除 lastCompletedDate 避免再次完成时 streak 计算异常
  void uncompleteAgenda(String id) {
    final agenda = _agendaItems.firstWhere((a) => a.id == id, orElse: () => AgendaItem(id: '', content: '', time: '', date: ''));
    if (agenda.id.isEmpty) return;
    if (agenda.status != AgendaStatus.completed) return;

    final now = this.now;
    final todayDate = DateTime(now.year, now.month, now.day);
    // 判断是否是今天完成的
    final isCompletedToday = agenda.lastCompletedDate != null &&
        DateTime(agenda.lastCompletedDate!.year, agenda.lastCompletedDate!.month, agenda.lastCompletedDate!.day) == todayDate;

    _agendaItems = _agendaItems.map((a) =>
      a.id == id ? a.copyWith(
        status: AgendaStatus.pending,
        remainingTime: '待进行',
        // 今天完成的取消：streak-1 并清除 lastCompletedDate，避免再次完成时 diffDays==0 导致 streak 不恢复
        streak: (a.streak > 0 && isCompletedToday) ? a.streak - 1 : a.streak,
        lastCompletedDate: isCompletedToday ? null : a.lastCompletedDate,
      ) : a
    ).toList();
    final updated = _agendaItems.firstWhere((a) => a.id == id);
    _scheduleReminderForAgenda(updated);
    
    // 取消完成时恢复关联的库存消耗
    _revertInventoryChanges('agenda', id);
    
    notifyListeners();
  }

  /// 策略3：用户确认降级
  void confirmDemotion(bool accepted) {
    if (_demotionPendingResult == null) return;
    final r = _demotionPendingResult!;
    if (accepted) {
      final newLevel = r.suggestedLevel;
      final newIsMustDo = newLevel.isMustDo;
      _agendaItems = _agendaItems.map((a) =>
        a.id == r.agenda.id ? a.copyWith(
          level: newLevel,
          isMustDo: newIsMustDo,
          failCount: 0, // 重置失败计数
        ) : a
      ).toList();
    } else {
      // 拒绝降级，重置失败计数给一次机会
      _agendaItems = _agendaItems.map((a) =>
        a.id == r.agenda.id ? a.copyWith(failCount: 0) : a
      ).toList();
    }
    _demotionPendingResult = null;
    notifyListeners();
  }

  /// 策略3：跳过事程（手动），记录失败
  /// 注意：expired 状态的事程已由 _checkExpiredAgendas 记录过失败，不重复记录
  /// 注意：必做事程（mustDoShort/mustDoLong）不允许跳过
  void skipAgenda(String id) {
    final agenda = _agendaItems.firstWhere((a) => a.id == id, orElse: () => AgendaItem(id: '', content: '', time: '', date: ''));
    if (agenda.id.isEmpty) return;
    if (agenda.status == AgendaStatus.completed || agenda.status == AgendaStatus.skipped) return;
    // 必做事程不允许跳过
    if (agenda.level == AgendaLevel.mustDoShort || agenda.level == AgendaLevel.mustDoLong) return;
    
    final duplicateIds = _agendaItems.where((a) => a.id == id).length;
    if (duplicateIds > 1) {
      print('[ERROR] Found $duplicateIds agendas with same id: $id');
      print('[ERROR] Duplicate agenda contents: ${_agendaItems.where((a) => a.id == id).map((a) => a.content).join(', ')}');
    }
    
    print('[DEBUG] skipAgenda called with id: $id, content: ${agenda.content}');
    print('[DEBUG] Before skip - items with status=skipped: ${_agendaItems.where((a) => a.status == AgendaStatus.skipped).length}');
    
    final wasExpired = agenda.status == AgendaStatus.expired;
    _agendaItems = _agendaItems.map((a) =>
      a.id == id ? a.copyWith(
        status: AgendaStatus.skipped,
        remainingTime: '已跳过',
        wasSkipped: true,
      ) : a
    ).toList();
    _notification.cancelReminder(id);
    // 仅对非 expired 状态记录失败（expired 已记录过）
    if (!wasExpired) {
      _recordAgendaFailure(agenda);
    }
    
    print('[DEBUG] After skip - items with status=skipped: ${_agendaItems.where((a) => a.status == AgendaStatus.skipped).length}');
    print('[DEBUG] Skipped items: ${_agendaItems.where((a) => a.status == AgendaStatus.skipped).map((a) => '${a.id}:${a.content}').join(', ')}');
    
    notifyListeners();
  }

  /// 恢复已跳过的事程为待进行
  void unskipAgenda(String id) {
    final agenda = _agendaItems.firstWhere((a) => a.id == id, orElse: () => AgendaItem(id: '', content: '', time: '', date: ''));
    if (agenda.id.isEmpty) return;
    if (agenda.status != AgendaStatus.skipped) return;
    final now = this.now;
    // 恢复后根据时间重新判定状态
    AgendaStatus newStatus = AgendaStatus.pending;
    String newRemaining = '待进行';
    final parts = agenda.date.split('-');
    final timeParts = agenda.time.split(':');
    if (parts.length == 3 && timeParts.length == 2) {
      try {
        final scheduled = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]),
          int.parse(timeParts[0]), int.parse(timeParts[1]),
        );
        if (now.isAfter(scheduled.add(const Duration(hours: 1)))) {
          newStatus = AgendaStatus.expired;
          newRemaining = '已过期';
        } else if (now.isAfter(scheduled)) {
          newRemaining = '已到时间';
        }
      } catch (_) {}
    }
    _agendaItems = _agendaItems.map((a) =>
      a.id == id ? a.copyWith(
        status: newStatus,
        remainingTime: newRemaining,
        failCount: a.failCount > 0 ? a.failCount - 1 : 0,
      ) : a
    ).toList();
    final updated = _agendaItems.firstWhere((a) => a.id == id);
    _scheduleReminderForAgenda(updated);
    notifyListeners();
  }

  /// 策略4：用户接受/拒绝时间推荐
  void acceptSmartTime(String agendaId, bool accepted) {
    if (_smartTimeSuggestion == null) return;
    if (accepted) {
      final newTime = _smartTimeSuggestion!.suggestedTime;
      _agendaItems = _agendaItems.map((a) =>
        a.id == agendaId ? a.copyWith(
          time: newTime,
          timeDeviationCount: 0,
          suggestedTime: null,
        ) : a
      ).toList();
      // 重新调度提醒
      final updated = _agendaItems.firstWhere((a) => a.id == agendaId);
      _notification.cancelReminder(agendaId);
      _scheduleReminderForAgenda(updated);
    } else {
      _agendaItems = _agendaItems.map((a) =>
        a.id == agendaId ? a.copyWith(timeDeviationCount: 0, suggestedTime: null) : a
      ).toList();
    }
    _smartTimeSuggestion = null;
    notifyListeners();
  }

  /// 策略5：检查链式事程提醒
  void _checkChainReminders(String completedAgendaId) {
    final nextAgendas = _agendaItems.where((a) =>
      a.chainAfterId == completedAgendaId &&
      a.status == AgendaStatus.pending
    ).toList();
    if (nextAgendas.isNotEmpty) {
      final completed = _agendaItems.firstWhere((a) => a.id == completedAgendaId);
      _chainReminderResult = ChainReminderResult(
        completedAgenda: completed,
        nextAgendas: nextAgendas,
      );
    }
  }

  /// 策略5：用户确认链式提醒
  void confirmChainReminder(bool startNext) {
    if (_chainReminderResult == null) return;
    if (startNext) {
      // 将下一个链式事程提到当前时间提醒
      for (final next in _chainReminderResult!.nextAgendas) {
        final now = this.now;
        final newTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _agendaItems = _agendaItems.map((a) =>
          a.id == next.id ? a.copyWith(time: newTime, remainingTime: '链式提醒-即将开始') : a
        ).toList();
        _notification.cancelReminder(next.id);
        _scheduleReminderForAgenda(_agendaItems.firstWhere((a) => a.id == next.id));
      }
    }
    _chainReminderResult = null;
    notifyListeners();
  }

  /// 消耗关键词（库存减少）- 按长度降序，优先匹配更具体的动词
  static const _consumeKeywords = [
    '服用了', '使用了', '消耗了', '吃了', '喝了', '服了', '用了',
    '服用', '使用', '消耗', '吃', '喝', '服', '用',
  ];
  /// 增加关键词（库存增加）
  static const _increaseKeywords = [
    '购买了', '采购了', '补充了', '入库了', '买了',
    '购买', '采购', '补充', '入库', '买',
  ];

  /// 从意图训练模式中查找库存方向配置
  /// 优先级：1. 完全匹配的模式 direction 字段
  ///       2. 模糊匹配（inputText 被 content 包含）的模式 direction 字段
  ///       3. 返回 null（由调用方回退到关键词判断）
  String? _getDirectionFromIntentPattern(String content) {
    if (_intentService == null) return null;
    final patterns = _intentService!.allPatterns;
    if (patterns.isEmpty) return null;

    // 1. 完全匹配
    for (final p in patterns) {
      if (p.inputText == content) {
        final dir = _extractDirectionFromPattern(p);
        if (dir != null) return dir;
      }
    }
    // 2. 模糊匹配：inputText 被 content 包含（按长度降序，优先更长的匹配）
    final sorted = List<UserPattern>.from(patterns)
      ..sort((a, b) => b.inputText.length.compareTo(a.inputText.length));
    for (final p in sorted) {
      if (p.inputText.isNotEmpty && p.inputText.length <= content.length && content.contains(p.inputText)) {
        final dir = _extractDirectionFromPattern(p);
        if (dir != null) return dir;
      }
    }
    return null;
  }

  /// 从单个 UserPattern 中提取 inventoryConsume 意图的 direction 字段
  String? _extractDirectionFromPattern(UserPattern pattern) {
    for (final slot in pattern.slots) {
      for (final intent in slot.intents) {
        if (intent.type == IntentType.inventoryConsume) {
          final dir = intent.slots['direction'];
          if (dir is String && (dir == 'consume' || dir == 'increase')) {
            return dir;
          }
        }
      }
    }
    return null;
  }

  /// 根据文本自动判断库存方向（消耗/补充）
  /// 增加类关键词优先于消耗类（避免"买药吃"被误判为消耗）
  String _detectDirectionByKeywords(String text) {
    for (final kw in _increaseKeywords) {
      if (text.contains(kw)) return 'increase';
    }
    for (final kw in _consumeKeywords) {
      if (text.contains(kw)) return 'consume';
    }
    return 'consume'; // 默认按消耗处理
  }

  /// 从事程内容中解析物品信息并处理库存变更
  void _processAgendaInventoryConsumption(AgendaItem agenda, String agendaId) {
    final content = agenda.content;

    // 1. 解析数量+单位+物品名，如 "吃2片降压药" → qty=2, unit=片, name=降压药
    final qtyUnitNameRegex = RegExp(
      r'(\d+(?:\.\d+)?)\s*(片|粒|盒|瓶|个|包|袋|支|颗|毫升|克|斤|公斤|箱|条|把|贴|滴)\s*([\u4e00-\u9fa5A-Za-z]{2,10})',
    );
    // 2. 解析物品名+数量+单位，如 "吃降压药2片" → name=降压药, qty=2, unit=片
    final nameQtyUnitRegex = RegExp(
      r'([\u4e00-\u9fa5A-Za-z]{2,10})\s*(\d+(?:\.\d+)?)\s*(片|粒|盒|瓶|个|包|袋|支|颗|毫升|克|斤|公斤|箱|条|把|贴|滴)',
    );

    final parsed = <Map<String, dynamic>>[];

    for (final m in qtyUnitNameRegex.allMatches(content)) {
      parsed.add({
        'name': m.group(3)!,
        'quantity': double.parse(m.group(1)!),
        'unit': m.group(2)!,
      });
    }
    for (final m in nameQtyUnitRegex.allMatches(content)) {
      final name = m.group(1)!;
      if (parsed.any((p) => p['name'] == name)) continue;
      parsed.add({
        'name': name,
        'quantity': double.parse(m.group(2)!),
        'unit': m.group(3)!,
      });
    }

    // 3. 如果没有解析到数量，尝试仅匹配物品名
    if (parsed.isEmpty) {
      for (final item in _inventory) {
        if (content.contains(item.name)) {
          double qty = item.dailyUsage ?? 1.0;
          parsed.add({
            'name': item.name,
            'quantity': qty,
            'unit': item.unit,
          });
        }
      }
    }

    if (parsed.isEmpty) return;

    // 4. 判断方向：优先使用意图训练中配置的 direction，其次使用关键词判断
    final trainedDirection = _getDirectionFromIntentPattern(content);
    final String direction;
    final bool isFromTraining;
    if (trainedDirection != null) {
      direction = trainedDirection;
      isFromTraining = true;
    } else {
      direction = _detectDirectionByKeywords(content);
      isFromTraining = false;
    }
    final isConsume = direction == 'consume';

    for (final p in parsed) {
      final itemName = p['name'] as String;
      double qty = p['quantity'] as double;
      String unit = p['unit'] as String;

      final matchedItem = findInventory(itemName);
      if (matchedItem != null) {
        // 匹配到库存物品，使用库存物品的单位
        if (matchedItem.unit == unit) {
          // 单位一致，直接使用解析数量
        } else {
          // 单位不一致，使用库存物品的 dailyUsage 或默认1
          qty = matchedItem.dailyUsage ?? qty;
          unit = matchedItem.unit;
        }
      }

      // 消耗=负数（减少），增加=正数（增加）
      final change = isConsume ? -qty : qty;
      final source = isFromTraining ? '训练模式' : '关键词';

      updateInventory(
        itemName,
        change,
        unit,
        reason: isConsume
            ? '事程完成消耗（$source：${agenda.content}）'
            : '事程完成入库（$source：${agenda.content}）',
        syncToTimeline: false,
        sourceType: 'agenda',
        sourceId: agendaId,
      );
    }
  }

  void postponeAgenda(String id, int minutes) {
    _agendaItems = _agendaItems.map((a) {
      if (a.id != id) return a;
      // 允许 pending/postponed/expired 状态推迟（expired 推迟后重新激活为 postponed）
      if (a.status != AgendaStatus.pending &&
          a.status != AgendaStatus.postponed &&
          a.status != AgendaStatus.expired) return a;
      final parts = a.time.split(':');
      if (parts.length != 2) return a;
      int h = int.tryParse(parts[0]) ?? 0;
      int m = int.tryParse(parts[1]) ?? 0;
      // 过期事程推迟时，从当前时间开始计算，而不是原计划时间
      if (a.status == AgendaStatus.expired) {
        final now = this.now;
        h = now.hour;
        m = now.minute;
      }
      int total = h * 60 + m + minutes;
      String newDate = a.date;
      if (total >= 24 * 60) {
        total -= 24 * 60;
        final dateParts = a.date.split('-');
        if (dateParts.length == 3) {
          final dt = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2])).add(const Duration(days: 1));
          newDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        }
      }
      final nh = total ~/ 60;
      final nm = total % 60;
      final newTime = '${nh.toString().padLeft(2, '0')}:${nm.toString().padLeft(2, '0')}';
      return a.copyWith(
        status: AgendaStatus.postponed,
        time: newTime,
        date: newDate,
        remainingTime: '推迟$minutes分钟',
        wasPostponed: true, // 标记曾经延期过
      );
    }).toList();
    final updated = _agendaItems.firstWhere((a) => a.id == id);
    _notification.cancelReminder(id);
    _scheduleReminderForAgenda(updated);
    notifyListeners();
  }

  void deleteAgenda(String id) {
    _revertInventoryChanges('agenda', id);
    _agendaItems = _agendaItems.where((a) => a.id != id).toList();
    _notification.cancelReminder(id);
    notifyListeners();
  }

  void deleteAgendaWithOption(String id, bool disableAutoAdd) {
    final agenda = _agendaItems.firstWhere((a) => a.id == id, orElse: () => AgendaItem(id: '', content: '', time: '', date: ''));
    if (disableAutoAdd && agenda.isHighFrequency) {
      _disabledHighFreqAgendas.add(agenda.content);
    }
    deleteAgenda(id);
  }

  List<String> _disabledHighFreqAgendas = [];
  List<String> get disabledHighFreqAgendas => _disabledHighFreqAgendas;

  // 晚下班检测结果
  LateOffWorkResult? _lateOffWorkResult;
  LateOffWorkResult? get lateOffWorkResult => _lateOffWorkResult;
  void clearLateOffWorkResult() => _lateOffWorkResult = null;

  // 策略3：连续失败降级待确认
  DemotionPendingResult? _demotionPendingResult;
  DemotionPendingResult? get demotionPendingResult => _demotionPendingResult;
  void clearDemotionPendingResult() => _demotionPendingResult = null;

  // 策略4：智能时间推荐
  SmartTimeSuggestion? _smartTimeSuggestion;
  SmartTimeSuggestion? get smartTimeSuggestion => _smartTimeSuggestion;
  void clearSmartTimeSuggestion() => _smartTimeSuggestion = null;

  // 策略5：链式事程提醒
  ChainReminderResult? _chainReminderResult;
  ChainReminderResult? get chainReminderResult => _chainReminderResult;
  void clearChainReminderResult() => _chainReminderResult = null;

  // 链式事程关联记忆
  // key: 事程内容, value: 关联的事程内容列表
  Map<String, List<String>> _chainAssociations = {};
  Map<String, List<String>> get chainAssociations => _chainAssociations;

  void recordChainAssociation(String fromContent, String toContent) {
    if (!_chainAssociations.containsKey(fromContent)) {
      _chainAssociations[fromContent] = [];
    }
    if (!_chainAssociations[fromContent]!.contains(toContent)) {
      _chainAssociations[fromContent]!.add(toContent);
      notifyListeners();
    }
  }

  List<String> getChainSuggestions(String content) {
    final suggestions = <String>{};

    if (_chainAssociations.containsKey(content)) {
      suggestions.addAll(_chainAssociations[content]!);
    }

    final timeRecords = <String, int>{};
    for (final record in _timelineRecords) {
      if (record.content.contains(content) || content.contains(record.content)) {
        final nextRecords = _timelineRecords.where((r) {
          if (r.id == record.id) return false;
          if (r.time.isBefore(record.time)) return false;
          final diff = r.time.difference(record.time).inMinutes;
          return diff > 0 && diff <= 120;
        });
        for (final next in nextRecords) {
          if (next.linkedAgendaId != null) {
            final agenda = _agendaItems.firstWhere(
              (a) => a.id == next.linkedAgendaId,
              orElse: () => AgendaItem(id: '', content: next.content, time: '', date: ''),
            );
            if (agenda.content.isNotEmpty && agenda.content != content) {
              timeRecords[agenda.content] = (timeRecords[agenda.content] ?? 0) + 1;
            }
          }
        }
      }
    }

    final sortedList = timeRecords.entries
        .where((e) => e.value >= 2)
        .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final sortedByFrequency = sortedList.map((e) => e.key).toList();

    suggestions.addAll(sortedByFrequency);

    return suggestions.toList();
  }

  void clearChainAssociation(String fromContent, String toContent) {
    if (_chainAssociations.containsKey(fromContent)) {
      _chainAssociations[fromContent]!.remove(toContent);
      if (_chainAssociations[fromContent]!.isEmpty) {
        _chainAssociations.remove(fromContent);
      }
      notifyListeners();
    }
  }

  Map<String, List<String>> _timePatterns = {};
  Map<String, List<String>> get timePatterns => _timePatterns;

  Map<String, Range> _timeSlots = {
    '早上': Range(6, 9),
    '早饭': Range(6, 9),
    '早餐': Range(6, 9),
    '上午': Range(9, 12),
    '中午': Range(11, 13),
    '午饭': Range(11, 13),
    '午餐': Range(11, 13),
    '下午': Range(13, 18),
    '晚饭': Range(17, 19),
    '晚餐': Range(17, 19),
    '晚上': Range(19, 22),
    '夜宵': Range(22, 24),
    '睡前': Range(21, 24),
    '起床': Range(6, 8),
    '睡觉': Range(21, 24),
    '午休': Range(12, 14),
    '下午茶': Range(14, 16),
    '下班': Range(17, 19),
    '上班': Range(7, 9),
    '出门': Range(7, 9),
    '回家': Range(17, 19),
  };

  void learnTimePattern(String timeSlot, String time) {
    _timePatterns.putIfAbsent(timeSlot, () => []);
    _timePatterns[timeSlot]!.add(time);
    if (_timePatterns[timeSlot]!.length > 20) {
      _timePatterns[timeSlot] = _timePatterns[timeSlot]!.sublist(_timePatterns[timeSlot]!.length - 20);
    }
  }

  String? inferTimeBySlot(String content) {
    for (final entry in _timeSlots.entries) {
      if (content.contains(entry.key)) {
        final times = _timePatterns[entry.key];
        if (times != null && times.isNotEmpty) {
          return _averageTime(times);
        }
        return _defaultTimeForSlot(entry.key);
      }
    }
    return null;
  }

  String _averageTime(List<String> times) {
    int totalMinutes = 0;
    for (final t in times) {
      final parts = t.split(':');
      if (parts.length == 2) {
        totalMinutes += int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    }
    final avg = (totalMinutes / times.length).round();
    return '${(avg ~/ 60).toString().padLeft(2, '0')}:${(avg % 60).toString().padLeft(2, '0')}';
  }

  String _defaultTimeForSlot(String slot) {
    final range = _timeSlots[slot];
    if (range != null) {
      final avgHour = ((range.start + range.end) / 2).round();
      return '${avgHour.toString().padLeft(2, '0')}:30';
    }
    return '12:00';
  }

  void _generateAgendaRecommendations() {
    // todayStr comes from the getter
    final todayContents = _agendaItems.where((a) => a.date == todayStr).map((a) => a.content).toList();
    final addedContents = <String>{};

    final behaviorRecords = _timelineRecords.where((r) => r.tags.contains('behavior')).toList();
    final behaviorCounts = <String, List<int>>{};

    for (final record in behaviorRecords) {
      final match = RegExp(r'(吃药|吃饭|早饭|午饭|晚饭|运动|散步|跑步|喝水|睡觉|起床|洗漱|阅读|锻炼)').firstMatch(record.content);
      String keyword = match?.group(1) ?? (record.content.isNotEmpty ? record.content.substring(0, 2) : '');
      behaviorCounts.putIfAbsent(keyword, () => []);
      behaviorCounts[keyword]!.add(record.time.hour * 60 + record.time.minute);
    }

    final highFreq = behaviorCounts.entries
        .where((e) => e.value.length >= 3)
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final newAgendas = <AgendaItem>[];
    for (final entry in highFreq.take(5)) {
      final keyword = entry.key;
      if (todayContents.any((c) => c.contains(keyword)) || addedContents.contains(keyword) || _disabledHighFreqAgendas.contains(keyword)) continue;
      final avgMinutes = (entry.value.reduce((a, b) => a + b) / entry.value.length).round();
      final time = '${(avgMinutes ~/ 60).toString().padLeft(2, '0')}:${(avgMinutes % 60).toString().padLeft(2, '0')}';
      newAgendas.add(AgendaItem(
        id: _genId(),
        date: todayStr,
        time: time,
        content: keyword,
        isMustDo: keyword.contains('药'),
        status: AgendaStatus.pending,
        remainingTime: '今日提醒',
        icon: autoDetectIcon(keyword),
        isHighFrequency: true,
        source: AgendaSource.ai,
      ));
      addedContents.add(keyword);
    }

    if (newAgendas.isNotEmpty) {
      _agendaItems = [..._agendaItems, ...newAgendas];
    }
  }

  /// 为事程调度提醒
  void _scheduleReminderForAgenda(AgendaItem agenda) {
    if (agenda.status != AgendaStatus.pending && agenda.status != AgendaStatus.postponed) return;

    final parts = agenda.date.split('-');
    if (parts.length != 3) return;
    final hourMin = agenda.time.split(':');
    if (hourMin.length != 2) return;

    try {
      final scheduledTime = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
        int.parse(hourMin[0]),
        int.parse(hourMin[1]),
      );

      // 免打扰时段不调度
      if (_notification.isQuietHours(
        start: _quietHours['start'] as String,
        end: _quietHours['end'] as String,
        enabled: _quietHours['enabled'] as bool,
      )) {
        return;
      }

      // 根据级别选择参数（单事程自定义优先，其次级别默认）
      final levelKey = agenda.level.name;
      final rule = agenda.customReminderConfig ?? (_reminderRules[levelKey] as Map<String, dynamic>? ?? {});
      int advanceMinutes = (rule['advanceMinutes'] ?? (agenda.advanceReminder ?? 10)) as int;
      int repeatCount = (rule['repeatCount'] ?? 1) as int;
      if (agenda.advanceReminder != null) {
        advanceMinutes = agenda.advanceReminder!;
      }

      // advanceMinutes 为 0 表示不提醒
      if (advanceMinutes == 0) return;

      _notification.scheduleAgendaReminder(
        agendaId: agenda.id,
        title: agenda.content,
        body: '即将开始「${agenda.content}」',
        scheduledTime: scheduledTime,
        advanceMinutes: advanceMinutes,
        repeatCount: repeatCount,
        isMustDo: agenda.level.isMustDo,
      );
    } catch (e) {
      debugPrint('调度提醒失败: $e');
    }
  }

  /// 启动时为所有今日未完成事程重新调度提醒
  void rescheduleAllReminders() {
    _notification.cancelAll();
    // todayStr comes from the getter
    for (final agenda in _agendaItems) {
      if (agenda.date == todayStr && agenda.status == AgendaStatus.pending) {
        _scheduleReminderForAgenda(agenda);
      }
    }
  }

  // ===== 时间线 =====
  List<TimelineRecord> _timelineRecords = [];
  List<TimelineRecord> get timelineRecords => _timelineRecords.toList()..sort((a, b) => b.time.compareTo(a.time));

  String addTimelineRecord(TimelineRecord record) {
    // 去重：3秒内同内容同类型的记录视为重复提交
    final dupThreshold = record.time.subtract(const Duration(seconds: 3));
    final isDuplicate = _timelineRecords.any((r) =>
      r.content == record.content &&
      r.type == record.type &&
      r.time.isAfter(dupThreshold) &&
      !r.deleted
    );
    if (isDuplicate) {
      return _timelineRecords.firstWhere((r) =>
        r.content == record.content && r.type == record.type && !r.deleted
      ).id;
    }

    final id = _genId();
    
    // 自动关联事程：使用统一语义匹配服务
    TimelineRecord finalRecord = record.copyWith(id: id);
    if (finalRecord.linkedAgendaId == null) {
      // 先用本地规则快速匹配
      final today = now;
      final todayStr = '${today.year}-${(today.month).toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final tomorrowStr = '${today.year}-${(today.month).toString().padLeft(2, '0')}-${(today.day + 1).toString().padLeft(2, '0')}';
      final candidateAgendas = _agendaItems.where((a) =>
        a.date == todayStr || a.date == tomorrowStr
      ).toList();

      if (candidateAgendas.isNotEmpty) {
        // 异步调用语义匹配（本地优先 → 大模型降级）
        _matchAgendaSemanticAsync(id, finalRecord.content, candidateAgendas, record.time);
      }
    }

    _timelineRecords = [
      finalRecord,
      ..._timelineRecords,
    ];

    final timeStr = '${record.time.hour.toString().padLeft(2, '0')}:${record.time.minute.toString().padLeft(2, '0')}';
    for (final slot in _timeSlots.keys) {
      if (record.content.contains(slot)) {
        learnTimePattern(slot, timeStr);
      }
    }

    // 如果记录了"下班"相关行为，检测是否晚下班
    if (RegExp(r'下班|回家|到家').hasMatch(record.content)) {
      _lateOffWorkResult = checkLateOffWork();
    }

    // 自动处理副作用：购物记录入库、库存数量变更
    _processTimelineSideEffects(finalRecord);

    notifyListeners();
    return id;
  }

  /// 统一事程语义匹配：本地优先 → 大模型降级
  Future<void> _matchAgendaSemanticAsync(
    String recordId, String recordContent, List<AgendaItem> candidates, DateTime recordTime,
  ) async {
    try {
      final result = await _semanticMatch.matchAgenda(
        recordContent: recordContent,
        candidates: candidates,
        recordTime: recordTime,
      );

      if (result.matched && result.matchedId != null) {
        final matchedAgenda = candidates.where((a) => a.id == result.matchedId).firstOrNull;
        if (matchedAgenda != null) {
          // 判断是否延期
          final agendaTime = DateTime.parse('${matchedAgenda.date} ${matchedAgenda.time}');
          final isDelayed = recordTime.isAfter(agendaTime);
          final delayTag = isDelayed ? ' [延期]' : '';
          final matchedAgendaDisplay = '${matchedAgenda.time}${matchedAgenda.content}$delayTag';

          // 更新时间线记录
          _timelineRecords = _timelineRecords.map((r) {
            if (r.id == recordId) {
              return r.copyWith(
                linkedAgendaId: matchedAgenda.id,
                matchedAgenda: matchedAgendaDisplay,
              );
            }
            return r;
          }).toList();

          // 自动完成事程
          if (matchedAgenda.status == AgendaStatus.pending) {
            completeAgenda(matchedAgenda.id);
          }

          notifyListeners();
          debugPrint('事程匹配成功 [${result.source}]: ${result.matchedName} - ${result.reason}');
        }
      }
    } catch (e) {
      debugPrint('事程语义匹配失败: $e');
    }
  }

  /// 处理时间线记录的副作用：购物记录自动入库、库存数量变更
  void _processTimelineSideEffects(TimelineRecord record) {
    final se = record.sideEffects;
    if (se == null) return;

    // 购物记录 → 自动入库（增加库存）
    if (se.shoppingRecord != null) {
      for (final item in se.shoppingRecord!.items) {
        final existing = findInventory(item.name);
        if (existing == null) {
          // 新物品：直接入库
          updateInventory(
            item.name,
            item.quantity.toDouble(),
            item.unit,
            reason: '购买入库（${se.shoppingRecord!.store}）',
            category: '食品',
            syncToTimeline: false,
            sourceType: 'timeline',
            sourceId: record.id,
          );
        } else if (existing.unit != item.unit) {
          // 单位不同：仅入库新物品，不合并
          updateInventory(
            item.name,
            item.quantity.toDouble(),
            item.unit,
            reason: '购买入库（${se.shoppingRecord!.store}）',
            category: existing.category,
            syncToTimeline: false,
            sourceType: 'timeline',
            sourceId: record.id,
          );
        } else {
          // 已存在且单位相同：累加数量
          updateInventory(
            item.name,
            item.quantity.toDouble(),
            item.unit,
            reason: '购买入库（${se.shoppingRecord!.store}）',
            category: existing.category,
            syncToTimeline: false,
            sourceType: 'timeline',
            sourceId: record.id,
          );
        }
      }
    }

    // 库存数量变更（消耗/调整）- 使用语义匹配
    if (se.inventoryUpdate != null) {
      // 先尝试语义匹配库存物品
      _matchInventorySemanticAsync(
        record.content,
        se.inventoryUpdate!.name,
        se.inventoryUpdate!.quantityChange,
        se.inventoryUpdate!.unit,
        se.inventoryUpdate!.reason,
        sourceType: 'timeline',
        sourceId: record.id,
      );
    }

    // 物品位置变更 - 使用语义匹配（本地优先 → 大模型降级）
    if (se.itemUpdate != null) {
      _matchLocationSemanticAsync(
        record.id,
        record.content,
        se.itemUpdate!.name,
        se.itemUpdate!.location,
      );
    }
  }

  /// 物品位置语义匹配：本地优先 → 大模型降级
  /// 匹配成功后更新时间线记录中的物品名，使同名物品自动合并
  Future<void> _matchLocationSemanticAsync(
    String recordId, String recordContent, String itemName, String location,
  ) async {
    try {
      // 排除与当前物品同名的候选项，避免匹配到自身
      final candidates = items.where((i) => i.name != itemName).toList();
      if (candidates.isEmpty) return;

      final result = await _semanticMatch.matchItemLocation(
        recordContent: recordContent,
        candidates: candidates,
      );

      if (result.matched && result.matchedName != null && result.matchedName != itemName) {
        final matchedName = result.matchedName!;
        debugPrint('物品位置匹配成功 [${result.source}]: $itemName → $matchedName - ${result.reason}');

        // 更新时间线记录中的物品名，使其与已有物品合并
        _timelineRecords = _timelineRecords.map((r) {
          if (r.id == recordId && r.sideEffects?.itemUpdate != null) {
            final oldUpdate = r.sideEffects!.itemUpdate!;
            return r.copyWith(
              sideEffects: r.sideEffects!.copyWith(
                itemUpdate: ItemUpdate(name: matchedName, location: oldUpdate.location),
              ),
            );
          }
          return r;
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('物品位置语义匹配失败: $e');
    }
  }

  /// 库存语义匹配：本地优先 → 大模型降级
  Future<void> _matchInventorySemanticAsync(
    String recordContent, String itemName, double quantityChange, String unit, String reason,
    {String? sourceType, String? sourceId}
  ) async {
    try {
      final result = await _semanticMatch.matchInventory(
        recordContent: recordContent,
        candidates: _inventory,
      );

      String finalItemName = itemName;
      double finalQuantity = quantityChange;
      String finalUnit = unit;

      if (result.matched && result.matchedName != null) {
        finalItemName = result.matchedName!;
        debugPrint('库存匹配成功 [${result.source}]: ${result.matchedName} - ${result.reason}');
      }

      InventoryItem matchedItem = InventoryItem(id: '', name: '', quantity: 0, lastUpdated: DateTime.now());
      for (final i in _inventory) {
        if (i.name == finalItemName) {
          matchedItem = i;
          break;
        }
      }
      if (matchedItem.id.isEmpty) {
        for (final i in _inventory) {
          if (finalItemName.contains(i.name)) {
            matchedItem = i;
            break;
          }
        }
      }

      if (matchedItem.id.isNotEmpty && matchedItem.dailyUsage != null && matchedItem.dailyUsage! > 0) {
        if (quantityChange.abs() == 1.0) {
          finalQuantity = matchedItem.dailyUsage! * (quantityChange < 0 ? -1 : 1);
          finalUnit = matchedItem.unit;
          debugPrint('使用实际用量: $finalItemName $finalQuantity$finalUnit');
        }
      }

      updateInventory(
        finalItemName,
        finalQuantity,
        finalUnit,
        reason: reason.isNotEmpty ? reason : '时间线记录变更',
        syncToTimeline: false,
        sourceType: sourceType,
        sourceId: sourceId,
      );
    } catch (e) {
      debugPrint('库存语义匹配失败: $e');
      updateInventory(itemName, quantityChange, unit, reason: reason, syncToTimeline: false, sourceType: sourceType, sourceId: sourceId);
    }
  }

  void updateRecordTags(String id, List<String> tags) {
    _timelineRecords = _timelineRecords.map((r) =>
      r.id == id ? r.copyWith(tags: tags) : r
    ).toList();
    notifyListeners();
  }

  void addNoteToRecord(String id, String content) {
    final note = NoteEntry(
      id: _genId(),
      content: content,
      time: now,
    );
    _timelineRecords = _timelineRecords.map((r) =>
      r.id == id ? r.copyWith(notes: [...r.notes, note]) : r
    ).toList();
    notifyListeners();
  }

  void deleteTimelineRecord(String id) {
    final recordIdx = _timelineRecords.indexWhere((r) => r.id == id);
    if (recordIdx < 0) return;
    final record = _timelineRecords[recordIdx];

    // 取消关联的库存消耗
    _revertInventoryChanges('timeline', id);

    // 删除关联的事程（同时恢复该事程完成时的库存消耗）
    if (record.linkedAgendaId != null) {
      _revertInventoryChanges('agenda', record.linkedAgendaId!);
      _agendaItems = _agendaItems.where((a) => a.id != record.linkedAgendaId).toList();
    }

    // 删除关联的待确认事程
    if (record.matchedAgenda != null) {
      _pendingAgendaConfirm = _pendingAgendaConfirm.where((p) {
        final matchKey = '${p.suggestedTime}${p.content}';
        return matchKey != record.matchedAgenda;
      }).toList();
    }

    // 删除时间线记录
    _timelineRecords = _timelineRecords.where((r) => r.id != id).toList();
    notifyListeners();
  }

  void deleteNoteFromRecord(String recordId, String noteId) {
    _timelineRecords = _timelineRecords.map((r) =>
      r.id == recordId ? r.copyWith(notes: r.notes.where((n) => n.id != noteId).toList()) : r
    ).toList();
    notifyListeners();
  }

  void updateRecordIntentData(String id, Map<String, dynamic> newSlots) {
    _timelineRecords = _timelineRecords.map((r) {
      if (r.id != id) return r;
      final oldIntentData = r.sideEffects?.intentData;
      if (oldIntentData == null) return r;
      final newIntentData = IntentData(
        intentType: oldIntentData.intentType,
        displayName: oldIntentData.displayName,
        slots: newSlots,
      );
      return r.copyWith(
        sideEffects: r.sideEffects?.copyWith(intentData: newIntentData),
      );
    }).toList();
    notifyListeners();
  }

  void reRecognizeRecord(String id) {
    final recordIdx = _timelineRecords.indexWhere((r) => r.id == id);
    if (recordIdx < 0) return;
    final record = _timelineRecords[recordIdx];
    _reprocessRecordWithAI(record);
  }

  // ===== 自定义标签 =====
  List<TagDef> _customTags = [];
  List<TagDef> get customTags => _customTags;
  static const int maxCustomTags = 20;

  List<TagDef> get allTags => [...TagDef.systemTags, ..._customTags];

  Map<String, dynamic> addCustomTag({required String name, required String color, String icon = '#'}) {
    if (_customTags.length >= maxCustomTags) {
      return {'success': false, 'error': '自定义标签最多 $maxCustomTags 个'};
    }
    final allNames = [...TagDef.systemTags.map((t) => t.name), ..._customTags.map((t) => t.name)];
    if (allNames.contains(name)) {
      return {'success': false, 'error': '标签名已存在'};
    }
    _customTags = [..._customTags, TagDef(
      id: _genId(),
      name: name,
      color: color,
      icon: icon,
    )];
    notifyListeners();
    return {'success': true};
  }

  void deleteCustomTag(String id) {
    _customTags = _customTags.where((t) => t.id != id).toList();
    notifyListeners();
  }

  Map<String, dynamic> renameCustomTag(String id, String name) {
    final allNames = [...TagDef.systemTags.map((t) => t.name), ..._customTags.where((t) => t.id != id).map((t) => t.name)];
    if (allNames.contains(name)) {
      return {'success': false, 'error': '标签名已存在'};
    }
    _customTags = _customTags.map((t) => t.id == id ? TagDef(id: t.id, name: name, color: t.color, icon: t.icon) : t).toList();
    notifyListeners();
    return {'success': true};
  }

  Map<String, dynamic> editCustomTag(String id, {String? name, String? color, String? icon}) {
    final idx = _customTags.indexWhere((t) => t.id == id);
    if (idx < 0) {
      return {'success': false, 'error': '标签不存在'};
    }
    final oldTag = _customTags[idx];
    final newName = name ?? oldTag.name;
    final newColor = color ?? oldTag.color;
    final newIcon = icon ?? oldTag.icon;

    if (newName != oldTag.name) {
      final allNames = [...TagDef.systemTags.map((t) => t.name), ..._customTags.where((t) => t.id != id).map((t) => t.name)];
      if (allNames.contains(newName)) {
        return {'success': false, 'error': '标签名已存在'};
      }
    }

    _customTags = _customTags.map((t) => t.id == id ? TagDef(id: t.id, name: newName, color: newColor, icon: newIcon) : t).toList();
    notifyListeners();
    return {'success': true};
  }

  TagDef? getTagDef(String tagId) {
    for (final t in TagDef.systemTags) {
      if (t.id == tagId) return t;
    }
    for (final t in _customTags) {
      if (t.id == tagId) return t;
    }
    return null;
  }

  List<TimelineRecord> getRecordsByTag(String tagId) {
    return _timelineRecords.where((r) => r.tags.contains(tagId)).toList();
  }

  int getTagUsageCount(String tagId) {
    return _timelineRecords.where((r) => r.tags.contains(tagId)).length;
  }

  // ===== 用户档案（个性化建议） =====
  UserProfile _userProfile = MockData.mockUserProfile;
  UserProfile get userProfile => _userProfile;

  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  // ===== 计划模板库 =====
  List<PlanTemplate> get planTemplates => MockData.mockPlanTemplates;

  // ===== 习惯徽章 =====
  List<HabitBadge> get allBadges => MockData.mockHabitBadges;
  List<String> _earnedBadges = []; // 已获得徽章ID
  List<String> get earnedBadges => _earnedBadges;

  // 计算某习惯的连续完成天数
  int getHabitStreak(String habitName) {
    int streak = 0;
    for (int i = 0; i < 100; i++) {
      final date = MockData.dateOffset(-i);
      final matched = _timelineRecords.any((r) =>
        r.date == date && r.content.contains(habitName));
      if (matched) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // 检查并奖励徽章
  String? checkAndAwardBadge(String habitName) {
    final streak = getHabitStreak(habitName);
    for (final badge in allBadges) {
      if (streak >= badge.requiredDays && !_earnedBadges.contains(badge.id)) {
        _earnedBadges.add(badge.id);
        notifyListeners();
        return '太棒了！您已连续完成 $streak 天「$habitName」，获得「${badge.name}」徽章 ${badge.icon}\n${badge.description}';
      }
    }
    return null;
  }

  // ===== 对话上下文（多轮对话） =====
  ConversationContext _context = const ConversationContext();
  ConversationContext get conversationContext => _context;

  // ===== 购物 =====
  List<ShoppingRecord> get shoppingRecords {
    return _timelineRecords
        .where((r) => r.type == TimelineType.shopping && r.sideEffects?.shoppingRecord != null)
        .map((r) => r.sideEffects!.shoppingRecord!)
        .toList();
  }

  void addShoppingRecord(ShoppingRecord record) {
    final itemStr = record.items.map((i) => '${i.name}${i.quantity}${i.unit}').join('、');
    final content = '在${record.store}购买了$itemStr';
    
    addTimelineRecord(TimelineRecord(
      id: '',
      content: content,
      time: record.time,
      type: TimelineType.shopping,
      tags: ['shopping'],
      sideEffects: SideEffects(shoppingRecord: record),
    ));
  }

  // ===== 物品 =====
  List<ItemRecord> get items {
    final Map<String, List<TimelineRecord>> itemRecords = {};
    for (final r in _timelineRecords) {
      if (r.sideEffects?.itemUpdate != null) {
        final name = r.sideEffects!.itemUpdate!.name;
        itemRecords.putIfAbsent(name, () => []);
        itemRecords[name]!.add(r);
      }
    }
    
    return itemRecords.entries.map((entry) {
      final name = entry.key;
      final records = entry.value;
      records.sort((a, b) => b.time.compareTo(a.time));
      final latest = records.first;
      final location = latest.sideEffects!.itemUpdate!.location;
      final history = records.map((r) => LocationHistory(
        id: r.id,
        location: r.sideEffects!.itemUpdate!.location,
        time: r.time,
      )).toList();
      
      return ItemRecord(
        id: 'item_$name',
        name: name,
        location: location,
        history: history,
      );
    }).toList();
  }

  void updateItemLocation(String name, String location) {
    // 获取当前位置（历史数据）
    final currentItem = items.firstWhere((item) => item.name == name, orElse: () => ItemRecord(id: '', name: name, location: '未知', history: []));
    final currentLocation = currentItem.location;
    
    // 创建时间线记录，格式：物品，由xx位置改为xx位置
    final content = currentLocation != '未知' && currentLocation != location
        ? '$name，由$currentLocation改为$location'
        : '$name，存放在$location';
    
    addTimelineRecord(TimelineRecord(
      id: '',
      content: content,
      time: now,
      type: TimelineType.item,
      tags: ['item'],
      sideEffects: SideEffects(itemUpdate: ItemUpdate(name: name, location: location)),
    ));
  }

  // ===== 库存 =====
  List<InventoryItem> _inventory = [];
  List<InventoryItem> get inventory => _inventory;

  InventoryItem? findInventory(String name) {
    for (final i in _inventory) {
      if (i.name == name) return i;
    }
    for (final i in _inventory) {
      if (name.contains(i.name)) return i;
    }
    return null;
  }

  void _revertInventoryChanges(String sourceType, String sourceId) {
    bool changed = false;
    _inventory = _inventory.map((item) {
      final matchingLogs = item.logs.where((log) => 
        log.sourceType == sourceType && log.sourceId == sourceId
      ).toList();
      if (matchingLogs.isEmpty) return item;

      double totalRevert = 0.0;
      for (final log in matchingLogs) {
        totalRevert -= log.change;
      }

      final newQty = (item.quantity + totalRevert).clamp(0.0, double.infinity) as double;
      final newLogs = item.logs.where((log) => 
        !(log.sourceType == sourceType && log.sourceId == sourceId)
      ).toList();

      changed = true;
      return item.copyWith(
        quantity: newQty,
        logs: newLogs,
        lastUpdated: now,
      );
    }).toList();

    if (changed) {
      _inventory = _inventory.where((item) => item.quantity > 0).toList();
      notifyListeners();
    }
  }

  void updateInventory(String name, double change, String unit, {String reason = '', String category = '其他', String? aiSuggestion, String? customSuggestion, double? dailyUsage, bool syncToTimeline = true, String? sourceType, String? sourceId}) {
    int existingIndex = -1;
    
    for (int i = 0; i < _inventory.length; i++) {
      final item = _inventory[i];
      if (item.name == name) {
        existingIndex = i;
        break;
      }
    }
    
    if (existingIndex < 0) {
      for (int i = 0; i < _inventory.length; i++) {
        final item = _inventory[i];
        if (name.contains(item.name)) {
          existingIndex = i;
          break;
        }
      }
    }
    final now = this.now;
    final log = InventoryLog(
      id: _genId(),
      change: change,
      reason: reason,
      time: now,
      sourceType: sourceType,
      sourceId: sourceId,
    );

    if (existingIndex >= 0) {
      final existing = _inventory[existingIndex];
      final oldQty = existing.quantity;
      final oldUnit = existing.unit;
      final newQty = (existing.quantity + change).clamp(0.0, double.infinity) as double;
      _inventory = _inventory.asMap().entries.map((e) {
        if (e.key != existingIndex) return e.value;
        return existing.copyWith(
          quantity: newQty,
          unit: unit,
          lastUpdated: now,
          logs: [log, ...existing.logs].take(50).toList(),
          aiSuggestion: aiSuggestion ?? existing.aiSuggestion,
          customSuggestion: customSuggestion ?? existing.customSuggestion,
          dailyUsage: dailyUsage ?? existing.dailyUsage,
        );
      }).toList();
      // 同步到时间线：物品，由xx数据改为xx数据
      if (syncToTimeline && (oldQty != newQty || oldUnit != unit)) {
        final changeDesc = oldQty != newQty
            ? '$name，由${_fmtQty(oldQty)}$oldUnit改为${_fmtQty(newQty)}$unit'
            : '$name，单位由$oldUnit改为$unit';
        _addInventoryChangeTimeline(changeDesc, now);
      }
    } else if (change > 0) {
      _inventory = [
        InventoryItem(
          id: _genId(),
          name: name,
          quantity: change,
          unit: unit,
          category: category,
          lastUpdated: now,
          logs: [log],
          aiSuggestion: aiSuggestion,
          customSuggestion: customSuggestion,
          dailyUsage: dailyUsage,
        ),
        ..._inventory,
      ];
      // 同步到时间线：新增物品
      if (syncToTimeline) {
        final changeDesc = '$name，新增${_fmtQty(change)}$unit';
        _addInventoryChangeTimeline(changeDesc, now);
      }
    }
    notifyListeners();
  }

  String _fmtQty(double qty) {
    return qty == qty.toInt() ? qty.toInt().toString() : qty.toStringAsFixed(1);
  }

  void _addInventoryChangeTimeline(String content, DateTime time) {
    final id = _genId();
    _timelineRecords = [
      TimelineRecord(
        id: id,
        time: time,
        content: content,
        type: TimelineType.item,
        tags: ['item'],
        deleted: false,
      ),
      ..._timelineRecords,
    ];
  }

  // 从购物记录自动入库
  void addInventoryFromShopping(List<ShoppingItem> items, {String category = '食品'}) {
    for (final item in items) {
      updateInventory(
        item.name,
        item.quantity.toDouble(),
        item.unit,
        reason: '购买入库',
        category: category,
      );
    }
  }

  void updateInventoryMetadata(String id, {String? unit, String? category, DateTime? expireDate, String? customSuggestion, double? dailyUsage}) {
    final existing = _inventory.where((i) => i.id == id).firstOrNull;
    _inventory = _inventory.map((item) {
      if (item.id != id) return item;
      return item.copyWith(
        unit: unit ?? item.unit,
        category: category ?? item.category,
        expireDate: expireDate,
        customSuggestion: customSuggestion,
        dailyUsage: dailyUsage ?? item.dailyUsage,
        lastUpdated: now,
      );
    }).toList();
    // 同步到时间线：物品元数据变更
    if (existing != null) {
      final changes = <String>[];
      if (unit != null && unit != existing.unit) {
        changes.add('单位由${existing.unit}改为$unit');
      }
      if (category != null && category != existing.category) {
        changes.add('分类由${existing.category}改为$category');
      }
      if (changes.isNotEmpty) {
        final changeDesc = '${existing.name}，${changes.join('，')}';
        _addInventoryChangeTimeline(changeDesc, now);
      }
    }
    notifyListeners();
  }

  String genId() => _genId();

  // ===== 常用事程 =====
  List<FrequentAgenda> _frequentAgendas = [];
  List<FrequentAgenda> get frequentAgendas => _frequentAgendas;

  // ===== 对话 =====
  List<ChatMessage> _chatMessages = [];
  List<ChatMessage> get chatMessages => _chatMessages;

  void addChatMessage(ChatMessage msg) {
    _chatMessages = [..._chatMessages, msg];
    if (msg.role == 'user') {
      _recordQuestionFrequency(msg.content);
    }
    notifyListeners();
  }

  Map<String, int> _questionFrequency = {};
  
  void _recordQuestionFrequency(String question) {
    _questionFrequency[question] = (_questionFrequency[question] ?? 0) + 1;
  }
  
  List<String> get frequentQuestions {
    final sorted = _questionFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(6).map((e) => e.key).toList();
  }

  void _loadQuestionFrequency() {
    try {
      final data = _storage.loadQuestionFrequency();
      if (data != null) {
        _questionFrequency = Map<String, int>.from(data);
      }
    } catch (_) {
      _questionFrequency = {};
    }
  }

  void _saveQuestionFrequency() {
    _storage.saveQuestionFrequency(_questionFrequency);
  }
  
  String getTimelineSummary() {
    final today = now;
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayRecords = _timelineRecords.where((r) => r.date == todayStr).toList();
    
    if (todayRecords.isEmpty) {
      return '今天暂无时间线记录';
    }
    
    String summary = '今天的时间线记录：\n';
    for (final record in todayRecords) {
      final timeStr = '${record.time.hour.toString().padLeft(2, '0')}:${record.time.minute.toString().padLeft(2, '0')}';
      summary += '$timeStr ${record.content}\n';
    }
    return summary.trim();
  }

  // ===== 待确认事程 =====
  List<PendingAgendaItem> _pendingAgendaConfirm = [];
  List<PendingAgendaItem> get pendingAgendaConfirm => _pendingAgendaConfirm;

  void addPendingAgenda(List<PendingAgendaItem> items) {
    _pendingAgendaConfirm = [..._pendingAgendaConfirm, ...items];
    notifyListeners();
  }

  void confirmPendingAgenda(List<String> ids) {
    for (final item in _pendingAgendaConfirm.where((p) => ids.contains(p.id))) {
      final agendaId = _genId();
      addAgenda(AgendaItem(
        id: agendaId,
        content: item.content,
        time: item.suggestedTime,
        date: item.suggestedDate,
        status: AgendaStatus.pending,
        remainingTime: item.suggestedDate == todayStr ? '今日提醒' : '待提醒',
      ));
      // 关联时间线记录
      final matchKey = '${item.suggestedTime}${item.content}';
      _timelineRecords = _timelineRecords.map((r) {
        if (r.matchedAgenda == matchKey && r.linkedAgendaId == null) {
          return r.copyWith(linkedAgendaId: agendaId);
        }
        return r;
      }).toList();
    }
    _pendingAgendaConfirm = _pendingAgendaConfirm.where((p) => !ids.contains(p.id)).toList();
    notifyListeners();
  }

  void rejectPendingAgenda(List<String> ids) {
    for (final item in _pendingAgendaConfirm.where((p) => ids.contains(p.id))) {
      final matchKey = '${item.suggestedTime}${item.content}';
      _timelineRecords = _timelineRecords.map((r) {
        if (r.matchedAgenda == matchKey && r.linkedAgendaId == null) {
          return r.copyWith(matchedAgenda: null);
        }
        return r;
      }).toList();
    }
    _pendingAgendaConfirm = _pendingAgendaConfirm.where((p) => !ids.contains(p.id)).toList();
    notifyListeners();
  }

  void clearPendingAgenda() {
    _pendingAgendaConfirm = [];
    notifyListeners();
  }

  void updatePendingAgendaTime(String id, String time) {
    _pendingAgendaConfirm = _pendingAgendaConfirm.map((p) =>
      p.id == id ? PendingAgendaItem(
        id: p.id,
        content: p.content,
        suggestedTime: time,
        suggestedDate: p.suggestedDate,
        timeSource: TimeSource.userSpecified,
      ) : p
    ).toList();
    notifyListeners();
  }

  /// 将时间线记录关联到事程（用于弹窗编辑后手动关联）
  void linkTimelineToAgenda(String matchedAgendaKey, String agendaId) {
    _timelineRecords = _timelineRecords.map((r) {
      if (r.matchedAgenda == matchedAgendaKey && r.linkedAgendaId == null) {
        return r.copyWith(linkedAgendaId: agendaId);
      }
      return r;
    }).toList();
    notifyListeners();
  }

  // ===== 到时提醒 =====
  AgendaItem? _activeReminder;
  AgendaItem? get activeReminder => _activeReminder;

  void dismissReminder() {
    _activeReminder = null;
    _isHomeOverlayOpen = false;
    notifyListeners();
  }

  void checkAgendaReminders() {
    final now = this.now;
    // todayStr comes from the getter
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final due = _agendaItems.where((a) =>
      a.date == todayStr &&
      a.status == AgendaStatus.pending &&
      a.time == currentTime
    ).firstOrNull;
    if (due != null && _activeReminder == null) {
      _activeReminder = due;
      _isHomeOverlayOpen = true;
      notifyListeners();
    }
  }

  // ===== 语音录入综合处理 =====

  /// 重新处理已有记录（更新识别结果，不创建新记录）
  Future<void> _reprocessRecordWithAI(TimelineRecord record) async {
    await _initCompleter.future;
    final t = record.content.trim();
    final now = record.time;

    final intentResult = await _intentService!.recognize(t);
    final parsed = _convertIntentResult(t, intentResult);
    final tags = parsed['tags'] as List<String>;
    final sideEffects = parsed['sideEffects'] as Map<String, dynamic>?;
    final hasCompleteSignal = parsed['hasCompleteSignal'] as bool;

    final result = await _processVoiceRecord(t, now, tags, sideEffects, hasCompleteSignal, intentResult);
    final matchedAgenda = result['matchedAgenda'] as String?;
    final linkedAgendaId = result['linkedAgendaId'] as String?;

    SideEffects? recordSideEffects;
    ShoppingRecord? shoppingRecord;
    ItemUpdate? itemUpdate;
    InventoryUpdate? inventoryUpdate;
    IntentData? intentData;
    String? agendaStr;
    List<String>? agendaListStr;

    if (sideEffects?['shoppingRecord'] != null) {
      final sr = sideEffects!['shoppingRecord'] as ShoppingRecord;
      shoppingRecord = ShoppingRecord(
        id: _genId(),
        store: sr.store,
        items: sr.items,
        time: now,
      );
    }
    if (sideEffects?['itemUpdate'] != null) {
      itemUpdate = sideEffects!['itemUpdate'] as ItemUpdate;
    }
    if (sideEffects?['inventoryUpdate'] != null) {
      inventoryUpdate = sideEffects!['inventoryUpdate'] as InventoryUpdate;
    }
    if (sideEffects?['intentData'] != null) {
      intentData = sideEffects!['intentData'] as IntentData;
    }
    if (sideEffects?['agenda'] != null) {
      final ag = sideEffects!['agenda'] as Map<String, dynamic>;
      agendaStr = '${ag['time'] ?? ''} ${ag['content'] ?? ''}';
    }
    if (sideEffects?['agendaList'] != null) {
      final agList = sideEffects!['agendaList'] as List;
      agendaListStr = agList.map((ag) => '${ag['time'] ?? ''} ${ag['content'] ?? ''}').toList().cast<String>();
    }

    if (shoppingRecord != null || itemUpdate != null || inventoryUpdate != null || intentData != null || agendaStr != null) {
      recordSideEffects = SideEffects(
        shoppingRecord: shoppingRecord,
        itemUpdate: itemUpdate,
        inventoryUpdate: inventoryUpdate,
        intentData: intentData,
        agenda: agendaStr,
        agendaList: agendaListStr,
      );
    }

    _timelineRecords = _timelineRecords.map((r) =>
      r.id == record.id ? r.copyWith(
        tags: tags,
        matchedAgenda: matchedAgenda,
        linkedAgendaId: linkedAgendaId,
        sideEffects: recordSideEffects,
      ) : r
    ).toList();
    notifyListeners();
  }

  /// AI意图识别版语音记录 - 异步，使用意图识别服务（支持多时间点多意图）
  Future<Map<String, dynamic>> submitVoiceRecordWithAI(String text) async {
    final t = text.trim();
    final now = this.now;

    // 等待初始化完成，防止 LateInitializationError
    await _initCompleter.future;

    // 清除之前的待确认事程，避免累积
    clearPendingAgenda();

    // 1. 调用意图识别服务
    final intentResult = await _intentService!.recognize(t);

    // 2. 如果只有一个时间槽，走单条记录逻辑
    final slots = intentResult.timelineSlots;

    // 无论多少时间槽，都只创建一条时间线记录
    // 时间线记录时间始终使用当前时间，计划时间只用于事程
    final parsed = _convertIntentResult(t, intentResult);
    final tags = parsed['tags'] as List<String>;
    final sideEffects = parsed['sideEffects'] as Map<String, dynamic>?;
    final hasCompleteSignal = parsed['hasCompleteSignal'] as bool;

    // 关键修复：时间线记录时间始终使用当前时间，不是计划时间
    final result = await _processVoiceRecord(t, now, tags, sideEffects, hasCompleteSignal, intentResult);
    result['_intentResult'] = intentResult;
    return result;
  }

  /// 从时间槽中解析时间，返回DateTime
  DateTime _parseSlotTime(TimelineSlot slot, DateTime fallback) {
    if (slot.time.isEmpty) return fallback;
    final parts = slot.time.split(':');
    if (parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    return DateTime(fallback.year, fallback.month, fallback.day, hour, minute);
  }

  /// 将意图识别结果转换为_parseVoiceText的输出格式（支持多意图多时间点）
  Map<String, dynamic> _convertIntentResult(String text, IntentResult intentResult) {
    final tags = <String>[];
    final sideEffects = <String, dynamic>{};
    bool hasCompleteSignal = false;

    for (final intent in intentResult.allIntents) {
      switch (intent.type) {
        case IntentType.itemLocation:
          tags.add('item');
          final itemName = intent.slots['item_name'] as String?;
          final location = intent.slots['location'] as String?;
          if (itemName != null && location != null) {
            sideEffects['itemUpdate'] = ItemUpdate(name: itemName, location: location);
          }
          break;

        case IntentType.shopping:
          tags.add('shopping');
          final store = intent.slots['store'] as String? ?? '';
          final itemsText = intent.slots['items_text'] as String? ?? '';
          final items = <ShoppingItem>[];
          if (intent.slots['items'] is List) {
            for (final item in intent.slots['items'] as List) {
              if (item is Map<String, dynamic>) {
                final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                final name = item['name'] as String? ?? '';
                final unit = item['unit'] as String? ?? '个';
                debugPrint('购物商品解析: name=$name, quantity=$qty, unit=$unit');
                items.add(ShoppingItem(
                  id: _genId(),
                  name: name,
                  quantity: qty,
                  unit: unit,
                ));
              }
            }
          }
          if (items.isEmpty && itemsText.isNotEmpty) {
            debugPrint('购物items为空，从itemsText解析: $itemsText');
            // 从文本中提取商品数量和单位
            final itemRegex = RegExp(
              r'(\d+(?:\.\d+)?)\s*(片|粒|盒|瓶|个|包|袋|支|颗|毫升|克|斤|公斤|箱|条|把)\s*([\u4e00-\u9fa5A-Za-z]{2,10})',
            );
            final matches = itemRegex.allMatches(itemsText);
            if (matches.isNotEmpty) {
              for (final m in matches) {
                items.add(ShoppingItem(
                  id: _genId(),
                  name: m.group(3)!,
                  quantity: int.tryParse(m.group(1)!) ?? 1,
                  unit: m.group(2)!,
                ));
              }
            } else {
              final names = itemsText.split(RegExp(r'[，,、和]')).where((s) => s.trim().isNotEmpty);
              for (final n in names) {
                items.add(ShoppingItem(id: _genId(), name: n.trim()));
              }
            }
          }
          debugPrint('购物记录解析结果: store=$store, itemsCount=${items.length}');
          sideEffects['shoppingRecord'] = ShoppingRecord(
            id: '',
            store: store,
            items: items,
            time: now,
          );
          break;

        case IntentType.agendaCreate:
          final time = intent.slots['time'] as String?;
          final content = intent.slots['content'] as String? ?? text;
          final isMustDo = intent.slots['is_must_do'] as bool? ?? false;
          final dateOffset = (intent.slots['date_offset'] as num?)?.toInt() ?? 0;
          final agendaItem = {
            'time': time, // 不默认填充当前时间，留空由后续逻辑推断
            'content': content,
            'isMustDo': isMustDo,
            'date_offset': dateOffset,
          };
          // 收集多个事程到 agendaList，同时保留最后一个到 agenda 以兼容旧逻辑
          if (!sideEffects.containsKey('agendaList')) {
            sideEffects['agendaList'] = <Map<String, dynamic>>[];
          }
          (sideEffects['agendaList'] as List).add(agendaItem);
          sideEffects['agenda'] = agendaItem;
          break;

        case IntentType.agendaComplete:
          hasCompleteSignal = true;
          sideEffects['completeMatch'] = true;
          break;

        case IntentType.inventoryConsume:
          if (!tags.contains('behavior')) {
            tags.add('behavior');
          }
          final itemName = intent.slots['item_name'] as String? ?? '';
          final quantity = (intent.slots['quantity'] as num?)?.toDouble() ?? 1.0;
          final unit = intent.slots['unit'] as String? ?? '个';
          sideEffects['inventoryUpdate'] = InventoryUpdate(
            name: itemName,
            quantityChange: -quantity,
            unit: unit,
            reason: '消耗使用',
          );
          sideEffects['intentData'] = IntentData(
            intentType: 'inventory_consume',
            displayName: '库存消耗',
            slots: {
              'item_name': itemName,
              'quantity': quantity,
              'unit': unit,
            },
          );
          break;

        case IntentType.behavior:
          if (!tags.contains('behavior')) {
            tags.add('behavior');
          }
          final keyword = intent.slots['keyword'] as String? ?? text;
          final category = _inferBehaviorCategory(keyword);
          sideEffects['intentData'] = IntentData(
            intentType: 'behavior',
            displayName: '行为活动',
            slots: {
              'keyword': keyword,
              'category': category,
            },
          );
          break;

        case IntentType.general:
          break;
      }
    }

    if (tags.isEmpty) tags.add('event');

    return {'tags': tags, 'sideEffects': sideEffects, 'hasCompleteSignal': hasCompleteSignal};
  }

  /// 推断行为分类
  String _inferBehaviorCategory(String keyword) {
    final healthKeywords = ['吃药', '服药', '量血压', '测血糖', '看病', '就医', '体检', '打针', '输液'];
    final dietKeywords = ['吃饭', '吃早饭', '吃午饭', '吃晚饭', '吃面', '吃米', '吃菜', '喝水', '喝汤', '吃水果'];
    final exerciseKeywords = ['运动', '散步', '跑步', '锻炼', '健身', '瑜伽', '太极', '走路', '爬山'];
    final dailyKeywords = ['起床', '睡觉', '洗漱', '洗澡', '刷牙', '洗脸', '穿衣', '出门', '回家'];
    final socialKeywords = ['聊天', '打电话', '视频', '聚会', '访友', '接孙子', '陪孙子', '买菜'];

    if (healthKeywords.any((k) => keyword.contains(k))) return '健康';
    if (dietKeywords.any((k) => keyword.contains(k))) return '饮食';
    if (exerciseKeywords.any((k) => keyword.contains(k))) return '运动';
    if (dailyKeywords.any((k) => keyword.contains(k))) return '日常';
    if (socialKeywords.any((k) => keyword.contains(k))) return '社交';
    return '其他';
  }

  /// 处理语音记录的共享逻辑
  Future<Map<String, dynamic>> _processVoiceRecord(
    String t,
    DateTime now,
    List<String> tags,
    Map<String, dynamic>? sideEffects,
    bool hasCompleteSignal,
    IntentResult? intentResult,
  ) async {
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 事程处理
    String? matchedAgenda;
    String? linkedAgendaId;
    int agendaCreatedCount = 0;
    bool needsConfirm = false;

    // 辅助：推断事程时间
    String _inferAgendaTime(String? agTime, String agContent) {
      // 如果LLM没有返回时间，或内容与返回时间明显不匹配，触发推断
      final hasExplicitTime = agTime != null && agTime.isNotEmpty;
      final needsInference = !hasExplicitTime || _shouldInferTime(agTime, agContent);
      if (needsInference) {
        final fromHistory = inferAgendaTimeByContent(agContent);
        if (fromHistory != null) return fromHistory;
        final fromCommon = inferAgendaTimeByCommonSense(agContent);
        if (fromCommon != null) return fromCommon;
      }
      return agTime ?? timeStr;
    }

    TimeSource _inferTimeSource(String? agTime, String agContent) {
      final hasExplicitTime = agTime != null && agTime.isNotEmpty;
      final needsInference = !hasExplicitTime || _shouldInferTime(agTime, agContent);
      if (!needsInference) return TimeSource.userSpecified;
      final fromHistory = inferAgendaTimeByContent(agContent);
      if (fromHistory != null) return TimeSource.history;
      final fromCommon = inferAgendaTimeByCommonSense(agContent);
      if (fromCommon != null) return TimeSource.commonSense;
      return TimeSource.current;
    }

    if (sideEffects?['agendaList'] != null) {
      final agendaList = sideEffects!['agendaList'] as List<Map<String, dynamic>>;
      final pendingItems = <PendingAgendaItem>[];
      for (final ag in agendaList) {
        final agTime = ag['time'] as String?;
        final agContent = ag['content'] as String? ?? t;
        final dateOffset = (ag['date_offset'] as num?)?.toInt() ?? 0;
        final agDate = MockData.dateOffset(dateOffset);
        final finalTime = _inferAgendaTime(agTime, agContent);
        final source = _inferTimeSource(agTime, agContent);
        pendingItems.add(PendingAgendaItem(
          id: _genId(),
          content: agContent,
          suggestedTime: finalTime,
          suggestedDate: agDate,
          timeSource: source,
        ));
      }
      addPendingAgenda(pendingItems);
      agendaCreatedCount = pendingItems.length;
      needsConfirm = true;
      matchedAgenda = '${pendingItems.first.suggestedTime}${pendingItems.first.content}';
    } else if (sideEffects?['agenda'] != null) {
      final ag = sideEffects!['agenda'] as Map<String, dynamic>;
      final agTime = ag['time'] as String?;
      final agContent = ag['content'] as String? ?? t;
      final dateOffset = (ag['date_offset'] as num?)?.toInt() ?? 0;
      final agDate = MockData.dateOffset(dateOffset);
      final finalTime = _inferAgendaTime(agTime, agContent);
      final source = _inferTimeSource(agTime, agContent);
      addPendingAgenda([PendingAgendaItem(
        id: _genId(),
        content: agContent,
        suggestedTime: finalTime,
        suggestedDate: agDate,
        timeSource: source,
      )]);
      agendaCreatedCount = 1;
      needsConfirm = true;
      matchedAgenda = '$finalTime$agContent';
    } else if (sideEffects?['completeMatch'] == true || hasCompleteSignal) {
      final tomorrowStr = DateTime.now().add(const Duration(days: 1)).toString().split(' ')[0];
      final candidates = _agendaItems.where((a) =>
        (a.date == todayStr || a.date == tomorrowStr) &&
        a.status != AgendaStatus.completed &&
        a.status != AgendaStatus.skipped
      ).toList();

      if (candidates.isNotEmpty) {
        AgendaItem? matched;

        final matchResult = await _semanticMatch.matchAgenda(
          recordContent: t,
          candidates: candidates,
          recordTime: now,
        );

        if (matchResult != null && matchResult.matched) {
          matched = candidates.where((a) => a.id == matchResult.matchedId).firstOrNull;
        }

        if (matched == null) {
          final behaviorMatch = RegExp(r'(吃药|吃饭|喝水|运动|散步|早饭|午饭|晚饭|睡觉|起床|洗漱|阅读)').firstMatch(t);
          if (behaviorMatch != null) {
            final keyword = behaviorMatch.group(1)!;
            final keywordCandidates = candidates.where((a) => a.content.contains(keyword)).toList();
            if (keywordCandidates.isNotEmpty) {
              matched = keywordCandidates.first;
            }
          }
        }

        if (matched == null) {
          final nowMinutes = now.hour * 60 + now.minute;
          int minDiff = 999999;
          for (final a in candidates) {
            final parts = a.time.split(':');
            if (parts.length != 2) continue;
            final aMinutes = int.tryParse(parts[0])! * 60 + int.tryParse(parts[1])!;
            final diff = (aMinutes - nowMinutes).abs();
            if (diff < minDiff) {
              minDiff = diff;
              matched = a;
            }
          }
        }

        if (matched != null) {
          matchedAgenda = '${matched.time}${matched.content}';
          linkedAgendaId = matched.id;
          completeAgenda(matched.id, addRecord: false);
        }
      }
    }

    // 构建 sideEffects
    SideEffects? recordSideEffects;
    ShoppingRecord? shoppingRecord;
    ItemUpdate? itemUpdate;
    InventoryUpdate? inventoryUpdate;
    IntentData? intentData;
    String? agendaStr;
    List<String>? agendaListStr;

    if (sideEffects?['shoppingRecord'] != null) {
      final sr = sideEffects!['shoppingRecord'] as ShoppingRecord;
      shoppingRecord = ShoppingRecord(
        id: _genId(),
        store: sr.store,
        items: sr.items,
        time: now,
      );
    }
    if (sideEffects?['itemUpdate'] != null) {
      itemUpdate = sideEffects!['itemUpdate'] as ItemUpdate;
    }
    if (sideEffects?['inventoryUpdate'] != null) {
      inventoryUpdate = sideEffects!['inventoryUpdate'] as InventoryUpdate;
    }
    if (sideEffects?['intentData'] != null) {
      intentData = sideEffects!['intentData'] as IntentData;
    }
    if (sideEffects?['agenda'] != null) {
      final ag = sideEffects!['agenda'] as Map<String, dynamic>;
      agendaStr = '${ag['time'] ?? ''} ${ag['content'] ?? ''}';
    }
    if (sideEffects?['agendaList'] != null) {
      final agList = sideEffects!['agendaList'] as List;
      agendaListStr = agList.map((ag) => '${ag['time'] ?? ''} ${ag['content'] ?? ''}').toList().cast<String>();
    }

    if (shoppingRecord != null || itemUpdate != null || inventoryUpdate != null || intentData != null || agendaStr != null) {
      recordSideEffects = SideEffects(
        shoppingRecord: shoppingRecord,
        itemUpdate: itemUpdate,
        inventoryUpdate: inventoryUpdate,
        intentData: intentData,
        agenda: agendaStr,
        agendaList: agendaListStr,
      );
    }

    // 写入时间线
    addTimelineRecord(TimelineRecord(
      id: '',
      content: t,
      time: now,
      type: _parseType(tags),
      tags: tags,
      matchedAgenda: matchedAgenda,
      linkedAgendaId: linkedAgendaId,
      sideEffects: recordSideEffects,
    ));

    if (shoppingRecord != null) {
      // 购物记录已通过sideEffects写入时间线，shoppingRecords getter会自动提取
    }

    return <String, dynamic>{
      'timelineId': _timelineRecords.last.id,
      'intent': intentResult?.primary.label ?? 'unknown',
      'confidence': intentResult?.primary.confidence ?? 0,
      'source': intentResult?.source ?? 'rule',
      'reason': intentResult?.reason?.toString(),
      'agendaCreated': agendaCreatedCount,
      'needsConfirm': needsConfirm,
      'feedback': null,
    };
  }

  /// 意图识别统计信息
  Map<String, dynamic> getIntentStats() {
    return _intentService?.getStats() ?? {'total': 0, 'llmCalls': 0, 'localMatches': 0, 'hitRate': 0.0};
  }

  /// 获取所有训练模式
  List<UserPattern> get allIntentPatterns => _intentService?.allPatterns ?? [];

  /// 获取意图识别服务
  IntentRecognitionService? get intentService => _intentService;

  /// 手动添加/更新训练模式
  Future<void> addIntentPattern(String text, List<TimelineSlot> slots) async {
    await _intentService?.addPattern(text, slots);
    notifyListeners();
  }

  /// 更新训练模式（编辑）
  Future<void> updateIntentPattern(String oldText, String newText, List<TimelineSlot> slots) async {
    await _intentService?.updatePattern(oldText, newText, slots);
    notifyListeners();
  }

  /// 删除训练模式
  Future<void> deleteIntentPattern(String text) async {
    await _intentService?.deletePattern(text);
    notifyListeners();
  }

  /// 清空所有训练模式
  Future<void> clearAllIntentPatterns() async {
    await _intentService?.clearPatterns();
    notifyListeners();
  }

  /// 加载预设模式（预训练）
  Future<void> loadPresetPatterns() async {
    await _intentService?.loadPresetPatterns();
    notifyListeners();
  }

  Map<String, dynamic> submitVoiceRecord(String text) {
    final t = text.trim();
    final now = this.now;
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 简化版解析
    final parsed = _parseVoiceText(t);
    var tags = parsed['tags'] as List<String>;
    final sideEffects = parsed['sideEffects'] as Map<String, dynamic>?;
    final hasCompleteSignal = parsed['hasCompleteSignal'] as bool;

    // 事程处理
    String? matchedAgenda;
    int agendaCreatedCount = 0;
    bool needsConfirm = false;

    if (sideEffects?['agendaList'] != null) {
      // 多事程拆分 → 逐个加入待确认队列
      final agendaList = sideEffects!['agendaList'] as List<Map<String, dynamic>>;
      final pendingItems = <PendingAgendaItem>[];
      for (final ag in agendaList) {
        final agTime = ag['time'] as String? ?? timeStr;
        final agContent = ag['content'] as String? ?? t;
        final dateOffset = (ag['date_offset'] as num?)?.toInt() ?? 0;
        final agDate = MockData.dateOffset(dateOffset);

        String finalTime = agTime;
        TimeSource source = TimeSource.current;
        if (agTime == timeStr) {
          final fromHistory = inferAgendaTimeByContent(agContent);
          if (fromHistory != null) {
            finalTime = fromHistory;
            source = TimeSource.history;
          } else {
            final fromCommon = inferAgendaTimeByCommonSense(agContent);
            if (fromCommon != null) {
              finalTime = fromCommon;
              source = TimeSource.commonSense;
            }
          }
        } else {
          source = TimeSource.userSpecified;
        }

        pendingItems.add(PendingAgendaItem(
          id: _genId(),
          content: agContent,
          suggestedTime: finalTime,
          suggestedDate: agDate,
          timeSource: source,
        ));
      }
      addPendingAgenda(pendingItems);
      agendaCreatedCount = pendingItems.length;
      needsConfirm = true;
      matchedAgenda = '${pendingItems.first.suggestedTime}${pendingItems.first.content}';
    } else if (sideEffects?['agenda'] != null) {
      final ag = sideEffects!['agenda'] as Map<String, dynamic>;
      final agTime = ag['time'] as String? ?? timeStr;
      final agContent = ag['content'] as String? ?? t;
      final dateOffset = (ag['date_offset'] as num?)?.toInt() ?? 0;
      final agDate = MockData.dateOffset(dateOffset);

      // 智能推断时间
      String finalTime = agTime;
      TimeSource source = TimeSource.current;
      if (agTime == timeStr) {
        final fromHistory = inferAgendaTimeByContent(agContent);
        if (fromHistory != null) {
          finalTime = fromHistory;
          source = TimeSource.history;
        } else {
          final fromCommon = inferAgendaTimeByCommonSense(agContent);
          if (fromCommon != null) {
            finalTime = fromCommon;
            source = TimeSource.commonSense;
          }
        }
      } else {
        source = TimeSource.userSpecified;
      }

      addPendingAgenda([PendingAgendaItem(
        id: _genId(),
        content: agContent,
        suggestedTime: finalTime,
        suggestedDate: agDate,
        timeSource: source,
      )]);
      agendaCreatedCount = 1;
      needsConfirm = true;
      matchedAgenda = '$finalTime$agContent';
    } else if (sideEffects?['completeMatch'] == true) {
      // 完成信号匹配已有事程
      final behaviorMatch = RegExp(r'(吃药|吃饭|喝水|运动|散步|早饭|午饭|晚饭|睡觉|起床|洗漱|阅读)').firstMatch(t);
      if (behaviorMatch != null) {
        final keyword = behaviorMatch.group(1)!;
        final matched = _agendaItems.where((a) =>
          a.date == todayStr &&
          a.status == AgendaStatus.pending &&
          a.content.contains(keyword)
        ).firstOrNull;
        if (matched != null) {
          matchedAgenda = '${matched.time}${matched.content}';
          completeAgenda(matched.id);
        }
      }
    } else if (hasCompleteSignal) {
      final behaviorMatch = RegExp(r'(吃药|吃饭|喝水|运动|散步|早饭|午饭|晚饭|睡觉|起床|洗漱|阅读)').firstMatch(t);
      if (behaviorMatch != null) {
        final keyword = behaviorMatch.group(1)!;
        final matched = _agendaItems.where((a) =>
          a.date == todayStr &&
          a.status == AgendaStatus.pending &&
          a.content.contains(keyword)
        ).firstOrNull;
        if (matched != null) {
          matchedAgenda = '${matched.time}${matched.content}';
          completeAgenda(matched.id);
        }
      }
    }

    // 构建 sideEffects
    SideEffects? recordSideEffects;
    ShoppingRecord? shoppingRecord;
    ItemUpdate? itemUpdate;
    String? agenda;
    InventoryUpdate? inventoryUpdate;
    
    if (sideEffects?['shoppingRecord'] != null) {
      final sr = sideEffects!['shoppingRecord'] as ShoppingRecord;
      shoppingRecord = ShoppingRecord(
        id: _genId(),
        store: sr.store,
        items: sr.items,
        time: now,
      );
    }
    if (sideEffects?['itemUpdate'] != null) {
      itemUpdate = sideEffects!['itemUpdate'] as ItemUpdate;
    }
    if (sideEffects?['agenda'] != null) {
      agenda = sideEffects!['agenda'] as String;
    }
    if (sideEffects?['agendaList'] != null) {
      // agendaList 在后面处理，这里先不构建
    }
    if (sideEffects?['inventoryUpdate'] != null) {
      inventoryUpdate = sideEffects!['inventoryUpdate'] as InventoryUpdate;
    }
    
    if (shoppingRecord != null || itemUpdate != null || agenda != null || inventoryUpdate != null) {
      recordSideEffects = SideEffects(
        shoppingRecord: shoppingRecord,
        itemUpdate: itemUpdate,
        agenda: agenda,
        inventoryUpdate: inventoryUpdate,
      );
    }

    // 写入时间线（副作用如购物入库、库存变更会自动处理）
    final timelineId = addTimelineRecord(TimelineRecord(
      id: '',
      content: t,
      time: now,
      type: _parseType(tags),
      tags: tags,
      matchedAgenda: matchedAgenda,
      sideEffects: recordSideEffects,
    ));

    return {
      'timelineId': timelineId,
      'tags': tags,
      'agendaCreated': agendaCreatedCount,
      'needsConfirm': needsConfirm,
      'feedback': null,
    };
  }

  /// 语音记录直接创建事程（不待确认）
  void submitVoiceRecordDirect(String text) {
    final t = text.trim();
    final now = this.now;
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final parsed = _parseVoiceText(t);
    var tags = parsed['tags'] as List<String>;
    final sideEffects = parsed['sideEffects'] as Map<String, dynamic>?;

    String? matchedAgenda;

    // 事程处理 - 直接创建，不待确认
    if (sideEffects?['agendaList'] != null) {
      final agendaList = sideEffects!['agendaList'] as List<Map<String, dynamic>>;
      for (final ag in agendaList) {
        final agTime = ag['time'] as String? ?? timeStr;
        final agContent = ag['content'] as String? ?? t;
        String finalTime = agTime;
        if (agTime == timeStr) {
          final fromHistory = inferAgendaTimeByContent(agContent);
          if (fromHistory != null) {
            finalTime = fromHistory;
          } else {
            final fromCommon = inferAgendaTimeByCommonSense(agContent);
            if (fromCommon != null) {
              finalTime = fromCommon;
            }
          }
        }
        addAgenda(AgendaItem(
          id: '',
          content: agContent,
          time: finalTime,
          date: todayStr,
          icon: autoDetectIcon(agContent),
          source: AgendaSource.user,
        ));
        matchedAgenda ??= '$finalTime$agContent';
      }
    } else if (sideEffects?['agenda'] != null) {
      final ag = sideEffects!['agenda'] as Map<String, dynamic>;
      final agTime = ag['time'] as String? ?? timeStr;
      final agContent = ag['content'] as String? ?? t;
      String finalTime = agTime;
      if (agTime == timeStr) {
        final fromHistory = inferAgendaTimeByContent(agContent);
        if (fromHistory != null) {
          finalTime = fromHistory;
        } else {
          final fromCommon = inferAgendaTimeByCommonSense(agContent);
          if (fromCommon != null) {
            finalTime = fromCommon;
          }
        }
      }
      addAgenda(AgendaItem(
        id: '',
        content: agContent,
        time: finalTime,
        date: todayStr,
        icon: autoDetectIcon(agContent),
        source: AgendaSource.user,
      ));
      matchedAgenda = '$finalTime$agContent';
    } else {
      for (final agenda in _agendaItems.where((a) =>
        a.date == todayStr &&
        a.status == AgendaStatus.pending
      )) {
        if (_shouldCompleteAgenda(agenda.content, t)) {
          matchedAgenda = '${agenda.time}${agenda.content}';
          completeAgenda(agenda.id);
          break;
        }
      }
    }

    // 构建 sideEffects
    SideEffects? recordSideEffects;
    ShoppingRecord? shoppingRecord;
    ItemUpdate? itemUpdate;
    InventoryUpdate? inventoryUpdate;
    
    if (sideEffects?['shoppingRecord'] != null) {
      final sr = sideEffects!['shoppingRecord'] as ShoppingRecord;
      shoppingRecord = ShoppingRecord(
        id: _genId(),
        store: sr.store,
        items: sr.items,
        time: now,
      );
    }
    if (sideEffects?['itemUpdate'] != null) {
      itemUpdate = sideEffects!['itemUpdate'] as ItemUpdate;
    }
    if (sideEffects?['inventoryUpdate'] != null) {
      inventoryUpdate = sideEffects!['inventoryUpdate'] as InventoryUpdate;
    }
    
    if (shoppingRecord != null || itemUpdate != null || inventoryUpdate != null) {
      recordSideEffects = SideEffects(
        shoppingRecord: shoppingRecord,
        itemUpdate: itemUpdate,
        inventoryUpdate: inventoryUpdate,
      );
    }

    // 写入时间线（副作用如购物入库、库存变更会自动处理）
    addTimelineRecord(TimelineRecord(
      id: '',
      content: t,
      time: now,
      type: _parseType(tags),
      tags: tags,
      matchedAgenda: matchedAgenda,
      sideEffects: recordSideEffects,
    ));

  }

  bool _shouldCompleteAgenda(String agendaContent, String userInput) {
    final lowerInput = userInput.toLowerCase();
    final pendingKeywords = ['记得', '该', '要', '还没', '没有', '没吃', '没做', '等会儿', '晚点', '准备', '提醒', '别忘了'];
    if (pendingKeywords.any(lowerInput.contains)) {
      return false;
    }
    final completedKeywords = ['完成', '吃了', '做了', '已经', '好了', '做完', '吃完', '刚吃', '刚做', '吃过了', '做完了'];
    final hasCompleted = completedKeywords.any(lowerInput.contains);
    if (hasCompleted) {
      final agendaLower = agendaContent.toLowerCase();
      if (agendaLower.contains('吃药') && lowerInput.contains('吃')) return true;
      if (agendaLower.contains('吃饭') && lowerInput.contains('吃')) return true;
      if (agendaLower.contains('运动') && lowerInput.contains('做')) return true;
      if (agendaLower.contains('散步') && lowerInput.contains('走')) return true;
      if (agendaLower.contains('睡觉') && lowerInput.contains('睡')) return true;
      if (agendaLower.contains('起床') && lowerInput.contains('起')) return true;
      if (agendaLower.contains('洗漱') && lowerInput.contains('洗')) return true;
      if (agendaLower.contains('阅读') && lowerInput.contains('读')) return true;
      if (agendaLower.contains('练字') && lowerInput.contains('练')) return true;
      if (agendaLower.contains('喝水') && lowerInput.contains('喝')) return true;
      if (lowerInput.contains('完成')) return true;
    }
    return false;
  }

  Future<bool> shouldCompleteAgendaWithAI(String agendaContent, String userInput) async {
    if (!_llm.isConfigured) {
      return _shouldCompleteAgenda(agendaContent, userInput);
    }
    final result = await _llm.analyzeAgendaCompletion(agendaContent, userInput);
    return result.isCompleted;
  }

  Map<String, dynamic> _parseVoiceText(String text) {
    final t = text.trim();
    final tags = <String>[];
    final sideEffects = <String, dynamic>{};

    // 物品位置 - 支持多种句式：把X放Y、X放Y、放到Y、放在Y
    final itemMatch = RegExp(r'(?:把|将)?\s*([\u4e00-\u9fa5A-Za-z]{1,8}?)\s*(?:放|搁|塞)(?:在|到)?(?:了)?\s*([\u4e00-\u9fa5A-Za-z]+)').firstMatch(t);
    if (itemMatch != null && itemMatch.groupCount >= 2) {
      tags.add('item');
      sideEffects['itemUpdate'] = ItemUpdate(
        name: itemMatch.group(1)!.trim(),
        location: itemMatch.group(2)!.trim().replaceAll(RegExp(r'^(在|到)'), '').replaceAll(RegExp(r'(中|里|上|下|内)$'), ''),
      );
    }

    // 购物
    final buyMatch = RegExp(r'在?(.+?)买了(.+)').firstMatch(t);
    if (buyMatch != null) {
      final store = buyMatch.group(1)!.trim();
      final itemsText = buyMatch.group(2)!.trim();
      final items = <ShoppingItem>[];
      final itemRegex = RegExp(r'([\u4e00-\u9fa5A-Za-z]+?)(\d+(?:\.\d+)?)\s*(斤|公斤|克|千克|瓶|个|盒|袋|包|只|箱|打|份|升|毫升)');
      for (final m in itemRegex.allMatches(itemsText)) {
        items.add(ShoppingItem(
          id: _genId(),
          name: m.group(1)!,
          quantity: int.tryParse(m.group(2)!) ?? 1,
          unit: m.group(3)!,
        ));
      }
      if (items.isEmpty) {
        final names = itemsText.split(RegExp(r'[，,、和]')).where((s) => s.trim().isNotEmpty);
        for (final n in names) {
          items.add(ShoppingItem(id: _genId(), name: n.trim()));
        }
      }
      tags.add('shopping');
      sideEffects['shoppingRecord'] = ShoppingRecord(
        id: '',
        store: store,
        items: items,
        time: now,
      );
    }

    // 行为
    final behaviorKeywords = ['吃', '喝', '睡', '运动', '散步', '跑步', '洗澡', '洗漱', '起床', '吃药', '吃饭', '午饭', '早饭', '晚饭', '喝水'];
    for (final kw in behaviorKeywords) {
      if (t.contains(kw)) {
        if (!tags.contains('behavior')) tags.add('behavior');
        break;
      }
    }

    // 库存消耗识别（吃药、吃了、用了、喝了等）
    // 匹配 "吃了XX药N片"、"喝了XX瓶牛奶"、"用了XX个XX"
    final consumeMatch = RegExp(
      r'(?:吃了|吃|喝了|喝|用了|用|服用|服)([\u4e00-\u9fa5A-Za-z]{1,10}?)(\d+(?:\.\d+)?)?\s*(片|粒|盒|瓶|个|包|袋|支|颗|毫升|克)?'
    ).firstMatch(t);
    if (consumeMatch != null) {
      final itemName = consumeMatch.group(1)!.trim();
      final qtyStr = consumeMatch.group(2);
      final unit = consumeMatch.group(3) ?? '个';
      final qty = qtyStr != null ? double.parse(qtyStr) : 1.0;

      // 判断品类
      String category = '其他';
      if (t.contains('药') || t.contains('降压') || t.contains('安眠') || t.contains('感冒')) {
        category = '药品';
      } else if (t.contains('奶') || t.contains('果') || t.contains('菜') || t.contains('肉') || t.contains('蛋') || t.contains('饭')) {
        category = '食品';
      }

      sideEffects['inventoryUpdate'] = InventoryUpdate(
        name: itemName,
        quantityChange: -qty,
        unit: unit,
        reason: '消耗使用',
      );
    }

    // 事程识别 - 完整的创建/完成意图判断
    final reminderKeywords = ['记得', '别忘了', '提醒我', '要记得', '一定要', '需要', '要做', '得去', '准备'];
    final mustDoKeywords = ['必做', '必须', '一定', '务必'];
    final completedKeywords = ['刚', '刚刚', '已经', '过了', '完了', '吃完了', '喝完了', '吃过了', '做完了'];
    final pastSuffixes = ['完了', '过了', '好了'];
    final futureTimeKeywords = ['明天', '下周', '下次', '以后'];

    int dateOffset = 0;
    if (t.contains('大后天')) {
      dateOffset = 3;
    } else if (t.contains('后天')) {
      dateOffset = 2;
    } else if (t.contains('明天')) {
      dateOffset = 1;
    }

    bool hasCreateSignal = reminderKeywords.any((kw) => t.contains(kw)) || futureTimeKeywords.any((kw) => t.contains(kw));
    bool hasCompleteSignal = completedKeywords.any((kw) => t.contains(kw)) || pastSuffixes.any((kw) => t.endsWith(kw));
    bool hasMustDoSignal = mustDoKeywords.any((kw) => t.contains(kw));

    // 时间对比判断：话语包含具体时间
    final timeInText = RegExp(r'(\d{1,2})[:：](\d{2})|(\d{1,2})点').firstMatch(t);
    if (timeInText != null && !hasCreateSignal) {
      // 尝试解析时间
      int? parsedHour, parsedMin;
      final hhmm = RegExp(r'(\d{1,2})[:：](\d{2})').firstMatch(t);
      final point = RegExp(r'(\d{1,2})点(?:(\d{1,2})分)?').firstMatch(t);
      if (hhmm != null) {
        parsedHour = int.tryParse(hhmm.group(1)!);
        parsedMin = int.tryParse(hhmm.group(2)!);
      } else if (point != null) {
        parsedHour = int.tryParse(point.group(1)!);
        parsedMin = point.group(2) != null ? int.tryParse(point.group(2)!) : 0;
        if ((t.contains('下午') || t.contains('晚上')) && (parsedHour ?? 0) < 12) parsedHour = parsedHour! + 12;
      }
      if (parsedHour != null && parsedMin != null) {
        final now = this.now;
        final textMinutes = parsedHour * 60 + parsedMin;
        final nowMinutes = now.hour * 60 + now.minute;
        final diff = nowMinutes - textMinutes;
        // 只有时间很近（10分钟内）且已有明确完成词时，才强化完成信号
        // 不能仅凭时间判定完成——"下午3点吃药"是创建事程，不是已完成
        if (diff >= 0 && diff <= 10 && hasCompleteSignal) {
          // 很近的过去 + 已有完成词 → 确认完成
          hasCompleteSignal = true;
        } else if (diff < 0) {
          // 时间未到 → 创建信号
          hasCreateSignal = true;
        }
        // diff > 10 或没有完成词时，不自动判定完成/创建，留待后续关键词判断
      }
    }

    // 多事程拆分：包含"还有""然后""，"且包含时间点
    // 注意：移除"和"和"再"作为分隔符，因为"和"是常见连词（如"我和妈妈"），"再"常出现在"再见"等词中
    if (hasCreateSignal && RegExp(r'还有|然后|，').hasMatch(t)) {
      final parts = t.split(RegExp(r'还有|然后|，')).where((s) => s.trim().isNotEmpty).toList();
      if (parts.length >= 2) {
        final agendaList = <Map<String, dynamic>>[];
        for (final part in parts) {
          final p = part.trim();
          if (p.isEmpty) continue;

          // 每个子句独立解析日期偏移
          int partDateOffset = 0;
          if (p.contains('大后天')) {
            partDateOffset = 3;
          } else if (p.contains('后天')) {
            partDateOffset = 2;
          } else if (p.contains('明天')) {
            partDateOffset = 1;
          }

          String? agTime;
          final hhmm = RegExp(r'(\d{1,2})[:：](\d{2})').firstMatch(p);
          final point = RegExp(r'(\d{1,2})点(?:(\d{1,2})分)?').firstMatch(p);
          if (hhmm != null) {
            agTime = '${hhmm.group(1)!.padLeft(2, '0')}:${hhmm.group(2)}';
          } else if (point != null) {
            int hour = int.parse(point.group(1)!);
            int min = point.group(2) != null ? int.parse(point.group(2)!) : 0;
            if ((p.contains('下午') || p.contains('晚上')) && hour < 12) hour += 12;
            agTime = '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
          }

          // 如果子句没有显式时间，尝试通过时间段关键词推断
          agTime ??= inferTimeBySlot(p) ?? inferAgendaTimeByCommonSense(p);

          String content = p
              .replaceAll(RegExp(r'^(记得|别忘了|提醒我|要记得|一定要|需要|要做|得去|准备)[，, ]?'), '')
              .replaceAll(RegExp(r'(大后天|后天|明天|今天)[，, ]?'), '')
              .replaceAll(RegExp(r'(早上|上午|中午|下午|晚上|凌晨|早饭|午饭|晚饭|下班)?\d{1,2}点(?:\d{1,2}分)?[钟]?[，, ]?'), '')
              .replaceAll(RegExp(r'\d{1,2}[:：]\d{2}[，, ]?'), '')
              .replaceAll(RegExp(r'[（(]?必做[）)]?'), '')
              .trim();

          // 如果去除关键词后内容为空（如"明天早饭"），保留原文中的关键信息
          if (content.isEmpty) {
            content = p
                .replaceAll(RegExp(r'^(记得|别忘了|提醒我|要记得|一定要|需要|要做|得去|准备)[，, ]?'), '')
                .replaceAll(RegExp(r'(大后天|后天|明天|今天)[，, ]?'), '')
                .trim();
          }
          if (content.isNotEmpty) {
            final now = this.now;
            agendaList.add({
              'time': agTime ?? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
              'content': content,
              'isMustDo': hasMustDoSignal,
              'date_offset': partDateOffset,
            });
          }
        }
        if (agendaList.length >= 2) {
          sideEffects['agendaList'] = agendaList;
        }
      }
    }

    if (hasCreateSignal && sideEffects['agendaList'] == null) {
      // 提取时间
      String? agTime;
      final hhmmMatch = RegExp(r'(\d{1,2})[:：](\d{2})').firstMatch(t);
      final pointMatch = RegExp(r'(\d{1,2})点(?:(\d{1,2})分)?').firstMatch(t);
      if (hhmmMatch != null) {
        agTime = '${hhmmMatch.group(1)!.padLeft(2, '0')}:${hhmmMatch.group(2)}';
      } else if (pointMatch != null) {
        int hour = int.parse(pointMatch.group(1)!);
        int min = pointMatch.group(2) != null ? int.parse(pointMatch.group(2)!) : 0;
        if ((t.contains('下午') || t.contains('晚上')) && hour < 12) hour += 12;
        agTime = '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
      }

      String content = t
          .replaceAll(RegExp(r'^(记得|别忘了|提醒我|要记得|一定要|需要|要做|得去|准备)[，, ]?'), '')
          .replaceAll(RegExp(r'^(正在|刚|刚刚|已经|在)'), '')
          .replaceAll(RegExp(r'(早上|上午|中午|下午|晚上|凌晨)?\d{1,2}点(?:\d{1,2}分)?[钟]?[，, ]?'), '')
          .replaceAll(RegExp(r'\d{1,2}[:：]\d{2}[，, ]?'), '')
          .replaceAll(RegExp(r'[（(]?必做[）)]?'), '')
          .trim();
      if (content.isEmpty) content = t;

      final now = this.now;
      sideEffects['agenda'] = {
        'time': agTime ?? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'content': content,
        'isMustDo': hasMustDoSignal,
        'date_offset': dateOffset,
      };
    }

    // 默认行为判断：包含时间点+行为关键词，但无明确完成信号 → 默认创建事程
    // 如"下午3点吃药"没有"记得"也没有"吃了"，应理解为"要吃药"而非"已吃药"
    final agendaBehaviorKeywords = ['吃药', '吃饭', '喝水', '运动', '散步', '睡觉', '起床', '洗漱', '阅读', '练字'];
    final hasTimeInText = RegExp(r'(\d{1,2})[:：](\d{2})|(\d{1,2})点').hasMatch(t);
    final hasBehaviorKeyword = agendaBehaviorKeywords.any((kw) => t.contains(kw));
    if (!hasCreateSignal && !hasCompleteSignal && hasTimeInText && hasBehaviorKeyword) {
      hasCreateSignal = true;
    }

    // 完成信号识别：尝试匹配已有事程
    if (hasCompleteSignal && sideEffects['agenda'] == null && sideEffects['agendaList'] == null) {
      sideEffects['completeMatch'] = true;
    }

    // 事件
    final eventKeywords = ['回家', '出门', '下班', '到', '去', '拿', '取', '送', '接', '回', '来', '走'];
    if (eventKeywords.any((kw) => t.contains(kw)) || tags.isEmpty) {
      if (!tags.contains('event')) tags.add('event');
    }

    return {'tags': tags, 'sideEffects': sideEffects, 'hasCompleteSignal': hasCompleteSignal};
  }

  TimelineType _parseType(List<String> tags) {
    if (tags.contains('shopping')) return TimelineType.shopping;
    if (tags.contains('item')) return TimelineType.item;
    if (tags.contains('behavior')) return TimelineType.behavior;
    return TimelineType.event;
  }

  // ===== 时间推断 =====
  String? inferAgendaTimeByContent(String content) {
    final fromSlot = inferTimeBySlot(content);
    if (fromSlot != null) return fromSlot;

    final behaviorMatch = RegExp(r'(吃药|吃饭|早饭|午饭|晚饭|运动|散步|喝水|睡觉|起床|洗漱|上班|下班)').firstMatch(content);
    String keyword = behaviorMatch?.group(1) ?? (content.isNotEmpty ? content.substring(0, content.length.clamp(0, 2)) : '');
    final matched = _timelineRecords.where((r) => r.content.contains(keyword)).toList();
    if (matched.isEmpty) return null;
    int totalMinutes = 0;
    for (final r in matched) {
      totalMinutes += r.time.hour * 60 + r.time.minute;
    }
    final avg = (totalMinutes / matched.length).round();
    return '${(avg ~/ 60).toString().padLeft(2, '0')}:${(avg % 60).toString().padLeft(2, '0')}';
  }

  String? inferAgendaTimeByCommonSense(String content) {
    if (RegExp(r'早饭|早餐|早上吃').hasMatch(content)) return '07:30';
    if (RegExp(r'午饭|午餐|吃中饭|中午吃').hasMatch(content)) return '12:00';
    if (RegExp(r'晚饭|晚餐|吃晚饭|晚上吃').hasMatch(content)) return '18:00';
    if (RegExp(r'夜宵|宵夜|半夜').hasMatch(content)) return '23:00';
    if (RegExp(r'吃药|服药').hasMatch(content)) return '08:00';
    if (RegExp(r'起床').hasMatch(content)) return '07:00';
    if (RegExp(r'睡觉|休息|就寝').hasMatch(content)) return '22:00';
    if (RegExp(r'运动|散步|跑步|锻炼').hasMatch(content)) return '18:30';
    if (RegExp(r'洗漱|洗脸|刷牙').hasMatch(content)) return '07:15';
    if (RegExp(r'下班').hasMatch(content)) return '18:00';
    if (RegExp(r'上班|出门').hasMatch(content)) return '08:30';
    if (RegExp(r'午休|午睡').hasMatch(content)) return '12:30';
    if (RegExp(r'下午茶|喝茶').hasMatch(content)) return '15:00';
    return null;
  }

  /// 判断LLM返回的时间是否需要被常识推断覆盖
  bool _shouldInferTime(String agTime, String agContent) {
    final parts = agTime.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]);
    if (hour == null) return false;

    // 早饭相关内容应该在早上（5-10点）
    if (RegExp(r'早饭|早餐|早上吃').hasMatch(agContent) && (hour < 5 || hour > 10)) return true;
    // 午饭相关内容应该在中午（10-14点）
    if (RegExp(r'午饭|午餐|吃中饭|中午吃').hasMatch(agContent) && (hour < 10 || hour > 14)) return true;
    // 晚饭相关内容应该在晚上（16-21点）
    if (RegExp(r'晚饭|晚餐|吃晚饭|晚上吃').hasMatch(agContent) && (hour < 16 || hour > 21)) return true;
    // 下班相关内容应该在傍晚（16-20点）
    if (RegExp(r'下班').hasMatch(agContent) && (hour < 16 || hour > 20)) return true;
    // 睡觉相关内容应该在晚上（19-24点）
    if (RegExp(r'睡觉|休息|就寝').hasMatch(agContent) && (hour < 19 || hour > 24)) return true;
    // 起床相关内容应该在早上（4-9点）
    if (RegExp(r'起床').hasMatch(agContent) && (hour < 4 || hour > 9)) return true;
    // 运动相关内容应该在傍晚（16-20点）
    if (RegExp(r'运动|散步|跑步|锻炼').hasMatch(agContent) && (hour < 16 || hour > 20)) return true;

    return false;
  }

  String autoDetectIcon(String content) {
    if (RegExp(r'药').hasMatch(content)) return '💊';
    if (RegExp(r'饭|餐|食').hasMatch(content)) return '🍚';
    if (RegExp(r'水|喝').hasMatch(content)) return '💧';
    if (RegExp(r'运动|散步|跑步|锻炼|走').hasMatch(content)) return '🏃';
    if (RegExp(r'睡|休息|午休').hasMatch(content)) return '🛏';
    if (RegExp(r'买|购|超市').hasMatch(content)) return '🛒';
    return '📋';
  }

  // ===== 晚下班检测与确认 =====

  /// 检测用户当天是否晚下班
  /// 判断逻辑：用户记录了"下班"相关行为，且实际时间比历史平均下班时间晚超过30分钟
  /// 返回 LateOffWorkResult，包含是否晚下班、延迟分钟数、受影响的待办事程列表
  LateOffWorkResult? checkLateOffWork() {
    final now = this.now;
    // todayStr comes from the getter
    final currentTimeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 获取历史平均下班时间
    final offWorkTimes = _timePatterns['下班'];
    if (offWorkTimes == null || offWorkTimes.isEmpty) return null;

    final avgTime = _averageTime(offWorkTimes);
    final avgParts = avgTime.split(':');
    final avgMinutes = int.parse(avgParts[0]) * 60 + int.parse(avgParts[1]);
    final currentMinutes = now.hour * 60 + now.minute;

    // 计算延迟分钟数，处理跨天边界（凌晨0-4点下班视为前一天的延续）
    int delayMinutes = currentMinutes - avgMinutes;
    // 如果当前时间在凌晨0-4点，且平均下班时间在17-23点，视为跨天延续
    if (now.hour <= 4 && avgMinutes >= 17 * 60) {
      delayMinutes = (24 * 60 - avgMinutes) + currentMinutes;
    }
    if (delayMinutes < 30) return null;

    // 查找今天受影响的待办事程（下班后的外出/就餐类事程）
    final affectedAgendas = _agendaItems.where((a) {
      if (a.date != todayStr) return false;
      if (a.status != AgendaStatus.pending) return false;
      // 事程时间在下班时间之后
      final aParts = a.time.split(':');
      if (aParts.length != 2) return false;
      final aMinutes = int.parse(aParts[0]) * 60 + int.parse(aParts[1]);
      if (aMinutes < avgMinutes) return false;
      // 包含外出/就餐关键词
      return RegExp(r'吃|饭|餐|搓|烤|聚|约|外出|出去|逛街|看电影|散步').hasMatch(a.content);
    }).toList();

    if (affectedAgendas.isEmpty) return null;

    return LateOffWorkResult(
      isLate: true,
      avgOffWorkTime: avgTime,
      currentTime: currentTimeStr,
      delayMinutes: delayMinutes,
      affectedAgendas: affectedAgendas,
    );
  }

  /// 确认晚下班后是否仍执行事程
  /// confirmed=true: 保留事程，更新提醒时间
  /// confirmed=false: 将事程标记为已放弃
  void confirmLateOffWorkAgenda(String agendaId, bool confirmed) {
    final agenda = _agendaItems.where((a) => a.id == agendaId).firstOrNull;
    if (agenda == null) return;

    if (confirmed) {
      // 保留事程，更新时间为当前时间+30分钟
      final now = this.now;
      final newTime = now.add(const Duration(minutes: 30));
      final newTimeStr = '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
      // 如果跨天了，更新日期
      String newDate = agenda.date;
      if (newTime.day != now.day) {
        newDate = MockData.dateOffset(1);
      }
      _agendaItems = _agendaItems.map((a) =>
        a.id == agendaId ? a.copyWith(time: newTimeStr, date: newDate, remainingTime: '已推迟到$newTimeStr') : a
      ).toList();
    } else {
      // 标记为已放弃
      _agendaItems = _agendaItems.map((a) =>
        a.id == agendaId ? a.copyWith(status: AgendaStatus.skipped, remainingTime: '晚下班已放弃') : a
      ).toList();
      // 策略3：记录失败
      _recordAgendaFailure(agenda, suppressNotify: true);
    }
    notifyListeners();
  }

  // ===== 动态统计计算 =====
  /// 根据时间范围筛选记录
  /// range: 'week' / 'month' / 'all'
  List<TimelineRecord> _filterByRange(String range) {
    final now = this.now;
    if (range == 'all') return _timelineRecords;
    if (range == 'today') {
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      return _timelineRecords.where((r) => r.date == todayStr).toList();
    }
    final days = range == 'week' ? 7 : 30;
    final cutoff = now.subtract(Duration(days: days));
    return _timelineRecords.where((r) => r.time.isAfter(cutoff)).toList();
  }

  /// 计算完成率
  int computeCompletionRate(String range) {
    final records = _filterByRange(range);
    if (records.isEmpty) return 0;
    final matched = records.where((r) =>
      r.matchedAgenda != null && r.matchedAgenda!.isNotEmpty).length;
    return ((matched / records.length) * 100).round().clamp(0, 100);
  }

  /// 计算行为热力图数据，返回日期标签和热力值
  /// 返回: { labels: ['7/5', '7/6', ...], data: [[1,0,...], ...] }
  Map<String, dynamic> computeHeatmapData(String range, {DateTime? customStart, DateTime? customEnd}) {
    final behaviors = ['吃药', '吃饭', '运动', '喝水'];
    final now = this.now;
    int dayCount;
    DateTime startDate;

    switch (range) {
      case 'today':
        dayCount = 1;
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        startDate = weekStart;
        dayCount = now.weekday;
        break;
      case 'month':
        final firstDay = DateTime(now.year, now.month, 1);
        startDate = firstDay;
        dayCount = now.day;
        break;
      case 'custom':
        if (customStart != null && customEnd != null) {
          dayCount = customEnd.difference(customStart).inDays + 1;
          startDate = customStart;
        } else {
          dayCount = 7;
          startDate = now.subtract(const Duration(days: 6));
        }
        break;
      default:
        dayCount = 7;
        startDate = now.subtract(const Duration(days: 6));
    }

    // 限制最大天数，避免UI溢出
    if (dayCount > 31) dayCount = 31;

    final labels = <String>[];
    final data = List.generate(behaviors.length, (_) => List.filled(dayCount, 0));

    for (int d = 0; d < dayCount; d++) {
      final date = startDate.add(Duration(days: d));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      labels.add('${date.month}/${date.day}');

      for (int b = 0; b < behaviors.length; b++) {
        final hit = _timelineRecords.any((r) =>
          r.date == dateStr && r.content.contains(behaviors[b]));
        data[b][d] = hit ? 1 : 0;
      }
    }

    return {
      'labels': labels,
      'data': data,
      'behaviors': behaviors,
      'dayCount': dayCount,
    };
  }

  /// 计算7天行为热力图 [4行为][7天] - 保留旧接口兼容
  List<List<int>> computeHeatmap(String range) {
    final result = List.generate(4, (_) => List.filled(7, 0));
    final behaviors = ['吃药', '吃饭', '运动', '睡觉'];
    final now = this.now;

    for (int b = 0; b < behaviors.length; b++) {
      for (int d = 0; d < 7; d++) {
        final date = now.subtract(Duration(days: 6 - d));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final hit = _timelineRecords.any((r) =>
          r.date == dateStr && r.content.contains(behaviors[b]));
        result[b][d] = hit ? 1 : 0;
      }
    }
    return result;
  }

  /// 计算行为排行：最规律 + 最易遗漏
  ({List<NameCount> topRegular, List<NameCount> topMissed}) computeBehaviorRanking(String range) {
    final records = _filterByRange(range);

    // 提取常见行为关键词
    final behaviorKeywords = ['吃药', '吃饭', '早饭', '午饭', '晚饭', '运动', '散步', '喝水', '睡觉', '起床', '洗漱'];
    final counts = <String, int>{};

    for (final kw in behaviorKeywords) {
      final hit = records.where((r) => r.content.contains(kw)).length;
      counts[kw] = hit;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final regular = sorted.where((e) => e.value > 0).take(5)
      .map((e) => NameCount(name: e.key, count: e.value))
      .toList();

    final missed = sorted.where((e) => e.value == 0).take(3)
      .map((e) => NameCount(name: e.key, count: 0))
      .toList();

    // 如果没有遗漏的，补充一些
    if (missed.isEmpty && regular.length < behaviorKeywords.length) {
      for (final kw in behaviorKeywords) {
        if (!regular.any((r) => r.name == kw)) {
          missed.add(NameCount(name: kw, count: 0));
          if (missed.length >= 3) break;
        }
      }
    }

    return (topRegular: regular, topMissed: missed);
  }

  /// 综合统计
  StatsData computeStats(String range, {AgendaLevel? level}) {
    final ranking = computeBehaviorRanking(range);
    return StatsData(
      completionRate: computeAgendaCompletionRate(range, level: level),
      heatmap: computeHeatmap(range),
      topRegular: ranking.topRegular,
      topMissed: ranking.topMissed,
    );
  }

  /// 自定义日期范围统计
  StatsData computeStatsForDateRange(DateTime start, DateTime end, {AgendaLevel? level}) {
    final records = _timelineRecords.where((r) =>
      r.time.isAfter(start.subtract(const Duration(seconds: 1))) &&
      r.time.isBefore(end.add(const Duration(days: 1)))
    ).toList();

    final matched = records.where((r) =>
      r.matchedAgenda != null && r.matchedAgenda!.isNotEmpty).length;
    final rate = records.isEmpty ? 0 : ((matched / records.length) * 100).round().clamp(0, 100);

    // 行为排行
    final behaviorKeywords = ['吃药', '吃饭', '早饭', '午饭', '晚饭', '运动', '散步', '喝水', '睡觉', '起床', '洗漱'];
    final counts = <String, int>{};
    for (final kw in behaviorKeywords) {
      counts[kw] = records.where((r) => r.content.contains(kw)).length;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final regular = sorted.where((e) => e.value > 0).take(5).map((e) => NameCount(name: e.key, count: e.value)).toList();
    final missed = sorted.where((e) => e.value == 0).take(3).map((e) => NameCount(name: e.key, count: 0)).toList();

    final agendaRate = computeAgendaCompletionRateForDateRange(start, end, level: level);

    return StatsData(
      completionRate: agendaRate,
      heatmap: computeHeatmap('week'),
      topRegular: regular,
      topMissed: missed,
    );
  }

  int computeAgendaCompletionRate(String range, {AgendaLevel? level}) {
    final now = this.now;
    DateTime startDate;
    DateTime endDate = now;

    switch (range) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    }

    final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    var agendas = _agendaItems.where((a) =>
      a.date.compareTo(startStr) >= 0 && a.date.compareTo(endStr) <= 0
    );

    if (level != null) {
      agendas = agendas.where((a) => a.level == level);
    }

    final total = agendas.length;
    if (total == 0) return 0;
    final completed = agendas.where((a) => a.status == AgendaStatus.completed).length;
    return ((completed / total) * 100).round().clamp(0, 100);
  }

  int computeAgendaCompletionRateForDateRange(DateTime start, DateTime end, {AgendaLevel? level}) {
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

    var agendas = _agendaItems.where((a) =>
      a.date.compareTo(startStr) >= 0 && a.date.compareTo(endStr) <= 0
    );

    if (level != null) {
      agendas = agendas.where((a) => a.level == level);
    }

    final total = agendas.length;
    if (total == 0) return 0;
    final completed = agendas.where((a) => a.status == AgendaStatus.completed).length;
    return ((completed / total) * 100).round().clamp(0, 100);
  }

  /// 获取事程完成排行（基于事程数据，不是时间线）
  List<Map<String, dynamic>> getAgendaRanking(String range, {DateTime? customStart, DateTime? customEnd, String? sortBy = 'score'}) {
    final now = this.now;
    DateTime startDate;
    DateTime endDate = now;

    switch (range) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'custom':
        if (customStart != null && customEnd != null) {
          startDate = customStart;
          endDate = customEnd;
        } else {
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        }
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    }

    final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    // 按内容分组统计
    final stats = <String, Map<String, dynamic>>{};
    for (final a in _agendaItems) {
      if (a.date.compareTo(startStr) < 0 || a.date.compareTo(endStr) > 0) continue;
      final key = a.content;
      if (!stats.containsKey(key)) {
        stats[key] = {
          'total': 0,
          'completed': 0,
          'expired': 0,
          'skipped': 0,
          'streak': 0,
          'level': a.level,
        };
      }
      stats[key]!['total'] = (stats[key]!['total'] as int) + 1;
      if (a.status == AgendaStatus.completed) {
        stats[key]!['completed'] = (stats[key]!['completed'] as int) + 1;
        if (a.streak > (stats[key]!['streak'] as int)) {
          stats[key]!['streak'] = a.streak;
        }
      } else if (a.status == AgendaStatus.expired) {
        stats[key]!['expired'] = (stats[key]!['expired'] as int) + 1;
      } else if (a.status == AgendaStatus.skipped) {
        stats[key]!['skipped'] = (stats[key]!['skipped'] as int) + 1;
      }
    }

    // 转换为列表并按综合评分排序
    final result = stats.entries.map((e) {
      final total = e.value['total'] as int;
      final completed = e.value['completed'] as int;
      final streak = e.value['streak'] as int;
      final rate = total > 0 ? ((completed / total) * 100).round() : 0;
      final level = e.value['level'] as AgendaLevel;

      // 综合评分：完成率(40%) + 连续天数(30%) + 总数(20%) + 级别权重(10%)
      final levelWeight = _getLevelWeight(level);
      final score = rate * 0.4 + streak * 2 * 0.3 + total * 0.2 + levelWeight * 0.1;

      return {
        'content': e.key,
        'total': total,
        'completed': completed,
        'expired': e.value['expired'] as int,
        'skipped': e.value['skipped'] as int,
        'streak': streak,
        'rate': rate,
        'level': level,
        'score': score,
      };
    }).toList();

    switch (sortBy) {
      case 'rate':
        result.sort((a, b) => (b['rate'] as int).compareTo(a['rate'] as int));
        break;
      case 'streak':
        result.sort((a, b) => (b['streak'] as int).compareTo(a['streak'] as int));
        break;
      case 'total':
        result.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
        break;
      case 'score':
      default:
        result.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    }
    return result;
  }

  int _getLevelWeight(AgendaLevel level) {
    switch (level) {
      case AgendaLevel.mustDoLong:
        return 100;
      case AgendaLevel.mustDoShort:
        return 80;
      case AgendaLevel.important:
        return 50;
      case AgendaLevel.normal:
        return 20;
    }
  }

  int _statusToInt(AgendaStatus status) {
    switch (status) {
      case AgendaStatus.pending: return 0;
      case AgendaStatus.completed: return 1;
      case AgendaStatus.skipped: return 2;
      case AgendaStatus.postponed: return 3;
      case AgendaStatus.expired: return 4;
    }
  }

  /// 聚合状态：-1=无数据, 0=待进行, 1=已完成, 2=已跳过, 3=已延后, 4=已过期
  int _aggregateStatus(List<AgendaItem> items) {
    if (items.isEmpty) return -1;
    if (items.any((a) => a.status == AgendaStatus.expired)) return 4;
    if (items.any((a) => a.status == AgendaStatus.skipped)) return 2;
    if (items.any((a) => a.status == AgendaStatus.postponed)) return 3;
    if (items.any((a) => a.status == AgendaStatus.pending)) return 0;
    return 1;
  }

  /// 获取事程热力图数据（按级别分组，每天的聚合状态）
  Map<String, dynamic> getAgendaHeatmap(String range, {DateTime? customStart, DateTime? customEnd, AgendaLevel? level}) {
    final now = this.now;
    int dayCount;
    DateTime startDate;

    switch (range) {
      case 'today':
        dayCount = 1;
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        startDate = weekStart;
        dayCount = 7;
        break;
      case 'month':
        final firstDay = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        startDate = firstDay;
        dayCount = lastDay.day;
        break;
      case 'custom':
        if (customStart != null && customEnd != null) {
          dayCount = customEnd.difference(customStart).inDays + 1;
          startDate = customStart;
        } else {
          dayCount = 7;
          startDate = now.subtract(const Duration(days: 6));
        }
        break;
      default:
        dayCount = 7;
        startDate = now.subtract(const Duration(days: 6));
    }

    if (range != 'custom' && dayCount > 31) {
      startDate = DateTime(now.year, now.month, 1);
      dayCount = DateTime(now.year, now.month + 1, 0).day;
    }

    // 日期标签
    final labels = <String>[];
    for (int d = 0; d < dayCount; d++) {
      final date = startDate.add(Duration(days: d));
      labels.add('${date.month}/${date.day}');
    }

    // 按级别分组（短期必做/长期必做/重要/普通）
    final allLevels = [
      AgendaLevel.mustDoShort,
      AgendaLevel.mustDoLong,
      AgendaLevel.important,
      AgendaLevel.normal,
    ];

    final List<List<int>> heatmapData = [];
    final List<AgendaLevel> agendaLevels = [];
    final List<int> levelCounts = [];

    for (final lv in allLevels) {
      if (level != null && lv != level) continue;

      final levelAgendas = _agendaItems.where((a) => a.level == lv).toList();
      if (levelAgendas.isEmpty) continue;

      agendaLevels.add(lv);
      levelCounts.add(levelAgendas.length);

      final row = List.filled(dayCount, -1);
      for (int d = 0; d < dayCount; d++) {
        final date = startDate.add(Duration(days: d));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final dayItems = levelAgendas.where((a) => a.date == dateStr).toList();
        row[d] = _aggregateStatus(dayItems);
      }
      heatmapData.add(row);
    }

    return {
      'labels': labels,
      'data': heatmapData,
      'levels': agendaLevels,
      'counts': levelCounts,
      'dayCount': dayCount,
    };
  }

  /// 获取完成趋势数据（每天各状态数量，用于堆叠柱状图）
  List<Map<String, dynamic>> getCompletionTrend(String range, {DateTime? customStart, DateTime? customEnd, AgendaLevel? level}) {
    final now = this.now;
    int dayCount;
    DateTime startDate;

    switch (range) {
      case 'today':
        dayCount = 1;
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        startDate = weekStart;
        dayCount = 7;
        break;
      case 'month':
        final firstDay = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        startDate = firstDay;
        dayCount = lastDay.day;
        break;
      case 'custom':
        if (customStart != null && customEnd != null) {
          dayCount = customEnd.difference(customStart).inDays + 1;
          startDate = customStart;
        } else {
          dayCount = 7;
          startDate = now.subtract(const Duration(days: 6));
        }
        break;
      default:
        dayCount = 7;
        startDate = now.subtract(const Duration(days: 6));
    }

    if (range != 'custom' && dayCount > 31) {
      startDate = DateTime(now.year, now.month, 1);
      dayCount = DateTime(now.year, now.month + 1, 0).day;
    }

    final result = <Map<String, dynamic>>[];
    final dayLabels = ['一', '二', '三', '四', '五', '六', '日'];

    for (int d = 0; d < dayCount; d++) {
      final date = startDate.add(Duration(days: d));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      var dayAgendas = _agendaItems.where((a) => a.date == dateStr);
      if (level != null) {
        dayAgendas = dayAgendas.where((a) => a.level == level);
      }
      final total = dayAgendas.length;
      final completed = dayAgendas.where((a) => a.status == AgendaStatus.completed).length;
      // 细分完成类型：按时完成 / 延期完成 / 跳过后完成
      final completedOnTime = dayAgendas.where((a) =>
        a.status == AgendaStatus.completed && !a.wasPostponed && !a.wasSkipped).length;
      final completedPostponed = dayAgendas.where((a) =>
        a.status == AgendaStatus.completed && a.wasPostponed).length;
      final completedAfterSkip = dayAgendas.where((a) =>
        a.status == AgendaStatus.completed && a.wasSkipped).length;
      final skipped = dayAgendas.where((a) => a.status == AgendaStatus.skipped).length;
      final postponed = dayAgendas.where((a) => a.status == AgendaStatus.postponed).length;
      final expired = dayAgendas.where((a) => a.status == AgendaStatus.expired).length;
      final pending = dayAgendas.where((a) => a.status == AgendaStatus.pending).length;

      result.add({
        'date': dateStr,
        'label': dayCount <= 7 ? '周${dayLabels[date.weekday - 1]}' : '${date.month}/${date.day}',
        'total': total,
        'completed': completed,
        'completedOnTime': completedOnTime,
        'completedPostponed': completedPostponed,
        'completedAfterSkip': completedAfterSkip,
        'skipped': skipped,
        'postponed': postponed,
        'expired': expired,
        'pending': pending,
      });
    }

    return result;
  }

  /// 习惯链推荐：基于已有事程推荐相关习惯
  List<Map<String, dynamic>> getHabitChainSuggestions() {
    final suggestions = <Map<String, dynamic>>[];
    final existingContents = _agendaItems.map((a) => a.content).toSet();

    // 习惯链规则：如果有A，推荐B
    final chains = <Map<String, dynamic>>[
      {
        'trigger': '起床',
        'suggestions': [
          {'content': '喝一杯温水', 'time': '06:30', 'level': AgendaLevel.normal, 'reason': '起床后喝水有助于唤醒身体'},
          {'content': '洗漱', 'time': '06:35', 'level': AgendaLevel.normal, 'reason': '晨起洗漱开启新一天'},
          {'content': '晨练', 'time': '06:45', 'level': AgendaLevel.normal, 'reason': '早晨运动提高代谢'},
        ],
      },
      {
        'trigger': '吃药',
        'suggestions': [
          {'content': '喝一杯水', 'time': '08:00', 'level': AgendaLevel.normal, 'reason': '服药时多喝水有助吸收'},
          {'content': '测血压', 'time': '08:10', 'level': AgendaLevel.important, 'reason': '服药后监测血压效果'},
        ],
      },
      {
        'trigger': '早饭',
        'suggestions': [
          {'content': '吃药', 'time': '07:30', 'level': AgendaLevel.mustDoShort, 'reason': '饭后服药减少肠胃刺激'},
          {'content': '散步', 'time': '08:00', 'level': AgendaLevel.normal, 'reason': '饭后散步促进消化'},
        ],
      },
      {
        'trigger': '午饭',
        'suggestions': [
          {'content': '午休', 'time': '12:30', 'level': AgendaLevel.normal, 'reason': '午后小憩恢复精力'},
          {'content': '散步', 'time': '13:00', 'level': AgendaLevel.normal, 'reason': '饭后散步助消化'},
        ],
      },
      {
        'trigger': '晚饭',
        'suggestions': [
          {'content': '散步', 'time': '18:30', 'level': AgendaLevel.normal, 'reason': '晚饭后散步有助睡眠'},
          {'content': '吃药', 'time': '19:00', 'level': AgendaLevel.mustDoShort, 'reason': '晚饭后服用晚间药物'},
        ],
      },
      {
        'trigger': '睡觉',
        'suggestions': [
          {'content': '洗漱', 'time': '21:00', 'level': AgendaLevel.normal, 'reason': '睡前洗漱保持清洁'},
          {'content': '泡脚', 'time': '21:30', 'level': AgendaLevel.normal, 'reason': '睡前泡脚促进睡眠'},
          {'content': '听轻音乐', 'time': '21:45', 'level': AgendaLevel.normal, 'reason': '舒缓音乐助眠'},
        ],
      },
      {
        'trigger': '运动',
        'suggestions': [
          {'content': '喝温水', 'time': '16:30', 'level': AgendaLevel.normal, 'reason': '运动后补充水分'},
          {'content': '休息', 'time': '16:45', 'level': AgendaLevel.normal, 'reason': '运动后适当放松'},
        ],
      },
    ];

    for (final chain in chains) {
      final trigger = chain['trigger'] as String;
      if (existingContents.any((c) => c.contains(trigger))) {
        final recs = chain['suggestions'] as List<Map<String, dynamic>>;
        for (final rec in recs) {
          final content = rec['content'] as String;
          if (!existingContents.any((c) => c.contains(content) || content.contains(c))) {
            suggestions.add({
              'trigger': trigger,
              'content': content,
              'time': rec['time'],
              'level': rec['level'],
              'reason': rec['reason'],
            });
          }
        }
      }
    }

    // 如果没有任何事程，推荐基础习惯
    if (suggestions.isEmpty && existingContents.isEmpty) {
      suggestions.addAll([
        {'trigger': '基础', 'content': '起床', 'time': '06:30', 'level': AgendaLevel.normal, 'reason': '规律作息是健康基础'},
        {'trigger': '基础', 'content': '早饭', 'time': '07:30', 'level': AgendaLevel.mustDoShort, 'reason': '早餐是一天中最重要的一餐'},
        {'trigger': '基础', 'content': '喝水', 'time': '10:00', 'level': AgendaLevel.normal, 'reason': '每天喝够8杯水'},
        {'trigger': '基础', 'content': '午饭', 'time': '12:00', 'level': AgendaLevel.mustDoShort, 'reason': '午餐补充能量'},
        {'trigger': '基础', 'content': '散步', 'time': '16:00', 'level': AgendaLevel.normal, 'reason': '下午运动保持活力'},
        {'trigger': '基础', 'content': '晚饭', 'time': '18:00', 'level': AgendaLevel.mustDoShort, 'reason': '晚餐不宜过饱'},
        {'trigger': '基础', 'content': '睡觉', 'time': '22:00', 'level': AgendaLevel.normal, 'reason': '保证7-8小时睡眠'},
      ]);
    }

    return suggestions.take(6).toList();
  }

  /// 最佳时间推荐：分析用户实际完成时间，推荐最佳事程时间
  String? suggestBestTime(String agendaContent) {
    // 找相关的时间线记录，分析实际完成时间
    final matchedRecords = _timelineRecords.where((r) =>
      r.content.contains(agendaContent) || agendaContent.contains(r.content)
    ).toList();

    if (matchedRecords.isEmpty) return null;

    // 统计每个小时的完成次数
    final hourCounts = <int, int>{};
    for (final r in matchedRecords) {
      final h = r.time.hour;
      hourCounts[h] = (hourCounts[h] ?? 0) + 1;
    }

    if (hourCounts.isEmpty) return null;

    // 找最频繁的小时
    final sorted = hourCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final bestHour = sorted.first.key;
    return '${bestHour.toString().padLeft(2, '0')}:00';
  }

  /// 事程按级别分组排行
  Map<String, List<Map<String, dynamic>>> getAgendaRankingByLevel(String range, {DateTime? customStart, DateTime? customEnd, String? sortBy}) {
    final ranking = getAgendaRanking(range, customStart: customStart, customEnd: customEnd, sortBy: sortBy);

    final mustDoLong = <Map<String, dynamic>>[];
    final mustDoShort = <Map<String, dynamic>>[];
    final important = <Map<String, dynamic>>[];
    final normal = <Map<String, dynamic>>[];

    for (final item in ranking) {
      final content = item['content'] as String;
      final sample = _agendaItems.firstWhere(
        (a) => a.content == content,
        orElse: () => AgendaItem(id: '', content: content, time: '', date: ''),
      );

      switch (sample.level) {
        case AgendaLevel.mustDoLong:
          mustDoLong.add(item);
          break;
        case AgendaLevel.mustDoShort:
          mustDoShort.add(item);
          break;
        case AgendaLevel.important:
          important.add(item);
          break;
        case AgendaLevel.normal:
          normal.add(item);
          break;
      }
    }

    return {
      'mustDoLong': mustDoLong,
      'mustDoShort': mustDoShort,
      'important': important,
      'normal': normal,
    };
  }

  /// 获取事程完成统计（提前/按时/延期/未进行）
  Map<String, int> getAgendaCompletionStats(String range) {
    final now = this.now;
    final days = range == 'today' ? 1 : (range == 'week' ? 7 : 30);
    final cutoff = now.subtract(Duration(days: days));
    final dateStr = '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';

    final agendas = _agendaItems.where((a) => a.date.compareTo(dateStr) >= 0).toList();

    int completed = agendas.where((a) => a.status == AgendaStatus.completed).length;
    int completedOnTime = agendas.where((a) =>
      a.status == AgendaStatus.completed && !a.wasPostponed && !a.wasSkipped).length;
    int completedPostponed = agendas.where((a) =>
      a.status == AgendaStatus.completed && a.wasPostponed).length;
    int completedAfterSkip = agendas.where((a) =>
      a.status == AgendaStatus.completed && a.wasSkipped).length;
    int expired = agendas.where((a) => a.status == AgendaStatus.expired).length;
    int skipped = agendas.where((a) => a.status == AgendaStatus.skipped).length;
    int postponed = agendas.where((a) => a.status == AgendaStatus.postponed).length;
    int pending = agendas.where((a) => a.status == AgendaStatus.pending).length;

    return {
      'completed': completed,
      'completedOnTime': completedOnTime,
      'completedPostponed': completedPostponed,
      'completedAfterSkip': completedAfterSkip,
      'expired': expired,
      'skipped': skipped,
      'postponed': postponed,
      'pending': pending,
      'total': agendas.length,
    };
  }

  /// 获取物品使用习惯分析
  Map<String, dynamic> getInventoryHabits() {
    final items = _inventory;
    final now = this.now;

    // 即将过期物品
    final expiringSoon = items.where((i) {
      if (i.expireDate == null) return false;
      final days = i.expireDate!.difference(now).inDays;
      return days <= 7 && days >= 0;
    }).toList();

    // 已过期物品
    final expired = items.where((i) {
      if (i.expireDate == null) return false;
      return i.expireDate!.isBefore(now);
    }).toList();

    // 药品
    final medicines = items.where((i) => i.category == '药品').toList();
    // 食品
    final foods = items.where((i) => i.category == '食品').toList();
    // 日用品
    final daily = items.where((i) => i.category == '日用品').toList();

    // 低库存物品（数量 <= 1）
    final lowStock = items.where((i) => i.quantity <= 1 && i.quantity > 0).toList();

    return {
      'total': items.length,
      'expiringSoon': expiringSoon,
      'expired': expired,
      'medicines': medicines,
      'foods': foods,
      'daily': daily,
      'lowStock': lowStock,
    };
  }

  /// 获取时间线行为分析
  Map<String, dynamic> getTimelineAnalysis(String range) {
    final records = _filterByRange(range);
    final now = this.now;

    // 按类型统计
    int behaviorCount = records.where((r) => r.type == TimelineType.behavior).length;
    int itemCount = records.where((r) => r.type == TimelineType.item).length;
    int shoppingCount = records.where((r) => r.type == TimelineType.shopping).length;
    int eventCount = records.where((r) => r.type == TimelineType.event).length;

    // 按时段统计
    int morning = records.where((r) => r.time.hour >= 6 && r.time.hour < 12).length;
    int afternoon = records.where((r) => r.time.hour >= 12 && r.time.hour < 18).length;
    int evening = records.where((r) => r.time.hour >= 18 && r.time.hour < 23).length;
    int night = records.where((r) => r.time.hour >= 23 || r.time.hour < 6).length;

    // 购买习惯分析
    final shoppingRecords = records.where((r) => r.type == TimelineType.shopping).toList();
    final purchaseItems = <String>[];
    for (final r in shoppingRecords) {
      if (r.sideEffects?.shoppingRecord != null) {
        for (final item in r.sideEffects!.shoppingRecord!.items) {
          purchaseItems.add(item.name);
        }
      }
    }
    // 常买物品 Top 3
    final purchaseCounts = <String, int>{};
    for (final name in purchaseItems) {
      purchaseCounts[name] = (purchaseCounts[name] ?? 0) + 1;
    }
    final topPurchased = purchaseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topPurchasedList = topPurchased.take(3).map((e) => NameCount(name: e.key, count: e.value)).toList();

    return {
      'total': records.length,
      'behaviorCount': behaviorCount,
      'itemCount': itemCount,
      'shoppingCount': shoppingCount,
      'eventCount': eventCount,
      'morning': morning,
      'afternoon': afternoon,
      'evening': evening,
      'night': night,
      'topPurchased': topPurchasedList,
    };
  }

  // ===== 问一问 AI 问答引擎 =====

  /// 问题类型描述
  final Map<QuestionType, String> _questionTypeDesc = {
    QuestionType.itemLocation: '物品位置查询',
    QuestionType.inventory: '库存查询',
    QuestionType.plan: '计划制定',
    QuestionType.habit: '习惯养成',
    QuestionType.timeline: '时间线查询',
    QuestionType.agenda: '事程/待办查询',
    QuestionType.stats: '行为统计',
    QuestionType.shopping: '购物记录',
    QuestionType.commonSense: '常识问题',
    QuestionType.template: '计划模板',
    QuestionType.badge: '徽章查询',
    QuestionType.stockProjection: '物资能用多久',
    QuestionType.habitAdvice: '习惯分析建议',
    QuestionType.learningAdvice: '学习建议',
    QuestionType.cycleReasoning: '周期推理',
    QuestionType.comparison: '对比分析',
    QuestionType.patternDiscovery: '寻找规律',
    QuestionType.complexQuery: '复杂问题拆解',
    QuestionType.faq: '常规问答',
    QuestionType.unknown: '未知类型',
  };

  /// 问题类型关键词映射
  final Map<QuestionType, List<String>> _typeKeywords = {
    QuestionType.itemLocation: ['在哪', '哪里', '位置', '放哪', '钥匙', '遥控器', '手机', '钱包'],
    QuestionType.inventory: ['还有多少', '剩余', '库存', '数量', '够不够'],
    QuestionType.plan: ['计划', '安排', '制定', '创建'],
    QuestionType.habit: ['习惯', '养成', '坚持'],
    QuestionType.timeline: ['做了什么', '发生了什么', '记录', '那天'],
    QuestionType.agenda: ['事程', '待办', '提醒', '要做', '过期', '未进行', '已完成'],
    QuestionType.stats: ['几次', '多少次', '统计', '频率', '完成率'],
    QuestionType.shopping: ['买了', '购物', '消费'],
    QuestionType.commonSense: ['正常值', '标准', '多少', '什么是'],
    QuestionType.template: ['模板', '有哪些计划'],
    QuestionType.badge: ['徽章', '成就', '连续'],
    QuestionType.stockProjection: ['能用多久', '还能吃几天', '用完'],
    QuestionType.habitAdvice: ['分析', '建议', '优化'],
    QuestionType.learningAdvice: ['学习', '想学', '培养'],
    QuestionType.cycleReasoning: ['到期', '过期', '换季', '生日', '纪念日'],
    QuestionType.comparison: ['比', '对比', '相比', '差异'],
    QuestionType.patternDiscovery: ['规律', '几点', '周末', '工作日'],
    QuestionType.complexQuery: ['回忆', '回顾', '总结', '汇总', '和', '以及'],
    QuestionType.faq: ['血压', '健康', '天气', '出行'],
  };

  /// 判断问题类型
  QuestionType _detectQuestionType(String q) {
    for (final entry in _typeKeywords.entries) {
      if (entry.value.any((kw) => q.contains(kw))) {
        return entry.key;
      }
    }
    return QuestionType.unknown;
  }

  /// 判断问题类型（支持多类型）
  List<QuestionType> _detectQuestionTypes(String q) {
    final types = <QuestionType>[];
    for (final entry in _typeKeywords.entries) {
      if (entry.value.any((kw) => q.contains(kw))) {
        types.add(entry.key);
      }
    }
    if (types.isEmpty) types.add(QuestionType.unknown);
    return types;
  }

  /// 针对问题类型检索数据
  Map<String, dynamic> _retrieveDataByType(QuestionType type) {
    final now = this.now;
    final ymd = (DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final todayKey = ymd(now);

    switch (type) {
      case QuestionType.itemLocation:
        return {
          'type': 'itemLocation',
          'data': items.map((i) => {'name': i.name, 'location': i.location}).toList(),
        };

      case QuestionType.inventory:
        return {
          'type': 'inventory',
          'data': _inventory.map((i) => {'name': i.name, 'quantity': i.quantity, 'unit': i.unit}).toList(),
        };

      case QuestionType.agenda:
        return {
          'type': 'agenda',
          'today': _agendaItems.where((a) => a.date == todayKey).map((a) => {
                'time': a.time,
                'content': a.content,
                'status': a.status == AgendaStatus.completed ? '已完成' : a.status == AgendaStatus.expired ? '已过期' : '待进行',
                'isMustDo': a.isMustDo,
              }).toList(),
          'pending': _agendaItems.where((a) => a.status == AgendaStatus.pending).map((a) => {
                'date': a.date,
                'time': a.time,
                'content': a.content,
              }).toList(),
          'expired': _agendaItems.where((a) => a.status == AgendaStatus.expired).map((a) => {
                'date': a.date,
                'time': a.time,
                'content': a.content,
              }).toList(),
        };

      case QuestionType.timeline:
        final todayTimeline = _timelineRecords.where((r) => r.date == todayKey).toList();
        return {
          'type': 'timeline',
          'today': todayTimeline.map((r) => {
                'time': r.timeStr,
                'content': r.content,
                'matchedAgenda': r.matchedAgenda,
              }).toList(),
          'recent7Days': _timelineRecords
              .where((r) => now.difference(r.time).inDays < 7)
              .map((r) => {'date': r.date, 'time': r.timeStr, 'content': r.content})
              .toList(),
        };

      case QuestionType.stats:
        return {
          'type': 'stats',
          'agendaCompleted': _agendaItems.where((a) => a.status == AgendaStatus.completed).length,
          'agendaTotal': _agendaItems.length,
          'timelineCount': _timelineRecords.length,
          'todayTimelineCount': _timelineRecords.where((r) => r.date == todayKey).length,
        };

      case QuestionType.shopping:
        return {
          'type': 'shopping',
          'records': shoppingRecords.map((s) => {
                'date': '${s.time.year}-${s.time.month.toString().padLeft(2, '0')}-${s.time.day.toString().padLeft(2, '0')}',
                'store': s.store,
                'items': s.items.map((i) => '${i.name}${i.quantity}${i.unit}').join('、'),
              }).toList(),
        };

      case QuestionType.habit:
        return {
          'type': 'habit',
          'streaks': {'运动': getHabitStreak('运动'), '吃药': getHabitStreak('吃药')},
          'badges': _earnedBadges.length,
          'totalBadges': allBadges.length,
        };

      case QuestionType.stockProjection:
        return {
          'type': 'stockProjection',
          'inventory': _inventory.map((i) => {
                'name': i.name,
                'quantity': i.quantity,
                'unit': i.unit,
                'logs': i.logs.length,
              }).toList(),
        };

      case QuestionType.badge:
        return {
          'type': 'badge',
          'earned': _earnedBadges.length,
          'total': allBadges.length,
          'details': allBadges.map((b) => {
                'name': b.name,
                'icon': b.icon,
                'requiredDays': b.requiredDays,
                'earned': _earnedBadges.contains(b.id),
              }).toList(),
        };

      case QuestionType.cycleReasoning:
        return {
          'type': 'cycleReasoning',
          'currentMonth': now.month,
          'currentSeason': now.month >= 3 && now.month <= 5 ? '春季' : now.month >= 6 && now.month <= 8 ? '夏季' : now.month >= 9 && now.month <= 11 ? '秋季' : '冬季',
        };

      case QuestionType.comparison:
        return {
          'type': 'comparison',
          'thisMonth': now.month,
          'lastMonth': now.month - 1,
          'thisMonthRecords': _timelineRecords.where((r) => r.time.month == now.month).length,
          'lastMonthRecords': _timelineRecords.where((r) => r.time.month == now.month - 1).length,
        };

      case QuestionType.patternDiscovery:
        return {
          'type': 'patternDiscovery',
          'timeline': _timelineRecords.map((r) => {'hour': r.time.hour, 'content': r.content}).toList(),
        };

      default:
        return {'type': 'unknown', 'data': {}};
    }
  }

  /// 复杂问题拆解器
  /// 将多意图问题拆分成多个子查询
  List<Map<String, String>> _parseComplexQuery(String q) {
    final subQueries = <Map<String, String>>[];

    // "帮我回忆去年体检结果和后续安排" → 拆成两个子查询
    if (q.contains('回忆') || q.contains('回顾')) {
      if (q.contains('体检') || q.contains('检查')) {
        subQueries.add({'type': 'health', 'query': '体检结果'});
      }
      if (q.contains('安排') || q.contains('计划')) {
        subQueries.add({'type': 'plan', 'query': '后续安排'});
      }
    }

    // "查询某天哪些事程过期，哪些未进行"
    if (q.contains('事程') || q.contains('待办')) {
      if (q.contains('过期')) {
        subQueries.add({'type': 'agenda', 'query': '过期事程'});
      }
      if (q.contains('未进行') || q.contains('待进行') || q.contains('未完成')) {
        subQueries.add({'type': 'agenda', 'query': '待进行事程'});
      }
      if (q.contains('已完成')) {
        subQueries.add({'type': 'agenda', 'query': '已完成事程'});
      }
    }

    // "今天做了什么，有什么事程"
    if (q.contains('做了什么') || q.contains('记录')) {
      subQueries.add({'type': 'timeline', 'query': '今天时间线'});
    }

    // "和"、"以及"连接的多意图
    if (q.contains('和') || q.contains('以及')) {
      final parts = q.split(RegExp(r'和|以及'));
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isEmpty) continue;
        final type = _detectQuestionType(trimmed);
        subQueries.add({'type': _questionTypeDesc[type]!, 'query': trimmed});
      }
    }

    // 如果没有拆解出子查询，返回原始问题
    if (subQueries.isEmpty) {
      subQueries.add({'type': 'direct', 'query': q});
    }

    return subQueries;
  }

  /// 多路检索融合层
  /// 将多个检索结果合并、排序、去重
  String _mergeSearchResults(List<Map<String, String>> subQueries) {
    final results = <String>[];

    for (final sq in subQueries) {
      final queryType = sq['type'];
      final query = sq['query'];

      if (queryType == 'agenda') {
        if (query!.contains('过期')) {
          final expired = _agendaItems.where((a) => a.status == AgendaStatus.expired).toList();
          if (expired.isEmpty) {
            results.add('• 没有过期的事程');
          } else {
            results.add('📋 过期事程（${expired.length}项）：');
            results.addAll(expired.map((a) => '  - ${a.date} ${a.time} ${a.content}'));
          }
        } else if (query.contains('待进行') || query.contains('未完成') || query.contains('未进行')) {
          final pending = _agendaItems.where((a) => a.status == AgendaStatus.pending).toList();
          if (pending.isEmpty) {
            results.add('• 没有待进行的事程，都已完成了！');
          } else {
            results.add('📋 待进行事程（${pending.length}项）：');
            results.addAll(pending.map((a) => '  - ${a.date} ${a.time} ${a.content}${a.isMustDo ? "（必做）" : ""}'));
          }
        } else if (query.contains('已完成')) {
          final completed = _agendaItems.where((a) => a.status == AgendaStatus.completed).toList();
          results.add('✅ 已完成事程（${completed.length}项）：');
          results.addAll(completed.map((a) => '  - ${a.date} ${a.time} ${a.content}'));
        }
      } else if (queryType == 'timeline') {
        final todayTimeline = _timelineRecords.where((r) => r.date == todayStr).toList();
        if (todayTimeline.isEmpty) {
          results.add('• 今天还没有时间线记录');
        } else {
          results.add('📝 今日时间线（${todayTimeline.length}条）：');
          results.addAll(todayTimeline.map((r) => '  - ${r.timeStr} ${r.content}'));
        }
      } else if (queryType == 'health') {
        results.add('🏥 关于体检：\n  • 您可以告诉我具体体检指标，我帮您查询正常值\n  • 例如："血压正常值是多少"');
      } else if (queryType == 'plan') {
        results.add('📅 后续安排建议：\n  • 根据体检结果调整饮食和作息\n  • 可以设置定期复查提醒');
      } else {
        // 直接调用规则匹配回答子查询
        final answer = answerQuestion(query!);
        if (!answer.startsWith('我暂时无法回答')) {
          results.add(answer);
        }
      }
    }

    // 如果只有一个结果，直接返回
    if (results.length == 1) return results.first;

    // 合并多个结果
    final merged = StringBuffer();
    merged.writeln('根据您的问题，我为您整理了以下信息：');
    merged.writeln();
    for (int i = 0; i < results.length; i++) {
      merged.writeln('${i + 1}. ${results[i]}');
      if (i < results.length - 1) merged.writeln();
    }
    merged.writeln();
    merged.writeln('💡 如果您想了解更多细节，可以继续问我。');

    return merged.toString();
  }

  /// 构建用户数据上下文，注入到 LLM 以支持个性化问答
  String _buildUserContext() {
    final buffer = StringBuffer();
    final now = this.now;
    final ymd = (DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final todayKey = ymd(now);

    // 当前时间
    buffer.writeln('【当前时间】${ymd(now)} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
    buffer.writeln();

    // 物品位置
    if (items.isNotEmpty) {
      buffer.writeln('【物品位置记录】');
      for (final item in items) {
        final loc = item.location.isNotEmpty ? item.location : '未知';
        buffer.writeln('- ${item.name}：${loc}');
      }
      buffer.writeln();
    }

    // 库存（物品数量）
    if (_inventory.isNotEmpty) {
      buffer.writeln('【物品库存（数量）】');
      for (final inv in _inventory) {
        final qtyStr = inv.quantity % 1 == 0
            ? inv.quantity.toInt().toString()
            : inv.quantity.toStringAsFixed(1);
        final lowWarn = inv.quantity <= 1 ? '（不足）' : '';
        final lastChange = inv.logs.isNotEmpty
            ? '，最近变更：${inv.logs.first.change > 0 ? '+' : ''}${inv.logs.first.change.toStringAsFixed(inv.logs.first.change % 1 == 0 ? 0 : 1)}（${inv.logs.first.reason}）'
            : '';
        buffer.writeln('- ${inv.name}：剩余$qtyStr${inv.unit}$lowWarn$lastChange');
      }
      buffer.writeln();
    }

    // 今日事程
    final todayAgendas = _agendaItems.where((a) => a.date == todayKey).toList();
    if (todayAgendas.isNotEmpty) {
      buffer.writeln('【今日事程】');
      for (final a in todayAgendas) {
        final status = a.status == AgendaStatus.completed
            ? '已完成'
            : a.status == AgendaStatus.expired
                ? '已过期'
                : '待进行';
        buffer.writeln('- ${a.time} ${a.content}（$status）');
      }
      buffer.writeln();
    }

    // 今日时间线
    final todayTimeline =
        _timelineRecords.where((r) => r.date == todayKey).toList()
          ..sort((a, b) => b.time.compareTo(a.time));
    if (todayTimeline.isNotEmpty) {
      buffer.writeln('【今日时间线（最近10条）】');
      for (int i = 0; i < todayTimeline.length && i < 10; i++) {
        final r = todayTimeline[i];
        final t = '${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}';
        buffer.writeln('- $t ${r.content}');
      }
      buffer.writeln();
    }

    // 最近 7 天时间线（用于回顾）
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentTimeline = _timelineRecords
        .where((r) => r.time.isAfter(sevenDaysAgo) && r.date != todayKey)
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    if (recentTimeline.isNotEmpty) {
      buffer.writeln('【最近7天时间线（最多20条）】');
      for (int i = 0; i < recentTimeline.length && i < 20; i++) {
        final r = recentTimeline[i];
        final t = '${r.date} ${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}';
        buffer.writeln('- $t ${r.content}');
      }
      buffer.writeln();
    }

    // 购买记录（用于消费习惯分析）
    if (shoppingRecords.isNotEmpty) {
      final recent = shoppingRecords.toList()
        ..sort((a, b) => b.time.compareTo(a.time));
      buffer.writeln('【购买记录（最近10条）】');
      for (int i = 0; i < recent.length && i < 10; i++) {
        final s = recent[i];
        final items = s.items.map((e) => '${e.name}${e.quantity}${e.unit}').join('、');
        buffer.writeln('- ${ymd(s.time)} ${s.store}：$items');
      }
      buffer.writeln();
    }

    // 待办事程（提醒）
    final pending = _agendaItems.where((a) => a.status == AgendaStatus.pending).toList();
    if (pending.isNotEmpty) {
      buffer.writeln('【待办/过期事程（最多10条）】');
      for (int i = 0; i < pending.length && i < 10; i++) {
        final a = pending[i];
        buffer.writeln('- ${a.date} ${a.time} ${a.content}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// 异步问答 - 优先 LLM，失败降级到规则匹配
  ///
  /// [history] 为多轮对话上下文（可选），最近的对话先放在前面或后面均可，
  /// 函数会按时间顺序使用最后 [historyLimit] 条
  Future<String> answerQuestionAsync(String question, {List<ChatMessage>? history, int historyLimit = 6}) async {
    final q = question.trim();

    // 先走规则匹配（快速响应本地数据查询）
    final ruleAnswer = answerQuestion(q, history: history);
    final isFallback = ruleAnswer.startsWith('我暂时无法回答');

    // LLM 未启用：直接返回规则结果
    if (!_llm.isConfigured) {
      return ruleAnswer;
    }

    final messages = _buildLlmMessages(q, ruleAnswer, isFallback, history, historyLimit);

    try {
      final reply = await _llm.chat(messages);
      return reply.trim().isNotEmpty ? reply : ruleAnswer;
    } catch (_) {
      // LLM 失败，降级到规则匹配
      return ruleAnswer;
    }
  }

  /// 流式异步问答 - 返回 stream，每个事件是当前已生成的完整文本
  ///
  /// [history] 为多轮对话上下文
  Stream<String> answerQuestionStream(String question, {List<ChatMessage>? history, int historyLimit = 6}) {
    final q = question.trim();
    final controller = StreamController<String>();

    () async {
      // LLM 未启用：直接返回规则匹配结果
      if (!_llm.isConfigured) {
        final ruleAnswer = answerQuestion(q, history: history);
        controller.add(ruleAnswer);
        controller.close();
        return;
      }

      final ruleAnswer = answerQuestion(q, history: history);
      final isFallback = ruleAnswer.startsWith('我暂时无法回答');
      final messages = _buildLlmMessages(q, ruleAnswer, isFallback, history, historyLimit);

      try {
        bool hasData = false;
        await for (final text in _llm.chatStream(messages)) {
          hasData = true;
          controller.add(text);
        }
        if (!hasData) {
          controller.add(ruleAnswer);
        }
        controller.close();
      } catch (_) {
        // LLM 失败，降级到规则匹配
        controller.add(ruleAnswer);
        controller.close();
      }
    }();

    return controller.stream;
  }

  /// 构建发给 LLM 的 messages 列表，包含多轮对话记忆 + 用户数据上下文
  List<ChatMsg> _buildLlmMessages(
    String question,
    String ruleAnswer,
    bool isFallback,
    List<ChatMessage>? history,
    int historyLimit,
  ) {
    final userContext = _buildUserContext();
    final ruleHint = isFallback
        ? '请直接根据用户数据和你的知识回答。'
        : '以下是系统根据规则查询到的参考答案（请参考但可补充完善）：\n$ruleAnswer\n\n';

    final userPrompt = '''# 当前问题
$question

# 用户数据上下文
$userContext

# 回答要求
$ruleHint
- 多轮对话时，请结合上文历史连贯回答
- 使用简洁、口语化的中文，避免专业术语
- 语气亲切、温暖
- 涉及医疗建议时，提醒请咨询医生
- 数据中找不到的请直接说"我暂时没找到这个记录"''';

    final messages = <ChatMsg>[];

    // 多轮对话历史
    if (history != null && history.isNotEmpty) {
      // 取最近 historyLimit 条
      final start = history.length > historyLimit ? history.length - historyLimit : 0;
      final recent = history.sublist(start);
      for (final m in recent) {
        if (m.role == 'user' || m.role == 'assistant') {
          messages.add(ChatMsg(m.role, m.content));
        }
      }
    }

    messages.add(ChatMsg('user', userPrompt));
    return messages;
  }

  // 上下文记忆：最近讨论的日期、物品、主题
  String? _lastMentionedDate;
  String? _lastMentionedDateDesc;
  String? _lastMentionedItem;
  String? _lastMentionedTopic;

  /// 上下文增强：解析日期指代（上个月、上周等）和指代消解（那个、它等）
  String _resolveContext(String question, List<ChatMessage>? history) {
    var q = question.trim();

    // 从历史记录中提取上下文
    if (history != null && history.isNotEmpty) {
      for (int i = history.length - 1; i >= 0; i--) {
        final msg = history[i];
        if (msg.role != 'user') continue;

        // 提取最近提到的日期
        if (_lastMentionedDate == null) {
          final dateInfo = _extractDateFromText(msg.content);
          if (dateInfo != null) {
            _lastMentionedDate = dateInfo['date'];
            _lastMentionedDateDesc = dateInfo['desc'];
          }
        }

        // 提取最近提到的物品
        if (_lastMentionedItem == null) {
          final itemMatch = RegExp(r'(钥匙|遥控器|手机|钱包|眼镜|药|护照|身份证|水杯|雨伞|外套)').firstMatch(msg.content);
          if (itemMatch != null) {
            _lastMentionedItem = itemMatch.group(1);
          }
        }

        if (_lastMentionedDate != null && _lastMentionedItem != null) break;
      }
    }

    // 解析"上个月" → 具体月份
    if (q.contains('上个月')) {
      final now = this.now;
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      _lastMentionedDate = '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';
      _lastMentionedDateDesc = '上个月';
      q = q.replaceAll('上个月', '${lastMonth.month}月');
    }

    // 解析"这个月"
    if (q.contains('这个月') || q.contains('本月')) {
      final now = this.now;
      _lastMentionedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      _lastMentionedDateDesc = '这个月';
      q = q.replaceAll(RegExp(r'这个月|本月'), '${now.month}月');
    }

    // 指代消解："那个"、"它"、"那个东西"
    if ((q.contains('那个') || q.contains('它') || q.contains('那个东西') || q.contains('那个物品')) && _lastMentionedItem != null) {
      q = q.replaceAll(RegExp(r'那个(东西|物品)?'), _lastMentionedItem!);
      q = q.replaceAll('它', _lastMentionedItem!);
    }

    // 日期指代："那天"、"那天的"
    if ((q.contains('那天') || q.contains('那天的')) && _lastMentionedDateDesc != null) {
      q = q.replaceAll(RegExp(r'那天的?'), _lastMentionedDateDesc!);
    }

    return q;
  }

  /// 从文本中提取日期信息
  Map<String, String>? _extractDateFromText(String text) {
    if (text.contains('今天') || text.contains('今日')) {
      return {'date': todayStr, 'desc': '今天'};
    }
    if (text.contains('昨天') || text.contains('昨日')) {
      return {'date': MockData.dateOffset(-1), 'desc': '昨天'};
    }
    if (text.contains('前天')) {
      return {'date': MockData.dateOffset(-2), 'desc': '前天'};
    }
    if (text.contains('上周')) {
      return {'date': MockData.dateOffset(-7), 'desc': '上周'};
    }
    return null;
  }

  /// 检测问题是否模糊，需要澄清
  String? _checkClarificationNeeded(String q) {
    // 只有"那个东西在哪"、"它在哪"等太模糊的问题
    if ((q.contains('那个') || q.contains('它') || q.contains('那个东西')) &&
        (q.contains('在哪') || q.contains('哪里') || q.contains('放哪'))) {
      final itemNames = items.map((e) => e.name).toList();
      if (itemNames.length >= 2) {
        return '您是想问${itemNames.take(2).join('还是')}的位置？';
      }
    }

    // "上次去医院" 模糊
    if (q.contains('上次') && (q.contains('医院') || q.contains('体检'))) {
      return '您是指最近一次体检，还是某一次特定的就诊？';
    }

    // "那个药" 模糊
    if (q.contains('那个药') && _inventory.length >= 2) {
      final meds = _inventory.where((i) => i.category == '药品' || i.name.contains('药')).toList();
      if (meds.length >= 2) {
        return '您是想问${meds.take(2).map((e) => e.name).join('还是')}？';
      }
    }

    return null;
  }

  /// 生成关联推荐
  List<String> _generateRelatedRecommendations(String q, String answer) {
    final recs = <String>[];

    // 回答体检/健康后，推荐血压趋势
    if (q.contains('体检') || q.contains('血压') || q.contains('健康')) {
      recs.add('查看血压变化趋势');
    }

    // 回答物品位置后，提醒出门记得带
    if (q.contains('在哪') || q.contains('位置') || q.contains('放哪')) {
      recs.add('出门前记得带好');
    }

    // 回答运动后，建议今天也运动
    if (q.contains('运动') || q.contains('散步') || q.contains('锻炼')) {
      recs.add('今天也运动一下吧');
    }

    // 回答事程后，推荐查看今日事程
    if (q.contains('事程') || q.contains('计划') || q.contains('待办')) {
      recs.add('查看今日事程');
    }

    return recs.take(2).toList();
  }

  /// 综合问答：基于时间线记录回答 + 常识性问题回答
  String answerQuestion(String question, {List<ChatMessage>? history}) {
    // 1. 上下文解析
    final q = _resolveContext(question.trim(), history);

    // 2. 模糊澄清检测
    final clarification = _checkClarificationNeeded(q);
    if (clarification != null) {
      return clarification;
    }

    // ============ 统一检索层 ============
    // 3. 问题类型判断
    final types = _detectQuestionTypes(q);

    // 4. 复杂问题检测与拆解
    if (types.contains(QuestionType.complexQuery) || types.length >= 2) {
      final subQueries = _parseComplexQuery(q);
      if (subQueries.length > 1) {
        return _mergeSearchResults(subQueries);
      }
    }

    // 5. 针对问题类型检索数据（给后续规则匹配提供数据支持）
    for (final type in types) {
      final data = _retrieveDataByType(type);
      if (data['type'] != 'unknown') {
        break;
      }
    }

    // ============ 规则匹配层 ============
    // === 第一类：物品位置查询 ===
    final itemAnswer = _answerItemLocation(q);
    if (itemAnswer != null) return _buildAnswerWithRecommendations(q, itemAnswer);

    // === 第二类：库存/剩余数量查询 ===
    final inventoryAnswer = _answerInventoryQuery(q);
    if (inventoryAnswer != null) return _buildAnswerWithRecommendations(q, inventoryAnswer);

    // === 第三类：计划制定助手 ===
    final planAnswer = _answerPlanQuery(q);
    if (planAnswer != null) return _buildAnswerWithRecommendations(q, planAnswer);

    // === 第四类：习惯养成助手 ===
    final habitAnswer = _answerHabitQuery(q);
    if (habitAnswer != null) return _buildAnswerWithRecommendations(q, habitAnswer);

    // === 第五类：时间线记录查询（某天做了什么） ===
    final timelineAnswer = _answerTimelineQuery(q);
    if (timelineAnswer != null) return _buildAnswerWithRecommendations(q, timelineAnswer);

    // === 第六类：事程/待办查询 ===
    final agendaAnswer = _answerAgendaQuery(q);
    if (agendaAnswer != null) return _buildAnswerWithRecommendations(q, agendaAnswer);

    // === 第七类：行为统计查询 ===
    final statsAnswer = _answerStatsQuery(q);
    if (statsAnswer != null) return _buildAnswerWithRecommendations(q, statsAnswer);

    // === 第八类：购物记录查询 ===
    final shoppingAnswer = _answerShoppingQuery(q);
    if (shoppingAnswer != null) return _buildAnswerWithRecommendations(q, shoppingAnswer);

    // === 第九类：常识性问题 ===
    final commonSenseAnswer = _answerCommonSense(q);
    if (commonSenseAnswer != null) return _buildAnswerWithRecommendations(q, commonSenseAnswer);

    // === 第十类：计划模板库 ===
    final templateAnswer = _answerTemplateQuery(q);
    if (templateAnswer != null) return _buildAnswerWithRecommendations(q, templateAnswer);

    // === 第十一类：徽章查询 ===
    final badgeAnswer = _answerBadgeQuery(q);
    if (badgeAnswer != null) return _buildAnswerWithRecommendations(q, badgeAnswer);

    // === 第十二类：物资能用多久 + 用完提醒 ===
    final stockProjectionAnswer = _answerStockProjection(q);
    if (stockProjectionAnswer != null) return _buildAnswerWithRecommendations(q, stockProjectionAnswer);

    // === 第十三类：行为习惯分析 + 事程建议 ===
    final habitAdviceAnswer = _answerHabitAdvice(q);
    if (habitAdviceAnswer != null) return _buildAnswerWithRecommendations(q, habitAdviceAnswer);

    // === 第十四类：学习/新技能事程设计建议 ===
    final learningAdviceAnswer = _answerLearningAdvice(q);
    if (learningAdviceAnswer != null) return _buildAnswerWithRecommendations(q, learningAdviceAnswer);

    // === 第十五类：周期推理（驾照到期、换季等） ===
    final cycleAnswer = _answerCycleReasoning(q);
    if (cycleAnswer != null) return _buildAnswerWithRecommendations(q, cycleAnswer);

    // === 第十六类：对比分析 ===
    final compareAnswer = _answerComparison(q);
    if (compareAnswer != null) return _buildAnswerWithRecommendations(q, compareAnswer);

    // === 第十七类：寻找规律 ===
    final patternAnswer = _answerPatternDiscovery(q);
    if (patternAnswer != null) return _buildAnswerWithRecommendations(q, patternAnswer);

    // === 第十八类：复杂拆解（多意图） ===
    final complexAnswer = _answerComplexQuery(q);
    if (complexAnswer != null) return _buildAnswerWithRecommendations(q, complexAnswer);

    // === 第十九类：常规问答（健康、生活、出行、天气等） ===
    final faqAnswer = _answerFaq(q);
    if (faqAnswer != null) return _buildAnswerWithRecommendations(q, faqAnswer);

    // === 兜底 ===
    return '我暂时无法回答这个问题，您可以尝试问我：\n'
        '• 物品放在哪里（如"钥匙在哪"）\n'
        '• 还有多少（如"药还剩多少"）\n'
        '• 计划制定（如"计划明天去医院"）\n'
        '• 习惯养成（如"养成运动习惯"）\n'
        '• 计划模板（如"有哪些计划模板"）\n'
        '• 我的徽章（如"我有几个徽章"）\n'
        '• 某天做了什么（如"昨天做了什么"）\n'
        '• 今日事程（如"今天有什么事程"）\n'
        '• 常识问题（如"血压正常值"）';
  }

  /// 构建带关联推荐的回答
  String _buildAnswerWithRecommendations(String question, String answer) {
    final recs = _generateRelatedRecommendations(question, answer);
    if (recs.isEmpty) return answer;

    final result = StringBuffer(answer);
    result.writeln();
    result.writeln();
    result.writeln('💡 相关推荐：');
    for (final rec in recs) {
      result.writeln('• $rec');
    }
    return result.toString();
  }

  /// 计划模板库查询
  String? _answerTemplateQuery(String q) {
    if (!q.contains('模板') && !q.contains('有哪些计划') && !q.contains('计划模板')) return null;

    final templates = planTemplates;
    String result = '📋 计划模板库（共${templates.length}个）：\n\n';
    for (int i = 0; i < templates.length; i++) {
      final t = templates[i];
      result += '${i+1}. ${t.icon} ${t.name}（${t.category}）\n';
      result += '   预估：${t.estimatedDuration}\n';
    }
    result += '\n您可以说"使用医院复诊模板"来快速创建计划。';
    return result;
  }

  /// 徽章查询
  String? _answerBadgeQuery(String q) {
    if (!q.contains('徽章') && !q.contains('成就') && !q.contains('连续')) return null;

    if (q.contains('运动') || q.contains('散步')) {
      final streak = getHabitStreak('运动');
      final nextBadge = allBadges.where((b) => b.requiredDays > streak).toList()
        ..sort((a, b) => a.requiredDays.compareTo(b.requiredDays));
      String result = '🏃 您已连续运动 $streak 天。\n\n';
      if (nextBadge.isNotEmpty) {
        result += '下一个徽章：${nextBadge.first.icon} ${nextBadge.first.name}（需连续${nextBadge.first.requiredDays}天）\n';
        result += '还需坚持 ${nextBadge.first.requiredDays - streak} 天';
      } else {
        result += '您已获得所有运动徽章！太了不起了！';
      }
      return result;
    }

    if (q.contains('吃药')) {
      final streak = getHabitStreak('吃药');
      return '💊 您已连续按时服药 $streak 天。继续保持！';
    }

    // 全部徽章
    String result = '🏆 我的徽章：\n\n';
    for (final badge in allBadges) {
      final earned = _earnedBadges.contains(badge.id);
      result += '${earned ? badge.icon : "🔒"} ${badge.name}（连续${badge.requiredDays}天）${earned ? " ✓" : ""}\n';
    }
    result += '\n已获得 ${_earnedBadges.length}/${allBadges.length} 个徽章';
    return result;
  }

  /// 物资能用多久 + 设置"用完提醒"
  String? _answerStockProjection(String q) {
    // 关键词：能用多久 / 还能吃几天 / 用完 / 多久吃完 / 还能撑几天
    final trigger = q.contains('能用多久') || q.contains('还能用多久') ||
        q.contains('还能吃几天') || q.contains('多久吃完') || q.contains('还能撑几天') ||
        q.contains('用完') || q.contains('够用') || q.contains('还能用') ||
        (q.contains('还剩') && q.contains('天'));
    if (!trigger) return null;

    if (_inventory.isEmpty) {
      return '您目前没有库存记录。您可以先通过首页"记录现在"或语音告诉我买了什么，我会自动入库。';
    }

    final ymd = (DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final now = this.now;
    final results = <String>[];

    for (final item in _inventory) {
      if (q.contains(item.name) || q == '能用多久' || q.contains('所有') || q.contains('全部') || q.contains('哪些')) {
        // 统计最近 30 天的消耗
        final monthLogs = item.logs.where((l) => l.change < 0 && now.difference(l.time).inDays < 30).toList();
        double? dailyAvg;
        int? daysLeft;
        if (monthLogs.isNotEmpty) {
          final totalUsed = monthLogs.fold<double>(0, (sum, l) => sum + l.change.abs());
          final daysUsed = monthLogs.map((l) => l.time.day).toSet().length;
          dailyAvg = totalUsed / daysUsed;
          daysLeft = dailyAvg > 0 ? (item.quantity / dailyAvg).floor() : null;
        }
        String line = '• ${item.name}：剩余 ${_formatQty(item.quantity)} ${item.unit}';
        if (dailyAvg != null && daysLeft != null) {
          final willRunOut = now.add(Duration(days: daysLeft));
          line += '\n  每天约用 ${_formatQty(dailyAvg)} ${item.unit}，预计还能用 $daysLeft 天（约到 ${ymd(willRunOut)}）';
        } else {
          line += '\n  暂无消耗数据，建议坚持几天记录后我能给您更准确的预测';
        }
        results.add(line);
      }
    }

    if (results.isEmpty) {
      // 没匹配到具体物品，给出总体建议
      return '目前我能识别的物资有：${_inventory.map((i) => i.name).join("、")}。\n请告诉我您想查询哪一项，比如"鸡蛋能用多久"。';
    }

    final wantReminder = q.contains('提醒') || q.contains('用完前') || q.contains('快用完') || q.contains('设置');
    if (wantReminder) {
      // 为命中的第一项设置"用完前 2 天"提醒
      for (final item in _inventory) {
        if (results.any((r) => r.contains('• ${item.name}'))) {
          final monthLogs = item.logs.where((l) => l.change < 0 && now.difference(l.time).inDays < 30).toList();
          if (monthLogs.isNotEmpty) {
            final totalUsed = monthLogs.fold<double>(0, (sum, l) => sum + l.change.abs());
            final daysUsed = monthLogs.map((l) => l.time.day).toSet().length;
            final dailyAvg = totalUsed / daysUsed;
            final daysLeft = (item.quantity / dailyAvg).floor();
            final remindDate = now.add(Duration(days: daysLeft - 2 > 0 ? daysLeft - 2 : 1));
            final remindTime = '${remindDate.hour.toString().padLeft(2, '0')}:00';
            final remindDateStr = ymd(remindDate);
            addAgenda(AgendaItem(
              id: '',
              content: '提醒购买${item.name}',
              time: remindTime,
              date: remindDateStr,
              icon: 'shopping_cart',
              source: AgendaSource.ai,
            ));
            results.add('\n✅ 已为您在 $remindDateStr $remindTime 设置了"提醒购买${item.name}"事程。');
          }
          break;
        }
      }
    } else {
      results.add('\n如果您希望我在快用完时提醒您，记得告诉我"设置${_inventory.first.name}用完提醒"哦～');
    }

    return results.join('\n');
  }

  /// 行为习惯分析 + 事程建议
  String? _answerHabitAdvice(String q) {
    final trigger = q.contains('帮我养成') || q.contains('养成') || q.contains('习惯建议') ||
        q.contains('分析我的') || q.contains('行为分析') || q.contains('作息') ||
        q.contains('健康建议') || q.contains('生活建议');
    if (!trigger) return null;

    final now = this.now;
    final monthAgo = now.subtract(const Duration(days: 30));
    final recentRecords = _timelineRecords.where((r) => r.time.isAfter(monthAgo)).toList();

    // 统计常见行为频次
    final Map<String, int> behaviorCount = {};
    for (final r in recentRecords) {
      if (r.content.length <= 12) {
        behaviorCount[r.content] = (behaviorCount[r.content] ?? 0) + 1;
      }
    }
    final sorted = behaviorCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final result = StringBuffer();
    result.writeln('📊 您最近30天的行为分析：\n');
    if (sorted.isEmpty) {
      result.writeln('记录较少，多记录几次我能给您更好的建议哦～');
      return result.toString();
    }

    result.writeln('最常见的行为 Top 5：');
    for (int i = 0; i < sorted.length && i < 5; i++) {
      result.writeln('  ${i+1}. ${sorted[i].key}（${sorted[i].value} 次）');
    }

    result.writeln('\n💡 改进建议：');
    final hasExercise = sorted.any((e) => e.key.contains('运动') || e.key.contains('散步') || e.key.contains('走'));
    if (!hasExercise) {
      result.writeln('• 您最近较少运动，建议每天饭后散步 15-30 分钟，可以设为提醒事程');
    }
    final hasMedicine = sorted.any((e) => e.key.contains('药') || e.key.contains('吃'));
    if (hasMedicine) {
      result.writeln('• 您有按时服药的好习惯，可继续保持');
    }
    final avgPerDay = recentRecords.length / 30.0;
    result.writeln('• 您平均每天记录 ${avgPerDay.toStringAsFixed(1)} 条行为');
    if (avgPerDay < 1) {
      result.writeln('  建议每天固定时段（如晚饭后）做记录，便于养成习惯');
    }

    return result.toString();
  }

  /// 学习/新技能事程设计建议
  String? _answerLearningAdvice(String q) {
    final trigger = q.contains('学习') || q.contains('想学') || q.contains('想练') ||
        q.contains('培养') || q.contains('进阶') || q.contains('进步') ||
        q.contains('我想') && (q.contains('学') || q.contains('练') || q.contains('做'));
    if (!trigger) return null;

    String? topic;
    if (q.contains('英语') || q.contains('英文')) topic = '英语';
    else if (q.contains('书法') || q.contains('写字')) topic = '书法';
    else if (q.contains('太极') || q.contains('拳')) topic = '太极拳';
    else if (q.contains('钢琴') || q.contains('琴')) topic = '钢琴';
    else if (q.contains('绘画') || q.contains('画画')) topic = '绘画';
    else if (q.contains('舞蹈') || q.contains('舞')) topic = '舞蹈';
    else if (q.contains('编程') || q.contains('代码')) topic = '编程';
    else if (q.contains('摄影') || q.contains('拍照')) topic = '摄影';
    else if (q.contains('游泳')) topic = '游泳';
    else if (q.contains('瑜伽')) topic = '瑜伽';
    else if (q.contains('唱歌') || q.contains('声乐')) topic = '唱歌';
    else if (q.contains('象棋') || q.contains('围棋')) topic = '象棋';
    else if (q.contains('阅读') || q.contains('看书')) topic = '阅读';
    else if (q.contains('写作') || q.contains('写文章')) topic = '写作';

    if (topic == null) {
      return '🎯 想培养新习惯是很棒的想法！请告诉我您想学什么（如英语、书法、太极、钢琴、绘画、瑜伽、游泳、阅读等），我会根据您的时间安排帮您设计事程计划。';
    }

    // 简单的事程计划
    final plan = StringBuffer();
    plan.writeln('🎯 「$topic」学习计划建议：\n');
    plan.writeln('📅 阶段性目标：');
    plan.writeln('  • 第 1-2 周：基础入门，每天 15 分钟');
    plan.writeln('  • 第 3-4 周：建立节奏，每天 20-30 分钟');
    plan.writeln('  • 第 5-8 周：进阶练习，每天 30 分钟');
    plan.writeln('  • 长期：每周 5-6 天，休息 1-2 天\n');
    plan.writeln('⏰ 建议时间安排：');
    plan.writeln('  • 早晨 7:00-7:30（头脑清醒）');
    plan.writeln('  • 或傍晚 17:00-17:30（精力充沛）\n');
    plan.writeln('💡 小贴士：');
    plan.writeln('  • 固定时间、固定地点，便于养成习惯');
    plan.writeln('  • 不要追求完美，重在坚持');
    plan.writeln('  • 每天完成后给自己一个小奖励\n');
    plan.writeln('您可以说"创建$topic学习计划"或"每天 7 点$topic学习"让我帮您建提醒事程。');
    return plan.toString();
  }

  /// 周期推理（驾照到期、换季衣服等）
  String? _answerCycleReasoning(String q) {
    final now = this.now;

    // 驾照到期/换证
    if (q.contains('驾照') && (q.contains('到期') || q.contains('过期') || q.contains('换证') || q.contains('什么时候'))) {
      return '🚗 驾照相关信息：\n\n'
          '• C1驾照有效期：6年、10年、长期\n'
          '• 换证时间：到期前90天内\n'
          '• 所需材料：身份证、驾照、体检报告、照片\n'
          '• 办理地点：车管所或"交管12123"APP\n\n'
          '💡 您可以告诉我您驾照的领取时间，我帮您计算到期时间并设置提醒。';
    }

    // 换季衣服
    if ((q.contains('换') || q.contains('该')) && (q.contains('衣服') || q.contains('季')) ||
        q.contains('换季')) {
      final month = now.month;
      String season;
      String suggestion;
      if (month >= 3 && month <= 5) {
        season = '春季';
        suggestion = '天气逐渐转暖，可以收起厚外套，准备薄外套和长袖衬衫。';
      } else if (month >= 6 && month <= 8) {
        season = '夏季';
        suggestion = '天气炎热，以短袖、短裤、裙子等清凉衣物为主。';
      } else if (month >= 9 && month <= 11) {
        season = '秋季';
        suggestion = '天气转凉，建议准备长袖、薄外套、风衣等过渡衣物。';
      } else {
        season = '冬季';
        suggestion = '天气寒冷，需要准备羽绒服、毛衣、厚外套等保暖衣物。';
      }
      return '👕 当前是$season：\n\n$suggestion\n\n'
          '💡 建议根据当地实际气温和个人体感调整，出门前可以看看天气预报。';
    }

    // 生日/纪念日推算
    if ((q.contains('生日') || q.contains('纪念日')) && (q.contains('还有') || q.contains('多久') || q.contains('什么时候'))) {
      return '🎂 您可以告诉我具体日期，我帮您计算还有多少天，并设置提前提醒。\n\n'
          '例如："妈妈生日是3月15日"、"结婚纪念日是10月1日"';
    }

    return null;
  }

  /// 对比分析（这个月比上个月、本周比上周等）
  String? _answerComparison(String q) {
    if (!q.contains('比') && !q.contains('对比') && !q.contains('相比')) return null;

    // 运动对比
    if (q.contains('运动') || q.contains('锻炼') || q.contains('散步')) {
      final now = this.now;
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);

      final thisMonthRecords = _timelineRecords.where((r) =>
          r.time.isAfter(thisMonthStart) &&
          (r.content.contains('运动') || r.content.contains('散步') || r.content.contains('锻炼'))
      ).toList().length;

      final lastMonthRecords = _timelineRecords.where((r) =>
          r.time.isAfter(lastMonthStart) &&
          r.time.isBefore(lastMonthEnd.add(const Duration(days: 1))) &&
          (r.content.contains('运动') || r.content.contains('散步') || r.content.contains('锻炼'))
      ).toList().length;

      final diff = thisMonthRecords - lastMonthRecords;
      final trend = diff > 0 ? '增加了' : diff < 0 ? '减少了' : '持平';

      return '📊 运动对比分析：\n\n'
          '• 本月运动次数：$thisMonthRecords 次\n'
          '• 上月运动次数：$lastMonthRecords 次\n'
          '• 变化趋势：$trend ${diff.abs()} 次\n\n'
          '${diff >= 0 ? '👍 继续保持！' : '💪 加油，本月多运动一下吧！'}';
    }

    // 吃药/作息对比
    if (q.contains('吃药') || q.contains('睡觉') || q.contains('起床')) {
      final keyword = q.contains('吃药') ? '吃药' : q.contains('睡觉') ? '睡觉' : '起床';
      final now = this.now;
      final thisWeekRecords = _timelineRecords.where((r) =>
          now.difference(r.time).inDays < 7 && r.content.contains(keyword)
      ).toList().length;

      final lastWeekRecords = _timelineRecords.where((r) =>
          now.difference(r.time).inDays >= 7 &&
          now.difference(r.time).inDays < 14 &&
          r.content.contains(keyword)
      ).toList().length;

      final diff = thisWeekRecords - lastWeekRecords;
      return '📊 $keyword 对比分析：\n\n'
          '• 本周次数：$thisWeekRecords 次\n'
          '• 上周次数：$lastWeekRecords 次\n'
          '• 变化：${diff >= 0 ? "+" : ""}$diff 次';
    }

    return null;
  }

  /// 寻找规律（一般几点睡觉、周末和工作日有什么不同等）
  String? _answerPatternDiscovery(String q) {
    // 睡觉/起床规律
    if (q.contains('几点睡觉') || q.contains('一般几点睡') || q.contains('睡觉规律') ||
        q.contains('几点起床') || q.contains('一般几点起') || q.contains('起床规律')) {
      final isSleep = q.contains('睡');
      final keyword = isSleep ? '睡觉' : '起床';
      final records = _timelineRecords.where((r) => r.content.contains(keyword)).toList();

      if (records.isEmpty) {
        return '😴 还没有足够的$keyword 记录来分析规律。\n多记录几天我就能帮您发现规律了！';
      }

      final hours = records.map((r) => r.time.hour).toList();
      final avgHour = hours.reduce((a, b) => a + b) ~/ hours.length;
      final avgMinute = 30;

      return '📊 您的$keyword 规律分析：\n\n'
          '• 平均时间：${avgHour.toString().padLeft(2, '0')}:${avgMinute.toString().padLeft(2, '0')} 左右\n'
          '• 记录天数：${records.length} 天\n\n'
          '${isSleep ? (avgHour >= 23 || avgHour < 1 ? '⏰ 睡得有点晚哦，建议23点前入睡更健康。' : '👍 作息比较规律，继续保持！') : '⏰ 起床时间比较规律。'}';
    }

    // 周末和工作日对比
    if (q.contains('周末') && (q.contains('工作日') || q.contains('平时')) ||
        q.contains('有什么不同') || q.contains('差别')) {
      final weekdayRecords = _timelineRecords.where((r) =>
          r.time.weekday >= 1 && r.time.weekday <= 5
      ).toList().length;
      final weekendRecords = _timelineRecords.where((r) =>
          r.time.weekday == 6 || r.time.weekday == 7
      ).toList().length;

      return '📊 周末 vs 工作日 规律分析：\n\n'
          '• 工作日记录数：$weekdayRecords 条\n'
          '• 周末记录数：$weekendRecords 条\n\n'
          '💡 记录更多数据后，我可以帮您分析更详细的作息、运动等差异。';
    }

    // 饮食习惯规律
    if (q.contains('吃饭') && (q.contains('规律') || q.contains('几点') || q.contains('一般'))) {
      return '🍽️ 您可以记录每天的用餐时间，持续一周后我就能帮您分析：\n\n'
          '• 三餐是否规律\n'
          '• 平均用餐时间\n'
          '• 用餐间隔是否合理\n\n'
          '现在就开始记录吧！比如"吃午饭了"。';
    }

    return null;
  }

  /// 复杂拆解（多意图问题拆解）
  String? _answerComplexQuery(String q) {
    // 检测是否是复杂问题（包含"和"、"以及"、还有"等连接词，或多个疑问词）
    final hasMultiIntent = q.contains('和') && (q.contains('?') || q.contains('？')) ||
        q.contains('以及') || q.contains('还有') && q.contains('多少');

    if (!hasMultiIntent && !q.contains('回忆') && !q.contains('回顾') &&
        !q.contains('总结') && !q.contains('汇总')) {
      return null;
    }

    // 体检结果+后续安排 这类复杂问题
    if (q.contains('体检') || q.contains('检查') || q.contains('体检结果')) {
      return '🏥 关于体检的综合信息：\n\n'
          '【体检结果】\n'
          '• 您可以在"问一问"中直接问我具体指标\n'
          '• 例如："血压正常值是多少"\n\n'
          '【后续安排建议】\n'
          '• 根据体检结果调整饮食和作息\n'
          '• 异常指标建议咨询医生\n'
          '• 可以设置定期复查提醒\n\n'
          '💡 告诉我您具体想了解什么，我可以为您提供更详细的信息。';
    }

    // 回忆/回顾某天
    if (q.contains('回忆') || q.contains('回顾') || q.contains('总结') || q.contains('汇总')) {
      final todayTimeline = _timelineRecords.where((r) => r.date == todayStr).toList();
      if (todayTimeline.isEmpty) {
        return '📝 今天还没有记录呢。\n您可以通过语音或文字记录当下的活动。';
      }
      return '📝 今日回顾：\n\n'
          '您今天共记录了 ${todayTimeline.length} 条\n'
          '${todayTimeline.map((r) => '• ${r.timeStr} ${r.content}').join('\n')}\n\n'
          '💡 继续保持记录的好习惯！';
    }

    return null;
  }

  /// 常规问答（不依赖个人数据）
  String? _answerFaq(String q) {
    // 健康常识
    if (q.contains('血压') && (q.contains('正常') || q.contains('多少') || q.contains('标准'))) {
      return '正常血压参考值：\n• 收缩压 90-120 mmHg\n• 舒张压 60-80 mmHg\n• 老年人略高属正常，>140/90 需关注。\n具体请以医生建议为准。';
    }
    if (q.contains('血糖') && (q.contains('正常') || q.contains('多少') || q.contains('标准'))) {
      return '空腹血糖正常值：3.9-6.1 mmol/L；餐后2小时 < 7.8 mmol/L。\n老年人略高需关注，具体请咨询医生。';
    }
    if (q.contains('心跳') && (q.contains('正常') || q.contains('多少'))) {
      return '正常心率：60-100 次/分钟。\n运动员或长期运动者可能 50-60 次/分钟也属正常。\n如有不适请咨询医生。';
    }
    if (q.contains('睡眠') && (q.contains('几小时') || q.contains('多少小时') || q.contains('建议'))) {
      return '老年人建议每天睡眠 7-8 小时。\n• 午休 20-30 分钟最佳\n• 晚上 10 点-凌晨 6 点为黄金睡眠期\n• 避免午睡过长影响夜间入睡';
    }
    if (q.contains('喝水') && (q.contains('多少') || q.contains('几杯'))) {
      return '建议每天饮水 1500-2000 ml（约 7-8 杯）。\n• 早晨起床喝一杯温水\n• 睡前 1 小时少量饮水\n• 运动或天热时适量增加';
    }
    if (q.contains('散步') && (q.contains('多久') || q.contains('时间') || q.contains('建议'))) {
      return '老年人散步建议：\n• 时长：每天 30-60 分钟\n• 强度：微微出汗、呼吸略快但能说话\n• 时间段：早晨 7-9 点或傍晚 17-19 点\n• 避免饭后立即剧烈散步';
    }
    if (q.contains('锻炼') || q.contains('运动')) {
      return '老年人运动建议：\n• 有氧运动：散步、慢跑、太极、游泳（每周 3-5 次）\n• 力量训练：每周 2 次轻负重或自重训练\n• 柔韧性：每天拉伸 10-15 分钟\n• 平衡训练：单脚站立、太极\n• 运动前热身 5-10 分钟，运动后放松 5-10 分钟';
    }
    // 出行
    if (q.contains('天气') || q.contains('气温')) {
      return '查看实时天气，建议您打开手机自带的天气 App 获取最准确的信息。\n出门建议：\n• 关注温度变化，及时增减衣物\n• 雨雪天气注意防滑\n• 极端高温/低温减少外出';
    }
    if (q.contains('地铁') || q.contains('公交') || q.contains('出行')) {
      return '出行前建议：\n• 提前查询路线和班次\n• 错峰出行（10 点前或 15 点后较舒适）\n• 携带老年卡、身份证\n• 雨天路滑注意安全';
    }
    // 心情
    if (q.contains('心情不好') || q.contains('不开心') || q.contains('焦虑') || q.contains('抑郁')) {
      return '我理解您的心情。可以试试：\n• 出门走走，呼吸新鲜空气\n• 听听喜欢的音乐或戏曲\n• 和家人朋友聊聊天\n• 做点简单的手工或家务\n• 保证充足睡眠\n如果持续低落，建议联系家人或咨询心理医生。';
    }
    if (q.contains('无聊') || q.contains('没事做')) {
      return '可以试试这些：\n• 阅读一本书或报纸\n• 练字、画画、听戏\n• 和朋友视频聊天\n• 整理家里的小角落\n• 学习一个新技能（我也可以帮您规划）\n• 出门散步晒太阳';
    }
    if (q.contains('谢谢') || q.contains('感谢')) {
      return '不客气，能帮到您是我的开心事！您随时可以问我～';
    }
    if (q.contains('你好') || q.contains('您好')) {
      return '您好呀！我是小爱，今天有什么可以帮您的吗？\n您可以问我：今天吃了什么、钥匙在哪、药还有多少，或者让我帮您设计一个学习计划～';
    }
    return null;
  }

  /// 物品位置查询
  String? _answerItemLocation(String q) {
    // 匹配 "XX在哪" / "XX放在哪" / "XX位置"
    if (!q.contains('在哪') && !q.contains('放在哪') && !q.contains('位置') && !q.contains('放哪')) {
      return null;
    }
    // 从物品列表中查找
    for (final item in items) {
      if (q.contains(item.name)) {
        return '根据您的记录，${item.name}放在了${item.location}。\n'
            '${item.history.length > 1 ? "历史位置：" + item.history.map((h) => h.location).join("→") : ""}';
      }
    }
    // 从时间线记录中查找物品放置信息
    for (final r in _timelineRecords) {
      if (r.tags.contains('item') && r.sideEffects?.itemUpdate != null) {
        final itemData = r.sideEffects!.itemUpdate!;
        if (q.contains(itemData.name)) {
          return '根据${r.date} ${r.timeStr}的记录，${itemData.name}放在了${itemData.location}。';
        }
      }
      // 也检查 extractedData 中的 item 信息
      if (r.tags.contains('item') && q.contains(r.content)) {
        return '根据${r.date} ${r.timeStr}的记录："${r.content}"';
      }
    }
    return '抱歉，我没有找到相关物品的记录。您可以通过语音告诉我物品的位置，下次就能帮您记住了。';
  }

  /// 库存/剩余数量查询
  String? _answerInventoryQuery(String q) {
    // 匹配 "还剩多少" / "还有多少" / "剩多少" / "多少斤/个/瓶" / "物品"
    final hasInventoryKeyword = q.contains('还剩') || q.contains('还有多少') ||
      q.contains('剩多少') || q.contains('多少') || q.contains('还有几个') ||
      q.contains('还有几瓶') || q.contains('还有几斤') ||
      q.contains('物品') || q.contains('物品记录') || q.contains('物品数量');

    if (!hasInventoryKeyword) return null;

    // 提取物品名（从库存列表中匹配）
    InventoryItem? matchedItem;
    for (final item in _inventory) {
      if (q.contains(item.name)) {
        matchedItem = item;
        break;
      }
    }

    // 匹配 "药" 类泛称
    if (matchedItem == null && (q.contains('药') || q.contains('药品'))) {
      final meds = _inventory.where((i) => i.category == '药品').toList();
      if (meds.isNotEmpty) {
        final parts = <String>[];
        for (final m in meds) {
          parts.add('• ${m.name}：${_formatQty(m.quantity)} ${m.unit}');
        }
        return '当前药品库存：\n${parts.join('\n')}';
      }
    }

    // 匹配吃了多少 / 用了多少（从日志统计）
    if (q.contains('吃了多少') || q.contains('用了多少') || q.contains('服用了多少')) {
      // 从库存日志中统计消耗
      for (final item in _inventory) {
        if (q.contains(item.name)) {
          // 统计最近7天消耗
          final now = this.now;
          final weekLogs = item.logs.where((l) =>
            l.change < 0 && now.difference(l.time).inDays < 7
          ).toList();
          final totalUsed = weekLogs.fold<double>(0, (sum, l) => sum + l.change.abs());
          return '最近7天${item.name}用了 ${_formatQty(totalUsed)} ${item.unit}。\n'
              '当前剩余：${_formatQty(item.quantity)} ${item.unit}';
        }
      }
      return null;
    }

    if (matchedItem != null) {
      // 计算还能吃几天（如果有日均消耗数据）
      String? usageInfo;
      final now = this.now;
      final monthLogs = matchedItem.logs.where((l) =>
        l.change < 0 && now.difference(l.time).inDays < 30
      ).toList();
      if (monthLogs.isNotEmpty) {
        final totalUsed = monthLogs.fold<double>(0, (sum, l) => sum + l.change.abs());
        final daysUsed = monthLogs.map((l) => l.time.day).toSet().length;
        final dailyAvg = totalUsed / daysUsed;
        final daysLeft = dailyAvg > 0 ? (matchedItem.quantity / dailyAvg).floor() : null;
        if (daysLeft != null && daysLeft > 0) {
          usageInfo = '\n按最近30天平均每天用 ${_formatQty(dailyAvg)} ${matchedItem.unit} 计算，还能用 $daysLeft 天。';
        }
      }

      return '${matchedItem.name}还剩 ${_formatQty(matchedItem.quantity)} ${matchedItem.unit}。'
          '${usageInfo ?? ''}\n'
          '上次更新：${matchedItem.lastUpdated.month}/${matchedItem.lastUpdated.day} ${matchedItem.lastUpdated.hour}:${matchedItem.lastUpdated.minute.toString().padLeft(2, '0')}';
    }

    // 没找到特定物品，列出所有库存
    if (_inventory.isNotEmpty && (q.contains('库存') || q.contains('都有什么') || q.contains('都有多少') || q.contains('物品') && (q.contains('哪些') || q.contains('什么') || q.contains('记录')))) {
      final parts = <String>[];
      for (final item in _inventory) {
        parts.add('• ${item.name}：${_formatQty(item.quantity)} ${item.unit}');
      }
      return '当前物品记录：\n${parts.join('\n')}';
    }

    return null;
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.round().toString();
    return qty.toStringAsFixed(1);
  }

  /// 计划制定助手
  String? _answerPlanQuery(String q) {
    final hasPlanKeyword = q.contains('计划') || q.contains('打算') || 
      q.contains('安排') || q.contains('准备') || q.contains('想要') || q.contains('计划要做');
    if (!hasPlanKeyword) return null;

    // 多轮对话：检查是否在修改之前的计划
    if (_context.isActive && _context.currentTopic == 'plan') {
      final result = _handlePlanContextUpdate(q);
      if (result != null) return result;
    }

    final dateMatch = RegExp(r'(明天|后天|下周(?:[一二三四五六日])?|下周一|下周二|下周三|下周四|下周五|下周六|下周日|这个周末)').firstMatch(q);
    String planDate = MockData.dateOffset(dateMatch != null ? 
      dateMatch[0]!.contains('明天') ? 1 : 
      dateMatch[0]!.contains('后天') ? 2 :
      dateMatch[0]!.contains('下周') ? 7 : 1 : 0);

    String dateDesc = dateMatch != null ? dateMatch[0]! : '今天';

    String planContent = q
        .replaceAll(RegExp(r'^(计划|打算|安排|准备|想要)'), '')
        .replaceAll(RegExp(r'(明天|后天|下周(?:[一二三四五六日])?)'), '')
        .trim();

    if (planContent.isEmpty) planContent = '完成计划';

    // ============ 优先检索已有安排 ============
    // 1. 检查时间线中是否已有相关记录
    final timelineRecords = _timelineRecords.where((r) => 
      r.date == planDate && 
      r.content.toLowerCase().contains(planContent.toLowerCase())
    ).toList();

    // 2. 检查事程中是否已有相关安排
    final agendaRecords = _agendaItems.where((a) => 
      a.date == planDate && 
      a.content.toLowerCase().contains(planContent.toLowerCase())
    ).toList();

    // 如果已有安排，先告知用户
    if (timelineRecords.isNotEmpty || agendaRecords.isNotEmpty) {
      String result = '根据您的记录，';
      
      if (timelineRecords.isNotEmpty) {
        result += '时间线中已有相关记录：\n';
        for (final r in timelineRecords) {
          result += '• ${r.timeStr} ${r.content}\n';
        }
      }
      
      if (agendaRecords.isNotEmpty) {
        if (timelineRecords.isNotEmpty) result += '\n';
        result += '事程中已有相关安排：\n';
        for (final a in agendaRecords) {
          result += '• ${a.time} ${a.content}（${a.status == AgendaStatus.completed ? '已完成' : a.status == AgendaStatus.expired ? '已过期' : '待进行'}）\n';
        }
      }
      
      result += '\n💡 如果您想修改时间或内容，可以告诉我。';
      return result;
    }

    final planAnalysis = _analyzePlan(planContent);

    List<String> suggestedTimes = List<String>.from(planAnalysis['suggestedTimes'] as List);
    final decomposedSteps = planAnalysis['steps'] as List<String>;
    final estimatedDuration = planAnalysis['duration'] as String;
    List<String> tips = List<String>.from(planAnalysis['tips'] as List);

    // 个性化建议（基于用户档案）
    final personalizedTips = _getPersonalizedTips(planContent);
    if (personalizedTips.isNotEmpty) {
      tips = [...tips, ...personalizedTips];
    }

    // 智能推荐改进：基于历史推迟率调整时间
    suggestedTimes = _optimizeTimeByHistory(planContent, suggestedTimes);

    // 日程冲突检测
    String? conflictWarning;
    final conflicts = <String>[];
    for (final time in suggestedTimes) {
      final conflict = _agendaItems.any((a) => a.date == planDate && a.time == time);
      if (conflict) {
        conflicts.add(time);
      }
    }
    if (conflicts.isNotEmpty) {
      conflictWarning = '⚠️ 注意：$dateDesc 的 ${conflicts.join("、")} 已有事程安排，建议选择其他时间。';
    }

    String result = '我来帮您制定${dateDesc}的计划：\n\n';
    if (conflictWarning != null) {
      result = '$conflictWarning\n\n$result';
    }
    result += '📅 建议时间：${suggestedTimes.join(' / ')}\n\n';
    result += '📋 事程分解：\n';
    for (int i = 0; i < decomposedSteps.length; i++) {
      result += '${i+1}. ${decomposedSteps[i]}\n';
    }
    result += '\n⏱ 预估耗时：$estimatedDuration\n\n';
    if (tips.isNotEmpty) {
      result += '💡 小贴士：\n';
      for (final tip in tips) {
        result += '• $tip\n';
      }
    }
    result += '\n请问是否需要我将这些事程添加到您的待办列表中？\n（可以说"改到后天"或"换个时间"来调整）';

    _pendingPlan = {
      'date': planDate,
      'content': planContent,
      'steps': decomposedSteps,
      'times': suggestedTimes,
    };

    // 保存对话上下文
    _context = ConversationContext(
      currentTopic: 'plan',
      planData: _pendingPlan,
      lastQuestion: q,
      lastUpdated: now,
    );

    return result;
  }

  /// 处理多轮对话中的计划修改
  String? _handlePlanContextUpdate(String q) {
    final planData = _context.planData;
    if (planData == null) return null;

    // 修改日期
    final dateMatch = RegExp(r'(后天|明天|下周[一二三四五六日]?|大后天)').firstMatch(q);
    if (q.contains('改到') || q.contains('换个') || q.contains('换成')) {
      if (dateMatch != null) {
        final newOffset = dateMatch[0]!.contains('明天') ? 1 :
                          dateMatch[0]!.contains('后天') ? 2 :
                          dateMatch[0]!.contains('下周') ? 7 : 0;
        final newDate = MockData.dateOffset(newOffset);
        _pendingPlan = {
          ...planData,
          'date': newDate,
        };
        _context = _context.copyWith(
          planData: _pendingPlan,
          lastQuestion: q,
          lastUpdated: now,
        );
        return '已将计划调整到${dateMatch[0]}，时间和其他内容保持不变。\n是否需要添加到待办列表？';
      }
      // 修改时间
      final timeMatch = RegExp(r'(\d{1,2})[:：点](\d{2})?').firstMatch(q);
      if (timeMatch != null) {
        final hour = int.parse(timeMatch[1]!);
        final min = timeMatch[2] != null ? int.parse(timeMatch[2]!) : 0;
        final newTime = '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
        final oldTimes = List<String>.from(planData['times'] as List);
        oldTimes[0] = newTime;
        _pendingPlan = {
          ...planData,
          'times': oldTimes,
        };
        _context = _context.copyWith(
          planData: _pendingPlan,
          lastQuestion: q,
          lastUpdated: now,
        );
        return '已将首个时间调整为 $newTime，其他时间不变。\n是否需要添加到待办列表？';
      }
    }
    return null;
  }

  /// 个性化建议（基于用户档案）
  List<String> _getPersonalizedTips(String planContent) {
    final tips = <String>[];
    final profile = _userProfile;

    // 高血压患者注意事项
    if (profile.hasHypertension) {
      if (planContent.contains('运动') || planContent.contains('散步')) {
        tips.add('您有高血压，运动时注意不要剧烈，建议散步等温和运动');
      }
      if (planContent.contains('医院') || planContent.contains('看病')) {
        tips.add('记得告知医生您的高血压情况，按时服用降压药');
      }
    }

    // 糖尿病患者注意事项
    if (profile.hasDiabetes) {
      if (planContent.contains('吃饭') || planContent.contains('饮食')) {
        tips.add('您有糖尿病，注意控制碳水摄入，少食多餐');
      }
      if (planContent.contains('医院')) {
        tips.add('记得告知医生您的糖尿病情况');
      }
    }

    // 老年人建议
    if (profile.isElderly) {
      if (planContent.contains('运动') && !planContent.contains('散步')) {
        tips.add('建议选择温和运动如散步、太极，避免剧烈运动');
      }
      if (planContent.contains('出门') || planContent.contains('外出')) {
        tips.add('出门记得带好常用药品和紧急联系人电话');
      }
    }

    return tips;
  }

  /// 智能时间优化：基于历史推迟率调整建议时间
  List<String> _optimizeTimeByHistory(String content, List<String> originalTimes) {
    // 找出与content相关的历史事程
    final relatedAgendas = _agendaItems.where((a) =>
      a.content.contains(content) || content.contains(a.content)
    ).toList();

    if (relatedAgendas.length < 3) return originalTimes; // 数据不足，不调整

    // 统计推迟率
    final postponed = relatedAgendas.where((a) => a.status == AgendaStatus.postponed).length;
    final postponeRate = postponed / relatedAgendas.length;

    if (postponeRate < 0.3) return originalTimes; // 推迟率低，无需调整

    // 计算实际平均完成时间（推迟后的时间）
    final actualTimes = <int>[];
    for (final agenda in relatedAgendas) {
      if (agenda.status == AgendaStatus.completed || agenda.status == AgendaStatus.postponed) {
        final parts = agenda.time.split(':');
        if (parts.length == 2) {
          actualTimes.add(int.parse(parts[0]) * 60 + int.parse(parts[1]));
        }
      }
    }

    if (actualTimes.isEmpty) return originalTimes;

    final avgMinutes = actualTimes.reduce((a, b) => a + b) ~/ actualTimes.length;
    final avgHour = (avgMinutes ~/ 60).toString().padLeft(2, '0');
    final avgMin = (avgMinutes % 60).toString().padLeft(2, '0');
    final optimizedTime = '$avgHour:$avgMin';

    // 返回优化后的时间列表（保持原数量）
    final optimized = List<String>.from(originalTimes);
    optimized[0] = optimizedTime;
    return optimized;
  }

  Map<String, dynamic> _analyzePlan(String content) {
    List<String> suggestedTimes = ['09:00', '14:00', '16:00'];
    List<String> steps = [];
    String duration = '30分钟';
    List<String> tips = [];

    if (content.contains('医院') || content.contains('看病') || content.contains('复诊')) {
      suggestedTimes = ['08:30', '09:00', '10:00'];
      steps = ['提前预约挂号', '准备病历和医保卡', '按时到达医院', '就诊检查', '取药回家'];
      duration = '2-3小时';
      tips = ['建议提前30分钟到达', '记得带上身份证和医保卡', '看病前不要空腹'];
    } else if (content.contains('购物') || content.contains('买菜') || content.contains('买东西')) {
      suggestedTimes = ['09:00', '10:00', '16:00'];
      steps = ['列出购物清单', '前往超市/菜市场', '按清单采购', '结账回家'];
      duration = '1-1.5小时';
      tips = ['避免在饭点购物，人多拥挤', '可以先查看库存，避免重复购买'];
    } else if (content.contains('运动') || content.contains('散步') || content.contains('锻炼')) {
      suggestedTimes = ['16:00', '18:30', '19:00'];
      steps = ['换上舒适的运动鞋', '做热身运动5分钟', '进行运动', '运动后拉伸放松'];
      duration = '30-60分钟';
      tips = ['运动强度要循序渐进', '运动后及时补充水分', '天气不好可以在家做室内运动'];
    } else if (content.contains('打扫') || content.contains('卫生') || content.contains('整理')) {
      suggestedTimes = ['09:00', '14:00', '15:00'];
      steps = ['整理杂物', '扫地拖地', '擦拭家具', '清理厨房卫生间'];
      duration = '1-2小时';
      tips = ['可以分阶段进行，避免劳累', '高处清洁要注意安全'];
    } else if (content.contains('做饭') || content.contains('做菜')) {
      suggestedTimes = ['11:00', '17:00', '17:30'];
      steps = ['准备食材', '清洗切配', '烹饪菜肴', '收拾厨房'];
      duration = '1-1.5小时';
      tips = ['注意厨房安全，防止烫伤', '可以提前准备好食材'];
    } else if (content.contains('取快递') || content.contains('拿快递')) {
      suggestedTimes = ['10:00', '16:00', '19:00'];
      steps = ['查看取件码', '前往快递点/驿站', '取件核对', '签收回家'];
      duration = '15-30分钟';
      tips = ['记得带上手机或身份证', '核对好快递信息再签收'];
    } else if (content.contains('理发') || content.contains('剪头发')) {
      suggestedTimes = ['09:30', '14:00', '15:00'];
      steps = ['提前预约', '前往理发店', '理发', '付款回家'];
      duration = '1-1.5小时';
      tips = ['可以带上口罩', '告知理发师想要的发型'];
    } else if (content.contains('银行') || content.contains('取钱') || content.contains('存钱')) {
      suggestedTimes = ['09:30', '10:00', '14:00'];
      steps = ['准备身份证和银行卡', '前往银行', '取号排队', '办理业务', '确认无误后离开'];
      duration = '1-2小时';
      tips = ['记得带上身份证', '大额取款注意安全'];
    } else {
      suggestedTimes = ['09:00', '14:00'];
      steps = ['准备工作', '执行计划', '检查完成情况'];
      duration = '30-60分钟';
      tips = ['可以分步骤完成，不要急于求成'];
    }

    return {
      'suggestedTimes': suggestedTimes,
      'steps': steps,
      'duration': duration,
      'tips': tips,
    };
  }

  Map<String, dynamic>? _pendingPlan;

  /// 确认添加计划到待办事程
  String confirmAddPlan(bool confirm) {
    if (_pendingPlan == null) return '没有待确认的计划。';

    if (confirm) {
      final plan = _pendingPlan!;
      final date = plan['date'] as String;
      final steps = plan['steps'] as List<String>;
      final times = plan['times'] as List<String>;

      for (int i = 0; i < steps.length; i++) {
        final timeIndex = i % times.length;
        addAgenda(AgendaItem(
          id: _genId(),
          content: steps[i],
          time: times[timeIndex],
          date: date,
          status: AgendaStatus.pending,
          icon: '📋',
        ));
      }

      _pendingPlan = null;
      _context = const ConversationContext(); // 清空对话上下文
      return '已成功将 ${steps.length} 项事程添加到${date}的待办列表中！\n${steps.map((s) => '• $s').join('\n')}\n\n记得按时完成哦，完成后告诉我即可！';
    } else {
      _pendingPlan = null;
      _context = const ConversationContext();
      return '好的，暂不添加。如有需要随时告诉我。';
    }
  }

  /// 习惯养成助手
  String? _answerHabitQuery(String q) {
    final hasHabitKeyword = q.contains('习惯') || q.contains('养成') || 
      q.contains('坚持') || q.contains('开始') || q.contains('练习');
    if (!hasHabitKeyword) return null;

    String habitContent = q
        .replaceAll(RegExp(r'^(养成|坚持|开始|练习)'), '')
        .replaceAll(RegExp(r'(习惯|的习惯)'), '')
        .trim();

    if (habitContent.isEmpty) habitContent = '好习惯';

    final habitAnalysis = _analyzeHabit(habitContent);

    final suggestedTimes = habitAnalysis['times'] as List<String>;
    final dailySteps = habitAnalysis['dailySteps'] as List<String>;
    final duration = habitAnalysis['duration'] as String;
    final tips = habitAnalysis['tips'] as List<String>;
    final weekPlan = habitAnalysis['weekPlan'] as List<String>;

    String result = '我来帮您规划养成「$habitContent」习惯：\n\n';
    result += '⏰ 建议时间：${suggestedTimes.join(' / ')}\n\n';
    result += '📅 每日步骤：\n';
    for (int i = 0; i < dailySteps.length; i++) {
      result += '${i+1}. ${dailySteps[i]}\n';
    }
    result += '\n⏱ 每次耗时：$duration\n\n';
    result += '📆 一周计划：\n';
    for (int i = 0; i < weekPlan.length; i++) {
      result += '周${'一二三四五六日'[i]}：${weekPlan[i]}\n';
    }
    result += '\n💡 坚持小贴士：\n';
    for (final tip in tips) {
      result += '• $tip\n';
    }
    result += '\n请问是否需要我将下周的习惯养成计划添加到您的待办事程中？';

    _pendingHabit = {
      'content': habitContent,
      'times': suggestedTimes,
      'steps': dailySteps,
      'weekPlan': weekPlan,
    };

    return result;
  }

  Map<String, dynamic> _analyzeHabit(String content) {
    List<String> times = [];
    List<String> dailySteps = [];
    String duration = '';
    List<String> tips = [];
    List<String> weekPlan = [];

    if (content.contains('运动') || content.contains('散步') || content.contains('锻炼')) {
      times = ['18:30', '19:00'];
      dailySteps = ['换上运动鞋', '热身运动5分钟', '散步/运动30分钟', '拉伸放松5分钟'];
      duration = '40分钟';
      tips = ['从短时间开始，逐渐增加', '固定时间更容易坚持', '可以找个同伴一起', '记录每天的运动情况'];
      weekPlan = ['第一天：散步15分钟', '第二天：散步20分钟', '第三天：散步25分钟', '第四天：散步30分钟', '第五天：散步30分钟', '第六天：散步35分钟', '第七天：散步40分钟'];
    } else if (content.contains('喝水') || content.contains('饮水')) {
      times = ['08:00', '10:00', '14:00', '16:00', '18:00'];
      dailySteps = ['早上起床喝一杯温水', '上午10点喝一杯', '下午2点喝一杯', '下午4点喝一杯', '晚上6点喝一杯'];
      duration = '每天5杯';
      tips = ['可以用大杯子，减少倒水次数', '设置提醒帮助养成习惯', '不要等到口渴才喝', '睡前1小时尽量少喝'];
      weekPlan = ['每天目标：5杯水', '每天目标：5杯水', '每天目标：5杯水', '每天目标：5杯水', '每天目标：5杯水', '每天目标：5杯水', '回顾本周喝水情况'];
    } else if (content.contains('阅读') || content.contains('看书') || content.contains('学习')) {
      times = ['20:00', '20:30'];
      dailySteps = ['找一个安静的环境', '阅读20-30页', '记录重点内容', '合上书本休息一下'];
      duration = '30分钟';
      tips = ['每天固定时间阅读', '从感兴趣的书籍开始', '可以做笔记加深记忆', '不要一次读太久，容易疲劳'];
      weekPlan = ['阅读10页', '阅读15页', '阅读20页', '阅读20页', '阅读25页', '阅读25页', '回顾本周阅读内容'];
    } else if (content.contains('早睡') || content.contains('睡觉') || content.contains('作息')) {
      times = ['21:30', '22:00'];
      dailySteps = ['21:00准备洗漱', '21:30放下手机', '22:00上床睡觉', '保证7-8小时睡眠'];
      duration = '7-8小时';
      tips = ['睡前1小时不看电子屏幕', '保持卧室安静黑暗', '睡前可以泡脚放松', '每天固定时间睡觉和起床'];
      weekPlan = ['22:30前睡', '22:15前睡', '22:00前睡', '22:00前睡', '21:45前睡', '21:30前睡', '保持规律作息'];
    } else if (content.contains('吃药') || content.contains('服药')) {
      times = ['08:00', '15:00', '21:00'];
      dailySteps = ['早餐后吃药', '定时服药', '晚餐后吃药', '睡前服药（如有）'];
      duration = '每日定时';
      tips = ['设置提醒帮助按时服药', '不要擅自增减药量', '忘记服药不要双倍补服', '定期检查药品有效期'];
      weekPlan = ['按时服药', '按时服药', '按时服药', '按时服药', '按时服药', '按时服药', '检查药品库存'];
    } else if (content.contains('冥想') || content.contains('放松') || content.contains('静心')) {
      times = ['08:00', '21:00'];
      dailySteps = ['找一个舒适的姿势', '闭上眼睛', '专注呼吸', '冥想5-10分钟'];
      duration = '10分钟';
      tips = ['呼吸节奏保持平稳', '不要强求清空思绪', '从短时间开始练习', '每天坚持效果更好'];
      weekPlan = ['冥想5分钟', '冥想5分钟', '冥想7分钟', '冥想7分钟', '冥想10分钟', '冥想10分钟', '回顾本周感受'];
    } else if (content.contains('做家务') || content.contains('打扫')) {
      times = ['09:00', '15:00'];
      dailySteps = ['简单整理房间', '扫地拖地', '擦拭桌面', '清理垃圾'];
      duration = '30分钟';
      tips = ['每天做一点，不要堆积', '可以放着音乐做家务', '分区域打扫更高效', '注意劳逸结合'];
      weekPlan = ['整理客厅', '打扫卧室', '清洁厨房', '整理阳台', '打扫卫生间', '深度清洁', '休息放松'];
    } else {
      times = ['09:00', '14:00'];
      dailySteps = ['明确目标', '制定计划', '开始行动', '记录进度'];
      duration = '30分钟';
      tips = ['从小事做起', '每天进步一点点', '记录自己的进步', '坚持21天养成习惯'];
      weekPlan = ['了解习惯内容', '开始第一天', '坚持第二天', '坚持第三天', '坚持第四天', '坚持第五天', '回顾本周进展'];
    }

    return {
      'times': times,
      'dailySteps': dailySteps,
      'duration': duration,
      'tips': tips,
      'weekPlan': weekPlan,
    };
  }

  Map<String, dynamic>? _pendingHabit;

  /// 确认添加习惯到待办事程
  String confirmAddHabit(bool confirm) {
    if (_pendingHabit == null) return '没有待确认的习惯计划。';

    if (confirm) {
      final habit = _pendingHabit!;
      final content = habit['content'] as String;
      final times = habit['times'] as List<String>;
      final weekPlan = habit['weekPlan'] as List<String>;

      for (int i = 0; i < weekPlan.length; i++) {
        final date = MockData.dateOffset(i);
        final timeIndex = i % times.length;
        addAgenda(AgendaItem(
          id: _genId(),
          content: weekPlan[i],
          time: times[timeIndex],
          date: date,
          status: AgendaStatus.pending,
          icon: '✅',
        ));
      }

      _pendingHabit = null;
      _context = const ConversationContext();
      return '已成功将「$content」习惯养成计划添加到未来7天的待办列表中！\n每周计划：${weekPlan.join(' → ')}\n\n坚持就是胜利，加油！每完成一天告诉我即可记录进度。';
    } else {
      _pendingHabit = null;
      _context = const ConversationContext();
      return '好的，暂不添加。如有需要随时告诉我。';
    }
  }

  /// 时间线记录查询
  String? _answerTimelineQuery(String q) {
    // 匹配日期关键词
    String? targetDate;
    String? dateDesc;

    if (q.contains('今天') || q.contains('今日')) {
      targetDate = todayStr;
      dateDesc = '今天';
    } else if (q.contains('昨天') || q.contains('昨日')) {
      targetDate = MockData.dateOffset(-1);
      dateDesc = '昨天';
    } else if (q.contains('前天')) {
      targetDate = MockData.dateOffset(-2);
      dateDesc = '前天';
    } else if (q.contains('大前天')) {
      targetDate = MockData.dateOffset(-3);
      dateDesc = '大前天';
    } else if (q.contains('上周')) {
      // 上周同一天
      final match = RegExp(r'上周([一二三四五六日天])').firstMatch(q);
      final dayOffset = match != null ? _parseWeekday(match[1]!) : 0;
      targetDate = MockData.dateOffset(-7 + dayOffset);
      dateDesc = '上周${match?[1] ?? ''}';
    } else if (q.contains('最近') && (q.contains('天') || q.contains('日'))) {
      // 最近N天
      final numMatch = RegExp(r'最近(\d+)').firstMatch(q);
      final days = numMatch != null ? int.parse(numMatch[1]!) : 7;
      final records = _timelineRecords.where((r) {
        final diff = now.difference(r.time).inDays;
        return diff < days;
      }).toList();
      if (records.isEmpty) return '最近$days天没有记录。';
      return '最近$days天的记录：\n${records.map((r) => '${r.date} ${r.timeStr} ${r.content}').join('\n')}';
    }

    if (targetDate == null) return null;

    // 检查是否只是问"做了什么"类
    if (!q.contains('做了') && !q.contains('干什么') && !q.contains('发生') &&
        !q.contains('记录') && !q.contains('做了什么') && !q.contains('怎么样') &&
        !q.contains('事情') && !q.contains('情况')) {
      // 可能只是提到日期但不是查询时间线
      return null;
    }

    final records = _timelineRecords.where((r) => r.date == targetDate).toList();
    if (records.isEmpty) return '$dateDesc没有时间线记录。';

    return '$dateDesc您做了以下事情：\n'
        '${records.map((r) => '${r.timeStr} ${r.content}${r.matchedAgenda != null ? " ✓" : ""}').join('\n')}';
  }

  /// 事程/待办查询
  String? _answerAgendaQuery(String q) {
    if (!q.contains('事程') && !q.contains('待办') && !q.contains('提醒') &&
        !q.contains('还有什么') && !q.contains('要做什么') && !q.contains('有什么事')) {
      return null;
    }

    final todayAgendas = _agendaItems.where((a) => a.date == todayStr).toList();
    final pending = todayAgendas.where((a) => a.status == AgendaStatus.pending).toList();
    final completed = todayAgendas.where((a) => a.status == AgendaStatus.completed).toList();

    if (q.contains('完成') || q.contains('做完')) {
      return '今天已完成 ${completed.length} 项事程：\n'
          '${completed.map((a) => '✓ ${a.time} ${a.content}').join('\n')}';
    }

    if (pending.isEmpty) return '今天没有待办事程，都已完成了！';

    return '今天还有 ${pending.length} 项待办事程：\n'
        '${pending.map((a) => '${a.time} ${a.content}${a.isMustDo ? "（必做）" : ""}${a.remainingTime != null ? " ${a.remainingTime}" : ""}').join('\n')}';
  }

  /// 行为统计查询
  String? _answerStatsQuery(String q) {
    // 匹配 "XX了几次" / "多少次" / "完成率"
    if (!q.contains('几次') && !q.contains('多少次') && !q.contains('完成率') &&
        !q.contains('统计') && !q.contains('频率')) {
      return null;
    }

    if (q.contains('完成率')) {
      final completed = _agendaItems.where((a) => a.status == AgendaStatus.completed).length;
      final total = _agendaItems.length;
      final rate = total > 0 ? (completed * 100 ~/ total) : 0;
      return '当前事程完成率为 $rate%（$completed/$total）。';
    }

    // 提取行为关键词
    final behaviorKeywords = ['吃药', '吃饭', '运动', '散步', '喝水', '睡觉', '起床', '洗漱', '跑步'];
    String? keyword;
    for (final kw in behaviorKeywords) {
      if (q.contains(kw)) { keyword = kw; break; }
    }
    if (keyword == null && (q.contains('运动') || q.contains('锻炼'))) keyword = '运动';

    if (keyword != null) {
      final matched = _timelineRecords.where((r) => r.content.contains(keyword!)).toList();
      return '您$keyword了${matched.length}次。\n'
          '${matched.isNotEmpty ? "最近一次：" + matched.first.timeStr + " " + matched.first.content : ""}';
    }

    return null;
  }

  /// 购物记录查询
  String? _answerShoppingQuery(String q) {
    if (!q.contains('买') && !q.contains('购物') && !q.contains('超市') &&
        !q.contains('菜') && !q.contains('商店')) {
      return null;
    }
    if (shoppingRecords.isEmpty) return '没有购物记录。';

    return '最近的购物记录：\n'
        '${shoppingRecords.take(3).map((r) => '${r.time.month}/${r.time.day} 在${r.store}买了${r.items.map((i) => '${i.name}${i.quantity}${i.unit}').join("、")}').join('\n')}';
  }

  /// 常识性问题回答
  String? _answerCommonSense(String q) {
    // 天气
    if (q.contains('天气')) {
      return '我暂时无法获取实时天气信息，建议您查看手机自带的天气应用。';
    }
    // 时间
    if (q.contains('几点') || q.contains('现在时间') || q.contains('什么时间')) {
      final now = this.now;
      return '现在是${now.hour}点${now.minute}分。';
    }
    // 日期
    if (q.contains('几号') || q.contains('今天日期') || q.contains('星期几') || q.contains('周几')) {
      final now = this.now;
      final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
      return '今天是${now.year}年${now.month}月${now.day}日，星期${weekdays[now.weekday - 1]}。';
    }
    // 血压
    if (q.contains('血压') && (q.contains('正常') || q.contains('多少') || q.contains('范围'))) {
      return '正常血压范围：\n'
          '• 收缩压（高压）：90-140 mmHg\n'
          '• 舒张压（低压）：60-90 mmHg\n'
          '• 65岁以上老人收缩压可放宽至150 mmHg\n'
          '如有异常，请及时就医。';
    }
    // 血糖
    if (q.contains('血糖') && (q.contains('正常') || q.contains('多少') || q.contains('范围'))) {
      return '正常血糖范围：\n'
          '• 空腹血糖：3.9-6.1 mmol/L\n'
          '• 餐后2小时：<7.8 mmol/L\n'
          '• 糖化血红蛋白：<6.5%\n'
          '如有异常，请及时就医。';
    }
    // 用药
    if (q.contains('吃药') && (q.contains('怎么') || q.contains('注意') || q.contains('饭前饭后'))) {
      return '一般用药建议：\n'
          '• 降血压药：早晨起床后服用\n'
          '• 降血糖药：饭前30分钟服用\n'
          '• 消炎药：饭后服用（减少胃肠刺激）\n'
          '• 安眠药：睡前30分钟服用\n'
          '具体用药请遵医嘱，切勿自行调整。';
    }
    // 饮食
    if ((q.contains('饮食') || q.contains('吃什么') || q.contains('营养')) &&
        (q.contains('注意') || q.contains('建议') || q.contains('怎么'))) {
      return '老年人饮食建议：\n'
          '• 每天饮水1500-1700毫升\n'
          '• 少盐少油（盐<6克/天）\n'
          '• 多吃蔬菜水果（300-500克蔬菜/天）\n'
          '• 适量蛋白质（鸡蛋1个/天，瘦肉50-75克/天）\n'
          '• 补钙（牛奶300毫升/天）\n'
          '• 少食多餐，细嚼慢咽';
    }
    // 运动
    if ((q.contains('运动') || q.contains('锻炼') || q.contains('散步')) &&
        (q.contains('多少') || q.contains('建议') || q.contains('多久') || q.contains('注意'))) {
      return '老年人运动建议：\n'
          '• 每天散步30分钟，步数6000-8000步为宜\n'
          '• 太极拳、八段锦适合老年人\n'
          '• 运动前热身5-10分钟\n'
          '• 避免空腹运动和饭后立即运动\n'
          '• 运动时如感到头晕、胸闷请立即停止\n'
          '• 天气不好时在家做简单拉伸即可';
    }
    // 睡眠
    if (q.contains('睡眠') || q.contains('失眠') || q.contains('睡不着')) {
      return '老年人睡眠建议：\n'
          '• 每天睡眠6-8小时为宜\n'
          '• 晚上10点前入睡最佳\n'
          '• 午睡20-30分钟，不超过1小时\n'
          '• 睡前避免饮茶、咖啡\n'
          '• 睡前可用温水泡脚15分钟\n'
          '• 长期失眠请就医，勿自行服用安眠药';
    }
    // 急救/紧急
    if (q.contains('急救') || q.contains('120') || q.contains('紧急')) {
      return '紧急情况处理：\n'
          '• 突发胸痛：立即停止活动，含服硝酸甘油，拨打120\n'
          '• 脑卒中：保持侧卧，勿搬动头部，拨打120\n'
          '• 跌倒：先评估能否活动，无骨折再缓慢起身\n'
          '• 急救电话：120\n'
          '• 报警电话：110\n'
          '• 火警电话：119';
    }
    // 证件
    if (q.contains('驾照') && (q.contains('到期') || q.contains('换'))) {
      return '驾照到期换证：\n'
          '• 驾照有效期为6年、10年、长期\n'
          '• 到期前90天内可换证\n'
          '• 需携带：身份证、旧驾照、体检表、照片\n'
          '• 可在交管12123 APP在线办理\n'
          '• 70岁以上需每年提交体检证明';
    }
    if (q.contains('身份证') && (q.contains('到期') || q.contains('换') || q.contains('补办'))) {
      return '身份证到期换证：\n'
          '• 身份证有效期为10年（46岁以上为20年，60岁以上为长期）\n'
          '• 到期前3个月可换证\n'
          '• 需携带户口本、旧身份证到户籍所在地派出所\n'
          '• 补办需40元工本费\n'
          '• 一般20个工作日可取';
    }
    return null;
  }

  int _parseWeekday(String day) {
    const map = {'一': 0, '二': 1, '三': 2, '四': 3, '五': 4, '六': 5, '日': 6, '天': 6};
    return map[day] ?? 0;
  }

  // ===== 工具 =====
  int _idCounter = 0;

  String _genId() {
    final now = DateTime.now();
    _idCounter = (_idCounter + 1) % 10000;
    return '${now.millisecondsSinceEpoch}${_idCounter.toString().padLeft(4, '0')}';
  }

  String get todayStr {
    final t = now;
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  // 问候语
  String get greeting {
    final hour = now.hour;
    if (hour >= 12 && hour < 18) return '下午好';
    if (hour >= 18) return '晚上好';
    return '早上好';
  }
}
