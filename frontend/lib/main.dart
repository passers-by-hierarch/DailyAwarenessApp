import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/speech_service.dart';
import 'core/services/storage_service.dart';
import 'core/state/app_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地存储
  await StorageService().init();
  // 初始化语音识别
  await SpeechService().initialize();
  // 初始化通知服务
  await NotificationService().initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStore(),
      child: const DailyAwarenessApp(),
    ),
  );
}
