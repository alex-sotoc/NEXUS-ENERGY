import 'package:flutter/material.dart';

import '../core/animations/custom_page_route.dart';
import '../core/animations/pressable_scale.dart';
import '../core/theme/app_theme.dart';
import '../navigation/main_scaffold.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';

class RegisterScreen
    extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<RegisterScreen>
      createState() =>
          _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _nameController =
      TextEditingController();

  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();

  final TextEditingController
      _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController
        .dispose();

    super.dispose();
  }

  Future<void> _register() async {
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
          await widget.authService
              .register(
        name:
            _nameController.text,
        email:
            _emailController.text,
        password:
            _passwordController.text,
        confirmPassword:
            _confirmPasswordController
                .text,
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
            'No fue posible crear la cuenta. Intenta nuevamente.';
      });
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppTheme.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Regresar',
          onPressed: _loading
              ? null
              : () {
                  Navigator.of(
                    context,
                  ).pop();
                },
          icon: const Icon(
            Icons
                .arrow_back_ios_new_rounded,
            size: 20.0,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            24.0,
            8.0,
            24.0,
            34.0,
          ),
          child: Center(
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
                      height: 28.0,
                    ),

                    const Text(
                      'Crea tu cuenta',
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
                      'Empieza a monitorear y controlar tu energía con NEXUS.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            AppTheme.textMuted,
                        fontSize: 13.0,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(
                      height: 30.0,
                    ),

                    TextFormField(
                      controller:
                          _nameController,
                      enabled:
                          !_loading,
                      textCapitalization:
                          TextCapitalization
                              .words,
                      textInputAction:
                          TextInputAction
                              .next,
                      autofillHints:
                          const <
                              String>[
                        AutofillHints
                            .name,
                      ],
                      validator:
                          (String?
                              value) {
                        final String
                            name =
                            value
                                    ?.trim() ??
                                '';

                        if (name
                            .isEmpty) {
                          return 'Ingresa tu nombre completo';
                        }

                        if (name.length <
                            2) {
                          return 'El nombre es demasiado corto';
                        }

                        return null;
                      },
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Nombre completo',
                        hintText:
                            'Tu nombre',
                        prefixIcon:
                            Icon(
                          Icons
                              .person_outline_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 14.0,
                    ),

                    TextFormField(
                      controller:
                          _emailController,
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
                      height: 14.0,
                    ),

                    TextFormField(
                      controller:
                          _passwordController,
                      enabled:
                          !_loading,
                      obscureText:
                          _obscurePassword,
                      textInputAction:
                          TextInputAction
                              .next,
                      autofillHints:
                          const <
                              String>[
                        AutofillHints
                            .newPassword,
                      ],
                      validator:
                          (String?
                              value) {
                        if (value ==
                                null ||
                            value
                                .isEmpty) {
                          return 'Ingresa una contraseña';
                        }

                        if (value.length <
                            6) {
                          return 'Usa al menos 6 caracteres';
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

                    const SizedBox(
                      height: 14.0,
                    ),

                    TextFormField(
                      controller:
                          _confirmPasswordController,
                      enabled:
                          !_loading,
                      obscureText:
                          _obscureConfirmation,
                      textInputAction:
                          TextInputAction
                              .done,
                      onFieldSubmitted:
                          (_) {
                        _register();
                      },
                      validator:
                          (String?
                              value) {
                        if (value ==
                                null ||
                            value
                                .isEmpty) {
                          return 'Confirma tu contraseña';
                        }

                        if (value !=
                            _passwordController
                                .text) {
                          return 'Las contraseñas no coinciden';
                        }

                        return null;
                      },
                      decoration:
                          InputDecoration(
                        labelText:
                            'Confirmar contraseña',
                        prefixIcon:
                            const Icon(
                          Icons
                              .lock_reset_rounded,
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed:
                              _loading
                                  ? null
                                  : () {
                                      setState(
                                        () {
                                          _obscureConfirmation =
                                              !_obscureConfirmation;
                                        },
                                      );
                                    },
                          icon: Icon(
                            _obscureConfirmation
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
                                      Text(
                                    _errorMessage!,
                                    textAlign:
                                        TextAlign
                                            .center,
                                    style:
                                        const TextStyle(
                                      color:
                                          AppTheme.danger,
                                      fontSize:
                                          12.0,
                                      fontWeight:
                                          FontWeight.w600,
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
                      onTap: _register,
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
                                  'Registrar cuenta',
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 17.0,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: <Widget>[
                        const Text(
                          '¿Ya tienes cuenta?',
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
                                  : () {
                                      Navigator.of(
                                        context,
                                      ).pop();
                                    },
                          child:
                              const Text(
                            'Ingresar',
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