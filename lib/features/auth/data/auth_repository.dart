import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/auth_models.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository(this.apiClient);

  Future<AuthResponse> signIn({
    required String identifier,
    String? password,
    String? pin,
  }) async {
    final response = await apiClient.dio.post('/auth/signin', data: {
      'identifier': identifier,
      if (password != null) 'password': password,
      if (pin != null) 'pin': pin,
    });
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> signUp({
    String? phone,
    String? email,
    String? username,
    String? password,
    String? pin,
  }) async {
    final response = await apiClient.dio.post('/auth/signup', data: {
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (pin != null) 'pin': pin,
      'role': 'client',
    });
    return AuthResponse.fromJson(response.data);
  }

  Future<User> getMyProfile() async {
    final response = await apiClient.dio.get('/users/me');
    return User.fromJson(response.data);
  }

  Future<void> logout() async {
    await apiClient.dio.post('/auth/logout');
  }

  Future<AuthResponse> verify2fa({required String code, String? tempToken}) async {
    final response = await apiClient.dio.post(
      '/auth/2fa/verify', 
      data: {'code': code},
      options: tempToken != null 
          ? Options(headers: {'Authorization': 'Bearer $tempToken'}) 
          : null,
    );
    return AuthResponse.fromJson(response.data);
  }
}
