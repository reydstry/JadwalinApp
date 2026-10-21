# 04 — Form tambah dan edit jadwal

Bab ini membahas seluruh 12 file Dart di `lib/pages/jadwal`. Baca [dasar Flutter dan Dart](00-dasar.md) terlebih dahulu jika istilah `Widget`, `build`, constructor, callback, atau `State` masih baru. Gunakan [glosarium](05-glosarium.md) ketika menemukan widget atau sintaks yang belum dikenal.

Halaman tambah dan edit memakai halaman yang sama, `KelolaJadwalPage`. Tanpa `jadwalAwal`, halaman menambah data; dengan `jadwalAwal`, halaman mengisi form dari jadwal yang dipilih untuk diedit. State dan proses penyimpanan berada di halaman induk. Sebagian besar file dalam folder `widgets` menerima nilai dan callback dari induk, lalu menggambar bagiannya.

| File | Tanggung jawab |
| --- | --- |
| `kelola_jadwal.dart` | Menyimpan state form, mengatur navigasi, memilih jam, memvalidasi, dan memanggil penyimpanan. |
| `jadwal_app_bar.dart` | Judul tambah/edit dan tombol kembali. |
| `jadwal_form_style.dart` | Tema lokal, ikon SVG, label field, dan judul bagian. |
| `jadwal_form_layout.dart` | Susunan satu/dua kolom, scroll, dan posisi tombol. |
| `mata_kuliah_form.dart` | Nama mata kuliah, dosen, dan SKS. |
| `waktu_kuliah_form.dart` | Hari, jam, dan ruangan. |
| `jam_kuliah_field.dart` | Tampilan satu pilihan jam yang ikut validasi `Form`. |
| `jadwal_time_picker_frame.dart` | Pembungkus dialog pemilih jam dengan format 24 jam dan scroll. |
| `pengingat_form.dart` | Toggle pengingat dan pilihan menit. |
| `simpan_jadwal_button.dart` | Tombol tambah/simpan serta indikator menyimpan. |
| `jadwal_form_footer.dart` | Area tombol tetap di bawah halaman. |
| `buang_perubahan_dialog.dart` | Konfirmasi meninggalkan form yang berubah. |

Urutan interaksi yang perlu diingat:

1. Home membuka halaman, membawa database dan jadwal awal bila sedang mengedit.
2. `initState` menyiapkan nilai form dan menyimpan salinan nilai awal.
3. Anak widget membaca nilai dari induk. Input teks mengubah controller; dropdown, toggle, dan pemilih jam mengirim callback.
4. Perubahan memanggil `setState`, sehingga Flutter membangun tampilan sesuai nilai terbaru.
5. Tombol simpan memvalidasi field, membuat `JadwalDraft`, memeriksa bentrok, lalu menyimpan melalui repository.
6. Halaman mengembalikan `true` setelah tersimpan, atau `false` ketika keluar tanpa menyimpan melalui jalur `_finish(false)`. Back sistem yang langsung diizinkan dapat mengembalikan `null` karena tidak memberi hasil eksplisit.

Kode lengkap di setiap bagian adalah kode proyek saat panduan disusun. Cuplikan sesudahnya menyorot bagian yang dijelaskan; cuplikan itu bukan pengganti file lengkap.

<a id="file-lib-pages-jadwal-kelola-jadwal-dart"></a>

## `lib/pages/jadwal/kelola_jadwal.dart`

[Buka sumber](../../lib/pages/jadwal/kelola_jadwal.dart).

File ini adalah pengatur utama form. Ia memakai `StatefulWidget` karena nilai isian, status menyimpan, pilihan jam, dan pengingat dapat berubah selama halaman terbuka. Class `KelolaJadwalPage` mendefinisikan masukan halaman; `_KelolaJadwalPageState` menyimpan nilai yang berubah dan menjalankan perilakunya.

### Kode lengkap

<!-- SUMBER:lib/pages/jadwal/kelola_jadwal.dart SHA256=58fd61de4fd9fa5d896453ae66d6d2ce306ad3199594c576ec00ac6ebff716b8 -->

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../repositories/jadwal_repository.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import 'widgets/jadwal_form_style.dart';
import 'widgets/mata_kuliah_form.dart';
import 'widgets/waktu_kuliah_form.dart';
import 'widgets/pengingat_form.dart';
import 'widgets/simpan_jadwal_button.dart';
import 'widgets/jadwal_form_footer.dart';
import 'widgets/jadwal_form_layout.dart';
import 'widgets/buang_perubahan_dialog.dart';
import 'widgets/jadwal_time_picker_frame.dart';
import 'widgets/jadwal_app_bar.dart';

class KelolaJadwalPage extends StatefulWidget {
  const KelolaJadwalPage({super.key, required this.database, this.jadwalAwal});
  final AppDatabase database;
  final JadwalDenganMataKuliah? jadwalAwal;

  @override
  State<KelolaJadwalPage> createState() => _KelolaJadwalPageState();
}

class _KelolaJadwalPageState extends State<KelolaJadwalPage> {
  final _formKey = GlobalKey<FormState>();
  // Keep field subtrees and their focus/validation state when columns reflow.
  final _infoKey = GlobalKey();
  final _timeKey = GlobalKey();
  final _reminderKey = GlobalKey();
  final _namaController = TextEditingController();
  final _dosenController = TextEditingController();
  final _sksController = TextEditingController();
  final _ruanganController = TextEditingController();

  int _hari = DateTime.monday;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;
  bool _pengingatAktif = false;
  int _menitSebelum = 15;
  bool _sedangMenyimpan = false;
  bool _submitted = false;
  bool _allowPop = false;
  bool _confirming = false;
  late final JadwalRepository _repository;
  late final Object _initialFormValue;

  bool get _modeEdit => widget.jadwalAwal != null;
  List<TextEditingController> get _controllers => [
    _namaController,
    _dosenController,
    _sksController,
    _ruanganController,
  ];
  Object get _formValue => (
    _namaController.text.trim(),
    _dosenController.text.trim(),
    _sksController.text.trim(),
    _ruanganController.text.trim(),
    _hari,
    _jamMulai,
    _jamSelesai,
    _pengingatAktif,
    _menitSebelum,
  );
  bool get _hasChanges => _formValue != _initialFormValue;

  @override
  void initState() {
    super.initState();
    _repository = JadwalRepository(database: widget.database);
    final data = widget.jadwalAwal;
    if (data != null) {
      final jadwal = data.jadwal;
      _namaController.text = data.mataKuliah.nama;
      _dosenController.text = data.mataKuliah.dosen ?? '';
      _sksController.text = data.mataKuliah.sks?.toString() ?? '';
      _ruanganController.text = jadwal.ruangan ?? '';
      _hari = jadwal.hari;
      _jamMulai = TimeOfDay(
        hour: jadwal.jamMulai ~/ 60,
        minute: jadwal.jamMulai % 60,
      );
      _jamSelesai = TimeOfDay(
        hour: jadwal.jamSelesai ~/ 60,
        minute: jadwal.jamSelesai % 60,
      );
      _pengingatAktif = jadwal.pengingatAktif;
      // Normalize legacy values to the supported five-minute steps.
      _menitSebelum = ((jadwal.menitSebelum / 5).round() * 5).clamp(5, 60);
    }
    _initialFormValue = _formValue;
    for (final controller in _controllers) {
      controller.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_onChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestClose() async {
    if (_sedangMenyimpan || _confirming || _allowPop) return;
    if (!_hasChanges) {
      _finish(false);
      return;
    }
    _confirming = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => const BuangPerubahanDialog(),
    );
    _confirming = false;
    if (mounted && discard == true) _finish(false);
  }

  void _finish(bool saved) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(saved);
    });
  }

  Future<void> _pickTime(bool start) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final value = await showTimePicker(
      context: context,
      initialTime: start
          ? (_jamMulai ?? const TimeOfDay(hour: 8, minute: 0))
          : (_jamSelesai ?? const TimeOfDay(hour: 10, minute: 0)),
      initialEntryMode: MediaQuery.sizeOf(context).height < 500
          ? TimePickerEntryMode.input
          : TimePickerEntryMode.dial,
      helpText: start ? 'Pilih jam mulai' : 'Pilih jam selesai',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) => JadwalTimePickerFrame(child: child!),
    );
    if (!mounted || value == null) return;
    setState(() {
      if (start) {
        _jamMulai = value;
      } else {
        _jamSelesai = value;
      }
    });
  }

  Future<void> _simpan() async {
    if (_sedangMenyimpan || _allowPop) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitted = true);
    final invalid = _formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && invalid.first.mounted) {
          Scrollable.ensureVisible(invalid.first.context, alignment: 0.15);
        }
      });
      return;
    }
    final draft = JadwalDraft(
      namaMataKuliah: _namaController.text.trim(),
      dosen: _dosenController.text.trim(),
      sks: int.parse(_sksController.text.trim()),
      hari: _hari,
      jamMulai: _jamMulai!.hour * 60 + _jamMulai!.minute,
      jamSelesai: _jamSelesai!.hour * 60 + _jamSelesai!.minute,
      ruangan: _ruanganController.text.trim(),
      pengingatAktif: _pengingatAktif,
      menitSebelum: _menitSebelum,
    );
    setState(() => _sedangMenyimpan = true);
    try {
      final bentrok = await _repository.hasConflict(
        draft,
        exceptScheduleId: widget.jadwalAwal?.jadwal.id,
      );
      if (!mounted) return;
      if (bentrok) {
        _showMessage(
          'Jadwal bentrok atau jeda antarkuliah kurang dari 1 menit. Pilih waktu lain.',
        );
        return;
      }
      if (_pengingatAktif &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
        final izin = await NotificationService.ensureReminderPermissions();
        if (!mounted) return;
        if (!izin) {
          _showMessage(
            'Aktifkan izin Notifikasi dan Alarm & pengingat untuk menggunakan pengingat.',
          );
          return;
        }
      }
      final jadwalId = await _repository.save(
        draft,
        jadwalAwal: widget.jadwalAwal,
      );
      if (!mounted) return;
      String? notificationWarning;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          await NotificationService.sinkronkanPengingatJadwal(
            notificationId: jadwalId,
            aktif: draft.pengingatAktif,
            namaMataKuliah: draft.namaMataKuliah,
            hari: draft.hari,
            jamMulai: draft.jamMulai,
            menitSebelum: draft.menitSebelum,
            ruangan: draft.ruangan,
          );
        } catch (_) {
          notificationWarning = 'Jadwal tersimpan, tetapi pengingat belum berhasil diperbarui. Periksa izin notifikasi.';
        }
      }
      if (!mounted) return;
      _showMessage(
        notificationWarning ??
            (_modeEdit
                ? 'Perubahan jadwal berhasil disimpan.'
                : 'Jadwal berhasil ditambahkan.'),
      );
      _finish(true);
    } catch (_) {
      _showMessage(
        'Jadwal belum berhasil disimpan. Data isian tetap tersedia, silakan coba lagi.',
      );
    } finally {
      if (mounted && !_allowPop) setState(() => _sedangMenyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = jadwalFormTheme(Theme.of(context));
    final pinSave =
        MediaQuery.sizeOf(context).height >= 600 &&
        MediaQuery.viewInsetsOf(context).bottom == 0 &&
        MediaQuery.textScalerOf(context).scale(20) <= 28;
    final saveButton = SimpanJadwalButton(
      isSaving: _sedangMenyimpan,
      isEditing: _modeEdit,
      onSave: _simpan,
    );
    return Theme(
      data: theme,
      child: PopScope<bool>(
        canPop: _allowPop || (!_hasChanges && !_sedangMenyimpan),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _requestClose();
        },
        child: Scaffold(
          backgroundColor: AppColors.primary,
          appBar: JadwalAppBar(
            isSaving: _sedangMenyimpan,
            isEditing: _modeEdit,
            onBack: _requestClose,
          ),
          bottomNavigationBar: pinSave
              ? JadwalFormFooter(button: saveButton)
              : null,
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 760 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 22;
                final info = JadwalSection(
                  key: _infoKey,
                  title: 'Informasi Kuliah',
                  child: MataKuliahForm(
                    namaController: _namaController,
                    dosenController: _dosenController,
                    sksController: _sksController,
                    enabled: !_sedangMenyimpan,
                  ),
                );
                final time = JadwalSection(
                  key: _timeKey,
                  title: 'Waktu & Lokasi',
                  child: WaktuKuliahForm(
                    stackTimes:
                        (!wide && constraints.maxWidth - 38 < 300) ||
                        MediaQuery.textScalerOf(context).scale(16) > 22,
                    hari: _hari,
                    onHariChanged: (value) => setState(() => _hari = value),
                    jamMulai: _jamMulai,
                    jamSelesai: _jamSelesai,
                    onPilihJamMulai: () => _pickTime(true),
                    onPilihJamSelesai: () => _pickTime(false),
                    ruanganController: _ruanganController,
                    enabled: !_sedangMenyimpan,
                  ),
                );
                final reminder = PengingatForm(
                  key: _reminderKey,
                  pengingatAktif: _pengingatAktif,
                  menitSebelum: _menitSebelum,
                  onPengingatChanged: (value) =>
                      setState(() => _pengingatAktif = value),
                  onMenitChanged: (value) =>
                      setState(() => _menitSebelum = value),
                  enabled: !_sedangMenyimpan,
                );
                return JadwalFormLayout(
                  constraints: constraints,
                  wide: wide,
                  pinSave: pinSave,
                  submitted: _submitted,
                  formKey: _formKey,
                  info: info,
                  time: time,
                  reminder: reminder,
                  saveButton: saveButton,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

### Masukan halaman dan pembagian tanggung jawab

```dart
const KelolaJadwalPage({super.key, required this.database, this.jadwalAwal});
final AppDatabase database;
final JadwalDenganMataKuliah? jadwalAwal;
```

`database` wajib diberikan agar halaman memakai database aplikasi yang sama. `jadwalAwal` boleh `null`, ditandai `?`. Getter `_modeEdit` membaca apakah nilai itu ada. Home membuka tambah tanpa `jadwalAwal`, dan membuka edit dengan data jadwal terpilih.

Import `material.dart` menyediakan widget Material. `foundation.dart` dipakai untuk pemeriksaan platform (`kIsWeb`, `defaultTargetPlatform`, `TargetPlatform.android`). Import repository, database, dan notification service menghubungkan UI ke penyimpanan dan pengingat; file ini bukan tempat menggambar seluruh detail field.

### State, controller, dan key

| Anggota state | Kegunaan nyata |
| --- | --- |
| `_formKey = GlobalKey<FormState>()` | Memanggil validasi seluruh field dari tombol simpan. |
| `_infoKey`, `_timeKey`, `_reminderKey` | Identitas bagian form ketika susunan berpindah antara satu dan dua kolom. Komentar kode menjelaskan tujuannya mempertahankan subtree, fokus, dan state validasi saat tata letak berubah. |
| Empat `TextEditingController` | Menyimpan dan membaca teks nama, dosen, SKS, serta ruangan. |
| `_hari` | Hari terpilih; nilai awal `DateTime.monday`. |
| `_jamMulai`, `_jamSelesai` | `TimeOfDay?`; awalnya `null` agar pengguna perlu memilih jam. |
| `_pengingatAktif`, `_menitSebelum` | Awalnya `false` dan `15`. |
| `_sedangMenyimpan` | Mengunci input dan menampilkan status menyimpan selama proses asinkron. |
| `_submitted` | Menandai bahwa pengguna sudah mencoba menyimpan agar validasi otomatis mulai aktif. |
| `_allowPop` | Mengizinkan halaman ditutup setelah keputusan keluar/simpan sudah dibuat. |
| `_confirming` | Mencegah beberapa dialog buang perubahan dibuka bersamaan. |
| `_repository` | Objek `JadwalRepository` untuk cek bentrok dan penyimpanan. |
| `_initialFormValue` | Nilai form awal untuk mendeteksi perubahan belum tersimpan. |

Awalan `_` membuat identifier bersifat privat pada library Dart. `late final` berarti nilainya ditetapkan kemudian, sebelum dibaca, dan hanya sekali. Di sini keduanya diisi oleh `initState`.

### Mendeteksi perubahan melalui record

```dart
Object get _formValue => (
  _namaController.text.trim(),
  _dosenController.text.trim(),
  _sksController.text.trim(),
  _ruanganController.text.trim(),
  _hari,
  _jamMulai,
  _jamSelesai,
  _pengingatAktif,
  _menitSebelum,
);
bool get _hasChanges => _formValue != _initialFormValue;
```

Tanda kurung dengan beberapa nilai dan koma membentuk **record Dart**, yaitu kumpulan nilai yang dapat dibandingkan menurut isinya. `_formValue` dihitung ulang ketika dibaca; ia bukan salinan yang terus diperbarui secara manual. `_initialFormValue` menyimpan record saat awal halaman.

Jika pengguna mengubah nama lalu mengembalikannya persis seperti semula, `_hasChanges` menjadi `false`. `trim()` menghapus spasi awal/akhir, sehingga menambah spasi di ujung nama saja tidak dianggap perubahan. SKS masih dibandingkan sebagai teks pada tahap ini: `3` dan `03` dianggap berbeda walau nanti sama-sama dapat diubah menjadi angka `3`.

### `initState`, listener, dan `dispose`

`initState` membuat repository dari database masukan. Pada mode edit, controller diisi dari data lama, termasuk `?? ''` untuk nilai nullable. Jam database berupa jumlah menit diubah ke `TimeOfDay`: `~/ 60` mengambil jam dengan pembagian bulat dan `% 60` mengambil sisa menit. Contoh `510` menit menjadi `08:30`.

```dart
_menitSebelum = ((jadwal.menitSebelum / 5).round() * 5).clamp(5, 60);
```

Baris ini menormalkan nilai pengingat lama ke kelipatan lima dalam rentang 5–60. Misalnya `17` menjadi `15`, dan nilai di atas `60` dibatasi menjadi `60`. Baru sesudah pengisian itu `_initialFormValue` disimpan.

Semua controller dipasangi listener `_onChanged`. Listener memanggil `setState(() {})`: nilai teksnya sudah berubah di controller, sehingga callback kosong cukup untuk meminta pembangunan ulang UI yang bergantung pada `_hasChanges`.

`dispose` menghapus listener, lalu memanggil `controller.dispose()` untuk masing-masing controller. Halaman yang membuat controller bertanggung jawab melepasnya. Widget anak hanya menerima controller, sehingga tidak melepas controller milik induk.

### Pesan dan keluar dari halaman

`_showMessage` memeriksa `mounted` sebelum memakai `context`, menyembunyikan snackbar sebelumnya, lalu menampilkan `SnackBar` baru melalui `ScaffoldMessenger`. Operator cascade `..` menjalankan beberapa pemanggilan pada objek yang sama.

`_requestClose` keluar lebih awal saat sedang menyimpan, sudah mengonfirmasi, atau sudah mengizinkan pop. Jika tidak ada perubahan, ia langsung memanggil `_finish(false)`. Bila form berubah, `showDialog<bool>` membuka `BuangPerubahanDialog`; hanya hasil `true` yang membuang perubahan dan menutup halaman.

```dart
void _finish(bool saved) {
  setState(() => _allowPop = true);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) Navigator.of(context).pop(saved);
  });
}
```

`_allowPop` mengubah izin keluar pada `PopScope`. Callback setelah frame memberi kesempatan Flutter menerapkan nilai itu sebelum `Navigator.pop` dijalankan. `saved` menjadi hasil route untuk pemanggil halaman.

### Memilih jam

`_pickTime(true)` memilih jam mulai; `_pickTime(false)` memilih jam selesai. `FocusManager.instance.primaryFocus?.unfocus()` melepas fokus input, sehingga keyboard teks dapat ditutup. `showTimePicker` memakai jam yang sudah dipilih, atau bawaan `08:00`/`10:00` bila belum ada.

Tinggi view di bawah `500` memilih `TimePickerEntryMode.input`; view lebih tinggi memakai `dial`. Jadi keputusan ini berdasarkan tinggi view, bukan tinggi intrinsik field. `builder` membungkus dialog dengan `JadwalTimePickerFrame` untuk format 24 jam dan penyesuaian ruang. Bila pengguna membatalkan (`value == null`) atau halaman sudah dilepas (`!mounted`), tidak ada perubahan. Hasil pilihan baru disalin ke state dengan `setState`.

### Menyimpan dan memvalidasi

```dart
setState(() => _submitted = true);
final invalid = _formKey.currentState!.validateGranularly();
if (invalid.isNotEmpty) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && invalid.first.mounted) {
      Scrollable.ensureVisible(invalid.first.context, alignment: 0.15);
    }
  });
  return;
}
```

`validateGranularly()` menjalankan validator pada field di `Form` dan mengembalikan kumpulan (`Set`) field yang tidak valid. [Dokumentasi Flutter menjelaskan hasil dan pembangunan ulang form ini](https://api.flutter.dev/flutter/widgets/FormState/validateGranularly.html). Kode memilih elemen pertama kumpulan tersebut dan menggulirkannya agar terlihat, dengan posisi sekitar 15% dari bagian atas area gulir. Pengguliran menunggu frame karena pesan error dapat mengubah ukuran field. Ini bukan pengguliran berdasarkan nama field yang ditulis manual.

Jika validasi lolos, `JadwalDraft` dibuat. Teks dirapikan dengan `trim`, SKS diubah dengan `int.parse`, dan jam diubah ke jumlah menit melalui `hour * 60 + minute`. Pemakaian `!` pada jam dan `int.parse` mengandalkan validator yang sudah memastikan nilai ada dan SKS berupa bilangan bulat positif.

Alur `try` setelah `_sedangMenyimpan = true`:

1. `_repository.hasConflict` meminta pemeriksaan bentrok/jeda. Saat edit, `exceptScheduleId` mengecualikan jadwal yang sedang diedit agar tidak bentrok dengan dirinya sendiri. UI menampilkan pesan bentrok atau jeda kurang dari satu menit jika hasilnya `true`. `JadwalRepository.hasConflict` meneruskan pemeriksaan ke `AppDatabase.adaBentrokJadwal`; algoritmanya berada di `lib/database/database.dart`.
2. Jika pengingat aktif pada Android asli, `ensureReminderPermissions` meminta/memeriksa izin. Bila izin tidak tersedia, penyimpanan dihentikan dan pesan ditampilkan. Web melewati blok ini.
3. `_repository.save` menyimpan draft dan mengembalikan ID jadwal.
4. Pada Android asli, `sinkronkanPengingatJadwal` memperbarui pengingat sesuai data tersimpan. Pemanggilan juga terjadi saat pengingat nonaktif agar service menerima status `aktif: false`.
5. Jika pengingat gagal diperbarui setelah data tersimpan, kode menampilkan peringatan bahwa jadwal tersimpan, lalu tetap menutup halaman dengan hasil `true`.
6. Jika proses utama melempar exception, pesan gagal simpan muncul dan isian dipertahankan. `finally` membuka kembali status menyimpan jika halaman masih ada dan belum sedang ditutup.

`async`/`await` membuat kode menunggu operasi database/izin tanpa menahan seluruh UI. Pemeriksaan `mounted` sesudah `await` diperlukan karena pengguna dapat meninggalkan halaman atau lifecycle dapat berubah selama menunggu. `catch (_)` menangkap exception tanpa menggunakan objek errornya; teks error teknis tidak ditampilkan pada pengguna.

Bab ini menjelaskan panggilan UI ke service; tampilan pengingat atau eksekusi web tidak membuktikan notifikasi Android berjalan.

### Menyusun tampilan dan aturan responsif

| Widget/API | Peran di file ini |
| --- | --- |
| `Theme` + `jadwalFormTheme(Theme.of(context))` | Memberi tema khusus form pada subtree halaman. |
| `PopScope<bool>` | Mengatur back sistem dan membawa tipe hasil route `bool`. |
| `Scaffold` | Menempatkan app bar, isi, dan footer. |
| `JadwalAppBar` | Menerima status edit/simpan serta callback kembali. |
| `SafeArea(top: false)` | Melindungi area isi dari bagian layar yang harus dihindari; area atas sudah ditangani app bar. |
| `LayoutBuilder` | Memberi batas ruang **isi halaman** dari parent, termasuk pengaruh app bar/footer. |
| `MediaQuery.sizeOf` | Membaca ukuran view untuk keputusan berdasarkan tinggi view. |
| `MediaQuery.viewInsetsOf(...).bottom` | Mengetahui ruang tertutup sistem di bawah, umumnya keyboard. |
| `MediaQuery.textScalerOf(...).scale(...)` | Memperhitungkan pembesaran teks dari pengaturan aksesibilitas. |
| `JadwalSection` | Menambahkan judul pada kelompok informasi dan waktu. |
| `MataKuliahForm`, `WaktuKuliahForm`, `PengingatForm` | Anak widget untuk field; nilai dan callback dikendalikan halaman ini. |
| `JadwalFormLayout` | Menerima seluruh bagian untuk ditata tanpa mengurus nilainya. |

`pinSave` bernilai `true` bila tinggi view minimal `600`, inset bawah `0`, dan hasil skala teks ukuran `20` tidak lebih dari `28`. Tombol lalu dipasang pada `bottomNavigationBar`. Bila kondisi itu tidak terpenuhi, tombol ikut isi yang dapat digulir. Dari struktur kode, tujuannya menjaga tombol tetap dapat diakses ketika ruang vertikal/keyboard/pembesaran teks mengubah kebutuhan ruang.

`wide` bernilai `true` bila lebar area isi minimal `760` dan ukuran teks hasil skala `16` tidak lebih dari `22`. Informasi dan waktu lalu tampil berdampingan. Pilihan jam ditumpuk (`stackTimes`) pada isi sempit dengan lebar efektif kurang dari `300`, atau ketika ukuran teks hasil skala `16` melebihi `22`.

`PopScope.canPop` mengizinkan keluar saat `_allowPop` aktif, atau ketika tidak ada perubahan dan tidak sedang menyimpan. `onPopInvokedWithResult` memanggil `_requestClose` hanya jika pop belum terjadi (`didPop == false`). Tombol kembali app bar memakai `_requestClose` yang sama, sehingga aturan konfirmasi berbagi satu jalur.

<a id="file-lib-pages-jadwal-widgets-jadwal-app-bar-dart"></a>

## `lib/pages/jadwal/widgets/jadwal_app_bar.dart`

[Buka sumber](../../lib/pages/jadwal/widgets/jadwal_app_bar.dart).

`JadwalAppBar` memisahkan bagian atas halaman dari logika form. Ia menerima `isSaving`, `isEditing`, dan `onBack`; widget ini tidak menyimpan atau membuang data sendiri.

### Kode lengkap

<!-- SUMBER:lib/pages/jadwal/widgets/jadwal_app_bar.dart SHA256=3d87d0c2d2f591ed2e38fc635c03247ba92229aaf0cd4cab22cba0f6a4b0ec6c -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'jadwal_form_style.dart';

class JadwalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const JadwalAppBar({
    super.key,
    required this.isSaving,
    required this.isEditing,
    required this.onBack,
  });
  final bool isSaving;
  final bool isEditing;
  final VoidCallback onBack;
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        tooltip: 'Kembali',
        onPressed: isSaving ? null : onBack,
        icon: const JadwalFormIcon('back', size: 28),
      ),
      title: Text(
        isEditing ? 'Edit Jadwal' : 'Tambah Jadwal',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      toolbarHeight: 64,
    );
  }
}
```

### Bedah pemakaian

```dart
class JadwalAppBar extends StatelessWidget implements PreferredSizeWidget
```

`StatelessWidget` cukup karena seluruh keadaan diberikan induk. `PreferredSizeWidget` menyediakan kontrak ukuran yang dibutuhkan `Scaffold.appBar`. Getter `preferredSize => Size.fromHeight(64)` menyatakan tinggi pilihan; `toolbarHeight: 64` juga mengatur tinggi toolbar `AppBar`.

`AppBar` memakai latar `AppColors.primary` dan foreground putih. `leading` berisi `IconButton` dengan tooltip `Kembali` dan ikon SVG `JadwalFormIcon('back', size: 28)`. `onPressed: isSaving ? null : onBack` menonaktifkan tombol selama penyimpanan. Callback diteruskan ke induk agar konfirmasi perubahan tetap memakai aturan halaman.

Judul `Text` dipilih dengan ternary: `Edit Jadwal` jika `isEditing`, selain itu `Tambah Jadwal`. `TextStyle` menetapkan font Inter, ukuran 24, dan ketebalan `w600`. Perubahan judul dan tombol terjadi ketika induk membangun widget lagi dengan nilai baru; tidak perlu state lokal tambahan.

<a id="file-lib-pages-jadwal-widgets-jadwal-form-style-dart"></a>

## `lib/pages/jadwal/widgets/jadwal_form_style.dart`

[Buka sumber](../../lib/pages/jadwal/widgets/jadwal_form_style.dart).

File ini menyatukan gaya dan pembungkus yang dipakai berulang. Terdapat satu fungsi (`jadwalFormTheme`) serta tiga class widget: `JadwalFormIcon`, `JadwalField`, dan `JadwalSection`.

### Kode lengkap

<!-- SUMBER:lib/pages/jadwal/widgets/jadwal_form_style.dart SHA256=4a05c2b0d2728f42baf72058a2327f42bfe794969fbf5ff9c7e7b1c5d72042b3 -->

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';

ThemeData jadwalFormTheme(ThemeData base) => base.copyWith(
  scaffoldBackgroundColor: AppColors.primary,
  textTheme: base.textTheme.apply(fontFamily: 'Inter'),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 16),
    errorStyle: const TextStyle(color: AppColors.peach, fontSize: 12),
    errorMaxLines: 3,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0xFFACB5BB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.peach, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.peach, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.peach, width: 2),
    ),
  ),
);

class JadwalFormIcon extends StatelessWidget {
  const JadwalFormIcon(this.name, {super.key, this.size = 20});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: SvgPicture.asset(
      'assets/icon/form_$name.svg',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
  );
}

class JadwalField extends StatelessWidget {
  const JadwalField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class JadwalSection extends StatelessWidget {
  const JadwalSection({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const JadwalFormIcon('section'),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      child,
    ],
  );
}
```

### `jadwalFormTheme`: tema lokal form

```dart
ThemeData jadwalFormTheme(ThemeData base) => base.copyWith(
  scaffoldBackgroundColor: AppColors.primary,
  textTheme: base.textTheme.apply(fontFamily: 'Inter'),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
```

`copyWith` menyalin tema dasar dengan beberapa pengaturan baru; bagian yang tidak diganti tetap berasal dari `base`. `textTheme.apply` menerapkan keluarga font pada gaya teks tema. Induk memasang hasil fungsi ini melalui `Theme`, sehingga pengaruhnya terbatas pada subtree form.

`InputDecorationTheme` membuat field putih (`filled`, `fillColor`), hint abu-abu ukuran 16, dan error peach ukuran 12 dengan maksimal tiga baris. `OutlineInputBorder` memberi garis tepi bersudut radius 9. `enabledBorder` memakai garis abu-abu; `focusedBorder`, `errorBorder`, dan `focusedErrorBorder` memakai peach selebar 2. Karena aturan diletakkan dalam tema, setiap field cukup mengisi hal khusus seperti hint dan ikon.

### `JadwalFormIcon`: ikon SVG dengan ukuran konsisten

```dart
SvgPicture.asset(
  'assets/icon/form_$name.svg',
  fit: BoxFit.contain,
  excludeFromSemantics: true,
)
```

`SvgPicture` berasal dari paket `flutter_svg`, digunakan untuk menggambar aset SVG. Interpolasi `$name` membentuk nama aset: `JadwalFormIcon('book')` memuat `assets/icon/form_book.svg`. `SizedBox.square(dimension: size)` memberi kotak persegi; ukuran bawaan 20. `BoxFit.contain` menjaga gambar tetap muat dengan rasio proporsional.

`excludeFromSemantics: true` mengeluarkan gambar itu dari informasi pembaca layar. Pada pemakaian file-file form, identitas kontrol disampaikan oleh teks/label/tooltip di sekitarnya, sehingga ikon berfungsi sebagai pendamping visual. Nama aset adalah string, jadi kecocokannya dengan file aset tetap diperlukan.

### `JadwalField`: label dan input

Widget ini menerima `label` dan `child`. `Column` menumpuk satu baris label, jarak 8, lalu input. Label diletakkan di dalam `Row > Expanded > Text` berwarna putih ukuran 16. `Expanded` membuat teks memakai ruang horizontal yang tersedia dan dapat membungkus bila dibutuhkan. `child` dapat berupa `TextFormField`, dropdown, atau `FormField` waktu, sehingga tampilan label seragam tanpa menyamakan perilaku semua input.

### `JadwalSection`: judul kelompok

Widget ini menerima `title` dan `child`. Judul memakai `Row`: ikon `section`, jarak 12, lalu `Expanded(Text(...))`. Teks putih ukuran 20 dengan `w800`; isi diletakkan setelah jarak 20. Pemisahan ini memberi kelompok informasi dan waktu gaya yang sama tanpa mengulang markup judul.

<a id="file-lib-pages-jadwal-widgets-jadwal-form-layout-dart"></a>

## `lib/pages/jadwal/widgets/jadwal_form_layout.dart`

[Buka sumber](../../lib/pages/jadwal/widgets/jadwal_form_layout.dart).

`JadwalFormLayout` hanya menata bagian form dan tombol. Nilai input tidak dimiliki file ini. Constructor menerima batas ruang (`constraints`), keputusan tampilan dari induk (`wide`, `pinSave`), status percobaan simpan (`submitted`), `formKey`, serta empat widget isi: `info`, `time`, `reminder`, `saveButton`.

### Kode lengkap

<!-- SUMBER:lib/pages/jadwal/widgets/jadwal_form_layout.dart SHA256=31d8e7d40dc628fc8400caca18cf5ed16a7909623ebd24b0456917ed34fcf182 -->

```dart
import 'package:flutter/material.dart';

/// Menata bagian form dan tombol simpan tanpa mengelola nilai inputnya.
class JadwalFormLayout extends StatelessWidget {
  const JadwalFormLayout({
    super.key,
    required this.constraints,
    required this.wide,
    required this.pinSave,
    required this.submitted,
    required this.formKey,
    required this.info,
    required this.time,
    required this.reminder,
    required this.saveButton,
  });
  final BoxConstraints constraints;
  final bool wide;
  final bool pinSave;
  final bool submitted;
  final GlobalKey<FormState> formKey;
  final Widget info;
  final Widget time;
  final Widget reminder;
  final Widget saveButton;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        SizedBox(
          width: constraints.maxWidth.clamp(0.0, 1040.0),
          height: constraints.maxHeight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Form(
              key: formKey,
              autovalidateMode: submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20),
                    Row(
                      children: [
                        const Spacer(),
                        SizedBox(
                          width:
                              (constraints.maxWidth.clamp(0.0, 1040.0) -
                                      2 * (wide ? 32 : 19))
                                  .clamp(0.0, double.infinity),
                          child: Column(
                            children: [
                              if (wide)
                                IntrinsicHeight(
                                  child: Row(
                                    key: const Key('schedule_two_columns'),

                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [info, const Spacer()],
                                        ),
                                      ),
                                      const SizedBox(width: 40),
                                      Expanded(
                                        child: Column(
                                          children: [time, const Spacer()],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else ...[
                                info,
                                const SizedBox(height: 26),
                                time,
                              ],
                              const SizedBox(height: 20),
                              reminder,
                              const SizedBox(height: 24),
                              if (!pinSave)
                                Row(
                                  children: [
                                    const Spacer(),
                                    SizedBox(
                                      width:
                                          (constraints.maxWidth.clamp(
                                                    0.0,
                                                    1040.0,
                                                  ) -
                                                  (wide ? 64 : 38))
                                              .clamp(0.0, 480.0),
                                      child: saveButton,
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
```

### Membatasi lebar dan memberi ruang gulir

`Row` terluar menempatkan `Spacer` di kedua sisi konten agar konten berada di tengah. `SizedBox` membatasi lebar ke `constraints.maxWidth.clamp(0.0, 1040.0)` dan tinggi ke `constraints.maxHeight`. Nilai constraints ini diterima dari `LayoutBuilder` di induk: [builder menerima batas ukuran dari parent ketika layout berlangsung](https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html). `clamp` menahan nilai di antara batas bawah dan atas. `ConstrainedBox(maxWidth: 1040)` menegaskan batas lebar maksimum yang sama.

`Form(key: formKey)` mengelompokkan field agar dapat divalidasi dari halaman induk. Sebelum percobaan simpan, `AutovalidateMode.disabled` menahan validasi otomatis; sesudahnya `AutovalidateMode.onUserInteraction` menjalankan validasi otomatis sebagai respons interaksi field. Validasi eksplisit tetap dijalankan oleh tombol simpan.

`SingleChildScrollView` membuat seluruh isi dapat digulir jika melebihi tinggi yang tersedia. `keyboardDismissBehavior: onDrag` meminta keyboard ditutup ketika pengguna menyeret area gulir. `Column(mainAxisSize: MainAxisSize.min)` menyusun konten dengan tinggi mengikuti kebutuhan anak. `SizedBox` dengan `height`/`width` memberi jarak konkret.

Lebar isi dikurangi dua sisi margin: masing-masing 32 pada mode lebar atau 19 pada mode sempit. `.clamp(0.0, double.infinity)` mencegah hasil perhitungan lebar menjadi negatif.

### Dua kolom dan fungsi `IntrinsicHeight`

```dart
if (wide)
  IntrinsicHeight(
    child: Row(
      key: const Key('schedule_two_columns'),
      children: [
        Expanded(child: Column(children: [info, const Spacer()])),
        const SizedBox(width: 40),
        Expanded(child: Column(children: [time, const Spacer()])),
      ],
    ),
  )
```

`Expanded` membagi ruang horizontal tersisa sama besar ke dua kolom, setelah jarak tengah 40. `IntrinsicHeight` menentukan tinggi berdasarkan kebutuhan intrinsik anak di bawah batas layout yang berlaku. Di sini ia memberi tinggi terhingga yang mengikuti kebutuhan baris, sehingga `Spacer` di bawah masing-masing bagian dapat mengisi sisa tinggi dan menjaga isi tetap di bagian atas.

**`IntrinsicHeight` tidak mengukur tinggi layar.** Ukuran view dibaca induk lewat `MediaQuery`; ruang yang diberikan parent dibaca lewat `LayoutBuilder`. `IntrinsicHeight` memerlukan perhitungan layout tambahan, sehingga pemakaiannya pada dua kolom ini memiliki biaya dibanding layout biasa. Perilaku terhadap constraints serta biaya tambahan ini dijelaskan pada [dokumentasi `IntrinsicHeight`](https://api.flutter.dev/flutter/widgets/IntrinsicHeight-class.html).

Saat `wide` tidak aktif, `else ...[...]` memasukkan beberapa anak sekaligus ke daftar `children`: informasi, jarak 26, kemudian waktu. Ini adalah collection spread Dart, bukan widget bernama `else` atau `...`.

### Pengingat dan tombol dalam scroll

Pengingat ditempatkan setelah bagian informasi/waktu dengan jarak 20. Jika `pinSave` bernilai `false`, tombol ditampilkan dalam isi gulir setelah jarak 24; jika `true`, tombol sudah ditangani footer oleh induk. Lebar tombol dalam scroll dibatasi maksimal 480 dan dipusatkan dengan dua `Spacer`. Dengan demikian satu keputusan `pinSave` menentukan satu lokasi tombol pada setiap pembangunan UI.

<a id="file-lib-pages-jadwal-widgets-mata-kuliah-form-dart"></a>

## `lib/pages/jadwal/widgets/mata_kuliah_form.dart`

[Buka sumber](../../lib/pages/jadwal/widgets/mata_kuliah_form.dart).

`MataKuliahForm` menampilkan tiga input teks. Ia menerima controller nama, dosen, SKS, serta `enabled` yang bawaan nilainya `true`. Karena controller dimiliki halaman induk, file ini tidak memerlukan `StatefulWidget` atau `dispose` sendiri.

### Kode lengkap

<!-- SUMBER:lib/pages/jadwal/widgets/mata_kuliah_form.dart SHA256=7c0bb7f8b5a99447c77ad3d02372e109522f03181c23d554c117a9185899341f -->

```dart
import 'package:flutter/material.dart';

import 'jadwal_form_style.dart';

class MataKuliahForm extends StatelessWidget {
  const MataKuliahForm({
    super.key,
    required this.namaController,
    required this.dosenController,
    required this.sksController,
    this.enabled = true,
  });
  final TextEditingController namaController;
  final TextEditingController dosenController;
  final TextEditingController sksController;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      JadwalField(
        label: 'Mata Kuliah',
        child: TextFormField(
          key: const Key('schedule_name'),
          controller: namaController,
          enabled: enabled,
          decoration: const InputDecoration(
            hintText: 'Nama Mata Kuliah',
            prefixIcon: SizedBox.square(
              dimension: 48,
              child: Column(
                children: [
                  Spacer(),
                  Row(children: [Spacer(), JadwalFormIcon('book'), Spacer()]),
                  Spacer(),
                ],
              ),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama mata kuliah wajib diisi';
            }
            if (value.trim().length > 100) {
              return 'Nama mata kuliah maksimal 100 karakter';
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 14),
      JadwalField(
        label: 'Nama Dosen',
        child: TextFormField(
          key: const Key('schedule_lecturer'),
          controller: dosenController,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Nama Dosen Pengampu',
            prefixIcon: SizedBox.square(
              dimension: 48,
              child: Column(
                children: [
                  Spacer(),
                  Row(
                    children: [Spacer(), JadwalFormIcon('lecturer'), Spacer()],
                  ),
                  Spacer(),
                ],
              ),
            ),
          ),
          textInputAction: TextInputAction.next,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Nama dosen wajib diisi'
              : null,
        ),
      ),
      const SizedBox(height: 14),
      JadwalField(
        label: 'Jumlah SKS',
        child: TextFormField(
          key: const Key('schedule_credits'),
          controller: sksController,
          enabled: enabled,
          decoration: const InputDecoration(
            hintText: 'Contoh: 3',
            prefixIcon: SizedBox.square(
              dimension: 48,
              child: Column(
                children: [
                  Spacer(),
                  Row(
                    children: [Spacer(), JadwalFormIcon('credits'), Spacer()],
                  ),
                  Spacer(),
                ],
              ),
            ),
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Jumlah SKS wajib diisi';
            }
            final sks = int.tryParse(value.trim());
            return sks == null || sks <= 0
                ? 'SKS harus berupa bilangan bulat positif'
                : null;
          },
        ),
      ),
    ],
  );
}
```

### Pola yang diulang pada setiap field

`Column` menyusun tiga `JadwalField` vertikal dengan `SizedBox(height: 14)`. Di dalamnya, `TextFormField` menghubungkan input teks dengan `Form` dan validator. `controller` menghubungkan teks field ke state induk; `enabled` menonaktifkan input saat halaman menyimpan.

`InputDecoration` berisi `hintText` dan `prefixIcon`. Ikon ditempatkan dalam kotak 48 × 48; `Column` dan `Row` dengan pasangan `Spacer` memusatkan ikon 20 × 20 di dalam kotak itu. Warna latar, border, dan gaya error diwarisi dari `jadwalFormTheme`.

`Key('schedule_name')`, `schedule_lecturer`, dan `schedule_credits` memberi identifier pada widget. Kode key itu tidak menyimpan teks atau menjalankan validasi; ia dapat membantu Flutter membedakan widget dan memudahkan pencarian widget oleh pengujian.

| Field | Pengaturan dan validasi |
| --- | --- |
| Mata kuliah | `TextCapitalization.words`, aksi keyboard `next`, wajib diisi setelah `trim`, maksimal 100 karakter setelah `trim`. Ikon `book`. |
| Dosen | Kapitalisasi kata, aksi `next`, wajib diisi setelah `trim`. Ikon `lecturer`. Tidak ada batas panjang eksplisit di validator file ini. |
| SKS | Keyboard angka (`TextInputType.number`), aksi `next`, wajib diisi dan harus bilangan bulat positif melalui `int.tryParse`. Ikon `credits`. Tidak ada batas maksimum SKS eksplisit di validator ini. |

```dart
final sks = int.tryParse(value.trim());
return sks == null || sks <= 0
    ? 'SKS harus berupa bilangan bulat positif'
    : null;
```

`tryParse` mengembalikan `null` jika teks tidak dapat dibaca sebagai integer. `||` berarti salah satu kondisi cukup untuk menolak nilai: gagal parse, nol, atau negatif. `validator` mengembalikan teks ketika tidak valid dan `null` ketika valid.

Keyboard angka membantu memasukkan angka tetapi bukan jaminan validasi; paste atau platform tertentu masih dapat memberi teks lain. Karena itu pengecekan `tryParse` tetap diperlukan. `textCapitalization` memberi petunjuk kapitalisasi kepada keyboard; ia bukan proses yang pasti mengubah seluruh teks controller menjadi kapital yang diminta.

<a id="file-lib-pages-jadwal-widgets-waktu-kuliah-form-dart"></a>

## `lib/pages/jadwal/widgets/waktu_kuliah_form.dart`

[Buka sumber](../../lib/pages/jadwal/widgets/waktu_kuliah_form.dart).

`WaktuKuliahForm` menerima hari, dua waktu nullable, controller ruangan, callback perubahan/pemilihan, status `enabled`, dan pilihan layout `stackTimes`. Ia menggambar bagian waktu/lokasi tanpa membuka dialog waktu sendiri; pembukaan dialog diserahkan ke induk melalui callback.

### Kode lengkap

<!-- SUMBER:lib/pages/jadwal/widgets/waktu_kuliah_form.dart SHA256=ddb1f019c68805fa90a4a2f7dacd53d3b21ca7a6ababda9fa35c4ff86d5d9936 -->

```dart
import 'package:flutter/material.dart';

import '../../../utils/day_helper.dart';
import 'jadwal_form_style.dart';
import 'jam_kuliah_field.dart';

class WaktuKuliahForm extends StatelessWidget {
  const WaktuKuliahForm({
    super.key,
    required this.hari,
    required this.onHariChanged,
    required this.jamMulai,
    required this.jamSelesai,
    required this.onPilihJamMulai,
    required this.onPilihJamSelesai,
    required this.ruanganController,
    required this.stackTimes,
    this.enabled = true,
  });
  final int hari;
  final ValueChanged<int> onHariChanged;
  final TimeOfDay? jamMulai;
  final TimeOfDay? jamSelesai;
  final VoidCallback onPilihJamMulai;
  final VoidCallback onPilihJamSelesai;
  final TextEditingController ruanganController;
  final bool enabled;
  final bool stackTimes;

  @override
  Widget build(BuildContext context) {
    final start = JamKuliahField(
      label: 'Jam Mulai',
      time: jamMulai,
      onTap: enabled ? onPilihJamMulai : null,
    );
    final end = JamKuliahField(
      label: 'Jam Selesai',
      time: jamSelesai,
      onTap: enabled ? onPilihJamSelesai : null,
      validator: (value) {
        if (value == null) return 'Jam selesai wajib dipilih';
        if (jamMulai != null &&
            value.hour * 60 + value.minute <=
                jamMulai!.hour * 60 + jamMulai!.minute) {
          return 'Harus setelah jam mulai';
        }
        return null;
      },
    );
    return Column(
      children: [
        JadwalField(
          label: 'Hari Kuliah',
          child: DropdownButtonFormField<int>(
            key: const Key('schedule_day'),
            initialValue: hari,
            isExpanded: true,
            dropdownColor: Colors.white,
            decoration: const InputDecoration(),
            items: DayHelper.dayNames.entries
                .map(
                  (day) =>
                      DropdownMenuItem(value: day.key, child: Text(day.value)),
                )
                .toList(),
            onChanged: enabled
                ? (value) {
                    if (value != null) onHariChanged(value);
                  }
                : null,
          ),
        ),
        const SizedBox(height: 14),
        if (stackTimes)
          Column(children: [start, const SizedBox(height: 14), end])
        else
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: Column(children: [start, const Spacer()])),
                const SizedBox(width: 12),
                Expanded(child: Column(children: [end, const Spacer()])),
              ],
            ),
          ),
        const SizedBox(height: 14),
        JadwalField(
          label: 'Ruangan',
          child: TextFormField(
            key: const Key('schedule_room'),
            controller: ruanganController,
            enabled: enabled,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Contoh: G301',
              prefixIcon: SizedBox.square(
                dimension: 48,
                child: Column(
                  children: [
                    Spacer(),
                    Row(children: [Spacer(), JadwalFormIcon('room'), Spacer()]),
                    Spacer(),
                  ],
                ),
              ),
            ),
            textInputAction: TextInputAction.done,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ruangan wajib diisi'
                : null,
          ),
        ),
      ],
    );
  }
}
```

### Dropdown hari

```dart
items: DayHelper.dayNames.entries
    .map(
      (day) => DropdownMenuItem(value: day.key, child: Text(day.value)),
    )
    .toList(),
```

`DropdownButtonFormField<int>` menyimpan pilihan berupa integer, sementara label yang terlihat adalah nama hari. `DayHelper.dayNames` menyediakan pemetaan angka dan nama; `.entries` membaca pasangan key/value, `.map` mengubah tiap pasangan menjadi pilihan, lalu `.toList()` membentuk daftar widget pilihan.

`initialValue: hari` memberi nilai awal field. `isExpanded: true` membuat bagian isi dropdown menggunakan lebar yang tersedia; `dropdownColor: Colors.white` mengatur warna menu yang terbuka. `InputDecoration()` kosong tetap menerima pengaturan tema form. Callback `onChanged` memeriksa nilai non-null sebelum meneruskannya lewat `onHariChanged`; jika `enabled` salah, callback menjadi `null` dan kontrol tidak bisa diubah.

### Membuat dua field waktu

Variabel lokal `start` dan `end` menyimpan widget `JamKuliahField` yang akan ditata sesudahnya. Ini bukan state jam tambahan. Masing-masing menerima `time` dan callback ketuk; ketika form dinonaktifkan, `onTap` menjadi `null`.

Jam mulai memakai validator bawaan `JamKuliahField` yang mewajibkan pilihan. Jam selesai memakai validator khusus:

```dart
if (value == null) return 'Jam selesai wajib dipilih';
if (jamMulai != null &&
    value.hour * 60 + value.minute <=
        jamMulai!.hour * 60 + jamMulai!.minute) {
  return 'Harus setelah jam mulai';
}
return null;
```

Jam diubah menjadi menit sejak pukul `00:00` agar dapat dibandingkan sebagai angka. `<=` menolak selesai yang sama atau lebih awal dari mulai. Contoh mulai `08:00` dan selesai `08:00` ditolak; `09:00` diterima oleh aturan urutan waktu ini. Cek bentrok dengan jadwal lain dilakukan kemudian oleh repository, bukan validator ini. Form ini juga tidak menerima rentang yang melewati tengah malam karena selesai harus lebih besar dari mulai dalam satu hari.

### Layout jam dan ruangan

Ketika `stackTimes` benar, `Column` menyusun jam mulai dan selesai bertingkat dengan jarak 14. Selain itu, `Row` di dalam `IntrinsicHeight` menampilkan dua field berdampingan. `Expanded` membagi lebar sama rata, `SizedBox(width: 12)` memberi jarak, dan `Spacer` di bawah masing-masing field mengisi tinggi tersisa jika pesan error membuat tinggi kedua field berbeda.

Ruangan memakai `JadwalField > TextFormField`, key `schedule_room`, ikon `room`, hint `Contoh: G301`, dan `TextInputAction.done`. `TextCapitalization.characters` meminta keyboard menawarkan kapitalisasi semua huruf, bukan memaksa teks dari segala sumber menjadi uppercase. Validator menolak teks kosong setelah `trim()`; tidak ada pola khusus seperti wajib huruf G atau jumlah digit tertentu dalam kode ini.

<a id="file-lib-pages-jadwal-widgets-jam-kuliah-field-dart"></a>

## `lib/pages/jadwal/widgets/jam_kuliah_field.dart`

[Buka sumber](../../lib/pages/jadwal/widgets/jam_kuliah_field.dart).

`JamKuliahField` membuat pilihan jam terlihat seperti field input. Kontrol ini tidak memakai keyboard teks dan tidak mempunyai `TextEditingController`. Nilai yang divalidasi bertipe `TimeOfDay`.

### Kode lengkap

<!-- SUMBER:lib/pages/jadwal/widgets/jam_kuliah_field.dart SHA256=3a093d0c8ed0cf376f7d11e3d0d48488673bedc7733b9831225169762523bf65 -->

```dart
import 'package:flutter/material.dart';

import 'jadwal_form_style.dart';

class JamKuliahField extends StatelessWidget {
  const JamKuliahField({
    super.key,
    required this.label,
    required this.time,
    required this.onTap,
    this.validator,
  });
  final String label;
  final TimeOfDay? time;
  final VoidCallback? onTap;
  final FormFieldValidator<TimeOfDay>? validator;
  @override
  Widget build(BuildContext context) => JadwalField(
    label: label,
    child: FormField<TimeOfDay>(
      // Update the FormField value when a time is selected, without controller text.
      key: ValueKey('$label-$time'),
      initialValue: time,
      validator:
          validator ??
          (value) => value == null ? 'Jam mulai wajib dipilih' : null,
      builder: (state) => InkWell(
        key: ValueKey(label == 'Jam Mulai' ? 'schedule_start' : 'schedule_end'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Semantics(
          button: true,
          label: label,
          child: InputDecorator(
            isEmpty: false,
            decoration: InputDecoration(
              errorText: state.errorText,
              enabled: onTap != null,
              prefixIcon: const SizedBox.square(
                dimension: 48,
                child: Column(
                  children: [
                    Spacer(),
                    Row(
                      children: [Spacer(), JadwalFormIcon('clock'), Spacer()],
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ),
            child: Text(
              time == null
                  ? 'Pilih waktu'
                  : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: time == null
                    ? const Color(0xFF757575)
                    : const Color(0xFF1E3A5F),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
```

### Nilai dan integrasi ke `Form`

Constructor menerima `label`, `time`, `onTap`, serta validator opsional. `TimeOfDay?` mengizinkan kondisi belum memilih; `VoidCallback?` mengizinkan kontrol dinonaktifkan; `FormFieldValidator<TimeOfDay>?` mengizinkan validator berbeda untuk jam selesai.

```dart
FormField<TimeOfDay>(
  key: ValueKey('$label-$time'),
  initialValue: time,
  validator:
      validator ??
      (value) => value == null ? 'Jam mulai wajib dipilih' : null,
```

`FormField` memasukkan kontrol buatan sendiri ke mekanisme validasi `Form`. `initialValue` adalah nilai awal state field, bukan perintah untuk selalu menimpa nilai setiap build. Karena itu key menyertakan label dan waktu: ketika waktu berubah, key berubah, Flutter membuat state field baru dengan nilai awal terbaru. Komentar sumber memang menyebut tujuan memperbarui nilai field ketika waktu dipilih, tanpa teks controller.

Operator `??` memilih validator yang diberikan; bila tidak ada, validator bawaan menolak jam kosong. Jam selesai memberikan validator khusus dari `WaktuKuliahForm`.

### Area ketuk, aksesibilitas, dan tampilan error

`builder: (state)` menerima `FormFieldState`, termasuk `state.errorText`. `InkWell` menyediakan area ketuk dan respons Material; ia memanggil `onTap`, yang akhirnya membuka pemilih jam di induk. Radius 9 mengikuti bentuk field. Key area ketuk memakai `schedule_start` untuk label `Jam Mulai`, atau `schedule_end` untuk label lain pada pemakaian sekarang.

`Semantics(button: true, label: label)` menyatakan kepada teknologi bantu bahwa area ini adalah tombol dengan nama field. `InputDecorator` menggambar bingkai, latar, ikon, dan error seperti input Material meskipun anaknya hanya `Text`. `errorText: state.errorText` menampilkan hasil validator; `enabled: onTap != null` mengikuti status interaksi. `isEmpty: false` menyatakan bahwa dekorator ini menampilkan konten; teks placeholder ditangani sendiri oleh `Text`, bukan oleh `hintText`.

```dart
time == null
    ? 'Pilih waktu'
    : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
```

`padLeft(2, '0')` menambahkan nol bila angka hanya satu digit: jam `8`, menit `5` menjadi `08:05`. Ini format 24 jam manual, sehingga tampilan field tidak bergantung pada format jam lokal pengguna. Nilai kosong berwarna abu-abu `0xFF757575`; nilai terpilih berwarna biru gelap `0xFF1E3A5F`. Ikon clock dipusatkan dalam kotak 48 seperti field teks lainnya.

<a id="file-lib-pages-jadwal-widgets-jadwal-time-picker-frame-dart"></a>

## `lib/pages/jadwal/widgets/jadwal_time_picker_frame.dart`

[Buka sumber](../../lib/pages/jadwal/widgets/jadwal_time_picker_frame.dart).

`JadwalTimePickerFrame` adalah pembungkus untuk widget pemilih jam yang diterima lewat `child`. Ia dipasang melalui parameter `builder` pada `showTimePicker` di halaman induk.

### Kode lengkap

<!-- SUMBER:lib/pages/jadwal/widgets/jadwal_time_picker_frame.dart SHA256=f84f990782a5e5af311a79ee8db31e4e0ac2996c3561edf243624b452bde3ae0 -->

```dart
import 'package:flutter/material.dart';

class JadwalTimePickerFrame extends StatelessWidget {
  const JadwalTimePickerFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Row(children: [Expanded(child: child)]),
          ),
        ),
      ),
    );
  }
}
```

### Bedah pemakaian

```dart
MediaQuery(
  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
```

Kode menyalin informasi `MediaQuery` yang sudah ada dan mengubah preferensi jam untuk subtree dialog menjadi 24 jam. Ukuran, inset, dan data lain tetap berasal dari konteks semula. Pengaruhnya berada pada pemilih jam yang dibungkus, bukan perubahan pengaturan jam seluruh perangkat.

`LayoutBuilder` membaca batas ruang dialog. `SingleChildScrollView` menyediakan gulir ketika konten membutuhkan ruang lebih. `ConstrainedBox(minHeight: constraints.maxHeight)` menetapkan tinggi minimum konten sebesar tinggi ruang yang tersedia; ini minimum, jadi konten masih boleh lebih tinggi. `Row > Expanded(child: child)` memberikan lebar yang tersedia kepada dialog.

Dari struktur ini, pembungkus berusaha menampung dialog pada ruang vertikal terbatas tanpa mengharuskan seluruh isi muat sekaligus. Pemilihan mode `input` pada tinggi view di bawah 500 tetap dilakukan di `_pickTime`, bukan di file pembungkus ini.

<a id="file-lib-pages-jadwal-widgets-pengingat-form-dart"></a>

## `lib/pages/jadwal/widgets/pengingat_form.dart`

[Buka sumber](../../lib/pages/jadwal/widgets/pengingat_form.dart).

`PengingatForm` menampilkan pengaturan pengingat saja. Ia menerima `pengingatAktif`, `menitSebelum`, callback untuk keduanya, dan `enabled`. Menyalakan switch mengubah state halaman melalui callback; widget ini tidak meminta izin sistem atau menjadwalkan notifikasi sendiri.

### Kode lengkap

<!-- SUMBER:lib/pages/jadwal/widgets/pengingat_form.dart SHA256=101004f412fe9c184e3dd0e162a888365ff727280ca6f3ded87416fbf6d70a2f -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'jadwal_form_style.dart';

class PengingatForm extends StatelessWidget {
  const PengingatForm({
    super.key,
    required this.pengingatAktif,
    required this.menitSebelum,
    required this.onPengingatChanged,
    required this.onMenitChanged,
    this.enabled = true,
  });
  final bool pengingatAktif;
  final int menitSebelum;
  final ValueChanged<bool> onPengingatChanged;
  final ValueChanged<int> onMenitChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Row(
              children: [
                SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Column(
                            children: [
                              Spacer(),
                              Row(
                                children: [
                                  Spacer(),
                                  JadwalFormIcon('bell', size: 24),
                                  Spacer(),
                                ],
                              ),
                              Spacer(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Aktifkan Pengingat',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Notifikasi sebelum kelas dimulai',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        key: const Key('schedule_reminder'),
                        value: pengingatAktif,
                        onChanged: enabled ? onPengingatChanged : null,
                        activeTrackColor: AppColors.primary,
                        activeThumbColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
              ],
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
      if (pengingatAktif) ...[
        const SizedBox(height: 14),
        Semantics(
          label: 'Waktu pengingat',
          child: DropdownButtonFormField<int>(
            key: ValueKey('reminder_minutes_$menitSebelum'),
            initialValue: menitSebelum,
            isExpanded: true,
            dropdownColor: Colors.white,
            items: [
              for (var minutes = 5; minutes <= 60; minutes += 5)
                DropdownMenuItem(
                  value: minutes,
                  child: Text('$minutes menit sebelumnya'),
                ),
            ],
            onChanged: enabled
                ? (value) {
                    if (value != null) onMenitChanged(value);
                  }
                : null,
          ),
        ),
      ],
    ],
  );
}
```

### Kartu pengingat dan switch

`Container` memakai `BoxDecoration` putih dengan radius 14 untuk kartu. Isi disusun oleh `Column(mainAxisSize: min)` dan `Row`. Jarak sisi 12 serta jarak antarisi diatur memakai `SizedBox`. Kotak ikon berukuran 44, berlatar `AppColors.primary`, bersudut radius 9, dengan ikon bell ukuran 24 di tengah.

Teks `Aktifkan Pengingat` berwarna primary, ukuran 14, ketebalan `w600`; deskripsi di bawahnya berukuran 12 dan abu-abu. `Expanded` pada area teks membagikan ruang yang tersisa bersama area ikon dan switch, sehingga teks dapat membungkus dalam batas lebar itu.

```dart
Switch(
  key: const Key('schedule_reminder'),
  value: pengingatAktif,
  onChanged: enabled ? onPengingatChanged : null,
  activeTrackColor: AppColors.primary,
  activeThumbColor: Colors.white,
)
```

`value` menentukan posisi switch saat ini. `onChanged` mengirim nilai boolean baru ke induk; switch tidak mengubah field `pengingatAktif` sendiri. Saat menyimpan, `enabled` salah dan callback `null` menonaktifkan interaksi. `activeTrackColor` adalah warna jalur saat aktif; `activeThumbColor` warna bulatan gesernya.

### Pilihan menit yang muncul secara kondisional

```dart
if (pengingatAktif) ...[
  const SizedBox(height: 14),
  Semantics(
    label: 'Waktu pengingat',
    child: DropdownButtonFormField<int>(
      key: ValueKey('reminder_minutes_$menitSebelum'),
      initialValue: menitSebelum,
```

Collection `if` dan spread `...` memasukkan dropdown beserta jaraknya hanya ketika pengingat aktif. `Semantics` memberikan nama kepada kontrol untuk teknologi bantu. `ValueKey` menyertakan menit terpilih sehingga field memperoleh state nilai awal yang baru bila menit dari induk berubah.

Daftar `items` memakai collection `for`: mulai `5`, bertambah `5`, dan berhenti setelah `60`. Hasilnya tepat 12 pilihan: 5, 10, 15, …, 60 menit sebelum kuliah. `DropdownMenuItem.value` berupa integer, sedangkan labelnya seperti `15 menit sebelumnya`.

`isExpanded` membuat isi dropdown memakai lebar tersedia dan `dropdownColor` membuat menu putih. `onChanged` mengabaikan `null` lalu mengirim angka melalui `onMenitChanged`. Mematikan toggle menyembunyikan dropdown tetapi tidak menghapus `_menitSebelum` di induk; menyalakannya kembali dalam halaman yang sama tetap memakai nilai tersebut.

<a id="file-lib-pages-jadwal-widgets-simpan-jadwal-button-dart"></a>

## `lib/pages/jadwal/widgets/simpan_jadwal_button.dart`

[Buka sumber](../../lib/pages/jadwal/widgets/simpan_jadwal_button.dart).

`SimpanJadwalButton` menggambar keadaan tombol dari `isSaving` dan `isEditing`, lalu meneruskan klik lewat `onSave`. Proses simpan sebenarnya berada pada `_simpan` milik halaman induk.

### Kode lengkap

<!-- SUMBER:lib/pages/jadwal/widgets/simpan_jadwal_button.dart SHA256=3ec4d058da65f13953d1953062a48eb825eae72d2349543c05f682a16daddbc0 -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'jadwal_form_style.dart';

class SimpanJadwalButton extends StatelessWidget {
  const SimpanJadwalButton({
    super.key,
    required this.isSaving,
    required this.isEditing,
    required this.onSave,
  });
  final bool isSaving;
  final bool isEditing;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('schedule_save'),
          onPressed: isSaving ? null : onSave,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            disabledBackgroundColor: Colors.white70,
            minimumSize: const Size(0, 52),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : (isEditing
                    ? const Icon(Icons.check)
                    : const JadwalFormIcon('add')),
          label: Text(
            isSaving
                ? 'Menyimpan...'
                : isEditing
                ? 'Simpan Perubahan'
                : 'Tambah Jadwal',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
```

### Ukuran, gaya, dan state

`ConstrainedBox(maxWidth: 480)` membatasi lebar maksimum, sementara `SizedBox(width: double.infinity)` meminta tombol mengisi lebar yang diizinkan parent. `double.infinity` di sini adalah permintaan mengisi batas lebar yang tersedia, bukan ukuran fisik layar tanpa batas.

`FilledButton.icon` menggabungkan ikon dan teks. `FilledButton.styleFrom` membuat latar putih, foreground primary, dan latar saat nonaktif `white70`. `minimumSize: Size(0, 52)` meminta tinggi minimum 52; isi dan batas parent tetap memengaruhi ukuran akhir. Gaya teks memakai Inter, ukuran 20, `w600`. `TextAlign.center` memusatkan isi teks pada ruang teksnya.

| Keadaan | Ikon | Label | Interaksi |
| --- | --- | --- | --- |
| Menambah, belum menyimpan | `JadwalFormIcon('add')` | `Tambah Jadwal` | Memanggil `onSave`. |
| Mengedit, belum menyimpan | `Icon(Icons.check)` | `Simpan Perubahan` | Memanggil `onSave`. |
| Sedang menyimpan | `CircularProgressIndicator` | `Menyimpan...` | Nonaktif karena `onPressed` bernilai `null`. |

Spinner dibatasi kotak 20 × 20 dengan `strokeWidth: 2` agar tidak menguasai ukuran tombol. Ternary bertingkat memilih ikon dan label sesuai dua boolean itu. Menonaktifkan tombol serta pemeriksaan awal `_sedangMenyimpan` pada induk bersama-sama mencegah pengiriman simpan berulang selama operasi berjalan.

<a id="file-lib-pages-jadwal-widgets-jadwal-form-footer-dart"></a>

## `lib/pages/jadwal/widgets/jadwal_form_footer.dart`

[Buka sumber](../../lib/pages/jadwal/widgets/jadwal_form_footer.dart).

`JadwalFormFooter` menerima satu `Widget button` dan menempatkannya di area bawah. Halaman induk memasangnya pada `Scaffold.bottomNavigationBar` hanya ketika kondisi `pinSave` terpenuhi.

### Kode lengkap

<!-- SUMBER:lib/pages/jadwal/widgets/jadwal_form_footer.dart SHA256=f1404f075591d3b4d9e4e64a1b7312d2ed09c81c4096d86d4ef78ebfecabdfa0 -->

```dart
import 'package:flutter/material.dart';

class JadwalFormFooter extends StatelessWidget {
  const JadwalFormFooter({super.key, required this.button});
  final Widget button;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12),
          Row(
            children: [
              SizedBox(width: 19),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      const Spacer(),
                      SizedBox(
                        width: constraints.maxWidth.clamp(0.0, 480.0),
                        child: button,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 19),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
```

### Bedah pemakaian

`SafeArea(top: false)` melindungi bagian bawah/samping dari area sistem yang harus dihindari tanpa menambah perlindungan atas. `Column(mainAxisSize: MainAxisSize.min)` membuat footer mengambil tinggi yang diperlukan isinya, bukan meminta seluruh tinggi halaman.

Jarak atas 12 dan bawah 16 memakai `SizedBox`. `Row` memberikan margin kiri/kanan 19. `Expanded` menyerahkan sisa lebar ke `LayoutBuilder`, yang kemudian membaca lebar setelah margin tersebut. Di dalamnya, dua `Spacer` memusatkan `SizedBox` tombol.

```dart
width: constraints.maxWidth.clamp(0.0, 480.0),
child: button,
```

Tombol mengisi lebar tersedia hingga maksimum 480. Karena `button` diterima sebagai widget, footer tidak menentukan apakah labelnya `Tambah Jadwal` atau `Simpan Perubahan`; perilaku dan tampilannya tetap menjadi tanggung jawab `SimpanJadwalButton` dan induknya.

<a id="file-lib-pages-jadwal-widgets-buang-perubahan-dialog-dart"></a>

## `lib/pages/jadwal/widgets/buang_perubahan_dialog.dart`

[Buka sumber](../../lib/pages/jadwal/widgets/buang_perubahan_dialog.dart).

`BuangPerubahanDialog` menampilkan keputusan saat pengguna akan meninggalkan form yang berubah. Ia tidak memeriksa perubahan sendiri; `_requestClose` di induk yang menentukan kapan dialog perlu dibuka.

### Kode lengkap

<!-- SUMBER:lib/pages/jadwal/widgets/buang_perubahan_dialog.dart SHA256=1b42b058a76b3130d5f476bb13fd1c755ce3a05ead41319d18e5be98aebf249b -->

```dart
import 'package:flutter/material.dart';

class BuangPerubahanDialog extends StatelessWidget {
  const BuangPerubahanDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Buang perubahan?'),
      content: const Text(
        'Perubahan jadwal belum disimpan. Kembali akan membuang perubahan ini.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Lanjut Mengisi'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Buang Perubahan'),
        ),
      ],
    );
  }
}
```

### Arti hasil dialog

`AlertDialog` berisi judul, pesan, dan dua action. `scrollable: true` memungkinkan bagian judul/konten dialog bergulir jika membutuhkan ruang lebih, misalnya saat ukuran teks membesar. Gaya yang tidak ditetapkan di file ini mengikuti tema yang tersedia pada konteks dialog.

```dart
TextButton(
  onPressed: () => Navigator.pop(context, false),
  child: const Text('Lanjut Mengisi'),
),
FilledButton(
  onPressed: () => Navigator.pop(context, true),
  child: const Text('Buang Perubahan'),
),
```

`Navigator.pop` di dalam dialog menutup route dialog terlebih dahulu, bukan langsung menutup halaman form. Nilai `false` berarti lanjut mengisi; `true` berarti pengguna setuju membuang perubahan. `showDialog<bool>` di induk menunggu hasil tersebut, lalu `_finish(false)` menutup halaman hanya jika hasilnya `true`. Jika dialog ditutup tanpa menekan kedua tombol, hasilnya dapat `null` dan induk tetap mempertahankan halaman karena mengecek `discard == true`.

Perbedaan `TextButton` dan `FilledButton` juga membedakan bobot visual kedua aksi. Tidak ada operasi hapus database pada dialog ini: yang dibuang adalah perubahan form yang belum disimpan.

## Latihan membaca alur form

Gunakan latihan ini untuk menguji pemahaman tanpa mengubah aplikasi:

1. Telusuri klik `Jam Mulai`: `JamKuliahField.onTap` → callback `WaktuKuliahForm` → `_pickTime(true)` → hasil dialog → `setState` → `time` baru → `ValueKey` baru pada `FormField`.
2. Telusuri SKS `0`: controller menyimpan teks → tombol memanggil `_simpan` → `validateGranularly` menjalankan validator SKS → pesan error → halaman tetap terbuka → field error digulirkan agar terlihat.
3. Telusuri toggle pengingat: `Switch.onChanged` → callback induk → `_pengingatAktif` berubah → dropdown menit muncul/hilang. Penjadwalan notifikasi baru diminta setelah proses simpan.
4. Telusuri kembali setelah mengubah nama: controller listener → `_hasChanges` benar → `PopScope` menahan keluar → `_requestClose` → dialog → nilai keputusan → lanjut mengisi atau `_finish(false)`.
5. Bedakan tiga ukuran: `MediaQuery` membaca view; `LayoutBuilder` membaca batas dari parent; `IntrinsicHeight` menata tinggi mengikuti kebutuhan intrinsik anak. Cari satu pemakaian masing-masing dalam bab ini.

