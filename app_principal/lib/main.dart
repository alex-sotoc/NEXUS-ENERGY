import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'models/user.dart';
import 'navigation/main_scaffold.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final StorageService storageService =
      StorageService.instance;

  await storageService.initialize();

  runApp(
    NexusEnergyApp(
      storageService: storageService,
    ),
  );
}

class NexusEnergyApp extends StatefulWidget {
  const NexusEnergyApp({
    super.key,
    required this.storageService,
  });

  final StorageService storageService;

  @override
  State<NexusEnergyApp> createState() =>
      _NexusEnergyAppState();
}

class _NexusEnergyAppState
    extends State<NexusEnergyApp> {
  late final ApiService _apiService;
  late final AuthService _authService;

  bool _initializing = true;

  bool _onboardingCompleted = false;

  User? _savedUser;

  @override
  void initState() {
    super.initState();

    _apiService = ApiService();

    _authService = AuthService(
      apiService: _apiService,
      storageService: widget.storageService,
    );

    _initializeApplication();
  }

  Future<void> _initializeApplication() async {
    try {
      final bool onboardingCompleted =
          await widget.storageService
              .isOnboardingCompleted();

      final User? savedUser =
          await widget.storageService
              .getSavedUser();

      if (!mounted) {
        return;
      }

      setState(() {
        _onboardingCompleted =
            onboardingCompleted;

        _savedUser = savedUser;

        _initializing = false;
      });
    } catch (error) {
      debugPrint(
        'Error inicializando NEXUS ENERGY: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _onboardingCompleted = false;
        _savedUser = null;
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _apiService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXUS ENERGY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
       useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor:
            AppTheme.backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              AppTheme.primaryTurquoise,
          brightness: Brightness.light,
          surface: AppTheme.surfaceWhite,
        ),
      ),
      home: _buildInitialScreen(),
    );
  }

  Widget _buildInitialScreen() {
    if (_initializing) {
      return const _NexusSplashScreen();
    }

    if (!_onboardingCompleted) {
      return WelcomeScreen(
        authService: _authService,
      );
    }

    if (_savedUser != null) {
      return MainScaffold(
        authService: _authService,
        user: _savedUser!,
      );
    }

    return LoginScreen(
      authService: _authService,
    );
  }
}

class _NexusSplashScreen
    extends StatelessWidget {
  const _NexusSplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _SplashLogo(),
              SizedBox(height: 22.0),
              Text(
                'NEXUS ENERGY',
                style: TextStyle(
                  color: AppTheme.secondaryDark,
                  fontSize: 22.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 7.0),
              Text(
                'Energía inteligente para tu hogar',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 30.0),
              SizedBox(
                width: 25.0,
                height: 25.0,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryTurquoise,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82.0,
      height: 82.0,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(
          25.0,
        ),
        boxShadow: AppTheme.turquoiseShadow,
      ),
      child: const Icon(
        Icons.bolt_rounded,
        color: Colors.white,
        size: 45.0,
      ),
    );
  }
}