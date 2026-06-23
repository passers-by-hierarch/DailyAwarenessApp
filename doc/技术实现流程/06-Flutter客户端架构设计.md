# 06 - Flutter客户端架构设计

## 1. 项目结构

### 1.1 整体目录结构

```
daily_assistant/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── app.dart                     # App配置（主题、路由、依赖注入）
│   │
│   ├── core/                        # 核心基础设施
│   │   ├── constants/               # 常量定义
│   │   │   ├── app_colors.dart      # 颜色系统
│   │   │   ├── app_strings.dart     # 字符串常量
│   │   │   ├── app_config.dart      # 应用配置
│   │   │   └── route_names.dart     # 路由名称
│   │   │
│   │   ├── errors/                  # 错误处理
│   │   │   ├── exceptions.dart      # 自定义异常
│   │   │   ├── failures.dart        # 业务失败类型
│   │   │   └── error_handler.dart   # 全局错误处理
│   │   │
│   │   ├── network/                 # 网络层
│   │   │   ├── api_client.dart      # Retrofit API客户端
│   │   │   ├── interceptors.dart    # Dio拦截器（认证、日志、重试）
│   │   │   ├── api_result.dart      # 统一响应封装
│   │   │   └── connectivity_checker.dart # 网络状态检测
│   │   │
│   │   ├── storage/                 # 本地存储
│   │   │   ├── database_helper.dart # SQLite数据库
│   │   │   ├── hive_helper.dart     # Hive缓存
│   │   │   └── secure_storage.dart  # 安全存储（Token等）
│   │   │
│   │   ├── utils/                   # 工具类
│   │   │   ├── date_utils.dart      # 日期时间工具
│   │   │   ├── logger.dart          # 日志工具
│   │   │   ├── validators.dart      # 表单验证
│   │   │   ├── audio_utils.dart     # 音频处理工具
│   │   │   └── time_parser.dart     # 时间表达式解析
│   │   │
│   │   └── di/                      # 依赖注入配置
│   │       └── providers.dart       # Riverpod Provider定义
│   │
│   ├── features/                    # 功能模块（按领域划分）
│   │   ├── auth/                    # 认证模块
│   │   │   ├── data/
│   │   │   │   ├── models/          # API响应模型
│   │   │   │   │   ├── login_response.dart
│   │   │   │   │   ├── register_response.dart
│   │   │   │   │   └── user_model.dart
│   │   │   │   ├── repositories/    # 数据仓库实现
│   │   │   │   │   └── auth_repository_impl.dart
│   │   │   │   └── datasources/     # 数据源
│   │   │   │       ├── remote_auth_datasource.dart
│   │   │   │       └── local_auth_datasource.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/        # 领域实体
│   │   │   │   │   └── user.dart
│   │   │   │   ├── repositories/    # 仓库接口
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases/        # 用例
│   │   │   │       ├── login_usecase.dart
│   │   │   │       ├── register_usecase.dart
│   │   │   │       └── send_verify_code_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── pages/           # 页面
│   │   │       │   ├── login_page.dart
│   │   │       │   ├── register_page.dart
│   │   │       │   └── phone_verify_page.dart
│   │   │       ├── widgets/         # 组件
│   │   │       │   ├── phone_input_field.dart
│   │   │       │   └── verify_code_field.dart
│   │   │       └── providers/       # 状态管理
│   │   │           └── auth_provider.dart
│   │   │
│   │   ├── timeline/                # 时间线模块
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── agenda/                  # 事程模块
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── voice/                   # 语音输入模块
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── reminder/                # 提醒模块
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── analytics/               # 分析模块
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   └── settings/                # 设置模块
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │
│   ├── shared/                      # 共享组件
│   │   ├── widgets/                 # 共享UI组件
│   │   │   ├── voice_button.dart    # 语音按钮
│   │   │   ├── voice_waveform.dart  # 语音波形
│   │   │   ├── timeline_item.dart   # 时间线项
│   │   │   ├── agenda_card.dart     # 事程卡片
│   │   │   ├── status_pill.dart     # 状态标签
│   │   │   ├── rule_setting_card.dart # 规则设置卡片
│   │   │   ├── toggle_switch.dart   # 开关组件
│   │   │   ├── segment_control.dart # 分段控制器
│   │   │   ├── loading_indicator.dart # 加载指示器
│   │   │   └── error_state_widget.dart # 错误状态
│   │   ├── providers/               # 共享状态
│   │   │   ├── app_state_provider.dart      # 应用全局状态
│   │   │   ├── user_provider.dart          # 用户状态
│   │   │   └── connectivity_provider.dart  # 网络连接状态
│   │   └── themes/                  # 主题配置
│   │       ├── app_theme.dart       # 主题定义
│   │       ├── dark_theme.dart      # 暗色主题
│   │       └── typography.dart      # 字体样式
│   │
│   ├── services/                    # 后台服务
│   │   ├── background_sync_service.dart    # 后台同步
│   │   ├── notification_service.dart       # 通知服务
│   │   ├── voice_recording_service.dart    # 录音服务
│   │   ├── location_service.dart           # 位置服务
│   │   ├── oss_upload_service.dart         # OSS上传
│   │   └── web_socket_service.dart         # WebSocket连接
│   │
│   └── l10n/                        # 国际化
│       ├── app_localizations.dart
│       ├── strings_zh_CN.arb
│       └── strings_en_US.arb
│
├── assets/                          # 资源文件
│   ├── fonts/
│   │   ├── InstrumentSans-Regular.ttf
│   │   ├── InstrumentSans-Bold.ttf
│   │   └── GeistMono-Regular.ttf
│   ├── images/
│   │   ├── ic_notification.png
│   │   └── splash.png
│   ├── sounds/
│   │   └── reminder_sound.wav
│   │
├── test/                            # 测试
│   ├── unit/                        # 单元测试
│   │   ├── date_utils_test.dart
│   │   ├── time_parser_test.dart
│   │   └── match_engine_test.dart
│   ├── widget/                      # Widget测试
│   │   ├── voice_button_test.dart
│   │   └── timeline_item_test.dart
│   └── integration/                 # 集成测试
│       └── login_flow_test.dart
│
├── pubspec.yaml                     # 依赖配置
├── build.yaml                       # 构建配置（json_serializable等）
└── analysis_options.yaml            # 代码分析配置
```

### 1.2 核心文件说明

#### main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化依赖
  await initializeDependencies();
  
  // 初始化本地存储
  await HiveHelper.initialize();
  await DatabaseHelper.instance.database;
  
  // 初始化通知服务
  await NotificationService().initialize();
  
  // 初始化后台服务
  await BackgroundSyncService().initialize();
  
  runApp(ProviderScope(
    child: MyApp(),
  ));
}
```

#### app.dart

```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    
    return MaterialApp(
      title: '私人助理',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,
      locale: appState.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: appState.isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/timeline': (context) => TimelinePage(),
        '/agenda': (context) => AgendaPage(),
        '/analytics': (context) => AnalyticsPage(),
        '/settings': (context) => SettingsPage(),
      },
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      builder: (context, child) {
        return ErrorHandlerWidget(child: child!);
      },
    );
  }
}
```

---

## 2. 状态管理架构（Riverpod）

### 2.1 Provider定义规范

```dart
// lib/core/di/providers.dart

// 1. Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localDataSource = ref.watch(localAuthDataSourceProvider);
  return AuthRepositoryImpl(apiClient, localDataSource);
});

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localDataSource = ref.watch(localTimelineDataSourceProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  return TimelineRepositoryImpl(apiClient, localDataSource, syncQueue);
});

// 2. UseCase Providers
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return LoginUseCase(repo);
});

final createTimelineUseCaseProvider = Provider<CreateTimelineUseCase>((ref) {
  final repo = ref.watch(timelineRepositoryProvider);
  final matchEngine = ref.watch(matchEngineProvider);
  return CreateTimelineUseCase(repo, matchEngine);
});

// 3. State Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final useCase = ref.watch(loginUseCaseProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(useCase, storage);
});

final timelineProvider = StateNotifierProvider<TimelineNotifier, TimelineState>((ref) {
  final useCase = ref.watch(getTimelineUseCaseProvider);
  return TimelineNotifier(useCase);
});

// 4. Service Providers
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
  ));
  
  // 添加拦截器
  dio.interceptors.add(AuthInterceptor());
  dio.interceptors.add(LoggingInterceptor());
  dio.interceptors.add(ErrorInterceptor());
  
  return dio;
});

final syncQueueProvider = Provider<SyncQueueService>((ref) {
  final localDataSource = ref.watch(localSyncDataSourceProvider);
  return SyncQueueService(localDataSource);
});
```

### 2.2 状态类定义示例

```dart
// lib/features/timeline/presentation/providers/timeline_provider.dart

@immutable
class TimelineState {
  final List<TimelineRecord> records;
  final bool isLoading;
  final bool isRecording;
  final String? error;
  final int matchedCount;
  final int unmatchedCount;
  
  const TimelineState({
    this.records = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.error,
    this.matchedCount = 0,
    this.unmatchedCount = 0,
  });
  
  TimelineState copyWith({
    List<TimelineRecord>? records,
    bool? isLoading,
    bool? isRecording,
    String? error,
    int? matchedCount,
    int? unmatchedCount,
  }) {
    return TimelineState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      error: error,
      matchedCount: matchedCount ?? this.matchedCount,
      unmatchedCount: unmatchedCount ?? this.unmatchedCount,
    );
  }
  
  // 计算属性：匹配率
  double get matchRate {
    final total = matchedCount + unmatchedCount;
    return total > 0 ? matchedCount / total : 0;
  }
}

class TimelineNotifier extends StateNotifier<TimelineState> {
  final GetTimelineUseCase _getTimelineUseCase;
  final CreateTimelineUseCase _createTimelineUseCase;
  
  TimelineNotifier(
    this._getTimelineUseCase,
    this._createTimelineUseCase,
  ) : super(const TimelineState());
  
  /// 加载今日时间线
  Future<void> loadTodayRecords() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final records = await _getTimelineUseCase.execute(Today());
      
      final matched = records.where((r) => r.matchedAgendaId != null).length;
      final unmatched = records.length - matched;
      
      state = state.copyWith(
        records: records,
        isLoading: false,
        matchedCount: matched,
        unmatchedCount: unmatched,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// 创建语音记录
  Future<void> createVoiceRecord(File voiceFile) async {
    state = state.copyWith(isRecording: true);
    
    try {
      final record = await _createTimelineUseCase.execute(
        CreateVoiceRecordParams(voiceFile: voiceFile),
      );
      
      // 添加到列表
      state = state.copyWith(
        records: [record, ...state.records],
        isRecording: false,
        matchedCount: state.matchedCount + (record.matchedAgendaId != null ? 1 : 0),
      );
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        error: e.toString(),
      );
    }
  }
  
  /// 创建文字记录
  Future<void> createTextRecord(String content) async {
    try {
      final record = await _createTimelineUseCase.execute(
        CreateTextRecordParams(content: content),
      );
      
      state = state.copyWith(
        records: [record, ...state.records],
        matchedCount: state.matchedCount + (record.matchedAgendaId != null ? 1 : 0),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
```

---

## 3. 主题与样式系统

### 3.1 颜色系统

```dart
// lib/core/constants/app_colors.dart

class AppColors {
  // 主色调
  static const Color primary = Color(0xFF4A7C6F);
  static const Color primaryDark = Color(0xFF3D6B5F);
  static const Color primaryLight = Color(0xFFE8F0ED);
  
  // 强调色
  static const Color accent = Color(0xFFD4A574);
  static const Color accentLight = Color(0xFFF5E6D3);
  
  // 成功/警告/危险
  static const Color success = Color(0xFF6B9E75);
  static const Color warning = Color(0xFFD4A574);
  static const Color danger = Color(0xFFC4706A);
  
  // 背景色
  static const Color background = Color(0xFFF7F5F2);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  
  // 文字色
  static const Color ink = Color(0xFF1E1E1E);
  static const Color inkLight = Color(0xFF8A8A8A);
  static const Color inkLighter = Color(0xFFB8B8B8);
  
  // 分隔线
  static const Color rule = Color(0xFFE0DCD7);
  
  // 状态色
  static const Color statusMatched = Color(0xFF6B9E75);
  static const Color statusPending = Color(0xFFD4A574);
  static const Color statusMissed = Color(0xFFC4706A);
  static const Color statusForced = Color(0xFFC4706A);
}
```

### 3.2 主题定义

```dart
// lib/shared/themes/app_theme.dart

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    backgroundColor: AppColors.background,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundSecondary,
      elevation: 0,
      titleTextStyle: Typography.header1,
      iconTheme: IconThemeData(color: AppColors.ink),
    ),
    cardTheme: CardTheme(
      color: AppColors.backgroundSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: AppColors.primary,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: Typography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: Typography.button,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundSecondary,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.rule),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      hintStyle: Typography.body2.copyWith(color: AppColors.inkLight),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: Typography.body1.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    fontFamily: 'InstrumentSans',
  );
  
  static ThemeData get darkTheme => ThemeData(
    // 暗色主题定义
    // ...
  );
}
```

### 3.3 字体样式

```dart
// lib/shared/themes/typography.dart

class Typography {
  static const TextStyle header1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    fontFamily: 'InstrumentSans',
    letterSpacing: -0.02,
  );
  
  static const TextStyle header2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    fontFamily: 'InstrumentSans',
    letterSpacing: -0.01,
  );
  
  static const TextStyle header3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    fontFamily: 'InstrumentSans',
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    fontFamily: 'InstrumentSans',
    height: 1.5,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    fontFamily: 'InstrumentSans',
    height: 1.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.inkLight,
    fontFamily: 'InstrumentSans',
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    fontFamily: 'InstrumentSans',
    letterSpacing: 0.02,
  );
  
  static const TextStyle mono = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.inkLight,
    fontFamily: 'GeistMono',
  );
}
```

---

## 4. 页面设计

### 4.1 首页设计

```dart
// lib/features/home/presentation/pages/home_page.dart

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // 加载数据
    ref.read(timelineProvider.notifier).loadTodayRecords();
    ref.read(agendaProvider.notifier).loadTodayAgendas();
  }
  
  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineProvider);
    final agendaState = ref.watch(agendaProvider);
    
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(timelineProvider.notifier).loadTodayRecords();
          await ref.read(agendaProvider.notifier).loadTodayAgendas();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // 语音按钮
              VoiceButton(
                onRecordingComplete: () {
                  ref.read(timelineProvider.notifier).loadTodayRecords();
                },
              ),
              
              SizedBox(height: 24),
              
              // 今日统计
              _buildStatusBar(),
              
              SizedBox(height: 24),
              
              // 今日时间线
              _buildTimelineSection(timelineState),
              
              SizedBox(height: 24),
              
              // 待匹配事程
              _buildAgendaSection(agendaState),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(DateTime.now()),
            style: Typography.body2.copyWith(color: AppColors.inkLight),
          ),
          Text(
            '今日概览',
            style: Typography.header2,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
      ],
    );
  }
  
  Widget _buildStatusBar() {
    final timelineState = ref.watch(timelineProvider);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rule),
      ),
      child: Row(
        children: [
          StatusPill(
            type: StatusType.matched,
            label: '已匹配 ${timelineState.matchedCount}',
          ),
          SizedBox(width: 12),
          StatusPill(
            type: StatusType.pending,
            label: '待验证 ${timelineState.unmatchedCount}',
          ),
          SizedBox(width: 12),
          StatusPill(
            type: StatusType.missed,
            label: '已跳过 0',
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimelineSection(TimelineState state) {
    if (state.isLoading) {
      return LoadingIndicator();
    }
    
    if (state.error != null) {
      return ErrorStateWidget(message: state.error!);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(label: '今日时间线'),
        SizedBox(height: 12),
        
        if (state.records.isEmpty)
          EmptyStateWidget(
            icon: Icons.history,
            title: '暂无记录',
            subtitle: '按住下方按钮记录今天的行为',
          )
        else
          TimelineList(records: state.records),
      ],
    );
  }
  
  Widget _buildAgendaSection(AgendaState state) {
    if (state.isLoading) {
      return LoadingIndicator();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(label: '待匹配事程'),
        SizedBox(height: 12),
        
        if (state.agendas.isEmpty)
          EmptyStateWidget(
            icon: Icons.list_alt,
            title: '暂无事程',
            subtitle: '添加今日计划',
          )
        else
          AgendaList(agendas: state.agendas),
      ],
    );
  }
  
  Widget _buildBottomNavigationBar() {
    final currentIndex = ref.watch(appStateProvider).currentTab;
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        ref.read(appStateProvider.notifier).changeTab(index);
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/timeline');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/agenda');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/analytics');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/settings');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '首页',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: '时间线',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: '事程',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: '分析',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: '设置',
        ),
      ],
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.inkLight,
      backgroundColor: AppColors.backgroundSecondary,
      elevation: 0,
    );
  }
  
  String _formatDate(DateTime date) {
    final formatter = DateFormat('MM月dd日 EEEE', 'zh_CN');
    return formatter.format(date);
  }
}
```

### 4.2 共享组件

```dart
// lib/shared/widgets/section_title.dart

class SectionTitle extends StatelessWidget {
  final String label;
  
  const SectionTitle({required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: Typography.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
          ),
        ),
      ],
    );
  }
}

// lib/shared/widgets/status_pill.dart

enum StatusType { matched, pending, missed, forced }

class StatusPill extends StatelessWidget {
  final StatusType type;
  final String label;
  
  const StatusPill({
    required this.type,
    required this.label,
  });
  
  Color get _backgroundColor {
    switch (type) {
      case StatusType.matched:
        return AppColors.primaryLight;
      case StatusType.pending:
        return AppColors.accentLight;
      case StatusType.missed:
      case StatusType.forced:
        return Color(0xFFF5E0DE);
    }
  }
  
  Color get _textColor {
    switch (type) {
      case StatusType.matched:
        return AppColors.primary;
      case StatusType.pending:
        return AppColors.accent;
      case StatusType.missed:
      case StatusType.forced:
        return AppColors.danger;
    }
  }
  
  Color get _dotColor {
    switch (type) {
      case StatusType.matched:
        return AppColors.success;
      case StatusType.pending:
        return AppColors.warning;
      case StatusType.missed:
      case StatusType.forced:
        return AppColors.danger;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _dotColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: Typography.caption.copyWith(
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. 导航与路由

### 5.1 路由配置

```dart
// lib/core/constants/route_names.dart

class RouteNames {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String timeline = '/timeline';
  static const String agenda = '/agenda';
  static const String agendaDetail = '/agenda/detail';
  static const String agendaCreate = '/agenda/create';
  static const String analytics = '/analytics';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String family = '/family';
}
```

### 5.2 路由守卫

```dart
// lib/core/network/interceptors/auth_interceptor.dart

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  
  AuthInterceptor(this._secureStorage);
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 添加Token
    final token = await _secureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token过期，尝试刷新
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await Dio().post(
            '/api/v1/auth/refresh',
            data: {'refreshToken': refreshToken},
          );
          
          final newToken = response.data['data']['accessToken'];
          await _secureStorage.saveToken(newToken);
          
          // 重试原请求
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await Dio().fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          // 刷新失败，清除Token，跳转到登录页
          await _secureStorage.clearTokens();
          // 触发全局登录状态更新
        }
      }
    }
    
    handler.next(err);
  }
}
```

---

## 6. 依赖配置

### 6.1 pubspec.yaml

```yaml
name: daily_assistant
description: 私人助理 - 语音行为记录与温和提醒助手
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.16.0'

dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # 网络请求
  dio: ^5.4.0
  retrofit: ^4.0.0
  json_annotation: ^4.8.0
  
  # 本地存储
  sqflite: ^2.3.0
  hive: ^2.2.0
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0
  
  # 语音
  flutter_sound: ^9.0.0
  audioplayers: ^5.0.0
  
  # 通知
  flutter_local_notifications: ^16.0.0
  
  # 后台任务
  workmanager: ^0.5.0
  
  # 权限
  permission_handler: ^11.0.0
  
  # 日期时间
  intl: ^0.19.0
  timezone: ^0.9.0
  
  # WebSocket
  web_socket_channel: ^2.4.0
  
  # UI
  flutter_slidable: ^3.0.0
  smooth_page_indicator: ^1.1.0
  
  # 状态管理辅助
  freezed_annotation: ^2.4.0
  equatable: ^2.0.0
  
  # 日志
  logger: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # 代码生成
  build_runner: ^2.4.0
  retrofit_generator: ^8.0.0
  json_serializable: ^6.7.0
  riverpod_generator: ^2.3.0
  freezed: ^2.4.0
  
  # 代码分析
  flutter_lints: ^2.0.0
  effective_dart: ^1.0.0
```

### 6.2 build.yaml

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
          any_map: true
          checked: true
      
      retrofit_generator:
        options:
          verbose: true
          nullable: true
      
      riverpod_generator:
        options:
          verbose: true
```

---

## 7. 性能优化策略

### 7.1 列表性能优化

```dart
// 使用ListView.builder + AutomaticKeepAliveClientMixin

class TimelineList extends StatelessWidget {
  final List<TimelineRecord> records;
  
  const TimelineList({required this.records});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return TimelineItem(record: record);
      },
    );
  }
}

class TimelineItem extends StatelessWidget {
  final TimelineRecord record;
  
  const TimelineItem({required this.record});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderLeft: BorderSide(
          color: AppColors.rule,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // 时间点
          Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(right: 16, left: -5),
            decoration: BoxDecoration(
              color: _getStatusColor(record),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.backgroundSecondary, width: 2),
            ),
          ),
          
          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('HH:mm').format(record.timestamp),
                  style: Typography.mono,
                ),
                SizedBox(height: 4),
                Text(
                  record.content,
                  style: Typography.body1,
                ),
                if (record.matchedAgendaId != null)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '已匹配',
                      style: Typography.caption.copyWith(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 7.2 图片缓存与懒加载

```dart
// 使用CachedNetworkImage + 占位符

class AvatarWidget extends StatelessWidget {
  final String? url;
  final double size;
  
  const AvatarWidget({
    this.url,
    this.size = 48,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight,
      ),
      child: url != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: size / 2,
                ),
              ),
            )
          : Icon(
              Icons.person,
              color: AppColors.primary,
              size: size / 2,
            ),
    );
  }
}
```

---

## 8. 测试策略

### 8.1 测试分类

| 测试类型 | 工具 | 覆盖范围 | 频率 |
|---------|------|---------|------|
| **单元测试** | flutter_test | 工具类、算法、状态管理 | 每次提交 |
| **Widget测试** | flutter_test | UI组件渲染、交互 | 每次提交 |
| **集成测试** | flutter_test | 页面流程、API交互 | 每日构建 |
| **E2E测试** | flutter_driver | 完整用户流程 | 版本发布 |

### 8.2 单元测试示例

```dart
// test/unit/time_parser_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_assistant/core/utils/time_parser.dart';

void main() {
  group('TimeParser', () {
    late TimeParser parser;
    
    setUp(() {
      parser = TimeParser();
    });
    
    test('parse "9点30分" should return 09:30', () async {
      final result = await parser.parseTimeExpr(
        '9点30分',
        DateTime(2024, 6, 22),
      );
      
      expect(result?.hour, 9);
      expect(result?.minute, 30);
    });
    
    test('parse "9:30" should return 09:30', () async {
      final result = await parser.parseTimeExpr(
        '9:30',
        DateTime(2024, 6, 22),
      );
      
      expect(result?.hour, 9);
      expect(result?.minute, 30);
    });
    
    test('parse "早上" should return 07:30', () async {
      final result = await parser.parseTimeExpr(
        '早上',
        DateTime(2024, 6, 22),
      );
      
      expect(result?.hour, 7);
      expect(result?.minute, 30);
    });
    
    test('parse null should return null', () async {
      final result = await parser.parseTimeExpr(
        null,
        DateTime(2024, 6, 22),
      );
      
      expect(result, null);
    });
  });
}
```

---

## 9. 下一步

- [07-MVP开发计划与里程碑.md](./07-MVP开发计划与里程碑.md) - 开发计划与里程碑