import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class NewDeviceDialog extends StatefulWidget {
  const NewDeviceDialog({
    super.key,
    required this.deviceId,
    required this.onSave,
    this.initialName = '',
  });

  final String deviceId;
  final String initialName;
  final Future<void> Function(String name) onSave;

  static Future<void> show(
    BuildContext context, {
    required String deviceId,
    required Future<void> Function(String name) onSave,
    String initialName = '',
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Nuevo dispositivo',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5.0,
            sigmaY: 5.0,
          ),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: NewDeviceDialog(
                deviceId: deviceId,
                initialName: initialName,
                onSave: onSave,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final Animation<double> curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.94,
              end: 1.0,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<NewDeviceDialog> createState() => _NewDeviceDialogState();
}

class _NewDeviceDialogState extends State<NewDeviceDialog> {
  late final TextEditingController _controller;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() {
        _error = 'Escribe un nombre para el dispositivo.';
      });
      return;
    }

    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(name);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxWidth =
        MediaQuery.sizeOf(context).width - 40.0;

    return Container(
      width: maxWidth > 420.0 ? 420.0 : maxWidth,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(26.0),
        border: Border.all(
          color: AppTheme.borderLight,
        ),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 58.0,
            height: 58.0,
            decoration: BoxDecoration(
              color: AppTheme.primaryTurquoiseLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryTurquoise.withValues(alpha: 0.20),
              ),
            ),
            child: const Icon(
              Icons.add_link_rounded,
              color: AppTheme.primaryTurquoise,
              size: 29.0,
            ),
          ),
          const SizedBox(height: 18.0),
          const Text(
            '¡Nuevo Dispositivo Detectado!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.secondaryDark,
              fontSize: 20.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Nombra tu dispositivo para identificarlo fácilmente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13.0,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.deviceId,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20.0),
          TextField(
            controller: _controller,
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              _save();
            },
            decoration: const InputDecoration(
              labelText: 'Nombre del dispositivo',
              hintText: 'Ej. Televisor Sala',
              prefixIcon: Icon(
                Icons.edit_outlined,
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppTheme.danger,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20.0),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _saving
                    ? const SizedBox(
                        key: ValueKey<String>('loading'),
                        width: 21.0,
                        height: 21.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar',
                        key: ValueKey<String>('save'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}