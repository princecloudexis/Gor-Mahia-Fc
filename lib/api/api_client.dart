import 'dart:async';
import 'package:dio/dio.dart';
import 'package:eventsbooking/utils/app_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio dio;
  static const String _apiBaseUrl =
      'https://footballclub.staging-workhub.com/api';

  // Cache SharedPreferences instance
  SharedPreferences? _prefs;

  ApiClient(this.dio) {
    dio.options = BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          _prefs ??= await SharedPreferences.getInstance();
          final token = _prefs!.getString('auth_token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('Bearer : ${token}');
          print('🌐 ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('[${response.statusCode}] ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          print('❌ [${e.response?.statusCode}] ${e.requestOptions.path}');

          if (e.response?.statusCode == 401) {
            _prefs ??= await SharedPreferences.getInstance();
            await _prefs!.remove('auth_token');
            print('🔴 Token cleared due to 401');
          }

          final appException = AppException.fromDioException(e);
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: appException,
              response: e.response,
              type: e.type,
            ),
          );
        },
      ),
    );

    assert(() {
      dio.interceptors.add(
        LogInterceptor(
          responseBody: false,  // Don't log full response body — saves memory
          requestBody: false,
          logPrint: (obj) => print('📝 $obj'),
        ),
      );
      return true;
    }());

    // ── Retry interceptor ──────────────────────────────────────────────────
    // Retries up to 2× with 1-second delay on network/timeout errors.
    // Essential for mobile networks where single requests may drop.
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) async {
          final isNetworkError = e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.sendTimeout;

          // Only retry non-upload (GET) requests automatically.
          final isIdempotent = e.requestOptions.method == 'GET';

          final retryCount =
              (e.requestOptions.extra['retryCount'] as int?) ?? 0;

          if (isNetworkError && isIdempotent && retryCount < 2) {
            e.requestOptions.extra['retryCount'] = retryCount + 1;
            await Future.delayed(const Duration(seconds: 1));
            try {
              final response = await dio.fetch(e.requestOptions);
              return handler.resolve(response);
            } catch (retryError) {
              // Let it fall through to the normal error handler below.
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  String get storageBaseUrl {
    final uri = Uri.parse(_apiBaseUrl);
    return '${uri.scheme}://${uri.host}/';
  }

  void clearCache() {
    _prefs = null;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(Dio());
});

final storageBaseUrlProvider = Provider<String>((ref) {
  return ref.watch(apiClientProvider).storageBaseUrl;
});
