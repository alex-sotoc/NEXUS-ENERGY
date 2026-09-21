import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class CustomPageRoute<T>
    extends PageRouteBuilder<T> {
  CustomPageRoute({
    required Widget page,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration:
              AppConstants
                  .pageTransitionDuration,
          reverseTransitionDuration:
              AppConstants
                  .pageTransitionDuration,
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double>
                secondaryAnimation,
          ) {
            return page;
          },
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double>
                secondaryAnimation,
            Widget child,
          ) {
            final Animation<double>
                curvedAnimation =
                CurvedAnimation(
              parent: animation,
              curve:
                  Curves.easeInOutCubic,
              reverseCurve:
                  Curves.easeInOutCubic,
            );

            final Animation<Offset>
                slideAnimation =
                Tween<Offset>(
              begin:
                  const Offset(
                0.08,
                0.02,
              ),
              end: Offset.zero,
            ).animate(
              curvedAnimation,
            );

            final Animation<double>
                fadeAnimation =
                Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              curvedAnimation,
            );

            return FadeTransition(
              opacity:
                  fadeAnimation,
              child:
                  SlideTransition(
                position:
                    slideAnimation,
                child: child,
              ),
            );
          },
        );
}