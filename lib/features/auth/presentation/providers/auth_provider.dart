import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/models/auth_models.dart';
import '../../data/auth_repository.dart';
import 'package:dio/dio.dart';

// --- Core Providers ---
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.read(tokenStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider));
});


// --- State Classes ---
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}
class AuthRequires2fa extends AuthState {
  final String tempToken;
  AuthRequires2fa(this.tempToken);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}


// --- Auth Notifier ---
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  AuthNotifier(this._repository, this._tokenStorage) : super(AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = AuthLoading();
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      state = AuthUnauthenticated();
      return;
    }

    try {
      final user = await _repository.getMyProfile();
      state = AuthAuthenticated(user);
    } catch (e) {
      await _tokenStorage.clearTokens();
      state = AuthUnauthenticated();
    }
  }

  Future<void> signIn(String identifier, String secret) async {
    state = AuthLoading();
    try {
      final isPin = RegExp(r'^\d{4,6}$').hasMatch(secret);
      final response = await _repository.signIn(
        identifier: identifier, 
        password: isPin ? null : secret,
        pin: isPin ? secret : null,
      );
      
      if (response.requires2fa) {
        state = AuthRequires2fa(response.tempToken!);
        return;
      }

      await _tokenStorage.saveTokens(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken,
      );

      final user = await _repository.getMyProfile();
      state = AuthAuthenticated(user);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final detail = e.response!.data['detail'];
        if (detail is String) {
          state = AuthError(detail);
        } else if (detail is List && detail.isNotEmpty) {
          state = AuthError(detail[0]['msg'] ?? 'Erreur de connexion.');
        } else {
          state = AuthError('Erreur de connexion. Vérifiez vos identifiants.');
        }
      } else {
        state = AuthError('Erreur de connexion. Vérifiez vos identifiants.');
      }
    }
  }

  Future<void> signUp({String? phone, String? email, String? username, String? password, String? pin}) async {
    state = AuthLoading();
    try {
      final response = await _repository.signUp(
        phone: phone,
        email: email,
        username: username,
        password: password,
        pin: pin,
      );

      await _tokenStorage.saveTokens(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken,
      );

      final user = await _repository.getMyProfile();
      state = AuthAuthenticated(user);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final detail = e.response!.data['detail'];
        if (detail is String) {
          state = AuthError(detail);
        } else if (detail is List && detail.isNotEmpty) {
          state = AuthError(detail[0]['msg'] ?? 'Erreur lors de l\'inscription.');
        } else {
          state = AuthError('Erreur lors de l\'inscription.');
        }
      } else {
        state = AuthError('Erreur lors de l\'inscription.');
      }
    }
  }

  Future<void> verify2fa(String code, {String? tempToken}) async {
    state = AuthLoading();
    try {
      final response = await _repository.verify2fa(code: code, tempToken: tempToken);
      
      await _tokenStorage.saveTokens(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken,
      );

      final user = await _repository.getMyProfile();
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError('Code 2FA invalide.');
    }
  }

  Future<void> logout() async {
    state = AuthLoading();
    try {
      await _repository.logout();
    } catch (_) {}
    await _tokenStorage.clearTokens();
    state = AuthUnauthenticated();
  }

  Future<void> updateProfile({String? username, String? phone, bool? is2faEnabled, String? role, String? vehicleType}) async {
    if (state is AuthAuthenticated) {
      final currentUser = (state as AuthAuthenticated).user;
      final updatedUser = currentUser.copyWith(
        username: username,
        phone: phone,
        is2faEnabled: is2faEnabled,
        role: role,
        vehicleType: vehicleType,
      );

      // Met à jour l'état immédiatement pour la réactivité locale
      state = AuthAuthenticated(updatedUser);

      try {
        final response = await _repository.apiClient.dio.put('/users/me', data: {
          if (username != null && username.isNotEmpty) 'username': username,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (role != null && role.isNotEmpty) 'role': role,
          if (vehicleType != null && vehicleType.isNotEmpty) 'vehicle_type': vehicleType,
          // note: 2FA n'est pas modifiable directement via /users/me sur le backend
        });
        
        // On récupère les valeurs réelles renvoyées par le serveur
        final freshUser = User.fromJson(response.data);
        state = AuthAuthenticated(freshUser);
      } catch (e) {
        print('Backend update profile failed: $e');
        // Revert to original state on failure
        state = AuthAuthenticated(currentUser);
        String errorMessage = 'Erreur lors de la mise à jour.';
        if (e is DioException && e.response?.data != null) {
           final detail = e.response!.data['detail'];
           if (detail is String) {
             errorMessage = detail;
           } else if (detail is List && detail.isNotEmpty) {
             errorMessage = detail[0]['msg'] ?? errorMessage;
           }
        }
        throw Exception(errorMessage);
      }
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(tokenStorageProvider),
  );
});
