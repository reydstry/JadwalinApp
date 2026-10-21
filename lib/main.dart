import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'database/database.dart';
import 'pages/auth/auth_flow.dart';
import 'pages/home/home.dart';
import 'pages/splash/splash_page.dart';
import 'services/app_bootstrapper.dart';
import 'services/auth_gateway.dart';
import 'services/notification_service.dart';

import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();

  runApp(MyApp(database: database));
}

class MyApp extends StatefulWidget {
  final AppDatabase database;
  final AppBootstrapper? bootstrapper;
  final AuthGateway? authGateway;

  const MyApp({
    super.key,
    required this.database,
    this.bootstrapper,
    this.authGateway,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppBootstrapper _bootstrapper;
  late final AuthGateway _authGateway;

  @override
  void initState() {
    super.initState();
    _authGateway = widget.authGateway ?? const SimulatedAuthGateway();
    _bootstrapper =
        widget.bootstrapper ??
        DefaultAppBootstrapper(
          database: widget.database,
          // Sesi persisten akan disambungkan bersama backend.
          hasStoredSession: () async => false,
          // Diganti dengan status koneksi pada milestone integrasi API.
          isOffline: () async => false,
          initializeNotifications: () async {
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
              await NotificationService.initialize();
            }
          },
        );
  }

  Widget _buildAuthFlow(BuildContext context) =>
      AuthFlow(authGateway: _authGateway, homeBuilder: _buildHome);

  Widget _buildHome(
    BuildContext context, {
    bool showOfflineEmptyState = false,
  }) => HomePage(
    database: widget.database,
    showOfflineEmptyState: showOfflineEmptyState,
    onLogout: () => _logout(context),
  );

  Future<void> _logout(BuildContext context) async {
    await _authGateway.logout();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: _buildAuthFlow),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jadwalin',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primary,
        ),
      ),
      home: SplashPage(
        load: _bootstrapper.load,
        destinationBuilder: (context, result) {
          return switch (result.destination) {
            AppLaunchDestination.login => _buildAuthFlow(context),
            AppLaunchDestination.home => _buildHome(
              context,
              showOfflineEmptyState: result.showOfflineEmptyState,
            ),
          };
        },
      ),
    );
  }
}
