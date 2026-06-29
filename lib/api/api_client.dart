import 'package:dio/dio.dart';
import 'package:eventsbooking/utils/app_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio dio;
  static const String _apiBaseUrl = 'https://undrgrnd.staging-workhub.com/api';

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
          responseBody: true,
          requestBody: true,
          logPrint: (obj) => print('📝 $obj'),
        ),
      );
      return true;
    }());
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
