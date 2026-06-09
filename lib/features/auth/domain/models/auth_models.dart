class User {
  final String id;
  final String? phone;
  final String? email;
  final String? username;
  final String role;
  final String? vehicleType;
  final bool isActive;
  final bool is2faEnabled;

  User({
    required this.id,
    this.phone,
    this.email,
    this.username,
    required this.role,
    this.vehicleType,
    required this.isActive,
    required this.is2faEnabled,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      phone: json['phone'],
      email: json['email'],
      username: json['username'],
      role: json['role'] ?? 'client',
      vehicleType: json['vehicle_type'],
      isActive: json['is_active'] ?? true,
      is2faEnabled: json['is_2fa_enabled'] ?? false,
    );
  }

  User copyWith({
    String? id,
    String? phone,
    String? email,
    String? username,
    String? role,
    String? vehicleType,
    bool? isActive,
    bool? is2faEnabled,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      vehicleType: vehicleType ?? this.vehicleType,
      isActive: isActive ?? this.isActive,
      is2faEnabled: is2faEnabled ?? this.is2faEnabled,
    );
  }
}

class AuthResponse {
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final String? role;
  final bool requires2fa;
  final String? tempToken;

  AuthResponse({
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.role,
    this.requires2fa = false,
    this.tempToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      userId: json['user_id'],
      role: json['role'],
      requires2fa: json['requires_2fa'] ?? false,
      tempToken: json['temp_token'],
    );
  }
}
