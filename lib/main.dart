import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'database/database.dart';
import 'pages/home/home.dart';
import 'pages/splash/splash_page.dart';
import 'services/app_bootstrapper.dart';
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

  const MyApp({super.key, required this.database, this.bootstrapper});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppBootstrapper _bootstrapper;

  @override
  void initState() {
    super.initState();
    _bootstrapper =
        widget.bootstrapper ??
        DefaultAppBootstrapper(
          database: widget.database,
          initializeNotifications: () async {
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
              await NotificationService.initialize();
            }
          },
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
        destinationBuilder: (_) => HomePage(database: widget.database),
      ),
    );
  }
}
