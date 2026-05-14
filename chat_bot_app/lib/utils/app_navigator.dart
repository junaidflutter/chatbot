import 'dart:io';

import 'package:flutter/cupertino.dart';

enum RouteAnimationType { rightToLeft, bottomToTop, fade }

class AppNavigator {
  AppNavigator._();

  static Route _buildPageRoute(
    Widget screen, {
    RouteAnimationType animation = RouteAnimationType.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    // ✅ iOS swipe-back gesture fix
    if (Platform.isIOS && animation == RouteAnimationType.rightToLeft) {
      return CupertinoPageRoute(builder: (context) => screen);
    }

    return PageRouteBuilder(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation1, animation2) => screen,
      transitionsBuilder: (context, animation1, animation2, child) {
        switch (animation) {
          case RouteAnimationType.bottomToTop:
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation1,
                      curve: Curves.easeInOut,
                    ),
                  ),
              child: child,
            );

          case RouteAnimationType.fade:
            return FadeTransition(opacity: animation1, child: child);

          case RouteAnimationType.rightToLeft:
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation1,
                      curve: Curves.easeInOut,
                    ),
                  ),
              child: child,
            );
        }
      },
    );
  }

  static Future<dynamic> push(
    BuildContext context,
    Widget screen, {
    RouteAnimationType animation = RouteAnimationType.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.push(
      context,
      _buildPageRoute(screen, animation: animation, duration: duration),
    );
  }

  static Future<dynamic> pushReplacement(
    BuildContext context,
    Widget screen, {
    RouteAnimationType animation = RouteAnimationType.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.pushReplacement(
      context,
      _buildPageRoute(screen, animation: animation, duration: duration),
    );
  }

  static Future<dynamic> removeAllPreviousAndPush(
    BuildContext context,
    Widget screen, {
    RouteAnimationType animation = RouteAnimationType.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.pushAndRemoveUntil(
      context,
      _buildPageRoute(screen, animation: animation, duration: duration),
      (route) => false,
    );
  }

  static void pop(BuildContext context, [dynamic data]) {
    Navigator.of(context).pop(data);
  }

  static void popUntilFirst(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
