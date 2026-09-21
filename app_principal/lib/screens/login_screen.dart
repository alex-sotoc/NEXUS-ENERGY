import 'package:flutter/material.dart';

import '../core/animations/custom_page_route.dart';
import '../core/animations/pressable_scale.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';
import '../navigation/main_scaffold.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();

  final FocusNode _emailFocus =
      FocusNode();

  final FocusNode _passwordFocus =
      FocusNode();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_loading) {
      return;
    }

    final bool valid =
        _formKey.currentState
                ?.validate() ??
            false;

    if (!valid) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user =
          await widget.authService.login(
        email:
            _emailController.text,
        password:
            _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context)
          .pushAndRemoveUntil(
        CustomPageRoute<void>(
          page: MainScaffold(
            authService:
                widget.authService,
            user: user,
          ),
        ),
        (Route<dynamic> route) =>
            false,
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage =
            error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage =
            'Ocurrió un error inesperado. Intenta nuevamente.';
      });
    }
  }

  void _openRegister() {
    if (_loading) {
      return;
    }

    Navigator.of(context).push(
      CustomPageRoute<void>(
        page: RegisterScreen(
          authService:
              widget.authService,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              24.0,
              30.0,
              24.0,
              30.0,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 460.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: <Widget>[
                    const Center(
                      child: AppLogo(
                        compact: true,
                        showSubtitle: false,
                      ),
                    ),

                    const SizedBox(
                      height: 42.0,
                    ),

                    const Text(
                      'Bienvenido de nuevo',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: AppTheme
                            .secondaryDark,
                        fontSize: 27.0,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing:
                            -0.7,
                      ),
                    ),

                    const SizedBox(
                      height: 8.0,
                    ),

                    const Text(
                      'Ingresa para ver y controlar el consumo de tu hogar.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: AppTheme
                            .textMuted,
                        fontSize: 13.0,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(
                      height: 34.0,
                    ),

                    TextFormField(
                      controller:
                          _emailController,
                      focusNode:
                          _emailFocus,
                      enabled:
                          !_loading,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                      textInputAction:
                          TextInputAction
                              .next,
                      autofillHints:
                          const <
                              String>[
                        AutofillHints
                            .email,
                      ],
                      onFieldSubmitted:
                          (_) {
                        _passwordFocus
                            .requestFocus();
                      },
                      validator:
                          (String?
                              value) {
                        final String
                            email =
                            value
                                    ?.trim() ??
                                '';

                        if (email
                            .isEmpty) {
                          return 'Ingresa tu correo electrónico';
                        }

                        if (!email
                                .contains(
                              '@',
                            ) ||
                            !email
                                .contains(
                              '.',
                            )) {
                          return 'Ingresa un correo válido';
                        }

                        return null;
                      },
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Correo electrónico',
                        hintText:
                            'correo@ejemplo.com',
                        prefixIcon:
                            Icon(
                          Icons
                              .mail_outline_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15.0,
                    ),

                    TextFormField(
                      controller:
                          _passwordController,
                      focusNode:
                          _passwordFocus,
                      enabled:
                          !_loading,
                      obscureText:
                          _obscurePassword,
                      textInputAction:
                          TextInputAction
                              .done,
                      autofillHints:
                          const <
                              String>[
                        AutofillHints
                            .password,
                      ],
                      onFieldSubmitted:
                          (_) {
                        _login();
                      },
                      validator:
                          (String?
                              value) {
                        if (value ==
                                null ||
                            value
                                .isEmpty) {
                          return 'Ingresa tu contraseña';
                        }

                        return null;
                      },
                      decoration:
                          InputDecoration(
                        labelText:
                            'Contraseña',
                        prefixIcon:
                            const Icon(
                          Icons
                              .lock_outline_rounded,
                        ),
                        suffixIcon:
                            IconButton(
                          tooltip:
                              _obscurePassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                          onPressed:
                              _loading
                                  ? null
                                  : () {
                                      setState(
                                        () {
                                          _obscurePassword =
                                              !_obscurePassword;
                                        },
                                      );
                                    },
                          icon: Icon(
                            _obscurePassword
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    AnimatedSize(
                      duration:
                          const Duration(
                        milliseconds:
                            220,
                      ),
                      curve: Curves
                          .easeInOutCubic,
                      child:
                          _errorMessage ==
                                  null
                              ? const SizedBox
                                  .shrink()
                              : Padding(
                                  padding:
                                      const EdgeInsets
                                          .only(
                                    top:
                                        14.0,
                                  ),
                                  child:
                                      Container(
                                    padding:
                                        const EdgeInsets
                                            .all(
                                      12.0,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: AppTheme
                                          .danger
                                          .withValues(
                                        alpha:
                                            0.07,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        12.0,
                                      ),
                                      border:
                                          Border
                                              .all(
                                        color: AppTheme
                                            .danger
                                            .withValues(
                                          alpha:
                                              0.18,
                                        ),
                                      ),
                                    ),
                                    child:
                                        Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: <
                                          Widget>[
                                        const Icon(
                                          Icons
                                              .error_outline_rounded,
                                          color:
                                              AppTheme.danger,
                                          size:
                                              18.0,
                                        ),
                                        const SizedBox(
                                          width:
                                              8.0,
                                        ),
                                        Expanded(
                                          child:
                                              Text(
                                            _errorMessage!,
                                            style:
                                                const TextStyle(
                                              color:
                                                  AppTheme.danger,
                                              fontSize:
                                                  12.0,
                                              height:
                                                  1.35,
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                    ),

                    const SizedBox(
                      height: 24.0,
                    ),

                    PressableScale(
                      enabled:
                          !_loading,
                      onTap: _login,
                      child: SizedBox(
                        height: 56.0,
                        child:
                            FilledButton(
                          onPressed:
                              null,
                          style: FilledButton
                              .styleFrom(
                            disabledBackgroundColor:
                                AppTheme
                                    .primaryTurquoise,
                            disabledForegroundColor:
                                Colors.white,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width:
                                      22.0,
                                  height:
                                      22.0,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2.3,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Ingresar',
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 25.0,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: <Widget>[
                        const Text(
                          '¿No tienes cuenta?',
                          style:
                              TextStyle(
                            color: AppTheme
                                .textMuted,
                            fontSize:
                                13.0,
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _loading
                                  ? null
                                  : _openRegister,
                          child:
                              const Text(
                            'Regístrate',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}