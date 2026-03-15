import 'package:flutter/material.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const main = '/main';
  static const settings = '/settings';
}

class AppNavigation {
  static void goToMain(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false);
  }

  static void goToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }
}
