import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// =================================
// TABEL MATA KULIAH
// =================================

@DataClassName('MataKuliahData')
class MataKuliahTable extends Table {
  @override
  String get tableName => 'mata_kuliah';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get nama => text().withLength(min: 1, max: 100)();

  TextColumn get dosen => text().nullable()();

  IntColumn get sks => integer().nullable()();
}

// =================================
// TABEL JADWAL KULIAH
// =================================

@DataClassName('JadwalKuliahData')
class JadwalKuliahTable extends Table {
  @override
  String get tableName => 'jadwal_kuliah';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get mataKuliahId =>
      integer().references(MataKuliahTable, #id, onDelete: KeyAction.cascade)();

  IntColumn get hari => integer()();

  IntColumn get jamMulai => integer()();

  IntColumn get jamSelesai => integer()();

  TextColumn get ruangan => text().nullable()();

  BoolColumn get pengingatAktif =>
      boolean().withDefault(const Constant(false))();

  IntColumn get menitSebelum => integer().withDefault(const Constant(15))();
}

class JadwalDenganMataKuliah {
  final JadwalKuliahData jadwal;
  final MataKuliahData mataKuliah;

  const JadwalDenganMataKuliah({
    required this.jadwal,
    required this.mataKuliah,
  });
}

// =================================
// DATABASE
// =================================

@DriftDatabase(tables: [MataKuliahTable, JadwalKuliahTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // =================================
  // CRUD MATA KULIAH
  // =================================

  Future<int> tambahMataKuliah({
    required String nama,
    String? dosen,
    int? sks,
  }) {
    return into(mataKuliahTable).insert(
      MataKuliahTableCompanion.insert(
        nama: nama,
        dosen: Value(dosen),
        sks: Value(sks),
      ),
    );
  }

  Future<List<MataKuliahData>> ambilSemuaMataKuliah() {
    return select(mataKuliahTable).get();
  }

  Stream<List<MataKuliahData>> watchSemuaMataKuliah() {
    return select(mataKuliahTable).watch();
  }

  // =================================
  // JADWAL LENGKAP CRUD
  // =================================

  Future<int> tambahJadwalLengkap({
    required String namaMataKuliah,
    String? dosen,
    int? sks,
    required int hari,
    required int jamMulai,
    required int jamSelesai,
    String? ruangan,
    bool pengingatAktif = false,
    int menitSebelum = 15,
  }) {
    return transaction(() async {
      final mataKuliahId = await into(mataKuliahTable).insert(
        MataKuliahTableCompanion.insert(
          nama: namaMataKuliah,
          dosen: Value(dosen),
          sks: Value(sks),
        ),
      );

      final jadwalId = await into(jadwalKuliahTable).insert(
        JadwalKuliahTableCompanion.insert(
          mataKuliahId: mataKuliahId,
          hari: hari,
          jamMulai: jamMulai,
          jamSelesai: jamSelesai,
          ruangan: Value(ruangan),
          pengingatAktif: Value(pengingatAktif),
          menitSebelum: Value(menitSebelum),
        ),
      );

      return jadwalId;
    });
  }

  Future<void> updateJadwalLengkap({
    required int jadwalId,
    required int mataKuliahId,
    required String namaMataKuliah,
    String? dosen,
    int? sks,
    required int hari,
    required int jamMulai,
    required int jamSelesai,
    String? ruangan,
    required bool pengingatAktif,
    required int menitSebelum,
  }) {
    return transaction(() async {
      await (update(
        mataKuliahTable,
      )..where((t) => t.id.equals(mataKuliahId))).write(
        MataKuliahTableCompanion(
          nama: Value(namaMataKuliah),
          dosen: Value(dosen),
          sks: Value(sks),
        ),
      );

      await (update(
        jadwalKuliahTable,
      )..where((t) => t.id.equals(jadwalId))).write(
        JadwalKuliahTableCompanion(
          hari: Value(hari),
          jamMulai: Value(jamMulai),
          jamSelesai: Value(jamSelesai),
          ruangan: Value(ruangan),
          pengingatAktif: Value(pengingatAktif),
          menitSebelum: Value(menitSebelum),
        ),
      );
    });
  }

  Future<void> hapusJadwalLengkap({
    required int jadwalId,
    required int mataKuliahId,
  }) {
    return transaction(() async {
      await (delete(
        jadwalKuliahTable,
      )..where((t) => t.id.equals(jadwalId))).go();

      final jadwalLain = await (select(
        jadwalKuliahTable,
      )..where((t) => t.mataKuliahId.equals(mataKuliahId))).get();

      if (jadwalLain.isEmpty) {
        await (delete(
          mataKuliahTable,
        )..where((t) => t.id.equals(mataKuliahId))).go();
      }
    });
  }

  Future<bool> adaBentrokJadwal({
    required int hari,
    required int jamMulai,
    required int jamSelesai,
    int? kecualiJadwalId,
  }) async {
    final query = select(jadwalKuliahTable)
      ..where((t) {
        var kondisi =
            t.hari.equals(hari) &
            t.jamMulai.isSmallerThanValue(jamSelesai) &
            t.jamSelesai.isBiggerThanValue(jamMulai);

        if (kecualiJadwalId != null) {
          kondisi = kondisi & t.id.equals(kecualiJadwalId).not();
        }

        return kondisi;
      })
      ..limit(1);

    final hasil = await query.get();

    return hasil.isNotEmpty;
  }

  // =================================
  // MIGRATION
  // =================================

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  // =================================
  // CONNECTION
  // =================================

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'jadwalin',

      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),

      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }

  Stream<List<JadwalDenganMataKuliah>> watchSemuaJadwalLengkap() {
    final query = select(jadwalKuliahTable).join([
      innerJoin(
        mataKuliahTable,
        mataKuliahTable.id.equalsExp(jadwalKuliahTable.mataKuliahId),
      ),
    ]);

    query.orderBy([
      OrderingTerm.asc(jadwalKuliahTable.hari),
      OrderingTerm.asc(jadwalKuliahTable.jamMulai),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return JadwalDenganMataKuliah(
          jadwal: row.readTable(jadwalKuliahTable),
          mataKuliah: row.readTable(mataKuliahTable),
        );
      }).toList();
    });
  }
}
