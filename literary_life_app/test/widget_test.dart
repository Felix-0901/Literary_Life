import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literary_life_app/main.dart';
import 'package:literary_life_app/navigation/app_launch_coordinator.dart';
import 'package:literary_life_app/pages/login_page.dart';
import 'package:literary_life_app/pages/main_shell.dart';
import 'package:literary_life_app/providers/auth_provider.dart';

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    final view = binding.platformDispatcher.views.first;
    view
      ..physicalSize = const Size(1080, 2200)
      ..devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    final view = binding.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('App routes unauthenticated users to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      LiteraryLifeApp(
        authProvider: AuthProvider(),
        launchCoordinator: const AppLaunchCoordinator(
          delay: Duration.zero,
          authResolver: _resolveLoggedOut,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('App routes authenticated users to main shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      LiteraryLifeApp(
        authProvider: AuthProvider(),
        launchCoordinator: const AppLaunchCoordinator(
          delay: Duration.zero,
          authResolver: _resolveLoggedIn,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });
}

Future<bool> _resolveLoggedOut(AuthProvider _) async => false;

Future<bool> _resolveLoggedIn(AuthProvider _) async => true;
