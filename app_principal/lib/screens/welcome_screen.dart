import 'package:flutter/material.dart';

import '../core/animations/custom_page_route.dart';
import '../core/animations/pressable_scale.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_logo.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<WelcomeScreen> createState() =>
      _WelcomeScreenState();
}

class _WelcomeScreenState
    extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController
      _animationController;

  late final Animation<double>
      _fadeAnimation;

  late final Animation<Offset>
      _slideAnimation;

  bool _continuing = false;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 800,
      ),
    );

    final CurvedAnimation curved =
        CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curved);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(
        0.0,
        0.06,
      ),
      end: Offset.zero,
    ).animate(curved);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  Future<void> _continue() async {
    if (_continuing) {
      return;
    }

    setState(() {
      _continuing = true;
    });

    try {
      // Guardamos localmente que el usuario
      // ya completó la pantalla de bienvenida.
      await StorageService.instance
          .setOnboardingCompleted(true);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        CustomPageRoute<void>(
          page: LoginScreen(
            authService:
                widget.authService,
          ),
        ),
      );
    } catch (error) {
      debugPrint(
        'Error guardando onboarding: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _continuing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible continuar. Intenta nuevamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppTheme.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                24.0,
                28.0,
                24.0,
                24.0,
              ),
              child: Column(
                children: <Widget>[
                  const Spacer(
                    flex: 2,
                  ),

                  const AppLogo(
                    showSubtitle: false,
                  ),

                  const SizedBox(
                    height: 44.0,
                  ),

                  const _WelcomeIllustration(),

                  const SizedBox(
                    height: 40.0,
                  ),

                  const Text(
                    'Bienvenido a\nNEXUS ENERGY',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: AppTheme
                          .secondaryDark,
                      fontSize: 30.0,
                      height: 1.08,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),

                  const SizedBox(
                    height: 15.0,
                  ),

                  const Text(
                    'Detección automática de dispositivos y control inteligente de tu consumo energético.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          AppTheme.textMuted,
                      fontSize: 14.0,
                      height: 1.55,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const Spacer(
                    flex: 2,
                  ),

                  PressableScale(
                    enabled: !_continuing,
                    onTap: _continue,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56.0,
                      child: FilledButton(
                        onPressed: null,
                        style:
                            FilledButton.styleFrom(
                          disabledBackgroundColor:
                              AppTheme
                                  .primaryTurquoise,
                          disabledForegroundColor:
                              Colors.white,
                        ),
                        child: _continuing
                            ? const SizedBox(
                                width: 22.0,
                                height: 22.0,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2.3,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: <
                                    Widget>[
                                  Text(
                                    'Comenzar',
                                  ),
                                  SizedBox(
                                    width: 8.0,
                                  ),
                                  Icon(
                                    Icons
                                        .arrow_forward_rounded,
                                    size: 20.0,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 13.0,
                  ),

                  const Text(
                    'Monitorea • Controla • Ahorra',
                    style: TextStyle(
                      color:
                          AppTheme.textLight,
                      fontSize: 11.0,
                      fontWeight:
                          FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeIllustration
    extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: 190.0,
      height: 150.0,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 145.0,
            height: 145.0,
            decoration: BoxDecoration(
              color: AppTheme
                  .primaryTurquoiseLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme
                    .primaryTurquoise
                    .withValues(
                  alpha: 0.12,
                ),
              ),
            ),
          ),

          Container(
            width: 96.0,
            height: 96.0,
            decoration: BoxDecoration(
              color:
                  AppTheme.surfaceWhite,
              shape: BoxShape.circle,
              boxShadow:
                  AppTheme.softShadow,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color:
                  AppTheme.primaryTurquoise,
              size: 55.0,
            ),
          ),

          const Positioned(
            left: 7.0,
            top: 31.0,
            child: _SmallEnergyNode(
              icon:
                  Icons.power_rounded,
            ),
          ),

          const Positioned(
            right: 3.0,
            top: 22.0,
            child: _SmallEnergyNode(
              icon:
                  Icons.eco_rounded,
            ),
          ),

          const Positioned(
            right: 18.0,
            bottom: 7.0,
            child: _SmallEnergyNode(
              icon:
                  Icons.home_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallEnergyNode
    extends StatelessWidget {
  const _SmallEnergyNode({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 42.0,
      height: 42.0,
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              AppTheme.borderLight,
        ),
        boxShadow:
            AppTheme.softShadow,
      ),
      child: Icon(
        icon,
        color:
            AppTheme.primaryTurquoise,
        size: 20.0,
      ),
    );
  }
}