import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwalin/database/database.dart';
import 'package:jadwalin/main.dart';
import 'package:jadwalin/pages/home/home.dart';
import 'package:jadwalin/services/app_bootstrapper.dart';
import 'package:jadwalin/services/auth_gateway.dart';

void main() {
  late AppDatabase database;
  late _AuthGateway gateway;
  var databaseClosed = false;

  setUp(() {
    databaseClosed = false;
    database = AppDatabase(NativeDatabase.memory());
    gateway = _AuthGateway();
  });

  tearDown(() async {
    if (!databaseClosed) await database.close();
  });

  Future<void> closeDatabase(WidgetTester tester) async {
    // Drift menunda pelepasan cache stream ke giliran event berikutnya.
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(database.close);
    databaseClosed = true;
    await tester.pump();
  }

  Future<void> launch(
    WidgetTester tester, {
    bool hasStoredSession = true,
  }) async {
    tester.view.physicalSize = const Size(400, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => database.customSelect('SELECT 1').getSingle());
    await tester.pumpWidget(
      MyApp(
        database: database,
        authGateway: gateway,
        bootstrapper: _Bootstrapper(hasStoredSession: hasStoredSession),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectLogout(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menu akun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar akun'));
  }

  for (final entry in ['sesi tersimpan', 'login', 'registrasi']) {
    testWidgets('keluar dari $entry membuka login tanpa riwayat Home', (
      tester,
    ) async {
      await launch(tester, hasStoredSession: entry == 'sesi tersimpan');
      if (entry != 'sesi tersimpan') {
        final register = entry == 'registrasi';
        final prefix = register ? 'register' : 'login';
        if (register) {
          await tester.tap(find.text('Daftarkeun'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('register_name_field')),
            'Raihan',
          );
        }
        await tester.enterText(
          find.byKey(Key('${prefix}_email_field')),
          'raihan@kampus.ac.id',
        );
        await tester.enterText(
          find.byKey(Key('${prefix}_password_field')),
          'rahasia123',
        );
        final submit = find.widgetWithText(
          FilledButton,
          register ? 'Register' : 'Log In',
        );
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
      }

      expect(find.byType(HomePage), findsOneWidget);
      await selectLogout(tester);
      await tester.pumpAndSettle();

      expect(gateway.logoutCalls, 1);
      expect(find.text('Loginkeun Kawan!'), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);

      // Login kembali tetap menyediakan aksi keluar pada Home berikutnya.
      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'raihan@kampus.ac.id',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'rahasia123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
      await tester.pumpAndSettle();
      await selectLogout(tester);
      await tester.pumpAndSettle();
      await tester.pump();
      expect(gateway.logoutCalls, 2);
      expect(find.text('Loginkeun Kawan!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await closeDatabase(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }

  testWidgets(
    'menu dapat dibatalkan; gagal keluar dapat dicoba ulang tanpa klik ganda',
    (tester) async {
      await launch(tester);
      await tester.tap(find.byTooltip('Menu akun'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 200));
      await tester.pumpAndSettle();
      expect(gateway.logoutCalls, 0);
      expect(find.byType(HomePage), findsOneWidget);

      // Menu tetap dapat digunakan pada layar landscape dengan teks besar.
      tester.view.physicalSize = const Size(844, 390);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      final pending = Completer<void>();
      gateway.logoutResult = pending.future;
      await selectLogout(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byTooltip('Sedang keluar akun'), findsOneWidget);
      await tester.tap(find.byTooltip('Sedang keluar akun'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(gateway.logoutCalls, 1);
      expect(find.text('Keluar akun'), findsNothing);

      pending.completeError(Exception('Kegagalan logout'));
      await tester.pumpAndSettle();
      expect(
        find.text('Gagal keluar akun. Silakan coba lagi.'),
        findsOneWidget,
      );
      expect(find.byType(HomePage), findsOneWidget);

      gateway.logoutResult = null;
      await selectLogout(tester);
      await tester.pumpAndSettle();
      await tester.pump();
      expect(gateway.logoutCalls, 2);
      expect(find.text('Loginkeun Kawan!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await closeDatabase(tester);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}

class _Bootstrapper implements AppBootstrapper {
  const _Bootstrapper({required this.hasStoredSession});

  final bool hasStoredSession;

  @override
  Future<AppBootstrapResult> load(BootstrapProgressCallback onProgress) async {
    onProgress(1);
    return AppBootstrapResult.resolve(
      hasStoredSession: hasStoredSession,
      isOffline: false,
      hasLocalData: false,
    );
  }
}

class _AuthGateway implements AuthGateway {
  int logoutCalls = 0;
  Future<void>? logoutResult;

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> logout() async {
    logoutCalls++;
    await logoutResult;
  }
}
