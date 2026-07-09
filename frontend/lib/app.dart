import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'core/constants/route_names.dart';
import 'layouts/main_layout.dart';
import 'shared/themes/app_theme.dart';
import 'features/agenda/presentation/pages/agenda_detail_page.dart';
import 'features/agenda/presentation/pages/edit_agenda_page.dart';
import 'features/agenda/presentation/pages/frequent_agenda_page.dart';
import 'features/timeline/presentation/pages/timeline_detail_page.dart';
import 'features/items/presentation/pages/items_page.dart';
import 'features/items/presentation/pages/item_detail_page.dart';
import 'features/shopping/presentation/pages/shopping_page.dart';
import 'features/profile/presentation/pages/family_page.dart';
import 'features/profile/presentation/pages/emergency_settings_page.dart';
import 'features/profile/presentation/pages/reminder_rules_page.dart';
import 'features/profile/presentation/pages/quiet_hours_page.dart';
import 'features/profile/presentation/pages/report_export_page.dart';
import 'features/profile/presentation/pages/health_devices_page.dart';
import 'features/profile/presentation/pages/privacy_security_page.dart';
import 'features/profile/presentation/pages/preferences_page.dart';
import 'features/profile/presentation/pages/about_help_page.dart';
import 'features/analytics/presentation/pages/weekly_report_page.dart';
import 'features/analytics/presentation/pages/behavior_analysis_page.dart';
import 'features/ask/presentation/pages/chat_history_page.dart';
import 'features/profile/presentation/pages/ai_settings_page.dart';
import 'features/tags/presentation/pages/tag_management_page.dart';
import 'features/profile/presentation/pages/intent_training_page.dart';

class DailyAwarenessApp extends StatelessWidget {
  const DailyAwarenessApp({super.key});

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'zh_CN';
    return MaterialApp(
      title: '日常意识助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainLayout(),
      routes: {
        RouteNames.agendaDetail: (ctx) => const AgendaDetailPage(),
        RouteNames.editAgenda: (ctx) => const EditAgendaPage(),
        RouteNames.frequentAgenda: (ctx) => const FrequentAgendaPage(),
        RouteNames.timelineDetail: (ctx) => const TimelineDetailPage(),
        RouteNames.items: (ctx) => const ItemsPage(),
        RouteNames.itemDetail: (ctx) => const ItemDetailPage(),
        RouteNames.shopping: (ctx) => const ShoppingPage(),
        RouteNames.family: (ctx) => const FamilyPage(),
        RouteNames.emergencySettings: (ctx) => const EmergencySettingsPage(),
        RouteNames.reminderRules: (ctx) => const ReminderRulesPage(),
        RouteNames.quietHours: (ctx) => const QuietHoursPage(),
        RouteNames.reportExport: (ctx) => const ReportExportPage(),
        RouteNames.healthDevices: (ctx) => const HealthDevicesPage(),
        RouteNames.privacySecurity: (ctx) => const PrivacySecurityPage(),
        RouteNames.preferences: (ctx) => const PreferencesPage(),
        RouteNames.aboutHelp: (ctx) => const AboutHelpPage(),
        RouteNames.weeklyReport: (ctx) => const WeeklyReportPage(),
        RouteNames.behaviorAnalysis: (ctx) => const BehaviorAnalysisPage(),
        RouteNames.chatHistory: (ctx) => const ChatHistoryPage(),
        RouteNames.aiSettings: (ctx) => const AiSettingsPage(),
        RouteNames.tagManagement: (ctx) => const TagManagementPage(),
        RouteNames.intentTraining: (ctx) => const IntentTrainingPage(),
      },
    );
  }
}
