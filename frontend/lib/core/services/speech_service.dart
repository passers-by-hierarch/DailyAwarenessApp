import 'dart:async';
import 'package:flutter/foundation.dart';

/// 语音识别服务
/// 当前为模拟实现，集成 speech_to_text 后即可使用真实识别
class SpeechService {
  static final SpeechService _instance = SpeechService._();
  factory SpeechService() => _instance;
  SpeechService._();

  bool _isAvailable = true;
  bool _isListening = false;
  String _lastResult = '';

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastResult => _lastResult;

  final _resultController = StreamController<String>.broadcast();
  Stream<String> get resultStream => _resultController.stream;

  final _stateController = StreamController<bool>.broadcast();
  Stream<bool> get stateStream => _stateController.stream;

  /// 初始化语音识别
  Future<bool> initialize() async {
    // 实际集成 speech_to_text 时的代码：
    // _speech = SpeechToText();
    // _isAvailable = await _speech.initialize(
    //   onStatus: (status) => _stateController.add(status == 'listening'),
    //   onError: (error) => debugPrint('语音识别错误: $error'),
    // );
    _isAvailable = true;
    return _isAvailable;
  }

  /// 开始监听
  Future<void> startListening({Duration? autoStop}) async {
    if (!_isAvailable || _isListening) return;

    _isListening = true;
    _stateController.add(true);
    _lastResult = '';

    debugPrint('[Speech] 开始监听');

    // 实际集成 speech_to_text 时的代码：
    // await _speech.listen(
    //   onResult: (result) {
    //     _lastResult = result.recognizedWords;
    //     _resultController.add(result.recognizedWords);
    //   },
    //   localeId: 'zh_CN',
    //   listenMode: ListenMode.dictation,
    // );

    // 模拟识别过程（每秒输出一个字的进度）
    _simulateRecognition();
  }

  /// 停止监听
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    _stateController.add(false);

    // 实际集成：await _speech.stop();
    debugPrint('[Speech] 停止监听，结果: $_lastResult');

    if (_lastResult.isEmpty) {
      // 模拟识别结果
      _lastResult = _getMockResult();
    }
    _resultController.add(_lastResult);
  }

  /// 取消监听（不保存结果）
  Future<void> cancelListening() async {
    _isListening = false;
    _stateController.add(false);
    _lastResult = '';
    debugPrint('[Speech] 取消监听');
  }

  /// 模拟识别过程
  void _simulateRecognition() {
    // 模拟实时识别输出
    final mockText = _getMockResult();
    int charIndex = 0;

    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isListening || charIndex >= mockText.length) {
        timer.cancel();
        return;
      }
      charIndex++;
      _lastResult = mockText.substring(0, charIndex);
      _resultController.add(_lastResult);
    });
  }

  String _getMockResult() {
    final samples = [
      '我刚喝了水',
      '记得下午3点吃药',
      '把钥匙放在玄关',
      '在超市买了牛奶和面包',
      '今天散步了30分钟',
      '吃了降压药',
      '中午吃了米饭和青菜',
      '刚起床洗漱完',
    ];
    return samples[DateTime.now().second % samples.length];
  }

  void dispose() {
    _resultController.close();
    _stateController.close();
  }
}
