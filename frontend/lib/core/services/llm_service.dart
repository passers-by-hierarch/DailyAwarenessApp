import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// LLM 配置
class LlmConfig {
  final bool enabled;
  final String apiKey;
  final String baseUrl;
  final String model;
  final double temperature;
  final int maxTokens;

  const LlmConfig({
    this.enabled = false,
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
    this.temperature = 0.7,
    this.maxTokens = 1000,
  });

  LlmConfig copyWith({
    bool? enabled,
    String? apiKey,
    String? baseUrl,
    String? model,
    double? temperature,
    int? maxTokens,
  }) {
    return LlmConfig(
      enabled: enabled ?? this.enabled,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'model': model,
        'temperature': temperature,
        'maxTokens': maxTokens,
      };

  factory LlmConfig.fromJson(Map<String, dynamic> json) => LlmConfig(
        enabled: json['enabled'] as bool? ?? false,
        apiKey: json['apiKey'] as String? ?? '',
        baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
        model: json['model'] as String? ?? 'gpt-4o-mini',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
        maxTokens: json['maxTokens'] as int? ?? 1000,
      );
}

/// LLM 聊天消息
class ChatMsg {
  final String role;
  final String content;

  const ChatMsg(this.role, this.content);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// 系统提示词 - 面向老年人的日常助手
const String _systemPrompt = '''你是"小爱"，一位贴心的老年人日常助手，温柔、耐心、亲切，像家人一样陪伴用户。

# 你的核心能力
1. **个人记录问答**：基于下方【用户数据上下文】回答关于时间线、事程、物品位置、库存、购买记录、行为习惯等所有关于用户自己的问题
2. **购买物资计算**：能根据库存数量、用户消费习惯（来自时间线）计算物资还够用多久，并可建议设置"用完"提醒
3. **进步与习惯优化**：分析用户历史行为，给出更合理的事程建议（如学习新技能、调整作息、培养习惯）
4. **常规问答**：回答健康、生活、用药、出行等常识性问题
5. **多轮对话**：能记住本会话内的前文，给出连贯自然的回答

# 回答风格
- 使用简洁、口语化的中文，避免专业术语
- 语气亲切、温暖，多用"您"、"咱们"等称呼
- 回答不宜过长，重点突出，必要时用要点列出
- 涉及医疗、用药、疾病的建议，务必提醒"请咨询医生确认"
- 不要凭空编造数据；如果【用户数据上下文】里没有，直接说"我暂时没找到这个记录"并建议怎么记录
- 如果用户想设置提醒、添加事程、记录什么，回复中明确说"好的，已经为您..."并给一个简短确认

# 注意事项
- 数据中日期格式为 YYYY-MM-DD，时间格式为 HH:MM，请基于这些回答
- 用户的【行为记录】可能来自语音或文字输入，内容中可能包含口语化的时间描述（如"下午3点"）
- 当用户问"我上周干了什么"、"我昨天吃了什么"时，请聚合对应日期范围内的记录
- 当用户问"XX东西放在哪"时，请优先匹配【物品位置记录】和【时间线】中的物品位置标签
- 当用户问"XX还有多少"或"能用多久"时，结合【库存记录】和【时间线中的消耗记录】计算
''';

/// LLM 服务
///
/// 支持 OpenAI 兼容接口（智谱、DeepSeek、通义千问等）
/// 支持流式和非流式响应
class LlmService {
  static const String _prefsKey = 'llm_config';
  /// 连接超时
  static const Duration _connectTimeout = Duration(seconds: 10);
  /// 请求超时
  static const Duration _requestTimeout = Duration(seconds: 30);
  /// 流式读取超时
  static const Duration _streamTimeout = Duration(seconds: 60);
  /// 最大重试次数
  static const int _maxRetries = 2;
  /// 重试延迟
  static const Duration _retryDelay = Duration(seconds: 1);

  LlmConfig _config = const LlmConfig();
  SharedPreferences? _prefs;

  LlmConfig get config => _config;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonStr = _prefs!.getString(_prefsKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        // API Key 使用 Base64 编码存储，避免明文出现在存储中
        final apiKey = decoded['apiKey'] as String? ?? '';
        if (apiKey.isNotEmpty && !_isBase64Encoded(apiKey)) {
          // 兼容旧版明文数据，迁移为编码存储
          decoded['apiKey'] = _encodeApiKey(apiKey);
          await _prefs!.setString(_prefsKey, jsonEncode(decoded));
        }
        // 解码使用
        if (apiKey.isNotEmpty && _isBase64Encoded(apiKey)) {
          decoded['apiKey'] = _decodeApiKey(apiKey);
        }
        _config = LlmConfig.fromJson(decoded);
      } catch (e) {
        debugPrint('LLM 配置加载失败: $e');
        _config = const LlmConfig();
      }
    }
  }

  Future<void> saveConfig(LlmConfig config) async {
    _config = config;
    // API Key 使用 Base64 编码存储
    final encodedConfig = config.copyWith(
      apiKey: _encodeApiKey(config.apiKey),
    );
    await _prefs?.setString(_prefsKey, jsonEncode(encodedConfig.toJson()));
  }

  static bool _isBase64Encoded(String s) {
    if (s.isEmpty) return false;
    try {
      // round-trip 检查：解码后再编码若等于原字符串，说明是合法的 base64 编码
      final decoded = utf8.decode(base64.decode(s));
      return decoded != s && base64.encode(utf8.encode(decoded)) == s;
    } catch (_) {
      return false;
    }
  }

  static String _encodeApiKey(String key) {
    if (key.isEmpty) return '';
    return base64.encode(utf8.encode(key));
  }

  static String _decodeApiKey(String encoded) {
    if (encoded.isEmpty) return '';
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (_) {
      return encoded;
    }
  }

  /// 使用指定配置进行测试连接（不保存到本地）
  Future<String> testWithConfig(LlmConfig config, List<ChatMsg> messages) async {
    final original = _config;
    _config = config;
    try {
      return await chat(messages);
    } finally {
      _config = original;
    }
  }

  bool get isConfigured =>
      _config.enabled && _config.apiKey.isNotEmpty && _config.baseUrl.isNotEmpty;

  /// 带超时和重试的 HTTP POST 请求
  Future<http.Response> _postWithRetry({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await http
            .post(uri, headers: headers, body: body)
            .timeout(_requestTimeout);
        // 5xx 错误可重试
        if (response.statusCode >= 500 && attempt <= _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
        return response;
      } on TimeoutException {
        if (attempt > _maxRetries) rethrow;
        await Future.delayed(_retryDelay * attempt);
      } on http.ClientException catch (e) {
        // 网络中断等可重试错误
        if (attempt > _maxRetries) rethrow;
        debugPrint('HTTP 请求失败（第$attempt次）: $e，重试中...');
        await Future.delayed(_retryDelay * attempt);
      }
    }
  }

  /// 流式聊天 - 返回 stream，每个事件是当前已生成的完整文本
  Stream<String> chatStream(List<ChatMsg> messages) {
    if (!isConfigured) {
      return Stream.error('LLM 未配置');
    }

    final controller = StreamController<String>();
    final buffer = StringBuffer();

    () async {
      String lineBuffer = ''; // 跨 chunk 的行缓冲
      try {
        final body = jsonEncode({
          'model': _config.model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ...messages.map((m) => m.toJson()),
          ],
          'temperature': _config.temperature,
          'max_tokens': _config.maxTokens,
          'stream': true,
        });

        final uri = Uri.parse('${_config.baseUrl}/chat/completions');

        final request = http.Request('POST', uri);
        request.headers['Content-Type'] = 'application/json';
        request.headers['Authorization'] = 'Bearer ${_config.apiKey}';
        request.headers['Accept'] = 'text/event-stream';
        request.body = body;

        final response = await request.send().timeout(_requestTimeout);

        if (response.statusCode != 200) {
          final errorBody = await response.stream.bytesToString();
          controller.addError('API 错误 (${response.statusCode}): $errorBody');
          controller.close();
          return;
        }

        response.stream.transform(utf8.decoder).timeout(_streamTimeout).listen(
          (chunk) {
            // 合并行缓冲，按 \n 分割，最后一段可能不完整，保留到下次
            final combined = lineBuffer + chunk;
            final lines = combined.split('\n');
            lineBuffer = lines.removeLast();
            for (final line in lines) {
              _processSseLine(line.trim(), buffer, controller);
            }
          },
          onDone: () {
            // 处理缓冲区中剩余的最后一行
            if (lineBuffer.trim().isNotEmpty) {
              _processSseLine(lineBuffer.trim(), buffer, controller);
            }
            controller.close();
          },
          onError: (e) {
            controller.addError('网络错误：$e');
            controller.close();
          },
          cancelOnError: true,
        );
      } catch (e) {
        controller.addError(e.toString());
        controller.close();
      }
    }();

    return controller.stream;
  }

  /// 处理单行 SSE 数据
  void _processSseLine(String trimmed, StringBuffer buffer, StreamController<String> controller) {
    if (!trimmed.startsWith('data:')) return;
    final data = trimmed.substring(5).trim();
    if (data == '[DONE]') return;
    if (data.isEmpty) return;
    try {
      final json = jsonDecode(data);
      final delta = json['choices']?[0]?['delta']?['content'] as String?;
      if (delta != null && delta.isNotEmpty) {
        buffer.write(delta);
        controller.add(buffer.toString());
      }
    } catch (e) {
      // 忽略单行解析错误，可能是不完整的 JSON 或心跳
      debugPrint('SSE 解析单行失败（可忽略）: $e');
    }
  }

  /// 非流式聊天
  Future<String> chat(List<ChatMsg> messages) async {
    if (!isConfigured) {
      throw 'LLM 未配置';
    }

    final body = jsonEncode({
      'model': _config.model,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        ...messages.map((m) => m.toJson()),
      ],
      'temperature': _config.temperature,
      'max_tokens': _config.maxTokens,
    });

    final uri = Uri.parse('${_config.baseUrl}/chat/completions');

    final response = await _postWithRetry(
      uri: uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_config.apiKey}',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw 'API 错误 (${response.statusCode}): ${response.body}';
    }

    final json = jsonDecode(response.body);
    return json['choices']?[0]?['message']?['content'] as String? ?? '';
  }

  Future<AgendaCompletionResult> analyzeAgendaCompletion(
    String agendaContent,
    String userInput,
  ) async {
    if (!isConfigured) {
      return AgendaCompletionResult(
        isCompleted: _heuristicCompletionCheck(agendaContent, userInput),
        confidence: 0.5,
        reason: 'LLM未配置，使用规则判断',
        postponedMinutes: null,
      );
    }

    final prompt = '''你是一个智能助手，负责分析用户的语音/文字输入是否表示已完成某个事程。

## 判断规则：
1. 只有用户明确表示已完成（如"吃了"、"做完了"、"已经吃药了"），才判断为完成
2. 如果用户说"记得吃药"、"该吃药了"、"还没吃"等，判断为未完成
3. 如果用户提到"晚一点"、"稍后"、"明天"等，判断为推迟，并提取推迟时间

## 输入：
- 事程内容：$agendaContent
- 用户输入：$userInput

## 输出格式（JSON）：
{
  "is_completed": true/false,
  "confidence": 0.0-1.0,
  "reason": "简短说明判断理由",
  "postponed_minutes": null/数字（如果推迟，单位分钟）
}''';

    final body = jsonEncode({
      'model': _config.model,
      'messages': [
        {'role': 'system', 'content': '你是一个精确的事程完成判断助手，只输出JSON格式结果'},
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.1,
      'max_tokens': 200,
    });

    final uri = Uri.parse('${_config.baseUrl}/chat/completions');

    try {
      final response = await _postWithRetry(
        uri: uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.apiKey}',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final content = json['choices']?[0]?['message']?['content'] as String?;
        if (content != null) {
          try {
            final result = jsonDecode(content);
            return AgendaCompletionResult(
              isCompleted: result['is_completed'] ?? false,
              confidence: (result['confidence'] ?? 0.5).toDouble(),
              reason: result['reason'] ?? 'AI判断',
              postponedMinutes: result['postponed_minutes'] is num
                  ? (result['postponed_minutes'] as num).toInt()
                  : null,
            );
          } catch (e) {
            debugPrint('分析事程完成-JSON解析失败: $e');
            return AgendaCompletionResult(
              isCompleted: _heuristicCompletionCheck(agendaContent, userInput),
              confidence: 0.5,
              reason: '解析失败，使用规则判断',
              postponedMinutes: null,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('分析事程完成-请求失败: $e');
    }

    return AgendaCompletionResult(
      isCompleted: _heuristicCompletionCheck(agendaContent, userInput),
      confidence: 0.5,
      reason: '请求失败，使用规则判断',
      postponedMinutes: null,
    );
  }

  bool _heuristicCompletionCheck(String agenda, String input) {
    final lower = input.toLowerCase();
    final completedKeywords = ['完成', '吃了', '做了', '已经', '好了', '做完', '吃完'];
    final pendingKeywords = ['记得', '该', '要', '还没', '没有', '没吃', '没做'];
    return completedKeywords.any(lower.contains) && !pendingKeywords.any(lower.contains);
  }
}

class AgendaCompletionResult {
  final bool isCompleted;
  final double confidence;
  final String reason;
  final int? postponedMinutes;

  const AgendaCompletionResult({
    required this.isCompleted,
    required this.confidence,
    required this.reason,
    this.postponedMinutes,
  });
}
