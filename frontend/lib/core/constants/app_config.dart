class AppConfig {
  AppConfig._();

  // API配置
  static const String baseUrl = 'http://localhost:8080/api/v1';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // 分页配置
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // 缓存配置
  static const int cacheMaxAge = 3600; // 秒
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';

  // 语音配置
  static const int maxRecordingDuration = 60; // 秒
  static const String defaultLanguage = 'zh-CN';

  // 问答配置
  static const double minConfidenceThreshold = 0.5;
  static const int maxQaHistory = 100;
}
