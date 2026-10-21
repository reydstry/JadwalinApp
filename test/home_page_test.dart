import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwalin/database/database.dart';
import 'package:jadwalin/pages/home/home.dart';
import 'package:jadwalin/pages/home/widgets/kartu_jadwal.dart';
import 'package:jadwalin/pages/jadwal/kelola_jadwal.dart';
import 'package:jadwalin/utils/day_helper.dart';

void main() {
  void homeTest(String description, WidgetTesterCallback callback) =>
      testWidgets(
        description,
        callback,
        variant: TargetPlatformVariant.only(TargetPlatform.windows),
      );
  late AppDatabase database;
  var databaseClosed = false;
  final today = DateTime.now().weekday;
  final otherDay = today == 7 ? 1 : today + 1;

  setUp(() {
    databaseClosed = false;
    database = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    if (!databaseClosed) await database.close();
  });

  Future<void> showHome(
    WidgetTester tester,
    Stream<List<JadwalDenganMataKuliah>> Function() loader,
  ) async {
    tester.view.physicalSize = const Size(400, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(database: database, scheduleLoader: loader),
      ),
    );
    await tester.pumpAndSettle();
  }

  homeTest('hari ini terpilih, jadwal terurut dan jumlah mengikuti stream', (
    tester,
  ) async {
    final controller = StreamController<List<JadwalDenganMataKuliah>>();
    addTearDown(controller.close);
    tester.view.physicalSize = const Size(400, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          database: database,
          scheduleLoader: () => controller.stream,
        ),
      ),
    );
    final lateClass = schedule(1, today, 780, 'Kuliah Siang');
    final earlyClass = schedule(2, today, 480, 'Kuliah Pagi');
    final otherClass = schedule(3, otherDay, 600, 'Kuliah Besok');
    controller.add([lateClass, otherClass, earlyClass]);
    await tester.pumpAndSettle();

    expect(find.text('Jadwal ${DayHelper.dayNames[today]}'), findsOneWidget);
    expect(find.text('${DayHelper.dayNames[today]} 2'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('selected_day_count'))).data,
      '2',
    );
    expect(find.text('Kuliah Besok'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('schedule_2'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('schedule_1'))).dy),
    );

    await tester.ensureVisible(find.byKey(ValueKey('day_$otherDay')));
    await tester.tap(find.byKey(ValueKey('day_$otherDay')));
    await tester.pumpAndSettle();
    expect(find.text('Kuliah Besok'), findsOneWidget);
    expect(find.text('Kuliah Pagi'), findsNothing);

    controller.add([lateClass, earlyClass]);
    await tester.pumpAndSettle();
    expect(find.text('Kosong'), findsOneWidget);
    expect(find.text('Tidak Ada Jadwal'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Tambah Jadwal'), findsOneWidget);
  });

  homeTest(
    'empty state membuka tambah dan kartu membuka edit dengan data tepat',
    (tester) async {
      await showHome(tester, () => Stream.value([]));
      await tester.tap(find.widgetWithText(FilledButton, 'Tambah Jadwal'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<KelolaJadwalPage>(find.byType(KelolaJadwalPage))
            .jadwalAwal,
        isNull,
      );
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();

      final data = schedule(1, today, 480, 'Pemrograman Mobile');
      await showHome(tester, () => Stream.value([data]));
      await tester.tap(find.byTooltip('Edit jadwal'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<KelolaJadwalPage>(find.byType(KelolaJadwalPage))
            .jadwalAwal,
        same(data),
      );
      expect(find.text('Pemrograman Mobile'), findsOneWidget);
    },
  );

  homeTest('gagal memuat dapat dicoba ulang melalui stream baru', (
    tester,
  ) async {
    var attempts = 0;
    await showHome(tester, () {
      attempts++;
      return attempts == 1
          ? Stream.error(Exception('detail internal database'))
          : Stream.value([schedule(1, today, 480, 'Pulih')]);
    });
    expect(find.text('Jadwal belum dapat dimuat'), findsOneWidget);
    expect(find.textContaining('detail internal'), findsNothing);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Pulih'), findsOneWidget);
    expect(find.text('Jadwal belum dapat dimuat'), findsNothing);
  });

  homeTest('loading tidak menampilkan empty state sebelum data tersedia', (
    tester,
  ) async {
    final controller = StreamController<List<JadwalDenganMataKuliah>>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          database: database,
          scheduleLoader: () => controller.stream,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Tidak Ada Jadwal'), findsNothing);
    controller.add([]);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Tidak Ada Jadwal'), findsOneWidget);
  });

  homeTest(
    'hapus batal mempertahankan data dan konfirmasi menghapus data lokal',
    (tester) async {
      await tester.runAsync(
        () => database.tambahJadwalLengkap(
          namaMataKuliah: 'Kuliah Hapus',
          hari: today,
          jamMulai: 480,
          jamSelesai: 540,
        ),
      );
      await tester.pumpWidget(MaterialApp(home: HomePage(database: database)));
      for (
        var i = 0;
        i < 30 && find.text('Kuliah Hapus').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.byTooltip('Hapus jadwal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Kuliah Hapus'), findsOneWidget);
      await tester.tap(find.byTooltip('Hapus jadwal'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      for (
        var i = 0;
        i < 30 && find.text('Tidak Ada Jadwal').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Kuliah Hapus'), findsNothing);
      expect(find.text('Kosong'), findsOneWidget);
      expect(find.text('Tidak Ada Jadwal'), findsOneWidget);
      expect(await tester.runAsync(database.ambilSemuaMataKuliah), isEmpty);
      await database.close();
      databaseClosed = true;
      await tester.pumpAndSettle();
    },
  );

  homeTest('portrait satu kolom, landscape dua kolom, tambah mengambang', (
    tester,
  ) async {
    await showHome(
      tester,
      () => Stream.value([
        schedule(1, today, 480, 'Kuliah Pertama'),
        schedule(2, today, 600, 'Kuliah Kedua'),
        schedule(3, today, 720, 'Kuliah Ketiga'),
      ]),
    );
    final first = find.byKey(const ValueKey('schedule_1'));
    final second = find.byKey(const ValueKey('schedule_2'));
    final third = find.byKey(const ValueKey('schedule_3'));
    for (final size in [
      const Size(1200, 900),
      const Size(844, 390),
      const Size(400, 874),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      final scrollable = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      );
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(first).dx, 19);
      final landscape = size.width > size.height;
      if (landscape) {
        expect(tester.getTopRight(second).dx, size.width - 19);
        expect(tester.getTopLeft(first).dy, tester.getTopLeft(second).dy);
      } else {
        expect(tester.getTopRight(first).dx, size.width - 19);
        expect(tester.getTopLeft(second).dx, 19);
        expect(
          tester.getTopLeft(second).dy,
          greaterThan(tester.getBottomLeft(first).dy),
        );
      }
      expect(tester.getBottomLeft(find.byType(ListView)).dy, size.height);
      final firstBottom = tester.getBottomLeft(first).dy;
      final thirdTop =
          firstBottom + (landscape ? 12 : tester.getSize(second).height + 24);
      await tester.scrollUntilVisible(third, 150, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(third).dy +
            tester.state<ScrollableState>(scrollable).position.pixels,
        closeTo(thirdTop, 0.01),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(third).dy,
        lessThan(tester.getTopLeft(find.byTooltip('Tambah Jadwal')).dy),
      );
      expect(tester.takeException(), isNull);
    }
    final add = find.byTooltip('Tambah Jadwal');
    expect(find.text('Tambah Jadwal'), findsNothing);
    expect(tester.getSize(add).width, 56);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.byType(KelolaJadwalPage), findsOneWidget);
  });

  homeTest('kartu menghapus bagian pengingat saat dinonaktifkan', (
    tester,
  ) async {
    final controller = StreamController<List<JadwalDenganMataKuliah>>();
    addTearDown(controller.close);
    final inactive = schedule(1, today, 480, 'Kuliah Pengingat');
    final active = JadwalDenganMataKuliah(
      jadwal: inactive.jadwal.copyWith(pengingatAktif: true, menitSebelum: 25),
      mataKuliah: inactive.mataKuliah,
    );
    controller.add([active]);
    await showHome(tester, () => controller.stream);
    final card = find.byType(KartuJadwal);
    expect(find.text('25 Menit Sebelumnya'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    final activeHeight = tester.getSize(card).height;
    controller.add([inactive]);
    await tester.pumpAndSettle();
    expect(find.text('25 Menit Sebelumnya'), findsNothing);
    expect(find.text('Pengingat Nonaktif'), findsNothing);
    expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    expect(tester.getSize(card).height, lessThan(activeHeight));

    final second = JadwalDenganMataKuliah(
      jadwal: inactive.jadwal.copyWith(id: 2, mataKuliahId: 2, jamMulai: 600),
      mataKuliah: inactive.mataKuliah.copyWith(id: 2),
    );
    tester.view.physicalSize = const Size(844, 390);
    controller.add([active, second]);
    await tester.pumpAndSettle();
    final firstCard = find.byKey(const ValueKey('schedule_1'));
    final secondCard = find.byKey(const ValueKey('schedule_2'));
    expect(tester.getTopLeft(firstCard).dy, tester.getTopLeft(secondCard).dy);
    expect(tester.getSize(secondCard).width, tester.getSize(firstCard).width);
    expect(
      tester.getSize(secondCard).height,
      lessThan(tester.getSize(firstCard).height),
    );

    controller.add([inactive, second]);
    await tester.pumpAndSettle();
    expect(tester.getSize(firstCard).height, tester.getSize(secondCard).height);
    expect(tester.takeException(), isNull);
  });

  homeTest(
    'kartu teks panjang dan skala teks besar tidak overflow pada layar sempit',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 700),
              textScaler: TextScaler.linear(1.6),
            ),
            child: HomePage(
              database: database,
              scheduleLoader: () => Stream.value([
                schedule(
                  1,
                  today,
                  480,
                  'Pemrograman Aplikasi Perangkat Bergerak Tingkat Lanjut',
                ),
              ]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KartuJadwal), findsOneWidget);
      expect(find.text('Pengingat Nonaktif'), findsNothing);
      expect(find.byIcon(Icons.notifications_off_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

JadwalDenganMataKuliah schedule(int id, int day, int start, String name) =>
    JadwalDenganMataKuliah(
      jadwal: JadwalKuliahData(
        id: id,
        mataKuliahId: id,
        hari: day,
        jamMulai: start,
        jamSelesai: start + 60,
        ruangan: 'E-301',
        pengingatAktif: false,
        menitSebelum: 5,
      ),
      mataKuliah: MataKuliahData(
        id: id,
        nama: name,
        dosen: 'Dosen dengan nama lengkap yang panjang',
        sks: 3,
      ),
    );
