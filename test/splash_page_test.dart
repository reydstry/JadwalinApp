import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwalin/pages/splash/splash_page.dart';
import 'package:jadwalin/services/app_bootstrapper.dart';

void main() {
  testWidgets('menampilkan progres nyata lalu membuka tujuan satu kali', (
    tester,
  ) async {
    final selesaiMemuat = Completer<void>();
    late ValueChanged<double> laporkanProgres;
    var jumlahPembuatanTujuan = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(
          load: (onProgress) {
            laporkanProgres = onProgress;
            return selesaiMemuat.future.then(
              (_) => const AppBootstrapResult(
                destination: AppLaunchDestination.home,
                isOffline: false,
                hasLocalData: true,
              ),
            );
          },
          destinationBuilder: (_, _) {
            jumlahPembuatanTujuan++;
            return const Scaffold(body: Text('Beranda tujuan'));
          },
        ),
      ),
    );

    expect(find.bySemanticsLabel('Memuat aplikasi 0%'), findsOneWidget);
    expect(find.text('Beranda tujuan'), findsNothing);

    laporkanProgres(0.5);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 375));
    expect(find.bySemanticsLabel('Memuat aplikasi 25%'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 375));

    expect(find.bySemanticsLabel('Memuat aplikasi 50%'), findsOneWidget);
    expect(find.text('Beranda tujuan'), findsNothing);

    selesaiMemuat.complete();
    await tester.pumpAndSettle();

    expect(find.text('Beranda tujuan'), findsOneWidget);
    expect(jumlahPembuatanTujuan, 1);
  });

  testWidgets('pemuatan instan tetap menampilkan animasi minimal 1,5 detik', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(
          load: (onProgress) async {
            onProgress(1);
            return const AppBootstrapResult(
              destination: AppLaunchDestination.login,
              isOffline: false,
              hasLocalData: false,
            );
          },
          destinationBuilder: (_, _) =>
              const Scaffold(body: Text('Login tujuan')),
        ),
      ),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Memuat aplikasi 0%'), findsOneWidget);
    final reveal = find.byKey(const ValueKey('splash-logo-reveal'));
    Path revealedArea() => tester
        .widget<ClipPath>(reveal)
        .clipper!
        .getClip(tester.getSize(reveal));
    expect(revealedArea().getBounds().isEmpty, isTrue);
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.bySemanticsLabel('Memuat aplikasi 50%'), findsOneWidget);
    final logo = find.byKey(const ValueKey('splash-logo'));
    expect(
      find.ancestor(of: logo, matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(tester.widget<Image>(logo).opacity, isNull);
    expect(revealedArea().contains(const Offset(100, 150)), isTrue);
    expect(revealedArea().contains(const Offset(100, 50)), isFalse);
    await tester.pump(const Duration(milliseconds: 749));
    expect(find.text('Login tujuan'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(revealedArea().contains(const Offset(100, 1)), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Login tujuan'), findsOneWidget);
  });

  testWidgets('durasi minimum tidak melewati pemuatan yang belum selesai', (
    tester,
  ) async {
    final loaded = Completer<AppBootstrapResult>();
    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(
          load: (onProgress) {
            onProgress(1);
            return loaded.future;
          },
          destinationBuilder: (_, _) =>
              const Scaffold(body: Text('Home tujuan')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Home tujuan'), findsNothing);
    expect(find.bySemanticsLabel('Memuat aplikasi 90%'), findsOneWidget);
    loaded.complete(
      const AppBootstrapResult(
        destination: AppLaunchDestination.home,
        isOffline: false,
        hasLocalData: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home tujuan'), findsOneWidget);
  });

  testWidgets('menutup splash saat animasi berjalan membatalkan navigasi', (
    tester,
  ) async {
    var navigations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(
          load: (_) async => const AppBootstrapResult(
            destination: AppLaunchDestination.login,
            isOffline: false,
            hasLocalData: false,
          ),
          destinationBuilder: (_, _) {
            navigations++;
            return const Scaffold();
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(navigations, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meneruskan kondisi offline tanpa data ke halaman tujuan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(
          load: (_) async => AppBootstrapResult.resolve(
            hasStoredSession: true,
            isOffline: true,
            hasLocalData: false,
          ),
          destinationBuilder: (_, result) {
            return Scaffold(
              body: Text(
                result.showOfflineEmptyState
                    ? 'Belum ada data lokal. Kamu sedang offline.'
                    : 'Home',
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Belum ada data lokal. Kamu sedang offline.'), findsOne);
  });

  test('tanpa sesi tersimpan menghasilkan tujuan login', () {
    final result = AppBootstrapResult.resolve(
      hasStoredSession: false,
      isOffline: true,
      hasLocalData: true,
    );

    expect(result.destination, AppLaunchDestination.login);
  });

  test('data lokal mencegah empty state offline', () {
    final result = AppBootstrapResult.resolve(
      hasStoredSession: true,
      isOffline: true,
      hasLocalData: true,
    );

    expect(result.destination, AppLaunchDestination.home);
    expect(result.showOfflineEmptyState, isFalse);
  });

  testWidgets('kegagalan dapat dicoba lagi tanpa proses ganda', (tester) async {
    final percobaanKedua = Completer<AppBootstrapResult>();
    var jumlahPercobaan = 0;
    var jumlahPembuatanTujuan = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(
          load: (_) {
            jumlahPercobaan++;

            if (jumlahPercobaan == 1) {
              return Future.error(Exception('Database tidak tersedia'));
            }

            return percobaanKedua.future;
          },
          destinationBuilder: (_, _) {
            jumlahPembuatanTujuan++;
            return const Scaffold(body: Text('Beranda tujuan'));
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Aplikasi belum siap'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Coba lagi'), findsOneWidget);
    expect(find.text('Beranda tujuan'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Coba lagi'));
    await tester.tap(find.widgetWithText(FilledButton, 'Coba lagi'));
    await tester.pump();

    expect(jumlahPercobaan, 2);
    expect(find.text('Beranda tujuan'), findsNothing);

    percobaanKedua.complete(
      const AppBootstrapResult(
        destination: AppLaunchDestination.home,
        isOffline: false,
        hasLocalData: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beranda tujuan'), findsOneWidget);
    expect(jumlahPembuatanTujuan, 1);
  });
}
