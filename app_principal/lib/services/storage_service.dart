import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/user.dart';

class StorageService {
  StorageService._();

  static final StorageService instance =
      StorageService._();

  SharedPreferences? _preferences;

  // ============================================================
  // KEYS LOCALES
  // ============================================================

  static const String _notificationsKey =
      'notifications_enabled';

  static const String _electricityTariffKey =
      'electricity_tariff';

  // ============================================================
  // INICIALIZACIÓN
  // ============================================================

  Future<void> initialize() async {
    _preferences ??=
        await SharedPreferences.getInstance();
  }

  Future<SharedPreferences>
      _getPreferences() async {
    if (_preferences == null) {
      await initialize();
    }

    return _preferences!;
  }

  // ============================================================
  // SESIÓN
  // ============================================================

  Future<void> saveSession({
    required User user,
  }) async {
    final SharedPreferences prefs =
        await _getPreferences();

    await prefs.setBool(
      AppConstants.sessionKey,
      true,
    );

    await prefs.setInt(
      AppConstants.userIdKey,
      user.id,
    );

    await prefs.setString(
      AppConstants.userNameKey,
      user.name,
    );

    await prefs.setString(
      AppConstants.userEmailKey,
      user.email,
    );
  }

  Future<bool> hasSession() async {
    final SharedPreferences prefs =
        await _getPreferences();

    return prefs.getBool(
          AppConstants.sessionKey,
        ) ??
        false;
  }

  Future<User?> getSavedUser() async {
    final SharedPreferences prefs =
        await _getPreferences();

    final bool hasSessionValue =
        prefs.getBool(
              AppConstants.sessionKey,
            ) ??
            false;

    if (!hasSessionValue) {
      return null;
    }

    final int? userId =
        prefs.getInt(
      AppConstants.userIdKey,
    );

    final String? userName =
        prefs.getString(
      AppConstants.userNameKey,
    );

    final String? userEmail =
        prefs.getString(
      AppConstants.userEmailKey,
    );

    if (userId == null ||
        userName == null ||
        userEmail == null) {
      await clearSession();
      return null;
    }

    return User(
      id: userId,
      name: userName,
      email: userEmail,
      createdAt: null,
    );
  }

  Future<void> clearSession() async {
    final SharedPreferences prefs =
        await _getPreferences();

    await prefs.remove(
      AppConstants.sessionKey,
    );

    await prefs.remove(
      AppConstants.userIdKey,
    );

    await prefs.remove(
      AppConstants.userNameKey,
    );

    await prefs.remove(
      AppConstants.userEmailKey,
    );
  }

  // ============================================================
  // ONBOARDING
  // ============================================================

  Future<bool>
      isOnboardingCompleted() async {
    final SharedPreferences prefs =
        await _getPreferences();

    return prefs.getBool(
          AppConstants
              .onboardingCompletedKey,
        ) ??
        false;
  }

  Future<void>
      setOnboardingCompleted(
    bool value,
  ) async {
    final SharedPreferences prefs =
        await _getPreferences();

    await prefs.setBool(
      AppConstants
          .onboardingCompletedKey,
      value,
    );
  }

  // ============================================================
  // TARIFA ELÉCTRICA - API ORIGINAL
  // ============================================================

  Future<double>
      getElectricityRate() async {
    final SharedPreferences prefs =
        await _getPreferences();

    /*
     * Primero intentamos leer la nueva key.
     * Si no existe, usamos la key antigua de AppConstants.
     * Así mantenemos compatibilidad con fases anteriores.
     */
    final double? newValue =
        prefs.getDouble(
      _electricityTariffKey,
    );

    if (newValue != null) {
      return newValue;
    }

    return prefs.getDouble(
          AppConstants
              .electricityRateKey,
        ) ??
        AppConstants
            .defaultElectricityRateMxnPerKwh;
  }

  Future<void> setElectricityRate(
    double value,
  ) async {
    if (value <= 0.0) {
      throw ArgumentError(
        'La tarifa eléctrica debe ser mayor que cero.',
      );
    }

    final SharedPreferences prefs =
        await _getPreferences();

    /*
     * Guardamos en ambas keys para mantener
     * compatibilidad con código anterior y nuevo.
     */
    await prefs.setDouble(
      AppConstants
          .electricityRateKey,
      value,
    );

    await prefs.setDouble(
      _electricityTariffKey,
      value,
    );
  }

  // ============================================================
  // TARIFA ELÉCTRICA - API PARA SETTINGS_SCREEN
  // ============================================================

  Future<double?>
      get electricityTariff async {
    final SharedPreferences prefs =
        await _getPreferences();

    final double? newValue =
        prefs.getDouble(
      _electricityTariffKey,
    );

    if (newValue != null) {
      return newValue;
    }

    /*
     * Si todavía no existe con la nueva key,
     * intentamos recuperar el valor anterior.
     */
    final double? legacyValue =
        prefs.getDouble(
      AppConstants
          .electricityRateKey,
    );

    return legacyValue;
  }

  Future<void>
      setElectricityTariff(
    double value,
  ) async {
    if (value <= 0.0) {
      throw ArgumentError(
        'La tarifa eléctrica debe ser mayor que cero.',
      );
    }

    final SharedPreferences prefs =
        await _getPreferences();

    await prefs.setDouble(
      _electricityTariffKey,
      value,
    );

    /*
     * También actualizamos la key original
     * para que getElectricityRate() siga
     * devolviendo el mismo valor.
     */
    await prefs.setDouble(
      AppConstants
          .electricityRateKey,
      value,
    );
  }

  Future<void>
      clearElectricityTariff() async {
    final SharedPreferences prefs =
        await _getPreferences();

    await prefs.remove(
      _electricityTariffKey,
    );

    await prefs.remove(
      AppConstants
          .electricityRateKey,
    );
  }

  // ============================================================
  // NOTIFICACIONES
  // ============================================================

  Future<bool>
      get notificationsEnabled async {
    final SharedPreferences prefs =
        await _getPreferences();

    return prefs.getBool(
          _notificationsKey,
        ) ??
        true;
  }

  Future<void>
      setNotificationsEnabled(
    bool value,
  ) async {
    final SharedPreferences prefs =
        await _getPreferences();

    await prefs.setBool(
      _notificationsKey,
      value,
    );
  }

  // ============================================================
  // UTILIDADES
  // ============================================================

  Future<bool> containsKey(
    String key,
  ) async {
    final SharedPreferences prefs =
        await _getPreferences();

    return prefs.containsKey(key);
  }

  Future<void> remove(
    String key,
  ) async {
    final SharedPreferences prefs =
        await _getPreferences();

    await prefs.remove(key);
  }

  // ============================================================
  // LIMPIEZA TOTAL
  // ============================================================

  Future<void> clearAll() async {
    final SharedPreferences prefs =
        await _getPreferences();

    await prefs.clear();
  }
}