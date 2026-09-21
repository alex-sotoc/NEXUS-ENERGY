import 'package:flutter/material.dart';

import '../core/animations/custom_page_route.dart';
import '../core/theme/app_theme.dart';
import '../models/user.dart';
import '../screens/dashboard_screen.dart';
import '../screens/history_screen.dart';
import '../screens/login_screen.dart';
import '../screens/savings_screen.dart';
import '../screens/settings_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({
    super.key,
    required this.authService,
    required this.user,
  });

  final AuthService authService;
  final User user;

  @override
  State<MainScaffold> createState() =>
      _MainScaffoldState();
}

class _MainScaffoldState
    extends State<MainScaffold> {
  late final ApiService _apiService;

  int _currentIndex = 0;

  bool _loggingOut = false;

  static const List<String> _titles =
      <String>[
    'Mi Hogar',
    'Ahorro',
    'Historial',
    'Configuración',
  ];

  @override
  void initState() {
    super.initState();

    _apiService = ApiService();
  }

  @override
  void dispose() {
    _apiService.dispose();

    super.dispose();
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() {
      _loggingOut = true;
    });

    try {
      await widget.authService.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        CustomPageRoute<void>(
          page: LoginScreen(
            authService: widget.authService,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible cerrar la sesión.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages =
        <Widget>[
      DashboardScreen(
        apiService: _apiService,
        userName: widget.user.name,
      ),
      SavingsScreen(
        apiService: _apiService,
      ),
      HistoryScreen(
        apiService: _apiService,
      ),
      SettingsScreen(
        apiService: _apiService,
        authService: widget.authService,
        user: widget.user,
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: AnimatedSwitcher(
          duration:
              const Duration(milliseconds: 250),
          child: Text(
            _titles[_currentIndex],
            key: ValueKey<int>(_currentIndex),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding:
                const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                width: 38.0,
                height: 38.0,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color:
                      AppTheme.primaryTurquoiseLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _initials(widget.user.name),
                  style: const TextStyle(
                    color:
                        AppTheme.primaryTurquoise,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          border: const Border(
            top: BorderSide(
              color: AppTheme.borderLight,
            ),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.035,
              ),
              blurRadius: 16.0,
              offset: const Offset(
                0.0,
                -4.0,
              ),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (
              int index,
            ) {
              if (index == _currentIndex) {
                return;
              }

              setState(() {
                _currentIndex = index;
              });
            },
            destinations:
                const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                ),
                selectedIcon: Icon(
                  Icons.home_rounded,
                ),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.eco_outlined,
                ),
                selectedIcon: Icon(
                  Icons.eco_rounded,
                ),
                label: 'Ahorro',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.history_outlined,
                ),
                selectedIcon: Icon(
                  Icons.history_rounded,
                ),
                label: 'Historial',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.settings_outlined,
                ),
                selectedIcon: Icon(
                  Icons.settings_rounded,
                ),
                label: 'Configuración',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where(
          (String part) => part.isNotEmpty,
        )
        .toList();

    if (parts.isEmpty) {
      return 'NE';
    }

    if (parts.length == 1) {
      final String value = parts.first;

      if (value.length == 1) {
        return value.toUpperCase();
      }

      return value
          .substring(0, 2)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}