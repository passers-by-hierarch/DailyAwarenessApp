import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/storage/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化安全存储
  await SecureStorage.initialize();

  runApp(
    const ProviderScope(
      child: DailyAwarenessApp(),
    ),
  );
}
