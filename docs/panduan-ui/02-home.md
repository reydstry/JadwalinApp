# Belajar UI Home Jadwalin

Bab ini membahas semua 16 file Dart pada `lib/pages/home`: halaman Home dan 15 widget penyusunnya. Baca [dasar Dart dan Flutter](00-dasar.md) untuk konsep `Widget`, `State`, constructor, callback, dan layout. Gunakan [glosarium](05-glosarium.md) ketika menemui istilah baru.

Penjelasan mengikuti kode yang tersedia. Kalimat tentang hasil layout menjelaskan perilaku kode; alasan rancangan dijelaskan sebagai manfaat atau konsekuensi susunan tersebut, bukan klaim tentang pikiran penulis. Pembacaan source ini tidak sama dengan bukti hasil pengujian tampilan pada perangkat.

## Peta hubungan komponen

`HomePage` menyimpan hari terpilih, menerima stream jadwal, menghitung jumlah mata kuliah, membuka form, serta mengurus konfirmasi hapus. Widget di bawahnya menerima nilai dan callback melalui constructor.

| Komponen | Tanggung jawab langsung |
|---|---|
| `HomeHeader` → `MenuAkunButton` | Judul aplikasi dan menu keluar akun. |
| `PilihHari` → `HariBubble` | Daftar hari yang dapat digeser dan dipilih. |
| `HomeDaySummary` | Judul hari terpilih dan jumlah mata kuliah. |
| `ListJadwal` | Memilih tampilan loading, error, kosong, atau daftar kartu. |
| `KartuJadwal` → `JadwalCardHeader`, `JadwalCardDetails`, `JadwalCardReminder` | Menyusun isi satu kartu jadwal. |
| `HomeIcon` | Menampilkan aset SVG yang dipakai sejumlah widget. |
| `TambahJadwalButton` | Tombol tambah dengan atau tanpa label. |
| `HapusJadwalDialog` | Mengembalikan keputusan hapus kepada halaman. |
| `JadwalKosong`, `JadwalLoadError`, `JadwalLoading` | Tiga kondisi tampilan selain daftar berisi. |

Alur datanya: stream jadwal → `HomePage` → nilai/callback ke anak → pengguna menekan tombol → callback kembali ke halaman → state atau data berubah → tampilan dibangun kembali. Anak tidak perlu mengetahui seluruh database maupun navigasi aplikasi.

<a id="file-lib-pages-home-home-dart"></a>

## `lib/pages/home/home.dart`

[Buka source Home](../../lib/pages/home/home.dart).

### Peran dan class

`HomePage` adalah `StatefulWidget`: konfigurasinya diterima melalui constructor, sedangkan nilai yang berubah selama halaman hidup disimpan dalam `_HomePageState`. Awalan `_` menjadikan nama privat pada library Dart; pada susunan file ini state menjadi detail implementasi halaman.

| Properti konfigurasi | Dipakai untuk |
|---|---|
| `database` | Membuat `JadwalRepository` dan diteruskan ke halaman tambah/edit. Wajib diberikan. |
| `showOfflineEmptyState` | Mengizinkan pesan kosong khusus offline. Nilai awalnya `false`; Home sendiri tidak mendeteksi koneksi melalui properti ini. |
| `scheduleLoader` | Fungsi opsional yang mengembalikan `Stream<List<JadwalDenganMataKuliah>>`; bila ada, stream ini menggantikan `watchAll()` untuk pembacaan daftar. Berguna sebagai titik penggantian sumber stream. |
| `onLogout` | Fungsi asinkron opsional yang diteruskan sampai ke menu akun. Home tidak mendefinisikan mekanisme autentikasi nyata. |

`JadwalDenganMataKuliah` adalah tipe data proyek, bukan widget Flutter. Pada UI, `data.jadwal` menyediakan informasi jadwal dan `data.mataKuliah` menyediakan informasi mata kuliah.

### Kode lengkap

<!-- SUMBER:lib/pages/home/home.dart SHA256=5023e486ab278ea1a005b47fde34a8c87c05dcaae52a1176a675db14bd98b428 -->

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../repositories/jadwal_repository.dart';
import '../../services/notification_service.dart';
import '../../utils/day_helper.dart';

import '../jadwal/kelola_jadwal.dart';

import 'widgets/pilih_hari.dart';
import 'widgets/list_jadwal.dart';
import 'widgets/tambah_jadwal_button.dart';
import 'widgets/home_header.dart';
import 'widgets/home_day_summary.dart';
import 'widgets/hapus_jadwal_dialog.dart';

import '../../theme/app_colors.dart';

class HomePage extends StatefulWidget {
  final AppDatabase database;
  final bool showOfflineEmptyState;
  final Stream<List<JadwalDenganMataKuliah>> Function()? scheduleLoader;
  final Future<void> Function()? onLogout;

  const HomePage({
    super.key,
    required this.database,
    this.showOfflineEmptyState = false,
    this.scheduleLoader,
    this.onLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State untuk hari yang sedang dipilih.
  late int _hariDipilih;

  // Repository sebagai perantara UI dan database.
  late JadwalRepository _repository;

  // Stream jadwal dibuat sekali agar tidak dibuat ulang
  // setiap kali setState dipanggil.
  late Stream<List<JadwalDenganMataKuliah>> _jadwalStream;

  @override
  void initState() {
    super.initState();

    // Pilih hari saat ini secara otomatis.
    _hariDipilih = DateTime.now().weekday;

    _initRepository();

    // Jalankan pemeriksaan izin notifikasi setelah frame pertama.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _requestNotificationPermissions();
    });
  }

  void _initRepository() {
    _repository = JadwalRepository(database: widget.database);

    _jadwalStream = widget.scheduleLoader?.call() ?? _repository.watchAll();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Jika instance database dari parent berubah,
    // perbarui repository dan stream.
    if (oldWidget.database != widget.database ||
        oldWidget.scheduleLoader != widget.scheduleLoader) {
      _initRepository();
    }
  }

  Future<void> _requestNotificationPermissions() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await NotificationService.handleInitialPermissions();
    }
  }

  Future<void> _bukaTambahJadwal() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KelolaJadwalPage(database: widget.database),
      ),
    );
  }

  Future<void> _bukaEditJadwal(JadwalDenganMataKuliah data) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            KelolaJadwalPage(database: widget.database, jadwalAwal: data),
      ),
    );
  }

  // Dialog konfirmasi sebelum menghapus jadwal.
  Future<bool> _konfirmasiHapus(JadwalDenganMataKuliah data) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return HapusJadwalDialog(namaMataKuliah: data.mataKuliah.nama);
      },
    );

    return result ?? false;
  }

  // Menghapus jadwal melalui repository.
  Future<void> _hapusJadwal(JadwalDenganMataKuliah data) async {
    final confirmed = await _konfirmasiHapus(data);

    if (!confirmed || !mounted) {
      return;
    }

    try {
      await _repository.delete(data);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jadwal berhasil dihapus.')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operasi belum selesai sepenuhnya: $error')),
      );
    }
  }

  // Mengubah hari terpilih.
  void _pilihHari(int day) {
    setState(() {
      _hariDipilih = day;
    });
  }

  void _retry() {
    setState(_initRepository);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Inter'),
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: StreamBuilder<List<JadwalDenganMataKuliah>>(
            key: ObjectKey(_jadwalStream),
            stream: _jadwalStream,
            builder: (context, snapshot) {
              final ready =
                  snapshot.hasData &&
                  !snapshot.hasError &&
                  snapshot.connectionState != ConnectionState.waiting;
              final schedules = ready
                  ? snapshot.data!
                  : <JadwalDenganMataKuliah>[];
              final counts = <int, int>{};
              for (final data in schedules) {
                counts.update(
                  data.jadwal.hari,
                  (count) => count + 1,
                  ifAbsent: () => 1,
                );
              }
              final count = counts[_hariDipilih] ?? 0;
              return Stack(
                children: [
                  Column(
                    children: [
                      HomeHeader(onLogout: widget.onLogout),
                      Row(
                        children: [
                          Expanded(
                            child: PilihHari(
                              selectedDay: _hariDipilih,
                              onDaySelected: _pilihHari,
                              scheduleCounts: counts,
                            ),
                          ),
                        ],
                      ),
                      HomeDaySummary(
                        dayName: DayHelper.dayNames[_hariDipilih] ?? '-',
                        ready: ready,
                        count: count,
                      ),
                      Expanded(
                        child: ListJadwal(
                          snapshot: snapshot,
                          selectedDay: _hariDipilih,
                          onAdd: _bukaTambahJadwal,
                          onEdit: _bukaEditJadwal,
                          onDelete: _hapusJadwal,
                          onRetry: _retry,
                          showOfflineEmptyState: widget.showOfflineEmptyState,
                        ),
                      ),
                    ],
                  ),
                  if (ready && count > 0)
                    Positioned(
                      right: 19,
                      bottom: 16,
                      child: TambahJadwalButton(onPressed: _bukaTambahJadwal),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
```

### Membaca state dan siklus hidup

Tiga field berawalan `late` diisi sebelum dipakai: `_hariDipilih`, `_repository`, dan `_jadwalStream`. `late` bukan berarti nilainya boleh kosong; programmer berjanji bahwa inisialisasi akan dilakukan sebelum pembacaan.

`initState()` berjalan sekali untuk satu objek state. `super.initState()` memanggil inisialisasi milik superclass. Hari awal ditentukan oleh `DateTime.now().weekday`, sehingga tampilan pertama memilih hari saat Home dibuat. Ini tidak memasang timer untuk otomatis mengganti hari ketika jam melewati tengah malam.

`_initRepository()` membuat repository dan memilih sumber stream melalui:

```dart
_jadwalStream = widget.scheduleLoader?.call() ?? _repository.watchAll();
```

`widget` menunjuk konfigurasi `HomePage` yang sedang digunakan state. `?.call()` hanya memanggil fungsi bila tersedia; `??` mengambil `watchAll()` jika hasil sisi kiri `null`. Field stream disimpan agar setiap perubahan hari tidak membuat stream baru di dalam `build()`.

`didUpdateWidget(oldWidget)` dipanggil ketika konfigurasi widget diperbarui sementara objek state tetap digunakan. Bila instance `database` atau fungsi `scheduleLoader` berubah, repository dan stream dibuat ulang. Perubahan konfigurasi dari parent sudah diikuti proses build; karena itu metode tersebut tidak perlu membungkus `_initRepository()` dengan `setState()`.

`addPostFrameCallback` menunda pemeriksaan izin notifikasi sampai frame pertama selesai. Setelah itu, `mounted` memastikan state masih berada dalam tree. `_requestNotificationPermissions()` membatasi panggilan layanan ke Android dan mengecualikan web melalui `!kIsWeb` serta `defaultTargetPlatform`. Panggilan ini adalah penghubung ke layanan, bukan bukti bahwa notifikasi Android sudah diuji dari tampilan web.

### Membaca navigasi dan aksi

`_bukaTambahJadwal()` memanggil `Navigator.push<bool>` dengan `MaterialPageRoute`. Route baru membuat `KelolaJadwalPage` dengan database yang sama. `_bukaEditJadwal(data)` membuka halaman yang sama sambil memberi `jadwalAwal: data`. Perbedaan argumen itulah yang membedakan konteks tambah dan edit pada pemanggilan ini.

`Future<void>` berarti pekerjaan dapat selesai kemudian tanpa mengembalikan nilai berguna. `await` menunggu route ditutup, tetapi tidak membekukan event loop atau memblokir seluruh UI. Walaupun route diberi tipe hasil `bool`, hasilnya tidak ditampung oleh kedua metode ini. Perubahan daftar ditangani melalui stream; tidak ada pemanggilan refresh eksplisit setelah route kembali pada kode ini.

Alur hapusnya berurutan:

1. `JadwalCardHeader` menjalankan callback hapus.
2. Callback diteruskan melalui `KartuJadwal` dan `ListJadwal` menuju `_hapusJadwal(data)`.
3. `_konfirmasiHapus(data)` membuka `showDialog<bool>` dengan nama mata kuliah.
4. `true` berarti lanjut. `false` atau dialog yang ditutup tanpa hasil berarti batal karena `result ?? false`.
5. `_repository.delete(data)` dijalankan, kemudian `ScaffoldMessenger` menampilkan `SnackBar` sukses atau pesan kegagalan dari `catch`.

Pemeriksaan `mounted` setelah `await` penting: ketika operasi menunggu, pengguna bisa saja sudah meninggalkan halaman. Kode menghindari penggunaan `context` untuk menampilkan pesan setelah state terlepas. Dialog hanya meminta keputusan; repositorylah yang menerima perintah hapus.

`_pilihHari(day)` mengubah `_hariDipilih` di dalam `setState()`. Callback `setState` dijalankan secara sinkron, lalu Flutter menjadwalkan build untuk state ini. Ia bukan perintah untuk memulai ulang aplikasi atau membuat ulang database. `_retry()` menggunakan `setState(_initRepository)` agar sumber stream dibuat ulang dan build berikutnya memakai sumber tersebut.

### Membaca susunan tampilan

`Theme.of(context).copyWith(...)` mengambil tema yang diwariskan, lalu mengganti `textTheme` untuk subtree Home dengan font `Inter`. `Theme` membungkus `Scaffold`, sehingga perubahan ini berlaku pada keturunannya; widget yang menentukan font sendiri, misalnya `HariBubble`, dapat memberi font lain.

`Scaffold` menyediakan kerangka halaman dengan latar `AppColors.primary`. `SafeArea` memberi jarak terhadap bagian sistem seperti status bar atau area perangkat yang terhalang. Area ini tetap diatur oleh constraint parent, bukan ukuran bebas tanpa batas.

`StreamBuilder<List<JadwalDenganMataKuliah>>` mendengarkan `_jadwalStream`. Parameter `snapshot` merupakan ringkasan kondisi stream saat build: ada data, error, serta status koneksi. Builder tidak otomatis dijalankan tepat sekali untuk setiap event; gunakan nilai snapshot yang diterima untuk membuat UI, sebagaimana dilakukan di sini.

`ObjectKey(_jadwalStream)` mengaitkan identitas `StreamBuilder` dengan objek stream. Ketika retry mengganti objek stream, key ikut berubah sehingga state builder lama diganti. `ObjectKey` bukan pengenal record jadwal; key record ada pada kartu di `ListJadwal`.

`ready` hanya benar bila data tersedia, tidak ada error, dan stream tidak sedang `waiting`. Daftar kosong tetap merupakan data yang valid. Saat belum siap, `schedules` menjadi list kosong sementara. Perulangan `counts.update(...)` membuat map jumlah per hari: `ifAbsent: () => 1` memulai hitungan dan `(count) => count + 1` menambahnya. Map ini dihitung ulang dari snapshot, bukan state lain yang harus disinkronkan secara terpisah.

Isi halaman menggunakan:

- `Stack` untuk menumpuk susunan utama dan tombol tambah di atasnya.
- `Column` untuk urutan header, pilihan hari, ringkasan, serta daftar.
- `Expanded` pada area `ListJadwal` untuk memberikan sisa tinggi halaman kepada daftar. Inilah batas tinggi yang memungkinkan daftar melakukan scroll sendiri.
- `Row` dengan `Expanded` di sekitar `PilihHari` untuk mengisi lebar yang tersedia.
- `Positioned(right: 19, bottom: 16)` untuk menempatkan tombol tambah di kanan bawah `Stack`. Angka itu adalah logical pixel Flutter, bukan selalu satu pixel fisik layar.

Tombol mengambang hanya muncul ketika `ready && count > 0`. Jika hari kosong, ajakan tambah ada pada `JadwalKosong`; ketika loading/error tombol tersebut tidak muncul. Label hari diambil melalui `DayHelper.dayNames[_hariDipilih] ?? '-'` sebagai fallback jika nilai tidak ditemukan.

### Hal yang perlu diingat

`build()` menggambarkan UI dari data saat ini; jangan menganggap pemanggilannya hanya sekali. Memilih hari tidak menjalankan query baru dalam kode Home ini: stream seluruh jadwal tetap sama, sedangkan filter dilakukan `ListJadwal`. Flag offline hanya mengatur pesan. Tidak ada bukti sinkronisasi server, sesi persisten, atau autentikasi produksi yang dapat disimpulkan dari halaman ini.

<a id="file-lib-pages-home-widgets-home-header-dart"></a>

## `lib/pages/home/widgets/home_header.dart`

[Buka source header](../../lib/pages/home/widgets/home_header.dart).

### Peran dan class

`HomeHeader` adalah `StatelessWidget` yang menampilkan tulisan `Jadwalin` di kiri dan `MenuAkunButton` di kanan. Ia menerima `Future<void> Function()? onLogout`, lalu meneruskannya tanpa menjalankan logout sendiri. Stateless bukan berarti tampilannya tak bisa berubah; parent tetap dapat membangun konfigurasi baru dengan nilai berbeda.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/home_header.dart SHA256=b8849da8d658cba364b151f7bf7f1bb367354c835b36a372201377eff344bf01 -->

```dart
import 'package:flutter/material.dart';

import 'menu_akun_button.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onLogout});

  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 16),
          Row(
            children: [
              const Spacer(),
              SizedBox(
                width: (constraints.maxWidth - 2 * (19)).clamp(
                  0.0,
                  double.infinity,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Jadwalin',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    MenuAkunButton(onLogout: onLogout),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
```

### Membaca susunan dan alasannya

`LayoutBuilder` memberikan `constraints` dari parent. Pada file ini, yang dipakai adalah `constraints.maxWidth`, yaitu lebar maksimum area header, bukan otomatis lebar perangkat. `SizedBox` tengah diberi lebar `maxWidth - 2 * 19`; `clamp(0.0, double.infinity)` mencegah hasil lebar negatif pada ruang yang sangat sempit.

`Spacer` di kiri dan kanan membagi ruang horizontal yang tersisa. Dengan lebar yang mencukupi, hasil susunan ini memberi jarak sekitar 19 di kedua sisi. Ini pola yang dipakai kode sebagai pengatur jarak, walaupun Flutter juga menyediakan widget pengatur padding.

`Column(mainAxisSize: MainAxisSize.min)` meminta tinggi secukupnya untuk anak, bukan memenuhi seluruh tinggi yang tersedia. `SizedBox(height: 16)` dan `SizedBox(height: 10)` menjadi ruang atas/bawah. `Row` terdalam menyusun judul dan menu secara horizontal. Judul berada dalam `Expanded`, sehingga mengambil sisa lebar setelah menu memperoleh tempatnya.

`TextStyle` mengatur `fontWeight: FontWeight.w800`, `fontSize: 25`, dan warna putih. Font keluarga mengikuti tema Home karena tidak diberikan secara lokal. `const` pada `Expanded` beserta isi konstan memungkinkan objek widget itu menjadi konstanta; ini tidak membuat teks berada di luar mekanisme layout Flutter.

### Hubungan interaksi

Pengguna menekan menu yang dibuat `MenuAkunButton`; `HomeHeader` hanya menyalurkan `onLogout`. Pemisahan ini membuat header tidak perlu mengetahui route login maupun detail gateway autentikasi.

<a id="file-lib-pages-home-widgets-menu-akun-button-dart"></a>

## `lib/pages/home/widgets/menu_akun_button.dart`

[Buka source menu akun](../../lib/pages/home/widgets/menu_akun_button.dart).

### Peran dan class

`MenuAkunButton` adalah `StatefulWidget` karena ikon dan status enabled berubah saat logout berlangsung. `_MenuAkunButtonState` menyimpan boolean `_sedangKeluar`. Enum privat `_AksiAkun` saat ini hanya berisi `keluar` dan menjadi tipe pilihan pada `PopupMenuButton<_AksiAkun>`.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/menu_akun_button.dart SHA256=818583d5c56bf23a3fd82f12651d1bfa466872f3b39fa597049ab4f1c43194a5 -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

enum _AksiAkun { keluar }

/// Menu profil beserta status proses keluar; navigasi disediakan oleh aplikasi.
class MenuAkunButton extends StatefulWidget {
  const MenuAkunButton({super.key, this.onLogout});

  final Future<void> Function()? onLogout;

  @override
  State<MenuAkunButton> createState() => _MenuAkunButtonState();
}

class _MenuAkunButtonState extends State<MenuAkunButton> {
  bool _sedangKeluar = false;

  Future<void> _keluar() async {
    final logout = widget.onLogout;
    if (_sedangKeluar || logout == null) return;

    setState(() => _sedangKeluar = true);
    try {
      await logout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Gagal keluar akun. Silakan coba lagi.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _sedangKeluar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AksiAkun>(
      tooltip: _sedangKeluar ? 'Sedang keluar akun' : 'Menu akun',
      enabled: !_sedangKeluar && widget.onLogout != null,
      position: PopupMenuPosition.under,
      color: AppColors.peach,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => _keluar(),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _AksiAkun.keluar,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Keluar akun',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      child: SizedBox.square(
        dimension: 48,
        child: Column(
          children: [
            const Spacer(),
            Row(
              children: [
                const Spacer(),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.peach,
                  child: _sedangKeluar
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 22,
                        ),
                ),
                const Spacer(),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
```

### Membaca proses keluar

`_keluar()` menyimpan referensi `widget.onLogout` ke variabel lokal. Bila proses sedang berlangsung atau callback tidak tersedia, metode langsung `return`. Setelah `setState(() => _sedangKeluar = true)`, callback ditunggu dalam `try`. Pemisahan ini mencegah permintaan ganda dari tombol yang sama saat proses berjalan.

Jika callback melempar error, `catch (_)` mengabaikan objek error dan menampilkan pesan umum. Operator cascade `..hideCurrentSnackBar()..showSnackBar(...)` memanggil dua metode pada `ScaffoldMessenger` yang sama. Pesan sebelumnya disembunyikan agar pesan kegagalan terbaru tampil. `finally` berjalan baik saat sukses maupun gagal; status dikembalikan ke `false` hanya jika state masih `mounted`.

### Membaca komponen dan properti

| Bagian | Kegunaan pada file ini |
|---|---|
| `PopupMenuButton<_AksiAkun>` | Menghubungkan tombol avatar dengan daftar pilihan bertipe enum. |
| `enabled` | Menu aktif hanya ketika tidak sedang logout dan callback tersedia. |
| `tooltip` | Teks bantuan berubah dari `Menu akun` menjadi `Sedang keluar akun`. |
| `position: PopupMenuPosition.under` | Meminta menu ditempatkan di bawah tombol. |
| `color`, `surfaceTintColor` | Mengatur warna peach dan menghilangkan warna tint tambahan pada permukaan menu. |
| `shape: RoundedRectangleBorder(...)` | Membuat sudut menu beradius 12. |
| `itemBuilder` | Menghasilkan satu `PopupMenuItem` dengan value `_AksiAkun.keluar`. |
| `onSelected: (_) => _keluar()` | Menjalankan aksi ketika pilihan dipilih; nilai enum diabaikan karena baru satu aksi. |

Isi item berupa `Row`: ikon logout, jarak 12, lalu teks di dalam `Flexible`. `Flexible` mengizinkan teks menggunakan sebagian ruang yang tersisa tanpa mewajibkannya mengisi seluruh lebar. Ini membantu teks tetap dibatasi bila ruang menu menyempit.

Area tombol dibentuk `SizedBox.square(dimension: 48)`. `Spacer` horizontal dan vertikal menempatkan `CircleAvatar` di tengah. `CircleAvatar(radius: 16)` menjadi lingkaran peach, bukan foto profil dari akun. Saat proses berjalan, isinya berubah menjadi indikator ukuran 18 dengan `strokeWidth: 2`; selain itu tampil ikon orang ukuran 22.

### Batas tanggung jawab

Widget ini tidak memilih halaman tujuan setelah logout. Callback dari aplikasi menyediakan tindakan tersebut. Tampilan avatar juga tidak membuktikan adanya profil pengguna yang sudah diambil dari server.

<a id="file-lib-pages-home-widgets-pilih-hari-dart"></a>

## `lib/pages/home/widgets/pilih_hari.dart`

[Buka source pilihan hari](../../lib/pages/home/widgets/pilih_hari.dart).

### Peran dan class

`PilihHari` menampilkan tujuh `HariBubble` dalam baris yang dapat digeser. Constructor menerima `selectedDay`, `ValueChanged<int> onDaySelected`, serta map `scheduleCounts` dengan default map kosong. `ValueChanged<int>` adalah callback yang menerima satu angka hari.

Nilai hari terpilih dimiliki `HomePage`. `_PilihHariState` tidak menyimpan salinan hari; state lokalnya berupa kumpulan key untuk menemukan posisi elemen dan menggulir ke hari yang dipilih.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/pilih_hari.dart SHA256=b328e31a04b49a1976b1e6808fa34a68cb2b9c2f4524bcd00c42afd624c354e2 -->

```dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'hari_bubble.dart';
import '../../../utils/day_helper.dart';

class PilihHari extends StatefulWidget {
  const PilihHari({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.scheduleCounts = const {},
  });
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final Map<int, int> scheduleCounts;
  @override
  State<PilihHari> createState() => _PilihHariState();
}

class _PilihHariState extends State<PilihHari> {
  final _dayKeys = {
    for (final day in DayHelper.dayNames.keys) day: GlobalKey(),
  };
  @override
  void initState() {
    super.initState();
    _revealSelectedDay();
  }

  @override
  void didUpdateWidget(covariant PilihHari oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay ||
        !mapEquals(oldWidget.scheduleCounts, widget.scheduleCounts)) {
      _revealSelectedDay();
    }
  }

  void _revealSelectedDay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dayContext = _dayKeys[widget.selectedDay]?.currentContext;
      if (dayContext != null) {
        Scrollable.ensureVisible(dayContext, alignment: 0.5);
      }
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 9),
        Row(
          children: [
            for (final day in DayHelper.dayNames.entries)
              Row(
                key: _dayKeys[day.key],
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HariBubble(
                        day: day.key,
                        label: day.value,
                        count: widget.scheduleCounts[day.key] ?? 0,
                        selected: widget.selectedDay == day.key,
                        onPressed: () => widget.onDaySelected(day.key),
                      ),
                      SizedBox(width: 2),
                    ],
                  ),
                ],
              ),
          ],
        ),
        SizedBox(width: 9),
      ],
    ),
  );
}
```

### Membaca key dan scroll otomatis

`_dayKeys` adalah map yang dibuat dengan collection `for`: setiap key hari dari `DayHelper.dayNames` mendapat satu `GlobalKey()`. Objek-objek ini dibuat sebagai field state, sehingga tetap sama ketika widget melakukan build kembali.

Setelah `initState()`, `_revealSelectedDay()` menjadwalkan pekerjaan melalui `WidgetsBinding.instance.addPostFrameCallback`. Pengguliran harus menunggu layout selesai agar `currentContext` dari key hari sudah dapat ditemukan. `mounted` memeriksa apakah state masih aktif dan `?.currentContext` menangani key yang tidak ditemukan. Jika context tersedia, `Scrollable.ensureVisible(dayContext, alignment: 0.5)` meminta scrollable membawa elemen hari itu ke area terlihat, dengan sasaran posisi tengah. Hasil akhirnya tetap dibatasi ujung scroll; elemen paling kiri/kanan tidak selalu bisa persis di tengah.

`didUpdateWidget()` mengulang proses tersebut bila hari berubah atau jumlah per hari berubah. `mapEquals(...)` dari `flutter/foundation.dart` membandingkan isi map, bukan sekadar apakah objek map yang diterima berbeda. Perubahan angka hitungan dapat mengubah lebar bubble, jadi penghitungan ulang posisi relevan meskipun hari yang dipilih sama.

### Membaca pembentukan daftar

`SingleChildScrollView(scrollDirection: Axis.horizontal)` menyediakan geser horizontal untuk satu subtree `Row`. `Row(mainAxisSize: MainAxisSize.min)` membiarkan lebar konten mengikuti total anak. Jika lebih lebar daripada viewport, barulah area tersebut dapat digeser.

Collection `for (final day in DayHelper.dayNames.entries)` membuat satu kelompok widget untuk setiap pasangan angka/nama hari. `day.key` menjadi angka hari dan `day.value` menjadi label. Key global ditempelkan pada `Row` pembungkus, bukan pada data jadwal. `scheduleCounts[day.key] ?? 0` membuat hari tanpa entri memiliki hitungan nol.

`selected: widget.selectedDay == day.key` menghitung status bubble dari nilai parent. Callback `() => widget.onDaySelected(day.key)` menunda pemanggilan sampai ditekan. Menuliskan pemanggilan langsung tanpa closure akan berarti menjalankannya ketika membangun UI, bukan ketika pengguna menekan tombol.

`SizedBox(width: 9)` di awal/akhir dan `SizedBox(width: 2)` setelah tiap bubble membentuk jarak horizontal. Beberapa `Row` bertingkat tidak menambah perilaku interaksi baru; yang menentukan scroll adalah `SingleChildScrollView`, sedangkan penataan anak dilakukan baris-baris tersebut.

### Hal yang perlu diingat

`GlobalKey` digunakan karena kode membutuhkan akses ke context elemen untuk `ensureVisible`. Ia berbeda dari `ValueKey` pada record kartu. Tidak ada `setState()` di file ini karena perubahan nilai terpilih datang dari parent; penggunaan `StatefulWidget` tetap diperlukan agar key dan lifecycle dapat dipertahankan.

<a id="file-lib-pages-home-widgets-hari-bubble-dart"></a>

## `lib/pages/home/widgets/hari_bubble.dart`

[Buka source bubble hari](../../lib/pages/home/widgets/hari_bubble.dart).

### Peran dan class

`HariBubble` adalah `StatelessWidget` yang menerima `day`, `label`, `count`, `selected`, dan `onPressed`. Ia menampilkan satu pilihan hari, bukan menentukan sendiri hari mana yang aktif.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/hari_bubble.dart SHA256=3da225fedfe1d62dc47bc5e147fa7e351c27a31bbcc875fdce01516cea9093b0 -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class HariBubble extends StatelessWidget {
  const HariBubble({
    super.key,
    required this.day,
    required this.label,
    required this.count,
    required this.selected,
    required this.onPressed,
  });
  final int day;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: TextButton(
        key: ValueKey('day_$day'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.peach : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white54),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 3),
                      blurRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: selected ? 7 : 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 18),
                  Text(
                    '$label${count > 0 ? ' $count' : ''}',
                    style: TextStyle(
                      fontFamily: 'Merriweather Sans',
                      fontSize: selected ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : Colors.white70,
                    ),
                  ),
                  SizedBox(width: 18),
                ],
              ),
              SizedBox(height: selected ? 7 : 5),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Membaca tombol, semantik, dan dekorasi

`Semantics(selected: selected, button: true)` memberikan informasi aksesibilitas bahwa elemen ini tombol dan apakah sedang dipilih. Ini membantu teknologi bantu memahami status yang secara visual dinyatakan lewat warna. `TextButton` menangani tekan melalui `onPressed`. Key `ValueKey('day_$day')` memberikan identitas berdasarkan nilai hari.

`TextButton.styleFrom(...)` mengatur `minimumSize: Size(0, 48)`, foreground putih, serta `StadiumBorder`. Tinggi 48 adalah permintaan minimum area tombol; bukan ketentuan bahwa seluruh elemen pasti persis setinggi itu. `StadiumBorder` membentuk batas tombol seperti kapsul. Bentuk tombol ini berbeda dari dekorasi `Container` di dalamnya yang memakai `BorderRadius.circular(15)`.

`Container` memberi isi visual bubble: latar peach jika dipilih dan transparan jika tidak, border putih dengan transparansi `white54`, serta bayangan hanya pada kondisi dipilih. `BoxShadow` menggunakan `offset: Offset(0, 3)` untuk menggeser bayangan ke bawah dan `blurRadius: 3` untuk memburamkan tepinya. Properti ini menghias kotak, bukan menambah ruang layout di bawah kotak.

`Column` dan `Row` memakai `MainAxisSize.min` agar ukuran isi mengikuti teks dan jaraknya. `SizedBox` memberi ruang horizontal 18 pada kedua sisi, serta ruang vertikal 7 saat dipilih atau 5 ketika tidak. Karena font dan jarak berubah, ukuran bubble terpilih juga dapat berubah; ini berkaitan dengan pengguliran ulang pada `PilihHari`.

Teks dibentuk oleh interpolasi:

```dart
'$label${count > 0 ? ' $count' : ''}'
```

Contohnya `Senin 3` jika hitungannya 3 dan `Senin` jika nol. Operator ternary `kondisi ? nilaiA : nilaiB` juga mengatur font 18/16 serta warna primary/putih transparan. Font secara eksplisit memakai `Merriweather Sans`, sehingga menggantikan font Inter yang diwariskan dari Home untuk teks ini.

### Hal yang perlu diingat

Bubble hanya memanggil callback. Data jadwal dan `_hariDipilih` tidak diubah di sini. File ini menggunakan `TextButton`; tidak ada `InkWell` atau `GestureDetector` yang ditulis langsung.

<a id="file-lib-pages-home-widgets-home-day-summary-dart"></a>

## `lib/pages/home/widgets/home_day_summary.dart`

[Buka source ringkasan hari](../../lib/pages/home/widgets/home_day_summary.dart).

### Peran dan class

`HomeDaySummary` adalah `StatelessWidget` dengan tiga masukan: `dayName`, `ready`, dan `count`. Hasilnya adalah judul `Jadwal Senin` misalnya, ditambah jumlah mata kuliah atau status singkat.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/home_day_summary.dart SHA256=36ef50f1980f489e9a81b43222e087ddfdeda509b873cbd5dea05fb11b3abac1 -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class HomeDaySummary extends StatelessWidget {
  const HomeDaySummary({
    super.key,
    required this.dayName,
    required this.ready,
    required this.count,
  });

  final String dayName;
  final bool ready;
  final int count;

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    const countStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    final title = DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Jadwal $dayName', style: titleStyle),
          SizedBox(height: 4),
        ],
      ),
    );
    final trailing = ready && count > 0
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Flexible(child: Text('Mata Kuliah', style: countStyle)),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 5),
                        Text(
                          '$count',
                          key: const Key('selected_day_count'),
                          style: countStyle.copyWith(color: AppColors.primary),
                        ),
                        SizedBox(width: 5),
                      ],
                    ),
                    SizedBox(height: 1),
                  ],
                ),
              ),
            ],
          )
        : Text(ready ? 'Kosong' : '...', style: countStyle);

    return LayoutBuilder(
      builder: (context, viewport) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              SizedBox(
                width: (viewport.maxWidth - 2 * (19)).clamp(
                  0.0,
                  double.infinity,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double textWidth(String text, TextStyle style) {
                      final measurement = TextPainter(
                        text: TextSpan(
                          text: text,
                          style: DefaultTextStyle.of(context).style
                              .merge(style),
                        ),
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
                      )..layout();
                      final width = measurement.width;
                      measurement.dispose();
                      return width;
                    }

                    final trailingWidth = ready && count > 0
                        ? textWidth('Mata Kuliah', countStyle) +
                              8 +
                              textWidth('$count', countStyle) +
                              10
                        : textWidth(ready ? 'Kosong' : '...', countStyle);
                    final fits =
                        textWidth('Jadwal $dayName', titleStyle) +
                            20 +
                            trailingWidth <=
                        constraints.maxWidth;

                    return fits
                        ? Row(children: [title, const Spacer(), trailing])
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(children: [Flexible(child: title)]),
                              const SizedBox(height: 8),
                              Row(children: [Flexible(child: trailing)]),
                            ],
                          );
                  },
                ),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 14),
        ],
      ),
    );
  }
}
```

### Membaca tampilan judul dan jumlah

`titleStyle` dan `countStyle` merupakan nilai `TextStyle` lokal, bukan widget. Judul memakai ukuran 20 dengan ketebalan `w600`; hitungan memakai ukuran 16 dengan `w700`. `DecoratedBox` menghias judul dengan `BoxDecoration(border: Border(bottom: ...))`, sehingga garis putih tebal 3 hanya muncul di bagian bawah. `SizedBox(height: 4)` memberi jarak antara teks dan garis pada kotak itu.

`trailing` memilih isi berdasarkan kondisi:

- `ready && count > 0`: tulisan `Mata Kuliah` dan badge angka.
- `ready` dengan jumlah nol: `Kosong`.
- Belum ready: `...`.

Pada kondisi pertama, `Row(mainAxisSize: MainAxisSize.min)` mengecil mengikuti isi. Teks `Mata Kuliah` dibungkus `Flexible` agar dapat menyesuaikan lebar. Badge merupakan `Container` peach dengan radius 5; `Row`/`Column` kecil dan `SizedBox` memberi ruang horizontal 5 serta vertikal 1. `countStyle.copyWith(color: AppColors.primary)` mempertahankan ukuran/ketebalan sambil mengganti warna angka. `Key('selected_day_count')` memberikan identitas pada teks angka; key itu tidak menghitung nilai atau menampilkannya secara otomatis.

### Membaca keputusan baris atau kolom

`LayoutBuilder` pertama membatasi area isi ke lebar maksimum dikurangi 38, diapit dua `Spacer` seperti header. `LayoutBuilder` kedua mengukur ruang yang benar-benar tersedia bagi judul dan informasi jumlah.

Fungsi lokal `textWidth(String text, TextStyle style)` membuat `TextPainter` untuk mengukur lebar teks setelah `layout()`. `TextSpan` menyimpan teks dan style yang diukur. `DefaultTextStyle.of(context).style.merge(style)` menggabungkan style bawaan dengan style lokal; `Directionality.of(context)` mengikuti arah tulisan; `MediaQuery.textScalerOf(context)` mengikuti pengaturan pembesaran teks pengguna. Jadi keputusan responsif tidak hanya berdasarkan panjang string atau jumlah huruf.

Setelah lebar dibaca, `measurement.dispose()` melepaskan sumber daya painter. `TextPainter` di sini tidak menggambar widget teks di layar; yang menggambar tampilan tetap `Text` di tree.

`trailingWidth` menghitung perkiraan lebar isi kanan: teks, jarak 8, angka, serta ruang badge total 10. `fits` membandingkan lebar judul + jarak 20 + lebar kanan dengan `constraints.maxWidth`. Jika cukup, UI menggunakan `Row` dengan `Spacer` di antara judul dan informasi jumlah. Jika tidak, UI menggunakan `Column`, dengan masing-masing bagian di dalam `Row` dan `Flexible` serta jarak vertikal 8.

### Alasan susunan ini berguna

Teks yang membesar atau area yang menyempit dapat membutuhkan dua baris susunan. Kode memilih struktur layout yang berbeda berdasarkan hasil pengukuran. Pengukuran teks tersebut bukan pengukuran tinggi layar dan bukan tugas `IntrinsicHeight`.

<a id="file-lib-pages-home-widgets-list-jadwal-dart"></a>

## `lib/pages/home/widgets/list_jadwal.dart`

[Buka source daftar jadwal](../../lib/pages/home/widgets/list_jadwal.dart).

### Peran dan class

`ListJadwal` adalah `StatelessWidget` yang mengubah `AsyncSnapshot<List<JadwalDenganMataKuliah>>` menjadi tampilan. Ia menerima hari terpilih, callback tambah/edit/hapus/retry, serta flag pesan offline. Callback edit dan hapus bertipe `ValueChanged<JadwalDenganMataKuliah>` karena perlu menyampaikan data mana yang dipilih.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/list_jadwal.dart SHA256=04f98b3b8d85680c4a39f645eb980bcb69585915b624acbe48db5ce83595b19e -->

```dart
import 'package:flutter/material.dart';

import '../../../database/database.dart';
import 'status_jadwal.dart';
import '../../../utils/day_helper.dart';
import 'jadwal_kosong.dart';
import 'kartu_jadwal.dart';

class ListJadwal extends StatelessWidget {
  const ListJadwal({
    super.key,
    required this.snapshot,
    required this.selectedDay,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
    this.showOfflineEmptyState = false,
  });
  final AsyncSnapshot<List<JadwalDenganMataKuliah>> snapshot;
  final int selectedDay;
  final VoidCallback onAdd;
  final ValueChanged<JadwalDenganMataKuliah> onEdit;
  final ValueChanged<JadwalDenganMataKuliah> onDelete;
  final VoidCallback onRetry;
  final bool showOfflineEmptyState;
  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return JadwalLoadError(onRetry: onRetry);
    }
    if (!snapshot.hasData ||
        snapshot.connectionState == ConnectionState.waiting) {
      return const JadwalLoading();
    }
    final allSchedules = snapshot.data!;
    final daySchedules =
        allSchedules.where((data) => data.jadwal.hari == selectedDay).toList()
          ..sort((a, b) {
            final byTime = a.jadwal.jamMulai.compareTo(b.jadwal.jamMulai);
            return byTime != 0 ? byTime : a.jadwal.id.compareTo(b.jadwal.id);
          });
    if (daySchedules.isEmpty) {
      return JadwalKosong(
        dayName: DayHelper.dayNames[selectedDay] ?? '-',
        onAdd: onAdd,
        showOfflineMessage: showOfflineEmptyState && allSchedules.isEmpty,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const sideGap = 19.0;
        final size = MediaQuery.sizeOf(context);
        final columns = size.width > size.height ? 2 : 1;
        final rowCount = (daySchedules.length + columns - 1) ~/ columns;
        final compact =
            (constraints.maxWidth - sideGap * 2 - spacing * (columns - 1)) /
                columns <
            300;

        Widget card(int index) {
          final data = daySchedules[index];
          return KartuJadwal(
            key: ValueKey('schedule_${data.jadwal.id}'),
            data: data,
            compact: compact,
            onEdit: () => onEdit(data),
            onDelete: () => onDelete(data),
          );
        }

        // Build rows lazily while letting their height follow text size/content.
        return Row(
          children: [
            const Spacer(),
            SizedBox(
              width: (constraints.maxWidth - sideGap * 2).clamp(
                0.0,
                double.infinity,
              ),
              child: ListView.separated(
                key: PageStorageKey('schedules_${selectedDay}_$columns'),
                itemCount: rowCount,
                separatorBuilder: (_, _) => const SizedBox(height: spacing),
                itemBuilder: (context, row) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (row == 0) const SizedBox(height: 8),
                    if (columns == 1)
                      card(row)
                    else
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [card(row * 2), const Spacer()],
                              ),
                            ),
                            const SizedBox(width: spacing),
                            Expanded(
                              child: Column(
                                children: [
                                  row * 2 + 1 < daySchedules.length
                                      ? card(row * 2 + 1)
                                      : const SizedBox.shrink(),
                                  const Spacer(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Allow the final card to scroll clear of the floating action.
                    if (row == rowCount - 1) const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        );
      },
    );
  }
}
```

### Membaca urutan kondisi

Urutan pemeriksaan berpengaruh pada hasil UI. `snapshot.hasError` lebih dulu menghasilkan `JadwalLoadError`. Bila tidak ada error tetapi data belum tersedia atau koneksi masih `waiting`, hasilnya `JadwalLoading`. Setelah dua pemeriksaan itu, `snapshot.data!` dibaca. Tanda `!` menyatakan kepada Dart bahwa nilai tersebut tidak null; keamanan pembacaan pada jalur ini bergantung pada pemeriksaan sebelumnya.

`where(...)` memilih jadwal dengan angka hari yang sesuai. `toList()` menghasilkan list baru, kemudian cascade `..sort(...)` mengurutkan list hasil filter tersebut. Data diurutkan dari `jamMulai` terkecil; jika waktu mulai sama, ID terkecil didahulukan. Pengurutan ini mengatur urutan tampilan, bukan melakukan validasi bentrok jadwal.

Bila hasil filter kosong, `JadwalKosong` menerima nama hari, callback tambah, dan `showOfflineMessage: showOfflineEmptyState && allSchedules.isEmpty`. Jadi pesan khusus offline hanya diizinkan ketika seluruh daftar kosong. Hari Selasa kosong sementara Senin berisi tidak otomatis menghasilkan pesan bahwa perangkat belum memiliki jadwal.

### Membaca layout responsif

`LayoutBuilder` memberikan constraint area daftar. `MediaQuery.sizeOf(context)` membaca ukuran media/area aplikasi yang diwariskan. Kode memilih dua kolom ketika `size.width > size.height`, dan satu kolom selain itu. Ini perbandingan ukuran media yang dipakai kode; ia tidak menghitung apakah setiap kartu pasti pas berdasarkan isi.

`spacing = 12` menjadi jarak antarbaris dan antar dua kolom. `sideGap = 19` menjadi jarak sisi area daftar. `rowCount = (daySchedules.length + columns - 1) ~/ columns` melakukan pembulatan ke atas dengan pembagian integer. Misalnya 5 jadwal dengan 2 kolom membutuhkan 3 baris.

`compact` bernilai benar ketika perkiraan lebar satu kartu, setelah jarak sisi dan jarak antarkolom dikurangi, kurang dari 300. Nilai ini diteruskan ke kartu. Ia bukan pemeriksaan jenis perangkat dan bukan pembacaan orientasi secara langsung.

Fungsi lokal `card(int index)` mengambil satu data dan membangun `KartuJadwal`. `ValueKey('schedule_${data.jadwal.id}')` memberikan identitas berdasarkan ID, membantu Flutter mencocokkan widget ketika posisi item berubah. Closure `() => onEdit(data)` dan `() => onDelete(data)` mengikat aksi pada data kartu tersebut tanpa menjalankannya saat build.

### Membaca daftar dan tinggi baris

`ListView.separated` membangun baris sesuai kebutuhan area scroll, dengan `itemBuilder` untuk isi dan `separatorBuilder` untuk jarak 12. Kode ini tidak menggunakan `GridView`; setiap item list merupakan satu baris yang dapat berisi satu atau dua kartu. `PageStorageKey('schedules_${selectedDay}_$columns')` mengidentifikasi scrollable menurut hari dan jumlah kolom, sehingga posisi scroll dapat disimpan/dipulihkan melalui `PageStorage` pada konteks yang sesuai.

Pada satu kolom, `card(row)` langsung digunakan. Pada dua kolom, `IntrinsicHeight` membungkus `Row`; dua `Expanded` membagi lebar yang tersedia secara sama rata. Tiap sisi berisi `Column` dengan kartu di atas dan `Spacer` di bawah. Baris mengikuti kebutuhan tinggi konten tertingginya; ruang lebih pada sisi yang lebih pendek berada di bawah kartu. Jadi tinggi luar baris disamakan, tetapi dekorasi dua kartu tidak dipaksa selalu setinggi satu sama lain.

Jika jumlah jadwal ganjil, sisi terakhir menggunakan `SizedBox.shrink()` sebagai widget kosong. Ekspresi `row * 2 + 1 < daySchedules.length` mencegah akses index yang melewati akhir list. `SizedBox(height: 8)` ditambah pada baris pertama dan `SizedBox(height: 100)` pada baris terakhir. Ruang bawah itu memungkinkan kartu terakhir digeser melewati area tombol tambah yang menumpuk di kanan bawah.

### Jebakan konsep

`IntrinsicHeight` menghitung kebutuhan tinggi intrinsik subtree; **bukan mengukur tinggi layar**. Ukuran akhirnya tetap tunduk pada batas dari parent. Layout ini memerlukan tahap pengukuran tambahan, sehingga bukan wrapper yang harus dipasang pada semua widget; lihat [dokumentasi IntrinsicHeight](https://api.flutter.dev/flutter/widgets/IntrinsicHeight-class.html). `Expanded` mengatur pembagian sisa ruang pada sumbu utama `Row`/`Column`; di `Row` ia membagi lebar, sedangkan di `Column` ia membagi tinggi. Baca [glosarium layout](05-glosarium.md) untuk hubungan constraint, ukuran intrinsik, dan flex.

<a id="file-lib-pages-home-widgets-kartu-jadwal-dart"></a>

## `lib/pages/home/widgets/kartu_jadwal.dart`

[Buka source kartu jadwal](../../lib/pages/home/widgets/kartu_jadwal.dart).

### Peran dan class

`KartuJadwal` adalah `StatelessWidget` yang menyatukan header, rincian, dan pengingat. Properti `data` memuat data jadwal/mata kuliah. `onEdit` dan `onDelete` adalah `VoidCallback`, sementara `compact` memiliki nilai awal `false` dan diteruskan ke bagian-bagian kartu.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/kartu_jadwal.dart SHA256=2d8f16d4d37b7b37e13446240fb74d3df585f9e37276ee9ebf9d923fd923739f -->

```dart
import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../theme/app_colors.dart';
import 'jadwal_card_header.dart';
import 'jadwal_card_details.dart';
import 'jadwal_card_reminder.dart';

/// Menyusun header, rincian kuliah, dan pengingat sesuai konten jadwal.
class KartuJadwal extends StatelessWidget {
  const KartuJadwal({
    super.key,
    required this.data,
    required this.onEdit,
    required this.onDelete,
    this.compact = false,
  });
  final JadwalDenganMataKuliah data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final jadwal = data.jadwal;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 2),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.0),
          Row(
            children: [
              SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  children: [
                    JadwalCardHeader(
                      nama: data.mataKuliah.nama,
                      compact: compact,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                    const SizedBox(height: 12),
                    JadwalCardDetails(data: data, compact: compact),
                    if (jadwal.pengingatAktif) ...[
                      const SizedBox(height: 12),
                      JadwalCardReminder(
                        menitSebelum: jadwal.menitSebelum,
                        compact: compact,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 16.0),
            ],
          ),
          SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
```

### Membaca bagian kartu

Variabel lokal `jadwal = data.jadwal` mempersingkat akses data berulang. `Container` terluar memberikan latar peach, sudut radius 14, serta `BoxShadow` hitam transparan yang bergeser ke bawah 4 dengan blur 2. `BoxDecoration` adalah objek konfigurasi dekorasi, bukan widget terpisah yang menempatkan anak.

`Column(mainAxisSize: MainAxisSize.min)` membuat kartu mengikuti tinggi isinya. Ruang atas 10 dan bawah 16 berasal dari `SizedBox`. Di tengah terdapat `Row` dengan jarak kiri/kanan 16 dan `Expanded` untuk kolom isi; dengan susunan ini, isi kartu memiliki lebar terbatas dan teks dapat menyesuaikan diri pada lebar tersebut.

`JadwalCardHeader` menerima nama mata kuliah dan callback aksi. Setelah jarak 12, `JadwalCardDetails` menerima seluruh `data`. Bagian pengingat menggunakan collection `if` dan spread:

```dart
if (jadwal.pengingatAktif) ...[
  const SizedBox(height: 12),
  JadwalCardReminder(
    menitSebelum: jadwal.menitSebelum,
    compact: compact,
  ),
]
```

`if` menentukan apakah elemen masuk ke daftar children; `...` menyisipkan isi list itu sebagai anak-anak terpisah. Ketika pengingat nonaktif, baik jarak 12 maupun banner pengingat tidak dibuat pada posisi tersebut. Ini berbeda dari menyisakan kotak kosong dengan tinggi tetap.

### Alasan pemisahan

File ini hanya menyusun kartu; rincian cara menampilkan waktu dan ikon ada pada file lain. Callback tetap bergerak ke parent sehingga kartu tidak perlu mengetahui repository maupun `Navigator`. Tidak ada aksi menekan seluruh permukaan kartu: hanya tombol-tombol yang memang dipasangi callback yang interaktif.

<a id="file-lib-pages-home-widgets-jadwal-card-header-dart"></a>

## `lib/pages/home/widgets/jadwal_card_header.dart`

[Buka source header kartu](../../lib/pages/home/widgets/jadwal_card_header.dart).

### Peran dan class

`JadwalCardHeader` menerima `nama`, `compact`, `onEdit`, dan `onDelete`. Ia menampilkan judul mata kuliah beserta dua tombol aksi. **`compact` memang diterima dan disimpan sebagai field, tetapi belum dibaca oleh `build()` pada source ini.** Jangan menganggap semua parameter yang ada sudah memengaruhi tampilan.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/jadwal_card_header.dart SHA256=031adaaa292682caa91f6831b8a2962a5539d7081ec6b1ecd3a93a5ef241224c -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'home_icon.dart';

class JadwalCardHeader extends StatelessWidget {
  const JadwalCardHeader({
    super.key,
    required this.nama,
    required this.compact,
    required this.onEdit,
    required this.onDelete,
  });
  final String nama;
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final title = Tooltip(
      message: nama,
      child: Text(
        nama,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
    final actions = [
      IconButton(
        tooltip: 'Edit jadwal',
        onPressed: onEdit,
        visualDensity: VisualDensity.compact,
        icon: const HomeIcon('edit', size: 18),
      ),
      IconButton(
        tooltip: 'Hapus jadwal',
        onPressed: onDelete,
        visualDensity: VisualDensity.compact,
        icon: const HomeIcon('delete', size: 18),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: title
                            )
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              ...actions.map(
                (action) => Column(children: [action, const Spacer()]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

### Membaca judul dan aksi

`title` adalah widget lokal berupa `Tooltip(message: nama)` yang membungkus `Text(nama)`. Tooltip menyediakan teks bantuan nama lengkap. Teks judul sendiri tidak diberi `maxLines` atau `TextOverflow.ellipsis`, sehingga kode ini tidak secara eksplisit memotongnya menjadi satu baris. Style memakai ukuran 20, ketebalan `w800`, dan warna primary.

`actions` adalah list dua `IconButton`. Tombol pertama menggunakan `HomeIcon('edit', size: 18)` dan callback `onEdit`; tombol kedua menggunakan ikon `delete` dan `onDelete`. `tooltip` membedakan tujuan tombol, sedangkan `visualDensity: VisualDensity.compact` meminta susunan tombol lebih padat. Ukuran ikon 18 bukan jaminan ukuran total area tekan juga 18 karena `IconButton` memiliki aturan ukuran/padding sendiri.

### Membaca alignment dan tinggi

`IntrinsicHeight` membungkus `Row` yang berisi area judul serta dua aksi. Area judul berada pada `Expanded`, sehingga memperoleh sisa lebar setelah tombol. Di dalamnya terdapat beberapa `Column`/`Row` tambahan yang kembali membatasi lebar teks melalui `Expanded`.

Setiap bagian diberi `Column(children: [..., const Spacer()])`. Pada tinggi baris yang sudah dibatasi hasil layout intrinsik, `Spacer` menyerap ruang di bawah isi. Manfaat susunan ini adalah menjaga judul dan tombol berada dekat bagian atas walaupun judul membungkus menjadi beberapa baris. `MainAxisSize.min` pada kolom pembungkus membantu bagian luar mengikuti isi.

`...actions.map(...)` mengubah setiap tombol menjadi `Column` berisi tombol dan spacer, lalu menyisipkan seluruh hasilnya ke `children` milik `Row`. `map` mengubah item; spread `...` memasukkan item-item hasil perubahan ke list children. Keduanya merupakan fitur Dart, bukan widget Flutter.

### Batas tanggung jawab

Tekan edit/hapus hanya memanggil callback. File ini tidak membuka halaman dan tidak menghapus record. `IntrinsicHeight` mengikuti isi header, bukan membaca tinggi perangkat. Referensi API: [IntrinsicHeight](https://api.flutter.dev/flutter/widgets/IntrinsicHeight-class.html).

<a id="file-lib-pages-home-widgets-jadwal-card-details-dart"></a>

## `lib/pages/home/widgets/jadwal_card_details.dart`

[Buka source rincian kartu](../../lib/pages/home/widgets/jadwal_card_details.dart).

### Peran dan class

`JadwalCardDetails` adalah `StatelessWidget` dengan masukan `data` dan `compact`. Ia membuat empat pasangan label/nilai: waktu kuliah, ruangan, dosen, dan SKS. Class privat `_InfoDetail` menyusun satu informasi yang terdiri dari ikon, label, serta nilai.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/jadwal_card_details.dart SHA256=5260befbefc8631cfcd1c77eaa99e9c0dd74bbbfcb820e0f8a37f2d121a9da64 -->

```dart
import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/time_helper.dart';
import 'home_icon.dart';

class JadwalCardDetails extends StatelessWidget {
  const JadwalCardDetails({
    super.key,
    required this.data,
    required this.compact,
  });
  final JadwalDenganMataKuliah data;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final jadwal = data.jadwal;
    final mataKuliah = data.mataKuliah;
    return Column(
      children: [
        _detailPair(
          _InfoDetail(
            icon: 'clock',
            label: 'Waktu Kuliah',
            value: TimeHelper.formatRange(jadwal.jamMulai, jadwal.jamSelesai),
          ),
          _InfoDetail(
            icon: 'room',
            label: 'Ruangan',
            value: _value(jadwal.ruangan),
          ),
        ),
        const SizedBox(height: 14),
        _detailPair(
          _InfoDetail(
            icon: 'lecturer',
            label: 'Dosen',
            value: _value(mataKuliah.dosen),
          ),
          _InfoDetail(
            icon: 'credits',
            label: 'SKS',
            value: mataKuliah.sks?.toString() ?? '-',
          ),
        ),
      ],
    );
  }

  Widget _detailPair(Widget first, Widget second) => compact
      ? Column(children: [first, const SizedBox(height: 10), second])
      : IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(children: [first, const Spacer()]),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(children: [second, const Spacer()]),
              ),
            ],
          ),
        );

  String _value(String? value) =>
      value == null || value.trim().isEmpty ? '-' : value.trim();
}

class _InfoDetail extends StatelessWidget {
  const _InfoDetail({
    required this.icon,
    required this.label,
    required this.value,
  });
  final String icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      children: [
        Column(children: [HomeIcon(icon), const Spacer()]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    ),
  );
}
```

### Membaca nilai yang ditampilkan

`final jadwal = data.jadwal` dan `final mataKuliah = data.mataKuliah` adalah referensi lokal agar ekspresi berikutnya lebih singkat. Waktu memakai `TimeHelper.formatRange(jadwal.jamMulai, jadwal.jamSelesai)`. Pada helper proyek, bilangan waktu berarti total menit: `480` menjadi `08:00`, dan `570` menjadi `09:30`; hasil rentangnya `08:00 - 09:30`.

Helper melakukan pembagian integer `~/ 60` untuk jam, sisa bagi `% 60` untuk menit, lalu `padLeft(2, '0')` untuk dua digit. Ini format tampilan dari angka menit, bukan pengukuran durasi build, pembacaan jam perangkat, atau penentuan zona waktu. Lihat pembahasan helper pada bab pendukung.

Ruangan serta dosen melewati `_value(String? value)`. Jika null atau setelah `trim()` ternyata kosong, hasilnya `'-'`; selain itu digunakan string yang sudah dibuang spasi awal/akhirnya. SKS memakai `mataKuliah.sks?.toString() ?? '-'`: integer nullable diubah menjadi teks bila ada. Kode ini tidak menambah akhiran `SKS` karena labelnya sudah terpisah.

### Membaca `_detailPair`

Metode `_detailPair(Widget first, Widget second)` mengatur pasangan informasi. Jika `compact` benar, hasilnya `Column` dengan kedua informasi ditumpuk dan jarak vertikal 10. Jika tidak, hasilnya `IntrinsicHeight` → `Row` dengan dua `Expanded` berjarak 16.

`flex: 3` pada informasi pertama dan `flex: 2` pada informasi kedua membagi **sisa lebar setelah jarak tetap** dengan perbandingan 3:2. Jadi kolom kiri memperoleh 60% dan kanan 40% dari sisa lebar itu, bukan 60%/40% dari seluruh layar. `Column` kecil di setiap `Expanded` berisi informasi di atas dan `Spacer` di bawah untuk menyerap selisih tinggi antarbagian.

Ada dua panggilan `_detailPair`: waktu/ruangan kemudian dosen/SKS, dipisahkan `SizedBox(height: 14)`. Saat compact, urutan visual menjadi waktu, ruangan, dosen, SKS dari atas ke bawah.

### Membaca `_InfoDetail`

Constructor `_InfoDetail` meminta tiga string: `icon`, `label`, dan `value`. `HomeIcon(icon)` berada di kolom kiri; `SizedBox(width: 12)` memberi jarak ke area teks. `Expanded` pada sisi teks membuat label dan nilai memperoleh lebar tersisa sehingga teks panjang dapat membungkus.

`IntrinsicHeight` terluar membuat baris informasi mengikuti kebutuhan tinggi anak. `Column(children: [HomeIcon(icon), const Spacer()])` menempatkan ikon di atas. Area teks memiliki label ukuran 12, ketebalan `w600`, nilai ukuran 14, serta jarak vertikal 2. Label dan nilai masing-masing dibungkus `Row` dengan `Expanded`, yang memastikan lebar teks dibatasi area tersebut. `Spacer` terakhir menjaga sisa ruang di bawah teks ketika tinggi baris lebih besar.

Semua teks memakai `AppColors.primary`. Tidak ada `maxLines` atau ellipsis; tinggi dapat tumbuh mengikuti isi. Ini alasan praktis layout berbasis isi relevan pada nama dosen atau ruangan yang panjang.

### Jebakan konsep

`_InfoDetail` tetap widget walaupun namanya privat. `_detailPair` adalah metode pembuat widget, bukan class. `IntrinsicHeight` bukan alat mengukur tinggi layar; kalau tujuannya membaca ukuran media, contoh yang benar dalam Home adalah `MediaQuery.sizeOf(context)` pada `ListJadwal`. Pengukuran intrinsik berlapis pada file ini juga memiliki biaya layout tambahan; manfaat penataan isinya tidak berarti wrapper tersebut perlu ditambahkan di semua tempat.

<a id="file-lib-pages-home-widgets-jadwal-card-reminder-dart"></a>

## `lib/pages/home/widgets/jadwal_card_reminder.dart`

[Buka source banner pengingat](../../lib/pages/home/widgets/jadwal_card_reminder.dart).

### Peran dan class

`JadwalCardReminder` adalah `StatelessWidget` untuk menampilkan informasi menit pengingat. Field `menitSebelum` menentukan teks dan `compact` menyesuaikan ukuran huruf serta jarak sisi. Banner hanya disertakan oleh `KartuJadwal` bila `pengingatAktif` benar.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/jadwal_card_reminder.dart SHA256=04e0530003507a3421c1463c8654b5c5427882ebed8b51eea5e154768dce4587 -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class JadwalCardReminder extends StatelessWidget {
  const JadwalCardReminder({
    super.key,
    required this.menitSebelum,
    required this.compact,
  });
  final int menitSebelum;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 3),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8),
          Row(
            children: [
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$menitSebelum Menit Sebelumnya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
```

### Membaca tampilan

`Container(width: double.infinity)` meminta lebar maksimum yang diizinkan parent. Ini tidak berarti widget boleh melampaui batas layar; constraint parent tetap menentukan ukuran akhirnya. Dekorasi memakai warna primary, radius 7, dan bayangan dengan offset bawah 3 serta blur 3.

`Column(mainAxisSize: MainAxisSize.min)` mempertahankan tinggi mengikuti isi. Jarak vertikal atas/bawah masing-masing 8. Pada baris utama, jarak kiri/kanan menjadi 8 ketika compact dan 12 ketika normal. `Expanded` menyediakan area isi yang dibatasi sehingga row di dalamnya dapat membagi ruang untuk ikon dan teks.

Ikon `Icons.notifications_outlined` berwarna putih dengan ukuran 18. Setelah jarak 8, `Expanded` membungkus teks `'$menitSebelum Menit Sebelumnya'`. Interpolasi mengganti angka sesuai data, contohnya `15 Menit Sebelumnya`. `fontSize` menjadi 14 pada compact atau 16 pada normal, dengan ketebalan `w600`.

### Batas tanggung jawab

Banner ini tidak memiliki toggle, callback, timer, maupun pemanggilan layanan notifikasi. Ia hanya menampilkan pengaturan yang sudah ada dalam data. Melihat banner `15 Menit Sebelumnya` tidak membuktikan notifikasi perangkat sudah dijadwalkan atau berhasil dikirim.

<a id="file-lib-pages-home-widgets-home-icon-dart"></a>

## `lib/pages/home/widgets/home_icon.dart`

[Buka source pembungkus ikon](../../lib/pages/home/widgets/home_icon.dart).

### Peran dan class

`HomeIcon` adalah `StatelessWidget` yang membungkus `SvgPicture.asset` dari paket `flutter_svg`. Constructor menerima `name` secara posisional, misalnya `HomeIcon('clock')`, dan `size` sebagai parameter bernama dengan nilai awal 32. `super.key` tetap memungkinkan parent memberi identitas widget.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/home_icon.dart SHA256=7ca4578e9174683f6323dc4862c5c80f6f5a4d464396a5e969b0b3f849bd099f -->

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Original Figma vectors, preserving their aspect ratios.
class HomeIcon extends StatelessWidget {
  const HomeIcon(this.name, {super.key, this.size = 32});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icon/$name.svg',
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
  );
}
```

### Membaca pemuatan aset

`'assets/icon/$name.svg'` membentuk path dari nama. Contohnya `HomeIcon('room')` memuat `assets/icon/room.svg`. Aset bersumber dari proyek, bukan permintaan HTTP. Berkas juga perlu tersedia dan didaftarkan sebagaimana pengaturan aset proyek; wrapper ini tidak membuat SVG yang hilang secara otomatis.

`width: size` serta `height: size` meminta kotak persegi. `fit: BoxFit.contain` menyesuaikan keseluruhan gambar agar tetap muat di kotak dengan rasio aspek dipertahankan. Jika gambar aslinya memanjang, ruang kosong dapat tersisa pada salah satu arah; gambar tidak dipaksa berubah proporsi.

`excludeFromSemantics: true` mengecualikan gambar dari deskripsi aksesibilitas. Pada detail, label teks di sebelah ikon sudah menjelaskan informasi; pada tombol edit/hapus tersedia tooltip. Pengecualian ini berarti ikon tidak memberikan nama aksesibilitasnya sendiri, sehingga konteks teks/tombol tetap penting.

### Alasan pembungkus ini berguna

Semua pemanggil memakai aturan path, ukuran bawaan, dan fit yang sama tanpa menulis `SvgPicture.asset` berulang. Komentar source menyebut vektor Figma; bab ini hanya menjelaskan aset yang dirujuk kode dan tidak melakukan pembandingan terhadap desain Figma.

<a id="file-lib-pages-home-widgets-tambah-jadwal-button-dart"></a>

## `lib/pages/home/widgets/tambah_jadwal_button.dart`

[Buka source tombol tambah](../../lib/pages/home/widgets/tambah_jadwal_button.dart).

### Peran dan class

`TambahJadwalButton` adalah `StatelessWidget` yang menerima callback `onPressed` dan boolean `showLabel` dengan default `false`. Satu class ini menghasilkan dua tampilan melalui operator ternary: tombol panjang dengan label atau tombol ikon bulat.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/tambah_jadwal_button.dart SHA256=32d6bd2765c107436fb5936b8ab7951f6f9ed17e0b18037856e402d465580936 -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class TambahJadwalButton extends StatelessWidget {
  const TambahJadwalButton({
    super.key,
    required this.onPressed,
    this.showLabel = false,
  });
  final VoidCallback onPressed;
  final bool showLabel;
  @override
  Widget build(BuildContext context) => showLabel
      ? FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.peach,
            foregroundColor: AppColors.primary,
            minimumSize: const Size(236, 50),
            visualDensity: VisualDensity.standard,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: const Icon(Icons.add, size: 28),
          label: const Text('Tambah Jadwal'),
        )
      : IconButton.filled(
          tooltip: 'Tambah Jadwal',
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.peach,
            fixedSize: const Size(56, 56),
            visualDensity: VisualDensity.standard,
            shape: const CircleBorder(),
            side: const BorderSide(color: AppColors.peach),
            elevation: 4,
            shadowColor: Colors.black45,
          ),
          icon: const Icon(Icons.add, size: 28),
        );
}
```

### Membaca dua bentuk tombol

Ketika `showLabel` benar, `FilledButton.icon` menampilkan ikon tambah ukuran 28 dan teks `Tambah Jadwal`. `FilledButton.styleFrom` membuat latar peach, foreground primary, `minimumSize: Size(236, 50)`, bentuk `StadiumBorder`, serta teks Inter ukuran 20 dengan ketebalan `w600`. Minimum size adalah batas minimum yang diminta dan tetap bekerja dalam constraint layout; ia bukan jaminan bahwa ukuran selalu tepat 236×50.

Ketika `showLabel` salah, `IconButton.filled` menampilkan ikon tambah tanpa teks terlihat. `tooltip: 'Tambah Jadwal'` menyediakan nama bantuan. Style menggunakan latar primary, foreground peach, `fixedSize: Size(56, 56)`, bentuk `CircleBorder`, garis sisi peach, `elevation: 4`, serta `shadowColor: Colors.black45`. Permintaan ukuran tetap pun masih tunduk pada constraint/aturan tombol yang berlaku. `visualDensity: VisualDensity.standard` dipilih pada kedua bentuk agar tidak memakai kepadatan compact.

`StadiumBorder` cocok untuk kotak memanjang dengan ujung membulat; `CircleBorder` membentuk batas lingkaran pada area persegi. Keduanya objek bentuk, bukan class halaman.

### Hubungan dengan Home

`JadwalKosong` memakai `showLabel: true` agar tersedia ajakan tambah yang jelas di area kosong. `HomePage` menggunakan default tanpa label untuk tombol kanan bawah ketika ada jadwal. Kedua bentuk menjalankan callback yang sama jenisnya; tombol tidak tahu halaman tambah harus dibuka dengan database apa.

<a id="file-lib-pages-home-widgets-jadwal-kosong-dart"></a>

## `lib/pages/home/widgets/jadwal_kosong.dart`

[Buka source kondisi kosong](../../lib/pages/home/widgets/jadwal_kosong.dart).

### Peran dan class

`JadwalKosong` adalah `StatelessWidget` yang menampilkan ilustrasi, tulisan `Tidak Ada Jadwal`, pesan offline opsional, serta tombol tambah. Ia menerima `dayName`, `onAdd`, dan `showOfflineMessage`. **`dayName` disimpan tetapi belum dibaca oleh `build()` saat ini**; teks kondisi kosong tidak menyebut nama hari walaupun pemanggil sudah memberikannya.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/jadwal_kosong.dart SHA256=943ece256efdf5fe7258df485281de963b6e3601bdd713832ea3a48b394547de -->

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'tambah_jadwal_button.dart';

class JadwalKosong extends StatelessWidget {
  const JadwalKosong({
    super.key,
    required this.dayName,
    required this.onAdd,
    this.showOfflineMessage = false,
  });
  final String dayName;
  final VoidCallback onAdd;
  final bool showOfflineMessage;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24),
          Row(
            children: [
              const Spacer(),
              SizedBox(
                width: (constraints.maxWidth - 2 * (24)).clamp(
                  0.0,
                  double.infinity,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: (constraints.maxWidth - 48).clamp(
                      0,
                      double.infinity,
                    ),
                    minHeight: (constraints.maxHeight - 48).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            // Preserve the illustration's original geometry and surrounding space.
                            ClipRect(
                              child: SizedBox.square(
                                dimension: 120,
                                child: SvgPicture.asset(
                                  'assets/icon/empty.svg',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.none,
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Tidak Ada Jadwal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (showOfflineMessage) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Kamu sedang offline dan belum memiliki jadwal tersimpan di perangkat ini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                            const SizedBox(height: 14),
                            TambahJadwalButton(
                              onPressed: onAdd,
                              showLabel: true,
                            ),
                            SizedBox(height: constraints.maxHeight * 0.18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
    ),
  );
}
```

### Membaca area scroll dan constraint

`LayoutBuilder` membungkus `SingleChildScrollView`, sehingga builder masih dapat membaca constraint viewport sebelum isi scroll memperoleh ruang vertikal yang dapat memanjang. `Column(mainAxisSize: MainAxisSize.min)` mengikuti isi. Jarak luar atas/bawah masing-masing 24, sedangkan `SizedBox` tengah memakai lebar `maxWidth - 48` dan dua `Spacer` horizontal untuk ruang sisi.

`ConstrainedBox` dengan `BoxConstraints(minWidth: ..., minHeight: ...)` menambahkan batas **minimum**, bukan tinggi maksimum. `minHeight` memakai `constraints.maxHeight - 48`; ini membantu area isi setidaknya memanfaatkan tinggi viewport yang tersedia setelah jarak atas/bawah. Bila isi bertambah tinggi, misalnya akibat teks yang diperbesar, scroll masih memungkinkan pengguna menjangkau konten. `clamp(0, double.infinity)` mencegah minimum bernilai negatif.

Di dalamnya ada `Row` dengan `Expanded` agar kolom isi mendapat lebar terbatas. Tidak ada `Spacer` vertikal di kolom isi yang berada langsung dalam scroll; tinggi tumbuh dari konten dan jarak-jarak yang ditulis. Ruang terakhir menggunakan `SizedBox(height: constraints.maxHeight * 0.18)`, yaitu 18% tinggi maksimum area kosong dari parent, bukan 18% tinggi seluruh perangkat.

### Membaca ilustrasi, pesan, dan tombol

`SvgPicture.asset('assets/icon/empty.svg')` dimuat dalam `SizedBox.square(dimension: 120)`. `fit: BoxFit.none` mempertahankan ukuran gambar tanpa menskalakannya agar muat; default alignment menempatkan gambar di tengah kotaknya. `ClipRect` memotong bagian yang melewati batas persegi. Ini berbeda dari `HomeIcon` yang memakai `BoxFit.contain` untuk menskalakan gambar agar seluruhnya muat.

`excludeFromSemantics: true` memperlakukan ilustrasi sebagai dekorasi; pesan `Tidak Ada Jadwal` tetap tersedia sebagai teks. Teks tersebut putih, ukuran 20, `w600`, serta `textAlign: TextAlign.center`. `textAlign` mengatur perataan teks dalam ruang teks, bukan menempatkan seluruh kolom di tengah layar.

Collection `if (showOfflineMessage) ...[...]` menambahkan jarak 12 dan pesan offline hanya saat flag benar. Setelah jarak 14, `TambahJadwalButton(onPressed: onAdd, showLabel: true)` menjadi tindakan utama.

### Hal yang perlu diingat

Widget ini tidak mendeteksi jaringan atau membaca database. Keputusan keadaan kosong dibuat `ListJadwal`, dan flag offline berasal dari parent. Menampilkan pesan offline berbeda dari menerapkan kemampuan sinkronisasi.

<a id="file-lib-pages-home-widgets-status-jadwal-dart"></a>

## `lib/pages/home/widgets/status_jadwal.dart`

[Buka source status jadwal](../../lib/pages/home/widgets/status_jadwal.dart).

### Peran dan class

File ini memuat dua class `StatelessWidget`: `JadwalLoadError` untuk kegagalan pemuatan, serta `JadwalLoading` untuk proses menunggu. Keduanya dipilih oleh `ListJadwal`, bukan memilih statusnya sendiri.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/status_jadwal.dart SHA256=8bae6dbad0d7a9da83c8730c4b4b1fba8c89845e06115f7a3f49f5c13e6e1ed5 -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class JadwalLoadError extends StatelessWidget {
  const JadwalLoadError({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 24),
            Row(
              children: [
                const Spacer(),
                SizedBox(
                  width: (constraints.maxWidth - 2 * (24)).clamp(
                    0.0,
                    double.infinity,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 48).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off_outlined,
                                color: Colors.white70,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Jadwal belum dapat dimuat',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Silakan coba lagi untuk menampilkan jadwalmu.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: onRetry,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.peach,
                                  foregroundColor: AppColors.primary,
                                ),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class JadwalLoading extends StatelessWidget {
  const JadwalLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Spacer(),
        Row(
          children: [
            Spacer(),
            CircularProgressIndicator(
              color: AppColors.peach,
              semanticsLabel: 'Memuat jadwal',
            ),
            Spacer(),
          ],
        ),
        Spacer(),
      ],
    );
  }
}
```

### Membaca `JadwalLoadError`

Constructor meminta `VoidCallback onRetry`. Susunan `LayoutBuilder` → `SingleChildScrollView` → `Column` membuat pesan tetap dapat digeser bila ruang vertikal tidak mencukupi. Jarak luar 24 dan lebar `constraints.maxWidth - 48` membentuk ruang sisi, dengan `clamp` sebagai perlindungan dari angka negatif.

`ConstrainedBox` memberi minimum tinggi `constraints.maxHeight - 48`; seperti pada keadaan kosong, minimum tersebut memungkinkan area isi menggunakan ruang viewport sambil tetap dapat tumbuh. `Row`/`Expanded` membatasi lebar kolom pesan. Kode tidak memakai `Center` secara eksplisit untuk penempatan keseluruhan blok; jangan menambahkan klaim bahwa seluruh blok pasti berada tepat di pusat vertikal layar.

Ikon `Icons.cloud_off_outlined` ukuran 48 dan warna `white70` menjadi penanda visual, diikuti judul `Jadwal belum dapat dimuat`, penjelasan, lalu `FilledButton.icon` dengan ikon refresh dan label `Coba lagi`. Tulisan terpusat melalui `textAlign`. Tombol memakai warna peach/primary dan menjalankan `onRetry`, yang pada Home terhubung ke `_retry()` untuk mengganti sumber stream.

Ikon awan terputus tidak berarti semua error pasti akibat internet. Pemicu tampilan ini adalah `snapshot.hasError`; jenis error tidak diperiksa di widget ini.

### Membaca `JadwalLoading`

`Column` dengan dua `Spacer` membagi sisa tinggi di atas dan bawah baris indikator. Dalam `Row`, dua `Spacer` membagi sisa lebar di kiri dan kanan. Kombinasi ini menempatkan `CircularProgressIndicator` di tengah area loading yang mendapatkan constraint dari `Expanded` milik Home.

Indikator memakai warna peach dan `semanticsLabel: 'Memuat jadwal'` sebagai penjelasan aksesibilitas. Tidak ada properti `value`, jadi indikator tidak menyatakan persentase tertentu. Animasi berputarnya tidak membuktikan ada kemajuan numerik; ia menyampaikan bahwa data sedang ditunggu.

### Hubungan tanggung jawab

`JadwalLoadError` tidak melakukan retry sendiri; ia memanggil callback. `JadwalLoading` tidak memulai pembacaan data. Dua class ini hanya menampilkan keadaan yang diputuskan lapisan di atasnya.

<a id="file-lib-pages-home-widgets-hapus-jadwal-dialog-dart"></a>

## `lib/pages/home/widgets/hapus_jadwal_dialog.dart`

[Buka source dialog hapus](../../lib/pages/home/widgets/hapus_jadwal_dialog.dart).

### Peran dan class

`HapusJadwalDialog` adalah `StatelessWidget` yang menerima `namaMataKuliah` untuk kalimat konfirmasi. Tidak diperlukan state lokal karena kedua tombol langsung menutup route dialog dengan hasil keputusan.

### Kode lengkap

<!-- SUMBER:lib/pages/home/widgets/hapus_jadwal_dialog.dart SHA256=da5fdc24bd5eb0a2658c72b386e9072d9658ed33b5cb170b988bb921e76147d2 -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class HapusJadwalDialog extends StatelessWidget {
  const HapusJadwalDialog({super.key, required this.namaMataKuliah});
  final String namaMataKuliah;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.primary,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
      title: const Text('Hapus Jadwal'),
      content: Text('Hapus jadwal $namaMataKuliah?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('Batal', style: TextStyle(color: Colors.white)),
        ),

        FilledButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.peach,
            foregroundColor: AppColors.primary,
          ),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}
```

### Membaca dialog dan hasilnya

`AlertDialog` menyediakan slot standar `title`, `content`, dan `actions`. `backgroundColor` menggunakan warna primary. `titleTextStyle` mengatur judul putih ukuran 22 dengan `w700`; `contentTextStyle` mengatur isi putih ukuran 16. Isi `Text('Hapus jadwal $namaMataKuliah?')` memasukkan nama yang dikirim parent sehingga pengguna mengetahui objek yang akan dihapus.

`TextButton` Batal menjalankan `Navigator.pop(context, false)`. `FilledButton` Hapus menjalankan `Navigator.pop(context, true)`, dengan latar peach serta foreground primary. `Navigator.pop` di sini menutup route dialog yang sedang aktif dan mengembalikan nilai kepada `showDialog<bool>` yang menunggunya.

Dialog ditampilkan oleh Home menggunakan `showDialog<bool>` tanpa penggantian `barrierDismissible`. Karena dialog dapat ditutup tanpa hasil boolean melalui mekanisme dismiss yang berlaku, `_konfirmasiHapus()` mengubah hasil `null` menjadi `false`. Aksi hapus hanya dilanjutkan ketika hasilnya benar-benar `true`.

### Batas tanggung jawab

Tidak ada repository atau SQL pada file ini. Menekan `Hapus` mengembalikan persetujuan; `_hapusJadwal()` di Home yang menjalankan penghapusan dan menampilkan `SnackBar`. Memisahkan keputusan dari operasi data membuat isi dialog dapat dipahami tanpa mengetahui cara penyimpanan jadwal.

## Membaca ulang alur Home sebagai latihan

Coba ikuti satu aksi tanpa mengubah kode: mulai dari `IconButton` edit pada `JadwalCardHeader`, lanjutkan ke callback yang diterima `KartuJadwal`, closure `onEdit(data)` dalam `ListJadwal`, kemudian `_bukaEditJadwal(data)` pada `HomePage`. Perhatikan bahwa tombol paling kecil tidak membutuhkan akses database; data dan callback menghubungkan lapisan-lapisan tersebut.

Untuk layout, bandingkan tiga alat yang berbeda: `MediaQuery.sizeOf` membaca ukuran media, [`LayoutBuilder`](https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html) menerima constraint parent ketika layout berlangsung, dan `IntrinsicHeight` meminta layout berdasarkan kebutuhan tinggi intrinsik subtree. Ketiganya menjawab pertanyaan berbeda. Pada Home, `Expanded`, `Flexible`, `Spacer`, dan batas area scroll menghubungkan ukuran yang tersedia dengan kebutuhan isi.

Di 16 file Home ini tidak ada `InkWell`, `GestureDetector`, atau `Material` yang ditulis secara eksplisit sebagai widget tersendiri. Interaksi tekan ditulis melalui tombol Material seperti `TextButton`, `IconButton`, `FilledButton`, serta `PopupMenuButton`. Perbedaan istilah-istilah tersebut dijelaskan di [glosarium](05-glosarium.md); jangan menambahkan contoh penggunaannya ke daftar fakta file jika widget itu tidak ada pada source.
