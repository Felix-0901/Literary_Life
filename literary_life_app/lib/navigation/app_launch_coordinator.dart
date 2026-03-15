import '../providers/auth_provider.dart';
import 'app_navigation.dart';

typedef AuthResolver = Future<bool> Function(AuthProvider authProvider);

class AppLaunchCoordinator {
  const AppLaunchCoordinator({
    this.delay = const Duration(seconds: 3),
    this.authResolver = _defaultAuthResolver,
  });

  final Duration delay;
  final AuthResolver authResolver;

  Future<String> resolveInitialRoute(AuthProvider authProvider) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    final isLoggedIn = await authResolver(authProvider);
    return isLoggedIn ? AppRoutes.main : AppRoutes.login;
  }

  static Future<bool> _defaultAuthResolver(AuthProvider authProvider) {
    return authProvider.tryAutoLogin();
  }
}
