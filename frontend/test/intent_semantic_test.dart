import 'package:flutter_test/flutter_test.dart';
import 'package:daily_awareness/core/services/intent_recognition_service.dart';
import 'package:daily_awareness/core/services/llm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences mock
class FakeSharedPreferences implements SharedPreferences {
  final Map<String, dynamic> _data = {};

  @override
  dynamic get(String key) => _data[key];

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  double? getDouble(String key) => _data[key] as double?;

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  @override
  Set<String> getKeys() => _data.keys.toSet();

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  Future<bool> commit() async => true;

  @override
  Future<void> reload() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences
  SharedPreferences.setMockInitialValues({});

  group('语义拆解测试', () {
    late IntentRecognitionService service;

    setUpAll(() async {
      // 创建一个未配置LLM的服务，使用规则匹配
      service = IntentRecognitionService(LlmService());
      await service.init();
    });

    test('多日期拆分 - "明天和后天早上都煮粥"', () async {
      // 核心测试：明天和后天早上都煮粥
      final result = await service.recognize('明天和后天早上都煮粥');

      print('\n=== 多日期拆解结果 ===');
      print('输入: "明天和后天早上都煮粥"');
      print('来源: ${result.source}');
      print('原因: ${result.reason}');
      print('时间槽数量: ${result.timelineSlots.length}');
      
      for (var i = 0; i < result.timelineSlots.length; i++) {
        final slot = result.timelineSlots[i];
        print('\n时间槽$i:');
        print('  时间: ${slot.time}');
        for (final intent in slot.intents) {
          print('  意图: ${intent.type}');
          print('  槽值: ${intent.slots}');
          print('  置信度: ${intent.confidence}');
        }
      }

      // 验证
      expect(result.timelineSlots.length, equals(2), reason: '应该拆分为2个时间槽（明天和后天）');

      // 检查第一个时间槽（明天）
      final slot1 = result.timelineSlots[0];
      expect(slot1.intents.any((i) => i.type == IntentType.agendaCreate), true, reason: '应该是创建事程意图');
      final agenda1 = slot1.intents.firstWhere((i) => i.type == IntentType.agendaCreate);
      expect(agenda1.slots['date_offset'], equals(1), reason: '第一个应该是明天(date_offset=1)');
      expect(agenda1.slots['content'], contains('煮粥'), reason: '内容应该包含"煮粥"');

      // 检查第二个时间槽（后天）
      final slot2 = result.timelineSlots[1];
      final agenda2 = slot2.intents.firstWhere((i) => i.type == IntentType.agendaCreate);
      expect(agenda2.slots['date_offset'], equals(2), reason: '第二个应该是后天(date_offset=2)');
    });

    test('单日期 - "明天早上煮粥"', () async {
      final result = await service.recognize('明天早上煮粥');

      print('\n=== 单日期结果 ===');
      print('输入: "明天早上煮粥"');
      print('时间槽数量: ${result.timelineSlots.length}');

      expect(result.timelineSlots.length, equals(1), reason: '单日期应该只有1个时间槽');

      final slot = result.timelineSlots[0];
      print('时间: ${slot.time}');
      
      // 时间应该是07:00（早上）
      expect(slot.time, equals('07:00'), reason: '时间应该是07:00（早上）');

      final agenda = slot.intents.firstWhere((i) => i.type == IntentType.agendaCreate);
      expect(agenda.slots['content'], contains('煮粥'), reason: '内容应该包含"煮粥"');
      expect(agenda.slots['date_offset'], equals(1), reason: '日期偏移应该是1（明天）');
    });

    test('三日期拆分 - "今天明天和后天都要吃药"', () async {
      final result = await service.recognize('今天明天和后天都要吃药');

      print('\n=== 三日期拆解结果 ===');
      print('输入: "今天明天和后天都要吃药"');
      print('时间槽数量: ${result.timelineSlots.length}');

      expect(result.timelineSlots.length, equals(3), reason: '应该拆分为3个时间槽');

      // 检查日期偏移
      final offsets = result.timelineSlots.map((s) {
        final agenda = s.intents.firstWhere((i) => i.type == IntentType.agendaCreate);
        return agenda.slots['date_offset'] as int;
      }).toList();

      print('日期偏移: $offsets');
      expect(offsets.contains(0), true, reason: '应该包含今天(0)');
      expect(offsets.contains(1), true, reason: '应该包含明天(1)');
      expect(offsets.contains(2), true, reason: '应该包含后天(2)');
    });

    test('模糊时间 - "晚上看电视"', () async {
      final result = await service.recognize('准备晚上看电视');

      print('\n=== 模糊时间结果 ===');
      print('输入: "准备晚上看电视"');
      print('时间槽数量: ${result.timelineSlots.length}');

      if (result.timelineSlots.isNotEmpty) {
        final slot = result.timelineSlots[0];
        print('时间: ${slot.time}');
        // 晚上应该映射为19:00
        expect(slot.time, equals('19:00'), reason: '晚上应该映射为19:00');
      }
    });

    test('模式学习验证', () async {
      // 先清空模式
      await service.clearPatterns();
      
      // 添加一个新模式
      await service.addPattern('测试煮粥', [
        TimelineSlot(time: '08:00', intents: [
          IntentItem(type: IntentType.agendaCreate, slots: {'content': '煮粥'}, confidence: 0.9)
        ])
      ]);

      // 获取所有模式
      final patterns = service.allPatterns;
      print('\n=== 模式学习结果 ===');
      print('模式数量: ${patterns.length}');
      
      if (patterns.isNotEmpty) {
        print('第一个模式: ${patterns.first.inputText}');
        print('出现次数: ${patterns.first.count}');
      }

      expect(patterns.isNotEmpty, true, reason: '应该有模式存在');
      
      // 清理
      await service.clearPatterns();
    });
  });
}