import '../database/database.dart';

typedef BootstrapProgressCallback = void Function(double progress);

enum AppLaunchDestination { login, home }

class AppBootstrapResult {
  const AppBootstrapResult({
    required this.destination,
    required this.isOffline,
    required this.hasLocalData,
  });

  factory AppBootstrapResult.resolve({
    required bool hasStoredSession,
    required bool isOffline,
    required bool hasLocalData,
  }) {
    return AppBootstrapResult(
      destination: hasStoredSession
          ? AppLaunchDestination.home
          : AppLaunchDestination.login,
      isOffline: isOffline,
      hasLocalData: hasLocalData,
    );
  }

  final AppLaunchDestination destination;
  final bool isOffline;
  final bool hasLocalData;

  bool get showOfflineEmptyState {
    return destination == AppLaunchDestination.home &&
        isOffline &&
        !hasLocalData;
  }
}

abstract interface class AppBootstrapper {
  Future<AppBootstrapResult> load(BootstrapProgressCallback onProgress);
}

class DefaultAppBootstrapper implements AppBootstrapper {
  DefaultAppBootstrapper({
    required this.database,
    required this.hasStoredSession,
    required this.isOffline,
    required this.initializeNotifications,
  });

  final AppDatabase database;
  final Future<bool> Function() hasStoredSession;
  final Future<bool> Function() isOffline;
  final Future<void> Function() initializeNotifications;

  @override
  Future<AppBootstrapResult> load(BootstrapProgressCallback onProgress) async {
    onProgress(0);

    final localSchedules = await database.watchSemuaJadwalLengkap().first;
    onProgress(0.25);

    final sessionAvailable = await hasStoredSession();
    onProgress(0.5);

    final offline = await isOffline();
    onProgress(0.75);

    await initializeNotifications();
    onProgress(1);

    return AppBootstrapResult.resolve(
      hasStoredSession: sessionAvailable,
      isOffline: offline,
      hasLocalData: localSchedules.isNotEmpty,
    );
  }
}
