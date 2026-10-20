import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jadwalin/database/database.dart';
import 'package:jadwalin/main.dart';
import 'package:jadwalin/services/app_bootstrapper.dart';
import 'package:jadwalin/services/auth_gateway.dart';

void main() {
  testWidgets('Jadwalin memuat splash sebelum membuka home', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      MyApp(
        database: database,
        bootstrapper: _ImmediateBootstrapper(
          const AppBootstrapResult(
            destination: AppLaunchDestination.home,
            isOffline: false,
            hasLocalData: false,
          ),
        ),
      ),
    );

    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));

      if (find.text('Jadwalin').evaluate().isNotEmpty) break;
    }

    expect(find.text('Jadwalin'), findsOneWidget);

    await database.close();
  });

  testWidgets('home kosong menjelaskan kondisi offline', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      MyApp(
        database: database,
        bootstrapper: _ImmediateBootstrapper(
          AppBootstrapResult.resolve(
            hasStoredSession: true,
            isOffline: true,
            hasLocalData: false,
          ),
        ),
      ),
    );

    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));

      if (find.textContaining('Kamu sedang offline').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.textContaining('Kamu sedang offline'), findsOneWidget);

    await database.close();
  });

  testWidgets('bootstrap tanpa sesi membuka alur login', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      MyApp(
        database: database,
        authGateway: _FakeAuthGateway(),
        bootstrapper: _ImmediateBootstrapper(
          AppBootstrapResult.resolve(
            hasStoredSession: false,
            isOffline: false,
            hasLocalData: false,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Loginkan Kawan!'), findsOneWidget);
    expect(find.text('Jadwalin'), findsNothing);

    await database.close();
  });
}

class _ImmediateBootstrapper implements AppBootstrapper {
  const _ImmediateBootstrapper(this.result);

  final AppBootstrapResult result;

  @override
  Future<AppBootstrapResult> load(BootstrapProgressCallback onProgress) async {
    onProgress(1);
    return result;
  }
}

class _FakeAuthGateway implements AuthGateway {
  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {}
}
