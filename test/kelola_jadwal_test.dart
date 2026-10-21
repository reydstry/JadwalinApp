import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwalin/database/database.dart';
import 'package:jadwalin/pages/jadwal/kelola_jadwal.dart';

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<void> openForm(
    WidgetTester tester, {
    JadwalDenganMataKuliah? data,
    Size size = const Size(400, 874),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('Buka formulir'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (_) =>
                      KelolaJadwalPage(database: database, jadwalAwal: data),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka formulir'));
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('schedule_save')));
    await tester.tap(find.byKey(const Key('schedule_save')));
    await tester.pump();
  }

  Future<void> enter(WidgetTester tester, String field, String value) async {
    final finder = find.byKey(Key('schedule_$field'));
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await tester.pump();
  }

  Future<void> settleDatabase(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  void formTest(String name, WidgetTesterCallback callback) => testWidgets(
    name,
    callback,
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  formTest('field wajib menolak form kosong dan SKS desimal', (tester) async {
    await openForm(tester);
    await tapSave(tester);
    await tester.pumpAndSettle();
    for (final message in [
      'Nama mata kuliah wajib diisi',
      'Nama dosen wajib diisi',
      'Jumlah SKS wajib diisi',
      'Jam mulai wajib dipilih',
      'Jam selesai wajib dipilih',
      'Ruangan wajib diisi',
    ]) {
      expect(find.text(message), findsOneWidget);
    }
    await enter(tester, 'credits', '2.5');
    await tapSave(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('SKS harus berupa bilangan bulat positif'),
      findsOneWidget,
    );
    expect(await tester.runAsync(database.ambilSemuaMataKuliah), isEmpty);
  });

  formTest('rotasi dan keyboard mempertahankan input serta pilihan pengingat', (
    tester,
  ) async {
    await openForm(tester);
    await enter(tester, 'name', 'Pemrograman Mobile');
    await enter(tester, 'lecturer', 'Dosen Kampus');
    await enter(tester, 'credits', '3');
    await enter(tester, 'room', 'G301');
    await tester.ensureVisible(find.byKey(const Key('schedule_reminder')));
    await tester.tap(find.byKey(const Key('schedule_reminder')));
    await tester.pumpAndSettle();
    final minutes = find.byKey(const ValueKey('reminder_minutes_15'));
    await tester.ensureVisible(minutes);
    await tester.tap(minutes);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('45 menit sebelumnya').last);
    await tester.tap(find.text('45 menit sebelumnya').last);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('schedule_two_columns')), findsOneWidget);
    for (final value in [
      'Pemrograman Mobile',
      'Dosen Kampus',
      '3',
      'G301',
      '45 menit sebelumnya',
    ]) {
      expect(find.text(value), findsOneWidget);
    }
    tester.view.viewInsets = const FakeViewPadding(bottom: 170);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('schedule_save')));
    expect(
      find.byKey(const Key('schedule_save')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  formTest(
    'perubahan belum disimpan dilindungi dan batal keluar mempertahankan input',
    (tester) async {
      await openForm(tester);
      await enter(tester, 'name', 'Data belum disimpan');
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(find.text('Buang perubahan?'), findsOneWidget);
      await tester.tap(find.text('Lanjut Mengisi'));
      await tester.pumpAndSettle();
      expect(find.text('Data belum disimpan'), findsOneWidget);
      // System back must use the same confirmation as the app-bar button.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buang Perubahan'));
      await tester.pumpAndSettle();
      expect(find.text('Buka formulir'), findsOneWidget);
      expect(find.byType(KelolaJadwalPage), findsNothing);
    },
  );

  formTest('edit terisi dan menyimpan identitas yang sama tanpa duplikat', (
    tester,
  ) async {
    final id = await tester.runAsync(
      () => database.tambahJadwalLengkap(
        namaMataKuliah: 'Kuliah Lama',
        dosen: 'Dosen',
        sks: 3,
        hari: 1,
        jamMulai: 480,
        jamSelesai: 540,
        ruangan: 'G301',
        pengingatAktif: true,
        menitSebelum: 25,
      ),
    );
    final data = await tester.runAsync(() => readSchedules(database));
    await openForm(tester, data: data!.single);
    expect(find.text('Edit Jadwal'), findsOneWidget);
    expect(find.text('Kuliah Lama'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    await enter(tester, 'name', 'Kuliah Baru');
    await tapSave(tester);
    await tester.tap(find.byKey(const Key('schedule_save')));
    await settleDatabase(tester);
    expect(find.byType(KelolaJadwalPage), findsNothing);
    final saved = await tester.runAsync(() => readSchedules(database));
    expect(saved, hasLength(1));
    expect(saved!.single.jadwal.id, id);
    expect(saved.single.mataKuliah.nama, 'Kuliah Baru');
    expect(saved.single.jadwal.menitSebelum, 25);
    await database.close();
  });

  formTest(
    'edit tanpa perubahan dapat kembali langsung dan teks besar tidak overflow',
    (tester) async {
      final data = fixture();
      await openForm(
        tester,
        data: data,
        size: const Size(320, 700),
        scale: 1.6,
      );
      await tester.ensureVisible(find.byKey(const Key('schedule_save')));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(find.text('Buang perubahan?'), findsNothing);
      expect(find.text('Buka formulir'), findsOneWidget);
    },
  );

  formTest('time picker landscape dapat dipakai tanpa overflow', (
    tester,
  ) async {
    await openForm(tester, size: const Size(844, 390));
    tester.view.viewInsets = const FakeViewPadding(bottom: 170);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('schedule_start')));
    await tester.tap(find.byKey(const ValueKey('schedule_start')));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Pilih'));
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();
    expect(find.text('08:00'), findsOneWidget);
  });

  formTest('jam selesai sebelum jam mulai ditolak di field terkait', (
    tester,
  ) async {
    await openForm(tester, data: fixture(), size: const Size(844, 390));
    await tester.ensureVisible(find.byKey(const ValueKey('schedule_start')));
    await tester.tap(find.byKey(const ValueKey('schedule_start')));
    await tester.pumpAndSettle();
    final hour = find
        .descendant(
          of: find.byType(TimePickerDialog),
          matching: find.byType(TextField),
        )
        .first;
    await tester.enterText(hour, '10');
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();
    await tapSave(tester);
    await tester.pumpAndSettle();
    expect(find.text('Harus setelah jam mulai'), findsOneWidget);
    expect(find.byType(KelolaJadwalPage), findsOneWidget);
    expect(await tester.runAsync(database.ambilSemuaMataKuliah), isEmpty);
  });

  formTest('tambah menyimpan data dan pengingat 60 menit dari landscape', (
    tester,
  ) async {
    await openForm(tester, size: const Size(844, 390));
    await enter(tester, 'name', 'Kuliah Baru');
    await enter(tester, 'lecturer', 'Dosen Kampus');
    await enter(tester, 'credits', '3');
    await enter(tester, 'room', 'G301');
    for (final field in ['start', 'end']) {
      await tester.ensureVisible(find.byKey(ValueKey('schedule_$field')));
      await tester.tap(find.byKey(ValueKey('schedule_$field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pilih'));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.byKey(const Key('schedule_reminder')));
    await tester.tap(find.byKey(const Key('schedule_reminder')));
    await tester.pumpAndSettle();
    final minutes = find.byKey(const ValueKey('reminder_minutes_15'));
    await tester.ensureVisible(minutes);
    await tester.tap(minutes);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('60 menit sebelumnya'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    for (
      var i = 0;
      i < 5 &&
          find.text('60 menit sebelumnya').hitTestable().evaluate().isEmpty;
      i++
    ) {
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -80));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('60 menit sebelumnya').hitTestable());
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(find.byKey(const Key('schedule_reminder')));
      await tester.tap(find.byKey(const Key('schedule_reminder')));
      await tester.pumpAndSettle();
    }
    expect(find.text('60 menit sebelumnya'), findsOneWidget);
    await tapSave(tester);
    await settleDatabase(tester);
    expect(find.byType(KelolaJadwalPage), findsNothing);
    final saved = await tester.runAsync(() => readSchedules(database));
    expect(saved, hasLength(1));
    expect(saved!.single.mataKuliah.nama, 'Kuliah Baru');
    expect(saved.single.jadwal.jamMulai, 480);
    expect(saved.single.jadwal.jamSelesai, 600);
    expect(saved.single.jadwal.pengingatAktif, isTrue);
    expect(saved.single.jadwal.menitSebelum, 60);
  });

  formTest(
    'gagal simpan mempertahankan isian dan mengaktifkan tombol kembali',
    (tester) async {
      await database.close();
      database = _FailingDatabase();
      await openForm(tester, data: fixture());
      await enter(tester, 'name', 'Perubahan Tetap Ada');
      await tapSave(tester);
      await settleDatabase(tester);
      expect(
        find.textContaining('Jadwal belum berhasil disimpan'),
        findsOneWidget,
      );
      expect(find.text('Perubahan Tetap Ada'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('schedule_save')))
            .onPressed,
        isNotNull,
      );
      expect(find.byType(KelolaJadwalPage), findsOneWidget);
    },
  );
}

JadwalDenganMataKuliah fixture() => JadwalDenganMataKuliah(
  jadwal: const JadwalKuliahData(
    id: 1,
    mataKuliahId: 1,
    hari: 1,
    jamMulai: 480,
    jamSelesai: 540,
    ruangan: 'G301',
    pengingatAktif: false,
    menitSebelum: 15,
  ),
  mataKuliah: const MataKuliahData(
    id: 1,
    nama: 'Pemrograman Mobile',
    dosen: 'Dosen Kampus',
    sks: 3,
  ),
);

Future<List<JadwalDenganMataKuliah>> readSchedules(AppDatabase database) async {
  final schedules = await database.select(database.jadwalKuliahTable).get();
  final subjects = await database.ambilSemuaMataKuliah();
  return [
    for (final schedule in schedules)
      JadwalDenganMataKuliah(
        jadwal: schedule,
        mataKuliah: subjects.singleWhere(
          (subject) => subject.id == schedule.mataKuliahId,
        ),
      ),
  ];
}

class _FailingDatabase extends AppDatabase {
  _FailingDatabase() : super(NativeDatabase.memory());

  @override
  Future<bool> adaBentrokJadwal({
    required int hari,
    required int jamMulai,
    required int jamSelesai,
    int? kecualiJadwalId,
  }) async {
    throw StateError('Database unavailable');
  }
}
