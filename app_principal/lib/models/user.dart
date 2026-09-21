class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final int id;

  final String name;

  final String email;

  final DateTime? createdAt;

  // ============================================================
  // FROM JSON
  // ============================================================

  factory User.fromJson(
    Map<String, dynamic> json,
  ) {
    return User(
      id: _toInt(
        json['id'],
      ),

      name:
          json['nombre']
                  ?.toString()
                  .trim() ??
              '',

      email:
          json['email']
                  ?.toString()
                  .trim() ??
              '',

      createdAt:
          _toDateTime(
        json['creado_en'],
      ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': name,
      'email': email,
      'creado_en':
          createdAt
              ?.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  User copyWith({
    int? id,
    String? name,
    String? email,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name:
          name ?? this.name,
      email:
          email ?? this.email,
      createdAt:
          createdAt ??
              this.createdAt,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
  });

  final String email;

  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'email': email.trim(),
      'password': password,
    };
  }
}

// ============================================================
// REGISTRO
// ============================================================

class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;

  final String email;

  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre': name.trim(),
      'email': email.trim(),
      'password': password,
    };
  }
}

// ============================================================
// RESPUESTA DE LOGIN
// ============================================================

class LoginResponse {
  const LoginResponse({
    required this.success,
    required this.message,
    required this.user,
    required this.token,
  });

  final bool success;

  final String message;

  final User? user;

  final String? token;

  factory LoginResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    User? parsedUser;

    final dynamic rawUser =
        json['user'];

    if (rawUser is Map) {
      parsedUser =
          User.fromJson(
        Map<String, dynamic>.from(
          rawUser,
        ),
      );
    }

    return LoginResponse(
      success:
          _toBool(
        json['success'] ?? true,
      ),

      message:
          json['message']
                  ?.toString() ??
              json['detail']
                  ?.toString() ??
              '',

      user:
          parsedUser,

      token:
          json['token']
                  ?.toString() ??
              json['access_token']
                  ?.toString(),
    );
  }

  static bool _toBool(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text =
        value
                ?.toString()
                .toLowerCase() ??
            '';

    return text == 'true' ||
        text == '1';
  }
}