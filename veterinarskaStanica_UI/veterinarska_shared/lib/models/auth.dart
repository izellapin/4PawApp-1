import 'package:json_annotation/json_annotation.dart';

part 'auth.g.dart';

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
  final Map<String, dynamic>? user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Backend returns user data directly in the response, not nested under 'user'
      final userData = Map<String, dynamic>.from(json);
      
      // Remove token fields from user data
      userData.remove('accessToken');
      userData.remove('refreshToken');
      userData.remove('tokenExpiration');
      
      return AuthResponse(
        accessToken: json['accessToken'] as String? ?? json['token'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        expiresAt: json['tokenExpiration'] != null ? DateTime.tryParse(json['tokenExpiration'].toString()) : null,
        user: userData,
      );
    } catch (e) {
      print('Error parsing AuthResponse: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class ApiError {
  final String message;
  final int? statusCode;
  final String? details;

  ApiError({
    required this.message,
    this.statusCode,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) => _$ApiErrorFromJson(json);
  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);

  @override
  String toString() => message;
}
