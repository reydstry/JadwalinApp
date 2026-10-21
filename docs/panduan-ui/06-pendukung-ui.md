# Helper, data, dan service yang berhubungan dengan UI

[Daftar isi](README.md) · [Dasar](00-dasar.md) · [Glosarium](05-glosarium.md)

Delapan file pendukung manual dibahas di sini. Kode lengkap disertakan untuk file yang memiliki isi; `api_service.dart` masih kosong. File kesembilan, `database.g.dart`, merupakan kode generator dan dipetakan perannya setelah file sumber database. Fokus penjelasan tetap pada bagaimana data dan service memengaruhi UI.

<a id="file-lib-utils-day-helper-dart"></a>

## `lib/utils/day_helper.dart`

[Buka sumber](../../lib/utils/day_helper.dart)

**Peran:** memetakan angka hari Dart ke nama hari berbahasa Indonesia.

### Kode lengkap

<!-- SUMBER:lib/utils/day_helper.dart SHA256=0b3d6df25f711dc08e8e939b7b1dd32079ca32bf9b2aadbdf8093bf715e5e3ce -->

```dart
class DayHelper {
  DayHelper._();

  static const Map<int, String> dayNames = {
    DateTime.monday: 'Senin',
    DateTime.tuesday: 'Selasa',
    DateTime.wednesday: 'Rabu',
    DateTime.thursday: 'Kamis',
    DateTime.friday: 'Jumat',
    DateTime.saturday: 'Sabtu',
    DateTime.sunday: 'Minggu',
  };
}
```

### Penjelasan dan alasan

`DayHelper` adalah class utilitas, bukan widget. `DayHelper._()` adalah constructor private; pemakai tidak perlu membuat objek helper. `static const Map<int, String> dayNames` menyediakan pasangan kunci/nilai yang tetap.

`DateTime.monday` sampai `DateTime.sunday` bernilai 1 sampai 7. Ini menyamakan representasi hari di data jadwal, pilihan hari, dan teks UI. Pemanggilan `DayHelper.dayNames[hari]` menghasilkan `String?` karena pencarian Map bisa gagal ketika kunci tidak tersedia; karena itu pemanggil perlu memperhatikan fallback atau penegasan non-null.

<a id="file-lib-utils-time-helper-dart"></a>

## `lib/utils/time_helper.dart`

[Buka sumber](../../lib/utils/time_helper.dart)

**Peran:** menampilkan waktu tersimpan sebagai teks yang konsisten.

### Kode lengkap

<!-- SUMBER:lib/utils/time_helper.dart SHA256=554d9bd26913d899e76e0c6c81734cc0afabd4576b4233ae869bcd9afa4a90b7 -->

```dart
class TimeHelper {
  TimeHelper._();

  static String formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    final formattedHours = hours.toString().padLeft(2, '0');
    final formattedMinutes = minutes.toString().padLeft(2, '0');

    return '$formattedHours:$formattedMinutes';
  }

  static String formatRange(int start, int end) {
    return '${formatMinutes(start)} - ${formatMinutes(end)}';
  }
}
```

### Penjelasan dan alasan

`TimeHelper` memakai constructor private dan method static. Data waktu jadwal disimpan sebagai jumlah menit dari awal hari, bukan string jam.

`formatMinutes` membagi nilai dengan `~/ 60` untuk mendapatkan jam dan mengambil `% 60` untuk menit. `toString().padLeft(2, '0')` memastikan satu digit mendapat nol di depan. Misalnya 485 menjadi jam 8 dan menit 5, lalu ditampilkan sebagai `08:05`.

`formatRange(start, end)` memanggil formatter yang sama untuk dua batas dan menambahkan pemisah ` - `. Manfaatnya, kartu dan ringkasan tidak perlu menulis ulang perhitungan jam. Method ini memformat nilai; ia tidak memvalidasi bahwa angka berada dalam rentang satu hari atau urutan waktunya benar.

<a id="file-lib-services-app-bootstrapper-dart"></a>

## `lib/services/app_bootstrapper.dart`

[Buka sumber](../../lib/services/app_bootstrapper.dart)

**Peran:** menyediakan hasil pemuatan awal agar splash mengetahui progress dan halaman tujuan.

### Kode lengkap

<!-- SUMBER:lib/services/app_bootstrapper.dart SHA256=f835f855ea38b9e7a295466cf71297809a55d82a64f17fb1630b674c0dc9719b -->

```dart
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
```

### Class dan fungsi yang dipakai

| Simbol | Fungsi dan alasan |
|---|---|
| `BootstrapProgressCallback` | Alias `void Function(double progress)`; melaporkan angka progress ke UI. |
| `AppLaunchDestination` | Enum login/home agar pilihan destinasi eksplisit. |
| `AppBootstrapResult` | Objek hasil berisi destinasi, offline, dan ketersediaan data lokal. |
| `AppBootstrapResult.resolve` | Factory yang memilih home jika ada sesi tersimpan, selain itu login. |
| `showOfflineEmptyState` | Getter true hanya untuk destinasi Home, kondisi offline, dan data lokal kosong. |
| `AppBootstrapper` | Interface untuk operasi `load`. |
| `DefaultAppBootstrapper` | Implementasi yang menerima database dan fungsi pemeriksa kondisi/inisialisasi. |
| `Future`, `Stream.first` | Menunggu operasi awal dan emisi data lokal pertama. |

### Membaca kode per bagian

`load` mengirim progress 0, membaca data lokal melalui `watchSemuaJadwalLengkap().first`, melaporkan 0.25, membaca sesi, melaporkan 0.5, membaca offline, melaporkan 0.75, menginisialisasi notifikasi, kemudian melaporkan 1 dan mengembalikan hasil.

Progress ini adalah tahapan logis yang ditetapkan kode, bukan persentase byte yang diunduh atau ukuran memori yang dimuat. Durasi tiap tahap bisa berbeda. `.first` menunggu satu emisi stream, berbeda dari Home yang terus memantau stream.

Interface dan fungsi yang disuntikkan memungkinkan proses pemuatan diganti tanpa mengubah widget splash. Kebenaran sesi/offline tergantung fungsi yang diberikan; di wiring default main keduanya masih mengembalikan false.

<a id="file-lib-services-auth-gateway-dart"></a>

## `lib/services/auth_gateway.dart`

[Buka sumber](../../lib/services/auth_gateway.dart)

**Peran:** kontrak operasi akun yang dipanggil alur autentikasi dan logout.

### Kode lengkap

<!-- SUMBER:lib/services/auth_gateway.dart SHA256=e443d04bac4365c0bc9a19140ecca393a3a0dc95c980882970aea5b5df7bc5f4 -->

```dart
abstract interface class AuthGateway {
  Future<void> login({required String email, required String password});

  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> logout();
}

class SimulatedAuthGateway implements AuthGateway {
  const SimulatedAuthGateway({this.delay = const Duration(milliseconds: 700)});

  final Duration delay;

  @override
  Future<void> login({required String email, required String password}) async {
    await Future<void>.delayed(delay);
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
  }

  @override
  Future<void> logout() async {
    // Penghapusan sesi/token akan dihubungkan saat integrasi backend.
    await Future<void>.delayed(delay);
  }
}
```

### Penjelasan dan alasan

`AuthGateway` adalah `abstract interface class` dengan `login`, `register`, dan `logout`. Fungsi-fungsi ini mengembalikan `Future<void>` sehingga UI dapat menunggu hasil, menampilkan loading, serta menangani exception.

`SimulatedAuthGateway` memenuhi interface tersebut. Constructor menerima `Duration` opsional dengan default 700 milidetik. Setiap operasi hanya melakukan `Future<void>.delayed(delay)`.

Dengan implementasi ini, UI dapat memperagakan alur submit dan perpindahan halaman. Email/password belum dikirim atau diverifikasi ke server; akun belum benar-benar dibuat. Logout juga belum menghapus token sesi persisten. Nama “simulated” sesuai perilaku kode.

Pemisahan kontrak dari implementasi berguna ketika operasi nyata akan dihubungkan: UI tetap memanggil operasi yang sama, sementara implementasinya dapat diganti.

<a id="file-lib-services-api-service-dart"></a>

## `lib/services/api_service.dart`

[Buka sumber](../../lib/services/api_service.dart)

File ini **kosong, berukuran 0 byte** pada saat panduan dibuat. Tidak ada class, fungsi, HTTP client, endpoint, ataupun kode untuk dilampirkan. Keberadaan nama file ini belum membuktikan integrasi API tersedia.

<a id="file-lib-repositories-jadwal-repository-dart"></a>

## `lib/repositories/jadwal_repository.dart`

[Buka sumber](../../lib/repositories/jadwal_repository.dart)

**Peran:** menyediakan operasi data yang digunakan Home dan halaman pengelolaan jadwal.

### Kode lengkap

<!-- SUMBER:lib/repositories/jadwal_repository.dart SHA256=c9c64801db17fe8d2e6dab28060885af071293da899a04be77f05729c20d39c8 -->

```dart

import '../database/database.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';

class JadwalDraft {
  final String namaMataKuliah;
  final String? dosen;
  final int? sks;
  final int hari;
  final int jamMulai;
  final int jamSelesai;
  final String? ruangan;
  final bool pengingatAktif;
  final int menitSebelum;

  const JadwalDraft({
    required this.namaMataKuliah,
    required this.dosen,
    required this.sks,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.ruangan,
    required this.pengingatAktif,
    required this.menitSebelum,
  });
}

class JadwalRepository {
  final AppDatabase database;

  const JadwalRepository({
    required this.database,
  });

  // Mendengarkan perubahan jadwal dari Drift.
  Stream<List<JadwalDenganMataKuliah>> watchAll() {
    return database.watchSemuaJadwalLengkap();
  }

  // Mengecek apakah jadwal bertabrakan.
  Future<bool> hasConflict(
    JadwalDraft draft, {
    int? exceptScheduleId,
  }) {
    return database.adaBentrokJadwal(
      hari: draft.hari,
      jamMulai: draft.jamMulai,
      jamSelesai: draft.jamSelesai,
      kecualiJadwalId: exceptScheduleId,
    );
  }

  // Digunakan untuk tambah maupun edit jadwal.
  Future<int> save(
    JadwalDraft draft, {
    JadwalDenganMataKuliah? jadwalAwal,
  }) async {
    if (jadwalAwal != null) {
      final jadwalId = jadwalAwal.jadwal.id;

      await database.updateJadwalLengkap(
        jadwalId: jadwalId,
        mataKuliahId: jadwalAwal.mataKuliah.id,
        namaMataKuliah: draft.namaMataKuliah,
        dosen: draft.dosen,
        sks: draft.sks,
        hari: draft.hari,
        jamMulai: draft.jamMulai,
        jamSelesai: draft.jamSelesai,
        ruangan: draft.ruangan,
        pengingatAktif: draft.pengingatAktif,
        menitSebelum: draft.menitSebelum,
      );

      return jadwalId;
    }

    return database.tambahJadwalLengkap(
      namaMataKuliah: draft.namaMataKuliah,
      dosen: draft.dosen,
      sks: draft.sks,
      hari: draft.hari,
      jamMulai: draft.jamMulai,
      jamSelesai: draft.jamSelesai,
      ruangan: draft.ruangan,
      pengingatAktif: draft.pengingatAktif,
      menitSebelum: draft.menitSebelum,
    );
  }

  // Menghapus jadwal dan membatalkan pengingat.
  Future<void> delete(
    JadwalDenganMataKuliah data,
  ) async {
    final jadwalId = data.jadwal.id;

    await database.hapusJadwalLengkap(
      jadwalId: jadwalId,
      mataKuliahId: data.mataKuliah.id,
    );

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      await NotificationService.batalkanPengingat(jadwalId);
    }
  }
}
```

### Class dan fungsi yang dipakai

| Simbol | Fungsi dan alasan |
|---|---|
| `JadwalDraft` | Data masukan tambah/edit: mata kuliah, dosen, SKS, hari, waktu, ruangan, dan pengingat. |
| `JadwalRepository` | Membungkus database dan operasi terkait agar halaman tidak menulis semua query sendiri. |
| `watchAll` | Mengembalikan stream jadwal lengkap untuk pembaruan UI. |
| `hasConflict` | Meneruskan pemeriksaan bentrok; `exceptScheduleId` mengecualikan jadwal sendiri ketika edit. |
| `save` | Memilih update jika `jadwalAwal` diberikan, selain itu tambah. |
| `delete` | Menghapus data, kemudian membatalkan pengingat pada Android non-web. |
| `kIsWeb` / `defaultTargetPlatform` | Menjaga panggilan service khusus Android pada jalur penghapusan. |

### Membaca kode per bagian

`JadwalDraft` adalah objek input immutable dengan field final. Beberapa tipe seperti `String?` dan `int?` masih nullable walaupun parameter constructornya required. Artinya pemanggil wajib memberikan argumen, tetapi nilainya boleh null. Persyaratan field pada UI diperiksa oleh form, sehingga tipe database dan validator form perlu dibaca sebagai lapisan berbeda.

`watchAll` langsung meneruskan stream database. `hasConflict` meneruskan hari dan batas waktu. `save` tidak menjalankan pemeriksaan bentrok sendiri; halaman form melakukan pemeriksaan tersebut sebelum memanggil save. Jadi memanggil save dari tempat baru membutuhkan perhatian pada urutan validasi itu.

Saat edit, ID mata kuliah dan jadwal lama dipakai untuk update. Saat tambah, repository mengembalikan ID baru. Saat hapus, data dihapus terlebih dahulu sebelum notifikasi dibatalkan; urutan ini penting ketika menjelaskan hasil operasi jika salah satu langkah gagal.

`save` pada file ini belum menjadwalkan ulang pengingat sendiri. Panggilan sinkronisasi pengingat ada pada alur simpan form; lihat [bab Form](04-form-jadwal.md).

<a id="file-lib-database-database-dart"></a>

## `lib/database/database.dart`

[Buka sumber](../../lib/database/database.dart)

**Peran:** skema data lokal, query jadwal, pemeriksaan bentrok, dan stream yang mendorong pembaruan Home.

### Kode lengkap

<!-- SUMBER:lib/database/database.dart SHA256=4e98813b0be1ba865a2274fedacfa824c923e62f3df955796d315f4e758c39f3 -->

```dart
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
            // An exact boundary leaves no one-minute gap between classes.
            t.jamMulai.isSmallerOrEqualValue(jamSelesai) &
            t.jamSelesai.isBiggerOrEqualValue(jamMulai);

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
```

### Class dan objek penting

| Simbol | Fungsi dan hubungannya dengan UI |
|---|---|
| `MataKuliahTable` / `Table` | Definisi tabel nama mata kuliah, dosen, dan SKS. |
| `JadwalKuliahTable` | Definisi hari, waktu, ruangan, dan pengingat; terkait mata kuliah lewat ID. |
| `@DataClassName` | Meminta generator memberi nama model row `MataKuliahData` dan `JadwalKuliahData`. |
| `IntColumn`, `TextColumn`, `BoolColumn` | Definisi tipe kolom; bukan widget input. |
| `JadwalDenganMataKuliah` | Menggabungkan dua model untuk menyediakan satu objek lengkap kepada UI. |
| `@DriftDatabase` / `AppDatabase` | Registrasi tabel dan class pengelola database. |
| `MataKuliahTableCompanion` / `JadwalKuliahTableCompanion` | Objek generated untuk nilai yang hendak ditulis. |
| `Value` / `Constant` | Wrapper nilai update/insert dan nilai default dalam API Drift. |
| `QueryExecutor` | Dependency eksekusi query; constructor memungkinkan penggantian executor. |
| `MigrationStrategy` | Membuat tabel awal dan mengaktifkan foreign key sebelum database dipakai. |
| `DriftNativeOptions` / `DriftWebOptions` | Pengaturan koneksi native dan web; web mengacu ke sqlite WASM dan worker. |
| `OrderingTerm` / `innerJoin` | Mengurutkan dan menggabungkan tabel untuk tampilan daftar. |

### Membaca kode per bagian

1. **Skema:** dua tabel menyimpan mata kuliah dan jadwal. Nama mata kuliah dibatasi panjangnya; sejumlah field data seperti dosen, SKS, dan ruangan menerima null pada skema. Waktu disimpan sebagai integer menit. Pengingat memiliki default false dan 15 menit.
2. **Model tampilan:** `JadwalDenganMataKuliah` membuat kartu dapat membaca `data.jadwal` dan `data.mataKuliah` tanpa mencari pasangan data secara manual.
3. **CRUD:** tambah/update jadwal lengkap memakai `transaction` untuk menggabungkan perubahan pada dua tabel. Ini berkaitan dengan konsistensi data ketika form menyimpan.
4. **Hapus:** jadwal dihapus, lalu mata kuliah ikut dihapus jika tidak ada jadwal lain yang masih menggunakannya.
5. **Bentrok:** query mengambil jadwal pada hari sama dengan kondisi `existing.start <= candidate.end` dan `existing.end >= candidate.start`. Batas tepat bersinggungan ikut ditolak. Karena presisi waktu adalah menit, jadwal lama selesai 09:00 dan jadwal baru mulai 09:01 tidak memenuhi kondisi bentrok; mulai 09:00 masih memenuhi. Rentang kandidat tetap perlu divalidasi form.
6. **Edit:** `kecualiJadwalId` mengecualikan jadwal sendiri agar waktunya tidak dianggap bentrok dengan dirinya.
7. **Koneksi:** native memakai direktori application support. Web membutuhkan `sqlite3.wasm` dan `drift_worker.dart.js` yang dirujuk kode. Keberadaan opsi ini bukan hasil pengujian bahwa semua target berhasil berjalan.
8. **Stream daftar:** query join menggabungkan jadwal dengan mata kuliah, mengurutkan hari lalu waktu mulai, dan `watch().map(...)` menghasilkan stream list model lengkap. Home mendengarkan hasil ini.

File ini menyediakan penyimpanan lokal. Dalam kode yang dibahas belum ada mekanisme sinkronisasi akun/perangkat ke backend.

<a id="file-lib-database-database-g-dart"></a>

## `lib/database/database.g.dart`

[Buka sumber generated](../../lib/database/database.g.dart)

**Peran:** keluaran generator Drift yang melengkapi library `database.dart` melalui directive `part`.

Model yang terlihat oleh bagian aplikasi antara lain `MataKuliahData` dan `JadwalKuliahData`. Companion seperti `MataKuliahTableCompanion` menyediakan bentuk nilai insert/update. Class tabel generated menyediakan representasi query, sedangkan class filter, ordering, annotation, dan table manager mendukung API database.

Kode generator lengkap tidak disalin ke materi UI: perilaku UI dijelaskan melalui model publik serta schema/query sumbernya di atas. Untuk belajar UI, cukup pahami akses `data.mataKuliah.nama` atau `data.jadwal.jamMulai` berasal dari model ini. Perubahan schema dilakukan di sumbernya, bukan mengedit file generated secara manual.

<a id="file-lib-services-notification-service-dart"></a>

## `lib/services/notification_service.dart`

[Buka sumber](../../lib/services/notification_service.dart)

**Peran:** inisialisasi dan pengingat lokal yang dipicu melalui alur jadwal pada Android.

### Kode lengkap

<!-- SUMBER:lib/services/notification_service.dart SHA256=24736ae65c3c76a2390ddb26c62262fd2cacdb673e07f51ebe53860a2b4164f1 -->

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'jadwal_kuliah';
  static const String _channelName = 'Pengingat Jadwal Kuliah';
  static const String _channelDescription =
      'Notifikasi pengingat sebelum jadwal kuliah dimulai';

  static const String _permissionOnboardingKey =
      'notification_permission_onboarding_done';

  static AndroidFlutterLocalNotificationsPlugin? get _androidPlugin {
    return _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  // =========================================================
  // INITIALIZE
  // =========================================================

  static Future<void> initialize() async {
    await _initializeTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings: initializationSettings);

    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _androidPlugin?.createNotificationChannel(channel);
  }

  // =========================================================
  // TIMEZONE
  // =========================================================

  static Future<void> _initializeTimezone() async {
    tz_data.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    final location = tz.getLocation(timezoneInfo.identifier);

    tz.setLocalLocation(location);
  }

  // =========================================================
  // FIRST INSTALL / FIRST LAUNCH
  // =========================================================

  static Future<void> handleInitialPermissions() async {
    final prefs = await SharedPreferences.getInstance();

    final sudahPernah = prefs.getBool(_permissionOnboardingKey) ?? false;

    if (sudahPernah) {
      return;
    }

    final notificationAllowed = await requestNotificationPermission();

    if (!notificationAllowed) {
      await prefs.setBool(_permissionOnboardingKey, true);

      return;
    }

    var exactAlarmAllowed = await canScheduleExactAlarm();

    if (!exactAlarmAllowed) {
      exactAlarmAllowed = await requestExactAlarmPermission();
    }

    await prefs.setBool(_permissionOnboardingKey, true);
  }

  // =========================================================
  // PERMISSION
  // =========================================================

  static Future<bool> requestNotificationPermission() async {
    final result = await _androidPlugin?.requestNotificationsPermission();

    return result ?? true;
  }

  static Future<bool> canScheduleExactAlarm() async {
    final result = await _androidPlugin?.canScheduleExactNotifications();

    return result ?? true;
  }

  static Future<bool> requestExactAlarmPermission() async {
    await _androidPlugin?.requestExactAlarmsPermission();

    return canScheduleExactAlarm();
  }

  static Future<bool> ensureReminderPermissions() async {
    final notificationAllowed = await requestNotificationPermission();

    if (!notificationAllowed) {
      return false;
    }

    var exactAlarmAllowed = await canScheduleExactAlarm();

    if (!exactAlarmAllowed) {
      exactAlarmAllowed = await requestExactAlarmPermission();
    }

    return exactAlarmAllowed;
  }

  // =========================================================
  // SINKRONISASI REMINDER
  // =========================================================

  static Future<void> sinkronkanPengingatJadwal({
    required int notificationId,
    required bool aktif,
    required String namaMataKuliah,
    required int hari,
    required int jamMulai,
    required int menitSebelum,
    String? ruangan,
  }) async {
    // Batalkan reminder lama terlebih dahulu.
    await batalkanPengingat(notificationId);

    // Jika pengingat dimatikan, cukup hapus reminder lama.
    if (!aktif) {
      return;
    }

    final permissionAllowed = await ensureReminderPermissions();

    if (!permissionAllowed) {
      throw Exception(
        'Izin notifikasi atau Alarm & pengingat belum diberikan.',
      );
    }

    await _jadwalkanPengingatMingguan(
      notificationId: notificationId,
      namaMataKuliah: namaMataKuliah,
      hari: hari,
      jamMulai: jamMulai,
      menitSebelum: menitSebelum,
      ruangan: ruangan,
    );
  }

  // =========================================================
  // JADWAL REMINDER MINGGUAN
  // =========================================================

  static Future<void> _jadwalkanPengingatMingguan({
    required int notificationId,
    required String namaMataKuliah,
    required int hari,
    required int jamMulai,
    required int menitSebelum,
    String? ruangan,
  }) async {
    final scheduledDate = _hitungNotifikasiBerikutnya(
      hari: hari,
      jamMulai: jamMulai,
      menitSebelum: menitSebelum,
    );

    final jamKuliah = _formatMenitKeJam(jamMulai);

    final String body;

    if (ruangan == null || ruangan.trim().isEmpty) {
      body = 'Kuliah dimulai pukul $jamKuliah';
    } else {
      body = 'Kuliah dimulai pukul $jamKuliah • $ruangan';
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id: notificationId,
      title: '$namaMataKuliah sebentar lagi',
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'jadwal:$notificationId',
    );
  }

  // =========================================================
  // HITUNG WAKTU REMINDER BERIKUTNYA
  // =========================================================

  static tz.TZDateTime _hitungNotifikasiBerikutnya({
    required int hari,
    required int jamMulai,
    required int menitSebelum,
  }) {
    final now = tz.TZDateTime.now(tz.local);

    final jam = jamMulai ~/ 60;

    final menit = jamMulai % 60;

    final selisihHari = (hari - now.weekday + 7) % 7;

    var waktuKuliah = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + selisihHari,
      jam,
      menit,
    );

    var waktuNotifikasi = waktuKuliah.subtract(Duration(minutes: menitSebelum));

    // Kalau waktu reminder minggu ini sudah lewat,
    // pindahkan ke minggu berikutnya.
    if (!waktuNotifikasi.isAfter(now)) {
      waktuKuliah = tz.TZDateTime(
        tz.local,
        waktuKuliah.year,
        waktuKuliah.month,
        waktuKuliah.day + 7,
        jam,
        menit,
      );

      waktuNotifikasi = waktuKuliah.subtract(Duration(minutes: menitSebelum));
    }

    return waktuNotifikasi;
  }

  static String _formatMenitKeJam(int totalMenit) {
    final jam = totalMenit ~/ 60;

    final menit = totalMenit % 60;

    return '${jam.toString().padLeft(2, '0')}:'
        '${menit.toString().padLeft(2, '0')}';
  }

  // =========================================================
  // CANCEL REMINDER
  // =========================================================

  static Future<void> batalkanPengingat(int notificationId) async {
    await _notifications.cancel(id: notificationId);
  }
}
```

### Class, plugin, dan fungsi penting

| Yang dipakai | Kegunaan di file |
|---|---|
| `NotificationService` dengan constructor private | Mengelompokkan operasi static pengingat. |
| `FlutterLocalNotificationsPlugin` | Menghubungkan operasi Dart dengan fasilitas notifikasi platform. |
| `AndroidFlutterLocalNotificationsPlugin` | Mengakses kemampuan/izin khusus Android. |
| `AndroidInitializationSettings` / `InitializationSettings` | Mengatur inisialisasi termasuk ikon launcher untuk notifikasi. |
| `AndroidNotificationChannel` | Menyiapkan channel pengingat beserta nama, suara, dan getaran. |
| `FlutterTimezone`, `tz_data`, `tz` | Membaca timezone perangkat, memuat data zona, dan menghitung waktu lokal berzona. |
| `SharedPreferences` | Menyimpan flag onboarding izin; ini bukan penyimpanan akun atau database jadwal. |
| `AndroidNotificationDetails` / `NotificationDetails` | Mengatur detail notifikasi yang akan dijadwalkan. |
| `Importance`, `Priority`, `AndroidScheduleMode`, `DateTimeComponents` | Pilihan tingkat perhatian, cara penjadwalan, dan pola ulang mingguan. |
| `tz.TZDateTime` / `Duration` | Menghitung tanggal pengingat berikutnya dan selisih menit sebelum kuliah. |
| `Exception` | Memberi kegagalan ketika izin pengingat belum tersedia. |

### Membaca kode per bagian

`initialize` memuat zona waktu, menginisialisasi plugin, dan membuat channel. `_androidPlugin` mengambil implementasi khusus Android yang nullable; pemanggilan `?.` menangani kemungkinan implementasi itu tidak tersedia.

`handleInitialPermissions` memeriksa flag onboarding, meminta izin yang diperlukan, lalu mencatat bahwa onboarding pernah dijalankan. Menyediakan fungsi ini tidak otomatis berarti semua jalur aplikasi memanggilnya; telusuri pemanggilnya untuk mengetahui kapan dijalankan.

`ensureReminderPermissions` digunakan sebelum pengingat aktif dijadwalkan. Fungsi ini memeriksa izin notifikasi dan kemampuan exact alarm. Jika tidak tersedia, sinkronisasi pengingat melempar exception yang dapat ditampilkan oleh alur form.

`sinkronkanPengingatJadwal` membatalkan pengingat lama terlebih dahulu. Jika toggle dimatikan, proses berhenti setelah pembatalan. Jika aktif, kode memeriksa izin lalu menjadwalkan pengingat mingguan.

`_hitungNotifikasiBerikutnya` memilih hari kuliah berikutnya berdasarkan weekday lokal, mengurangi menit pengingat, lalu menggeser satu minggu jika waktu pengingat sudah lewat. `zonedSchedule` memakai waktu berzona, ID jadwal, judul/body, dan pola `dayOfWeekAndTime`. `payload` membawa penanda ID jadwal.

`batalkanPengingat` membatalkan berdasarkan ID yang sama. ID ini menghubungkan pengingat dengan jadwal saat diedit atau dihapus.

**Hubungan dengan UI:** toggle dan pilihan menit hanya input konfigurasi. Keberhasilan menampilkan toggle atau menguji halaman di web tidak membuktikan notifikasi Android tampil ketika aplikasi berada di latar belakang. Bab ini menerangkan jalur kode yang tersedia; tidak menjalankan validasi Android.
