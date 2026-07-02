import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/route_names.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/qa/presentation/pages/qa_page.dart';
import 'features/timeline/presentation/pages/timeline_page.dart';
import 'features/agenda/presentation/pages/agenda_page.dart';
import 'shared/themes/app_theme.dart';

class DailyAwarenessApp extends ConsumerWidget {
  const DailyAwarenessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Daily Awareness',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: RouteNames.login,
      routes: {
        RouteNames.login: (context) => const LoginPage(),
        RouteNames.home: (context) => const HomePage(),
        RouteNames.qa: (context) => const QaPage(),
        RouteNames.timeline: (context) => const TimelinePage(),
        RouteNames.agenda: (context) => const AgendaPage(),
      },
    );
  }
}
