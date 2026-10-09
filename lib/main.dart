import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'database/database.dart';
import 'pages/home/home.dart';
// import 'pages/home/latihan_home.dart';
import 'services/notification_service.dart';

import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await NotificationService.initialize();
  }

  runApp(MyApp(database: database));
}

class MyApp extends StatefulWidget {
  final AppDatabase database;

  const MyApp({super.key, required this.database});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await NotificationService.handleInitialPermissions();
      }
    });
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
      home: HomePage(database: widget.database),
      // home: LatihanHomePage(),
    );
  }
}
