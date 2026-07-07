import 'dart:async';
import 'package:flutter/foundation.dart';

/// TTS 语音朗读服务
/// 注：当前为简化实现，使用 MethodChannel 调用原生 Android TTS
/// 实际项目中可集成 flutter_tts 包
class TtsService {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._();

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  final _speakingStateController = StreamController<bool>.broadcast();
  Stream<bool> get speakingState => _speakingStateController.stream;

  /// 朗读文本
  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await stop();
    }
    _isSpeaking = true;
    _speakingStateController.add(true);

    try {
      // 实际集成 flutter_tts 时的代码：
      // await FlutterTts().setLanguage('zh-CN');
      // await FlutterTts().setSpeechRate(0.4);
      // await FlutterTts().speak(text);
      debugPrint('[TTS] 开始朗读: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');

      // 模拟朗读时长（按字数估算）
      final duration = Duration(milliseconds: (text.length * 200).clamp(1000, 15000));
      await Future.delayed(duration);
    } finally {
      _isSpeaking = false;
      _speakingStateController.add(false);
    }
  }

  /// 停止朗读
  Future<void> stop() async {
    _isSpeaking = false;
    _speakingStateController.add(false);
    debugPrint('[TTS] 停止朗读');
  }

  /// 释放资源
  void dispose() {
    _speakingStateController.close();
  }
}
