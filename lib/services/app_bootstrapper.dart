import '../database/database.dart';

typedef BootstrapProgressCallback = void Function(double progress);

abstract interface class AppBootstrapper {
  Future<void> load(BootstrapProgressCallback onProgress);
}

class DefaultAppBootstrapper implements AppBootstrapper {
  DefaultAppBootstrapper({
    required this.database,
    required this.initializeNotifications,
  });

  final AppDatabase database;
  final Future<void> Function() initializeNotifications;

  @override
  Future<void> load(BootstrapProgressCallback onProgress) async {
    onProgress(0);

    await database.customSelect('SELECT 1').get();
    onProgress(0.5);

    await initializeNotifications();
    onProgress(1);
  }
}
