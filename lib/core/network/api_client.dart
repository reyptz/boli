import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../storage/token_storage.dart';

class ApiClient {
  late final Dio dio;
  final TokenStorage tokenStorage;

  static String get baseUrl => kIsWeb 
      ? (dotenv.env['API_BASE_URL_WEB'] ?? 'http://127.0.0.1:8000/api/v1')
      : (dotenv.env['API_BASE_URL_MOBILE'] ?? 'http://10.0.2.2:8000/api/v1');


  ApiClient({required this.tokenStorage}) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Tentative de refresh token
          final refreshToken = await tokenStorage.getRefreshToken();
          if (refreshToken != null) {
            try {
              // Créer une nouvelle instance de Dio pour éviter les boucles infinies
              final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
              final response = await refreshDio.post(
                '/auth/refresh',
                data: {'refresh_token': refreshToken},
              );

              final newAccessToken = response.data['access_token'];
              final newRefreshToken = response.data['refresh_token'];

              await tokenStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              // Rejouer la requête d'origine avec le nouveau token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';
              
              final cloneReq = await dio.request(
                opts.path,
                options: Options(
                  method: opts.method,
                  headers: opts.headers,
                ),
                data: opts.data,
                queryParameters: opts.queryParameters,
              );
              return handler.resolve(cloneReq);
            } catch (e) {
              // Échec du refresh -> on clear les tokens
              await tokenStorage.clearTokens();
            }
          } else {
            await tokenStorage.clearTokens();
          }
        }
        return handler.next(error);
      },
    ));
  }
}
