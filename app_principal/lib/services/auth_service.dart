import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  AuthService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService =
            apiService ??
                ApiService(),
        _storageService =
            storageService ??
                StorageService.instance;

  final ApiService _apiService;

  final StorageService _storageService;

  // ============================================================
  // ESTADO DE SESIÓN
  // ============================================================

  Future<bool> hasSession() async {
    return _storageService
        .hasSession();
  }

  Future<User?> getCurrentUser() async {
    return _storageService
        .getSavedUser();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final String cleanEmail =
        email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw const AuthException(
        'Ingresa tu correo electrónico.',
      );
    }

    if (!_isValidEmail(
      cleanEmail,
    )) {
      throw const AuthException(
        'Ingresa un correo electrónico válido.',
      );
    }

    if (password.isEmpty) {
      throw const AuthException(
        'Ingresa tu contraseña.',
      );
    }

    try {
      final LoginResponse response =
          await _apiService.login(
        email: cleanEmail,
        password: password,
      );

      final User? user =
          response.user;

      if (user == null) {
        throw const AuthException(
          'El servidor no devolvió los datos del usuario.',
        );
      }

      await _storageService.saveSession(
        user: user,
      );

      return user;
    } on ApiException catch (error) {
      throw AuthException(
        error.message,
      );
    }
  }

  // ============================================================
  // REGISTRO
  // ============================================================

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final String cleanName =
        name.trim();

    final String cleanEmail =
        email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw const AuthException(
        'Ingresa tu nombre completo.',
      );
    }

    if (cleanName.length < 2) {
      throw const AuthException(
        'El nombre es demasiado corto.',
      );
    }

    if (cleanEmail.isEmpty) {
      throw const AuthException(
        'Ingresa tu correo electrónico.',
      );
    }

    if (!_isValidEmail(
      cleanEmail,
    )) {
      throw const AuthException(
        'Ingresa un correo electrónico válido.',
      );
    }

    if (password.isEmpty) {
      throw const AuthException(
        'Ingresa una contraseña.',
      );
    }

    if (password.length < 6) {
      throw const AuthException(
        'La contraseña debe contener al menos 6 caracteres.',
      );
    }

    if (confirmPassword.isEmpty) {
      throw const AuthException(
        'Confirma tu contraseña.',
      );
    }

    if (password !=
        confirmPassword) {
      throw const AuthException(
        'Las contraseñas no coinciden.',
      );
    }

    try {
      final User user =
          await _apiService.register(
        name: cleanName,
        email: cleanEmail,
        password: password,
      );

      await _storageService.saveSession(
        user: user,
      );

      return user;
    } on ApiException catch (error) {
      throw AuthException(
        error.message,
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _storageService
        .clearSession();
  }

  // ============================================================
  // ONBOARDING
  // ============================================================

  Future<bool>
      isOnboardingCompleted() async {
    return _storageService
        .isOnboardingCompleted();
  }

  Future<void>
      completeOnboarding() async {
    await _storageService
        .setOnboardingCompleted(
      true,
    );
  }

  // ============================================================
  // VALIDACIÓN
  // ============================================================

  bool _isValidEmail(
    String email,
  ) {
    final RegExp expression =
        RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    return expression
        .hasMatch(email);
  }
}

// ============================================================
// AUTH EXCEPTION
// ============================================================

class AuthException
    implements Exception {
  const AuthException(
    this.message,
  );

  final String message;

  @override
  String toString() {
    return message;
  }
}