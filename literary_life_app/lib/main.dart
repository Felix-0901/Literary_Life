import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'navigation/app_launch_coordinator.dart';
import 'navigation/app_navigation.dart';
import 'providers/auth_provider.dart';
import 'providers/quote_provider.dart';
import 'providers/inspiration_provider.dart';
import 'providers/cycle_provider.dart';
import 'providers/work_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/group_provider.dart';
import 'providers/notification_provider.dart';
import 'services/api_service.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/main_shell.dart';
import 'pages/settings_page.dart';
import 'widgets/maintenance_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 攔截 Flutter 框架層級的錯誤
  FlutterError.onError = (FlutterErrorDetails details) {
    // 過濾特定的按鍵斷言錯誤 (硬體鍵盤 Control Left / _pressedKeys 系列)
    final errorStr = details.exceptionAsString();
    if (errorStr.contains('_pressedKeys.containsKey(event.physicalKey)') ||
        errorStr.contains(
          'A KeyUpEvent is dispatched, but the state shows that the physical key is not pressed',
        )) {
      // 忽略此錯誤，不對外拋出大紅字
      debugPrint('Ignored a known Flutter keyboard assertion error: $errorStr');
      return;
    }

    // 其他錯誤照常印出
    FlutterError.presentError(details);
  };

  // 攔截底層非同步錯誤
  PlatformDispatcher.instance.onError = (error, stack) {
    final errorStr = error.toString();
    if (errorStr.contains('_pressedKeys.containsKey(event.physicalKey)') ||
        errorStr.contains(
          'A KeyUpEvent is dispatched, but the state shows that the physical key is not pressed',
        )) {
      debugPrint('Ignored async keyboard assertion error: $errorStr');
      return true; // 代表已處理
    }
    debugPrint('Async Error caught by PlatformDispatcher: $error');
    return false; // 其他錯誤繼續拋出
  };

  // 替換預設出現大紅字的畫面，改為溫和的空畫面或簡易提示
  ErrorWidget.builder = (FlutterErrorDetails details) {
    bool isKeyboardError = details.exceptionAsString().contains('_pressedKeys');

    if (isKeyboardError) {
      return const SizedBox.shrink(); // 如果是按鍵錯誤直接給空的，不影響後方畫面
    }

    return Material(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.red.withValues(alpha: 0.1),
          child: Text(
            kReleaseMode
                ? '發生預期外的錯誤，請稍後再試。'
                : 'Widget 渲染錯誤:\n${details.exception}',
            style: const TextStyle(color: Colors.red, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  runApp(const LiteraryLifeApp());
}

class LiteraryLifeApp extends StatefulWidget {
  const LiteraryLifeApp({
    super.key,
    this.authProvider,
    this.launchCoordinator = const AppLaunchCoordinator(),
  });

  final AuthProvider? authProvider;
  final AppLaunchCoordinator launchCoordinator;

  @override
  State<LiteraryLifeApp> createState() => _LiteraryLifeAppState();
}

class _LiteraryLifeAppState extends State<LiteraryLifeApp> with WidgetsBindingObserver {
  Timer? _maintenanceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ApiService.refreshMaintenanceStatus();
    _startMaintenanceTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ApiService.refreshMaintenanceStatus();
      _startMaintenanceTimer();
      return;
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopMaintenanceTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopMaintenanceTimer();
    super.dispose();
  }

  void _startMaintenanceTimer() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ApiService.refreshMaintenanceStatus(),
    );
  }

  void _stopMaintenanceTimer() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppLaunchCoordinator>.value(value: widget.launchCoordinator),
        if (widget.authProvider != null)
          ChangeNotifierProvider<AuthProvider>.value(value: widget.authProvider!)
        else
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(create: (_) => InspirationProvider()),
        ChangeNotifierProvider(create: (_) => CycleProvider()),
        ChangeNotifierProvider(create: (_) => WorkProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: '拾字日常',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const MaintenanceOverlay(),
            ],
          );
        },
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashPage(),
          AppRoutes.login: (context) => const LoginPage(),
          AppRoutes.register: (context) => const RegisterPage(),
          AppRoutes.main: (context) => const MainShell(),
          AppRoutes.settings: (context) => const SettingsPage(),
        },
      ),
    );
  }
}
