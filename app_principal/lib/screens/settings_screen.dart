import 'package:flutter/material.dart';

import '../core/animations/custom_page_route.dart';
import '../core/theme/app_theme.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'devices_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.apiService,
    required this.authService,
    required this.user,
    required this.onLogout,
  });

  final ApiService apiService;
  final AuthService authService;
  final User user;
  final Future<void> Function() onLogout;

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService =
      StorageService.instance;

  bool _notifications = true;
  bool _loadingPreferences = true;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final bool notifications =
          await _storageService.notificationsEnabled;

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _loadingPreferences = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingPreferences = false;
      });
    }
  }

  Future<void> _toggleNotifications(
    bool value,
  ) async {
    setState(() {
      _notifications = value;
    });

    await _storageService
        .setNotificationsEnabled(value);
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() {
      _loggingOut = true;
    });

    await widget.onLogout();

    if (mounted) {
      setState(() {
        _loggingOut = false;
      });
    }
  }

  void _openDevices() {
    Navigator.of(context).push(
      CustomPageRoute<void>(
        page: DevicesScreen(
          apiService: widget.apiService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20.0,
        12.0,
        20.0,
        35.0,
      ),
      children: <Widget>[
        _buildProfile(),

        const SizedBox(height: 24.0),

        const _SectionTitle(
          title: 'Mi NEXUS',
        ),

        const SizedBox(height: 10.0),

        _SettingsContainer(
          children: <Widget>[
            _SettingsTile(
              icon: Icons.devices_other_rounded,
              title: 'Dispositivos registrados',
              subtitle:
                  'Consulta los dispositivos conocidos por NEXUS',
              onTap: _openDevices,
            ),
          ],
        ),

        const SizedBox(height: 24.0),

        const _SectionTitle(
          title: 'Preferencias',
        ),

        const SizedBox(height: 10.0),

        _SettingsContainer(
          children: <Widget>[
            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notificaciones',
              subtitle:
                  'Alertas y avisos de NEXUS',
              trailing: _loadingPreferences
                  ? const SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                      ),
                    )
                  : Switch(
                      value: _notifications,
                      onChanged: _toggleNotifications,
                    ),
            ),
            const _SettingsDivider(),
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              title: 'Ayuda y soporte',
              subtitle:
                  'Información del sistema NEXUS ENERGY',
              onTap: _showHelp,
            ),
          ],
        ),

        const SizedBox(height: 28.0),

        OutlinedButton.icon(
          onPressed:
              _loggingOut ? null : _logout,
          icon: _loggingOut
              ? const SizedBox(
                  width: 18.0,
                  height: 18.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                  ),
                )
              : const Icon(
                  Icons.logout_rounded,
                ),
          label: Text(
            _loggingOut
                ? 'Cerrando sesión...'
                : 'Cerrar sesión',
          ),
        ),

        const SizedBox(height: 25.0),

        const Center(
          child: Text(
            'NEXUS ENERGY · V2',
            style: TextStyle(
              color: AppTheme.textLight,
              fontSize: 10.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfile() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppTheme.borderLight,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 57.0,
            height: 57.0,
            decoration: const BoxDecoration(
              color: AppTheme.primaryTurquoiseLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppTheme.primaryTurquoise,
              size: 27.0,
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    color: AppTheme.secondaryDark,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  widget.user.email,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'NEXUS ENERGY',
          ),
          content: const Text(
            'NEXUS ENERGY permite visualizar el consumo eléctrico de tus dispositivos, consultar su historial y controlar equipos compatibles desde una sola aplicación.',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.secondaryDark,
        fontSize: 14.0,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SettingsContainer extends StatelessWidget {
  const _SettingsContainer({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(19.0),
        border: Border.all(
          color: AppTheme.borderLight,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15.0,
        vertical: 5.0,
      ),
      leading: Container(
        width: 41.0,
        height: 41.0,
        decoration: BoxDecoration(
          color: AppTheme.primaryTurquoiseLight,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryTurquoise,
          size: 20.0,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.secondaryDark,
          fontSize: 13.0,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10.0,
        ),
      ),
      trailing: trailing ??
          (onTap == null
              ? null
              : const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                )),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1.0,
      indent: 70.0,
      color: AppTheme.borderLight,
    );
  }
}