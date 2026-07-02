import 'package:dio/dio.dart';
import '../constants/app_config.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _authInterceptor(),
      _logInterceptor(),
      _errorInterceptor(),
    ]);
  }
  late final Dio dio;

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await SecureStorage.clearToken();
        }
        handler.next(error);
      },
    );
  }

  Interceptor _logInterceptor() {
    return LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => debugPrint(object.toString()),
    );
  }

  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        String message;
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            message = '连接超时，请检查网络';
            break;
          case DioExceptionType.connectionError:
            message = '网络连接失败';
            break;
          case DioExceptionType.badResponse:
            final data = error.response?.data;
            message = data?['message']?.toString() ?? '请求失败';
            break;
          default:
            message = '未知错误';
        }
        error = error.copyWith(message: message);
        handler.next(error);
      },
    );
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
