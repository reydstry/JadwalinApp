# 03 — Splash dan autentikasi

Bab ini membedah 12 file UI: tiga file splash dan sembilan file autentikasi. Mulai dari [dasar Flutter dan Dart](00-dasar.md) jika istilah seperti `build`, `State`, `context`, atau callback masih baru. Arti istilah yang ingin dicari cepat tersedia di [glosarium](05-glosarium.md).

Kode lengkap di bawah adalah salinan kode proyek pada saat panduan dibuat. Penjelasan membahas perilaku yang benar-benar tertulis. Kalimat tentang alasan pemisahan komponen merupakan interpretasi berdasarkan hubungan kode, bukan riwayat keputusan pembuatnya.

Alur yang perlu dibayangkan:

```text
SplashPage
  ├─ memanggil loader dari luar sambil menerima progres
  ├─ menampilkan LiquidLogo selama loading
  ├─ menampilkan SplashError jika gagal → tombol Coba lagi
  └─ memanggil destinationBuilder jika berhasil

AuthFlow
  └─ LoginPage
       ├─ Daftarkeun → push RegisterPage
       │    ├─ Kembali / Loginkeun → pop ke LoginPage
       │    └─ submit berhasil → Home, hapus riwayat rute sebelumnya
       └─ submit berhasil → Home, hapus riwayat rute sebelumnya
```

`SplashPage` sendiri tidak memilih apakah pengguna harus ke home atau login: keputusan itu diserahkan kepada `destinationBuilder`. Begitu pula halaman login dan registrasi tidak membuat home secara langsung, tetapi menerima `homeBuilder`.

**Batas autentikasi saat ini:** halaman memanggil `AuthGateway`. Implementasi bawaan aplikasi, `SimulatedAuthGateway`, hanya menunggu `Future.delayed` selama 700 milidetik secara default. Keberhasilan alur UI ini belum membuktikan email/password diperiksa server, akun dibuat, atau sesi disimpan. Sembilan file autentikasi yang dibahas di sini juga belum menyediakan UI login Google, verifikasi email, dan lupa password. Kebutuhan produk dan kode yang tersedia harus dibedakan.

<a id="file-lib-pages-splash-splash-page-dart"></a>

## `lib/pages/splash/splash_page.dart`

[Buka sumber](../../lib/pages/splash/splash_page.dart).

**Peran file:** mengatur proses memuat aplikasi, progres logo, kegagalan, percobaan ulang, dan perpindahan ke halaman tujuan. `LiquidLogo` menangani bentuk animasinya, sedangkan `SplashError` menangani tampilan error.

### Kode lengkap

<!-- SUMBER:lib/pages/splash/splash_page.dart SHA256=73ec3a1218aad6b735632f867718f7e3b0f70fe124486cb8cdc2eec5c31a92df -->

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/app_bootstrapper.dart';
import '../../theme/app_colors.dart';
import 'widgets/splash_error.dart';
import 'widgets/liquid_logo.dart';

typedef SplashLoader = Future<AppBootstrapResult> Function(
  BootstrapProgressCallback onProgress,
);
typedef SplashDestinationBuilder = Widget Function(
  BuildContext context,
  AppBootstrapResult result,
);

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.load,
    required this.destinationBuilder,
  });

  final SplashLoader load;
  final SplashDestinationBuilder destinationBuilder;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _minimumDisplayDuration = Duration(milliseconds: 1500);
  late final AnimationController _progressController;
  double _targetProgress = 0;
  double get _progress => _progressController.value;
  bool _hasNavigated = false;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    )..addListener(() => setState(() {}));
    _runLoading();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  TickerFuture _animateProgress(double target) {
    _targetProgress = target;
    // Limit reveal speed so moving from 0 to 1 takes at least 1.5 seconds.
    final milliseconds = math.max(
      250,
      (_minimumDisplayDuration.inMilliseconds * (target - _progress)).ceil(),
    );
    return _progressController.animateTo(
      target,
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.linear,
    );
  }

  Future<void> _runLoading() async {
    try {
      final result = await widget.load(_reportProgress);

      if (!mounted || _hasNavigated) return;

      await _animateProgress(1).orCancel;
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      _isLoading = false;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => widget.destinationBuilder(context, result),
        ),
      );
    } on TickerCanceled {
      // The page was disposed before its reveal finished.
      return;
    } catch (_) {
      if (!mounted || _hasNavigated) return;

      _progressController.stop();
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _reportProgress(double progress) {
    if (!mounted || _hasNavigated || !_isLoading) return;

    // Reserve the full logo for a successfully completed loader.
    final target = progress.clamp(0.0, 0.9).toDouble();
    if (target > _targetProgress) _animateProgress(target);
  }

  void _retry() {
    if (_isLoading || _hasNavigated) return;

    setState(() {
      _targetProgress = 0;
      _progressController.reset();
      _hasError = false;
      _isLoading = true;
    });

    _runLoading();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return SplashError(onRetry: _retry);
    }

    final percentage = (_progress * 100).round();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          const Spacer(),
          Row(
            children: [
              const Spacer(),
              Semantics(
                label: 'Memuat aplikasi $percentage%',
                value: '$percentage%',
                child: ExcludeSemantics(child: LiquidLogo(progress: _progress)),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
```

### Class, tipe, dan state yang digunakan

| Bagian | Kegunaannya pada file ini |
| --- | --- |
| `SplashLoader` | Alias tipe fungsi yang menerima callback progres dan menghasilkan `Future<AppBootstrapResult>`. Loader bekerja di luar widget ini. |
| `SplashDestinationBuilder` | Alias fungsi yang menerima `BuildContext` serta hasil bootstrap, lalu menghasilkan `Widget` tujuan. |
| `SplashPage` | `StatefulWidget` yang menyimpan konfigurasi tetap: `load` dan `destinationBuilder`. |
| `_SplashPageState` | Menyimpan dan mengubah progres, status loading, error, serta penanda bahwa navigasi sudah dilakukan. Awalan `_` membuat nama privat dalam library Dart. |
| `SingleTickerProviderStateMixin` | Menyediakan ticker untuk satu `AnimationController`. Dipakai sebagai `vsync: this`. |
| `AnimationController` | Menghasilkan nilai progres yang berubah per frame; nilai itu dibaca oleh getter `_progress`. |
| `TickerFuture` | Hasil operasi animasi seperti `animateTo`; dapat ditunggu menggunakan `.orCancel`. |
| `AppBootstrapResult` / `BootstrapProgressCallback` | Kontrak data dan callback dari service bootstrap; halaman tidak membuka database atau menyiapkan notifikasi sendiri. |

State-nya memiliki fungsi yang berbeda:

- `_targetProgress` menyimpan tujuan animasi terbaru, bukan nilai yang sedang tampil.
- `_progress` membaca `_progressController.value`, yaitu nilai tampilan saat ini.
- `_hasNavigated` mencegah proses yang selesai terlambat memulai navigasi lagi.
- `_isLoading` membatasi retry dan laporan progres agar sesuai proses aktif.
- `_hasError` menentukan apakah `build` menampilkan error atau logo.

### Bedah kode dan alasan pemakaiannya

**1. Tipe fungsi membuat halaman dapat menerima proses loading dari luar.**

```dart
typedef SplashLoader = Future<AppBootstrapResult> Function(
  BootstrapProgressCallback onProgress,
);
```

`typedef` memberi nama pada sebuah bentuk fungsi. Cara membacanya: “`SplashLoader` adalah fungsi yang menerima pelapor progres dan nanti mengembalikan hasil bootstrap.” `Future` berarti hasilnya mungkin belum tersedia sekarang. Dengan menerima fungsi, splash dapat dipakai bersama loader yang berbeda tanpa mengganti widget tampilan.

**2. Controller dibuat sekali dalam `initState`, lalu dibersihkan dalam `dispose`.**

```dart
_progressController = AnimationController(
  vsync: this,
  animationBehavior: AnimationBehavior.preserve,
)..addListener(() => setState(() {}));
_runLoading();
```

`late final` berarti controller diisi setelah objek state dibuat, tetapi hanya sekali. `..addListener(...)` adalah cascade: sesudah controller dibuat, listener ditambahkan pada objek yang sama. Setiap nilai berubah, listener memanggil `setState` agar `build` membaca progres baru. Callback `setState` kosong di sini karena perubahan nilainya sudah terjadi di controller.

`vsync` menghubungkan animasi dengan ticker widget. `AnimationBehavior.preserve` mempertahankan perilaku durasi controller saat sistem meminta pengurangan animasi. Ini terpisah dari gelombang `LiquidLogo`, yang justru dihentikan pada kondisi tersebut. Saat widget dilepas, `dispose` memanggil `_progressController.dispose()` untuk membersihkan sumber daya controller. Pola pembuatan dan pembersihan ini mengikuti [dokumentasi `AnimationController`](https://api.flutter.dev/flutter/animation/AnimationController-class.html).

**3. `_animateProgress` mengubah angka target menjadi animasi yang halus.**

```dart
final milliseconds = math.max(
  250,
  (_minimumDisplayDuration.inMilliseconds * (target - _progress)).ceil(),
);
return _progressController.animateTo(
  target,
  duration: Duration(milliseconds: milliseconds),
  curve: Curves.linear,
);
```

`math.max` memilih nilai lebih besar. Durasi dihitung dari jarak progres dengan acuan 1.500 ms untuk rentang penuh, dan setiap animasi memiliki batas minimum 250 ms. `ceil()` membulatkan ke atas agar dapat digunakan sebagai jumlah milidetik integer. `Curves.linear` berarti perubahan nilai memiliki kecepatan konstan selama animasi tersebut. Ini mengatur kecepatan pengungkapan logo; angka progres bukan pengukuran persentase byte unduhan.

**4. `_runLoading` menunggu pekerjaan, menyelesaikan animasi, lalu mengganti rute.**

```dart
final result = await widget.load(_reportProgress);
if (!mounted || _hasNavigated) return;

await _animateProgress(1).orCancel;
if (!mounted || _hasNavigated) return;
```

`widget.load` mengakses konfigurasi dari `SplashPage`. Loader menerima `_reportProgress` agar dapat melaporkan perkembangan. Setelah loader berhasil, animasi diarahkan ke `1`, yaitu 100%. `await` memberi kesempatan pekerjaan lain berjalan sambil menunggu; bukan membekukan seluruh aplikasi.

`mounted` memastikan state masih terpasang sebelum menggunakan konteksnya. Pengguna bisa meninggalkan halaman ketika proses asynchronous belum selesai. `.orCancel` menyebabkan penantian animasi menghasilkan `TickerCanceled` jika ticker dibatalkan; `on TickerCanceled` menanganinya tanpa menampilkan pesan error pemuatan. Perilaku Future animasi saat dibatalkan dijelaskan pada [referensi `AnimationController`](https://api.flutter.dev/flutter/animation/AnimationController-class.html).

```dart
await Navigator.of(context).pushReplacement(
  MaterialPageRoute<void>(
    builder: (context) => widget.destinationBuilder(context, result),
  ),
);
```

`Navigator.of(context)` mengambil pengelola rute. `MaterialPageRoute<void>` membungkus halaman tujuan dengan perilaku rute Material. `pushReplacement` mengganti splash sehingga tombol kembali tidak sekadar membuka splash lagi. Future navigasi ini terkait berakhirnya rute tujuan; tampilnya halaman tujuan tidak berarti Future tersebut langsung selesai.

Jika loader melempar error lain, controller dihentikan dan `_hasError` menjadi `true`. `catch (_)` sengaja tidak memakai objek error dalam UI; pesan yang ditampilkan tetap pesan umum di `SplashError`.

**5. Progres sementara dibatasi dan retry mengulang keadaan awal.**

```dart
final target = progress.clamp(0.0, 0.9).toDouble();
if (target > _targetProgress) _animateProgress(target);
```

`clamp` membatasi nilai ke rentang 0–0,9. Tujuannya, logo penuh hanya muncul setelah loader benar-benar berhasil. Target yang lebih kecil atau sama diabaikan sehingga target tidak mundur. `_retry` menolak panggilan saat masih loading/sudah navigasi, mengembalikan controller ke awal dengan `reset()`, menghapus error, lalu menjalankan loader lagi.

**6. Pohon UI memusatkan logo dan memberi informasi aksesibilitas.**

| Widget/properti | Cara membacanya di sini |
| --- | --- |
| `Scaffold(backgroundColor: AppColors.primary)` | Kanvas halaman dengan warna utama aplikasi. |
| `Column` + dua `Spacer` | Ruang fleksibel di atas dan bawah memusatkan baris logo secara vertikal. |
| `Row` + dua `Spacer` | Ruang fleksibel di kiri dan kanan memusatkan logo secara horizontal. |
| `Semantics(label:, value:)` | Memberi pembaca layar keterangan pemuatan dan persentasenya. |
| `ExcludeSemantics` | Mencegah isi gambar menyumbangkan keterangan tambahan yang tumpang tindih dengan keterangan progres pada parent. |
| `LiquidLogo(progress: _progress)` | Mengirim nilai animasi saat ini kepada komponen visual. |
| `(_progress * 100).round()` | Mengubah rentang 0–1 menjadi persentase integer untuk teks aksesibilitas. |

`if (_hasError) return SplashError(...)` adalah percabangan widget: seluruh isi splash diganti dengan halaman error, bukan ditumpuk di atas logo.

<a id="file-lib-pages-splash-widgets-liquid-logo-dart"></a>

## `lib/pages/splash/widgets/liquid_logo.dart`

[Buka sumber](../../lib/pages/splash/widgets/liquid_logo.dart).

**Peran file:** menampilkan gambar logo yang terungkap dari bawah ke atas dengan batas berbentuk gelombang. Ketinggian isian mengikuti `progress` dari parent; gerakan gelombangnya memiliki controller sendiri.

### Kode lengkap

<!-- SUMBER:lib/pages/splash/widgets/liquid_logo.dart SHA256=2e06371c08c97bf59cbe0a963ff9db9883d6f59a08b5f6e1b4f1407c9d771d66 -->

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

class LiquidLogo extends StatefulWidget {
  const LiquidLogo({super.key, required this.progress});

  final double progress;

  @override
  State<LiquidLogo> createState() => _LiquidLogoState();
}

class _LiquidLogoState extends State<LiquidLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _waveController.stop();
    } else if (!_waveController.isAnimating) {
      _waveController.repeat();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 201.0;

    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: ColoredBox(
          color: Colors.white,
          child: AnimatedBuilder(
            animation: _waveController,
            child: Image.asset(
              'assets/icon/app_icon.png',
              key: const ValueKey('splash-logo'),
              fit: BoxFit.cover,
            ),
            builder: (context, child) {
              return ClipPath(
                key: const ValueKey('splash-logo-reveal'),
                clipper: _LogoWaveClipper(
                  progress: widget.progress,
                  phase: _waveController.value,
                ),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LogoWaveClipper extends CustomClipper<Path> {
  const _LogoWaveClipper({required this.progress, required this.phase});

  final double progress;
  final double phase;

  @override
  Path getClip(Size size) {
    if (progress <= 0) return Path();
    if (progress >= 1) return Path()..addRect(Offset.zero & size);

    final surfaceY = size.height * (1 - progress);
    final amplitude = 5 * math.sin(math.pi * progress);
    final wavePath = Path()
      ..moveTo(0, surfaceY + math.sin(phase * math.pi * 2) * amplitude);

    for (var x = 0.0; x <= size.width; x += 2) {
      final angle = ((x / size.width) * math.pi * 2) + (phase * math.pi * 2);
      wavePath.lineTo(x, surfaceY + math.sin(angle) * amplitude);
    }

    wavePath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    return wavePath;
  }

  @override
  bool shouldReclip(covariant _LogoWaveClipper oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.phase != phase;
  }
}
```

### Class dan widget yang digunakan

| Bagian | Fungsi |
| --- | --- |
| `LiquidLogo` | `StatefulWidget` dengan input `double progress`. |
| `_LiquidLogoState` | Mengelola controller fase gelombang dan lifecycle-nya. |
| `SingleTickerProviderStateMixin` | Penyedia ticker bagi satu controller gelombang. |
| `_LogoWaveClipper extends CustomClipper<Path>` | Menghitung bentuk potongan gambar yang boleh terlihat. |
| `SizedBox.square(dimension: 201)` | Menetapkan area persegi 201 × 201 logical pixel. |
| `ClipOval` | Memotong keseluruhan area menjadi oval; karena areanya persegi, hasilnya lingkaran. |
| `ColoredBox(color: Colors.white)` | Memberi latar putih di area lingkaran. |
| `AnimatedBuilder` | Membuat ulang subtree potongan saat controller fase berubah. |
| `Image.asset` | Memuat `assets/icon/app_icon.png` dari aset aplikasi. |
| `ClipPath(clipper: ...)` | Memotong gambar menurut `Path` gelombang yang dihitung clipper. |

### Bedah kode dan alasan pemakaiannya

**1. Gerakan gelombang dan progres pemuatan berbeda.**

```dart
_waveController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1400),
)..repeat();
```

Controller ini berulang setiap 1.400 ms. Nilainya digunakan sebagai `phase`, yakni posisi gerakan gelombang dalam satu siklus. Ia tidak memutuskan kapan pemuatan selesai. `widget.progress` datang dari splash dan menentukan seberapa tinggi gambar terlihat.

Pemisahan tersebut membuat gelombang tetap bergerak walaupun laporan progres loader untuk sementara tidak berubah. Itu alasan yang dapat disimpulkan dari dua sumber nilai berbeda dalam implementasi.

**2. Preferensi animasi dibaca ketika dependency berubah.**

```dart
if (MediaQuery.disableAnimationsOf(context)) {
  _waveController.stop();
} else if (!_waveController.isAnimating) {
  _waveController.repeat();
}
```

`didChangeDependencies` digunakan karena kode bergantung pada `MediaQuery` dari konteks. Jika pengurangan animasi aktif, gerakan fase dihentikan. Bila preferensi berubah kembali dan controller belum berjalan, pengulangan dimulai lagi. Progres dari parent masih bisa berubah; yang dihentikan di file ini adalah gerakan gelombangnya. `dispose` membersihkan `_waveController` saat logo dilepas.

**3. `AnimatedBuilder.child` memisahkan gambar tetap dari bagian yang berubah.**

```dart
child: Image.asset(
  'assets/icon/app_icon.png',
  key: const ValueKey('splash-logo'),
  fit: BoxFit.cover,
),
```

Gambar dipasok melalui properti `child` milik `AnimatedBuilder`, lalu dipakai lagi dalam callback `builder`. Karena gambar tidak bergantung pada fase, widget gambar itu tidak perlu dibuat ulang oleh callback setiap tick. `BoxFit.cover` membuat gambar menutupi area yang diberikan dan dapat memotong sisinya jika rasionya berbeda. `ValueKey` memberi identitas berbasis nilai; key pada gambar dan `ClipPath` juga memudahkan pencarian elemen spesifik dalam pengujian.

**4. `getClip` mengubah angka menjadi garis gelombang.**

```dart
if (progress <= 0) return Path();
if (progress >= 1) return Path()..addRect(Offset.zero & size);

final surfaceY = size.height * (1 - progress);
final amplitude = 5 * math.sin(math.pi * progress);
```

`Path()` kosong berarti belum ada bagian gambar yang terlihat. Pada progres penuh, persegi seluruh ukuran dimasukkan ke path. `Offset.zero & size` adalah operasi yang membentuk persegi panjang dari titik `(0, 0)` dan ukuran widget.

Koordinat Y Flutter membesar ke arah bawah. Maka, saat progres naik, `surfaceY` mengecil: batas gambar bergerak ke atas. `amplitude` mengatur tinggi naik-turun gelombang; nilainya kecil di dekat awal/akhir dan terbesar di sekitar pertengahan karena fungsi sinus.

```dart
for (var x = 0.0; x <= size.width; x += 2) {
  final angle = ((x / size.width) * math.pi * 2) + (phase * math.pi * 2);
  wavePath.lineTo(x, surfaceY + math.sin(angle) * amplitude);
}
```

Loop menambahkan titik setiap dua logical pixel di sepanjang lebar logo. `math.pi * 2` mewakili satu putaran sinus. `phase` menggeser gelombang dari waktu ke waktu. Setelah garis atas selesai, path disambungkan ke sudut kanan bawah dan kiri bawah, lalu `close()` menutup bentuk. Akibatnya, bagian di bawah batas gelombanglah yang terlihat.

**5. `shouldReclip` menjelaskan kapan bentuk perlu dihitung ulang.**

```dart
return oldDelegate.progress != progress || oldDelegate.phase != phase;
```

Bentuk bergantung pada ketinggian progres dan fase gelombang. Salah satu berubah berarti potongan perlu diperbarui. `covariant _LogoWaveClipper oldDelegate` mempersempit tipe parameter ke clipper ini sehingga propertinya dapat dibandingkan langsung.

<a id="file-lib-pages-splash-widgets-splash-error-dart"></a>

## `lib/pages/splash/widgets/splash_error.dart`

[Buka sumber](../../lib/pages/splash/widgets/splash_error.dart).

**Peran file:** menyajikan pesan kegagalan menyiapkan aplikasi dan tombol mencoba lagi. File ini tidak menjalankan bootstrap sendiri: ia memanggil `onRetry` yang dikirim `SplashPage`.

### Kode lengkap

<!-- SUMBER:lib/pages/splash/widgets/splash_error.dart SHA256=35d176a14a162e444d39d9ed4ef66e33936c705b9e577b6acf9e291713dae80f -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class SplashError extends StatelessWidget {
  const SplashError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 32),
                          Row(
                            children: [
                              const Spacer(),
                              SizedBox(
                                width: (constraints.maxWidth - 2 * (32)).clamp(
                                  0.0,
                                  double.infinity,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.white,
                                      size: 56,
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Aplikasi belum siap',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Terjadi masalah saat menyiapkan aplikasi. '
                                      'Periksa kembali lalu coba lagi.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: onRetry,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        foregroundColor: AppColors.primary,
                                      ),
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Coba lagi'),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### Class dan widget yang digunakan

`SplashError` adalah `StatelessWidget`. Ia cukup menerima `VoidCallback onRetry`, sebab status loading/error dimiliki parent. `VoidCallback` berarti fungsi tanpa parameter dan tanpa nilai hasil.

| Widget/properti | Kegunaan |
| --- | --- |
| `Scaffold` | Menetapkan latar `AppColors.primary`. |
| `SafeArea` | Memberi ruang terhadap bagian sistem seperti status bar dan cutout. |
| `LayoutBuilder` | Memberi `constraints.maxWidth` dan `maxHeight` dari ruang parent. |
| `SingleChildScrollView` | Membuat pesan dan tombol dapat digulir bila ruang vertikal sempit. |
| `ConstrainedBox` + `BoxConstraints(minHeight: ...)` | Menetapkan tinggi minimum isi sebesar area yang tersedia, sambil mengizinkan isi lebih tinggi untuk scrolling. |
| `Row` + `Expanded` | Memberikan seluruh lebar baris kepada area pesan. |
| `Semantics(liveRegion: true)` | Menandai perubahan pesan sebagai informasi yang dapat diumumkan pembaca layar. |
| `Column(mainAxisSize: MainAxisSize.min)` | Mengelompokkan ikon, judul, penjelasan, dan tombol dengan tinggi sesuai isi. |
| `Spacer` di kiri/kanan | Mengatur pembagian ruang kosong horizontal. |
| `SizedBox` | Memberikan jarak 8, 20, 24, atau 32 dan mengatur lebar konten. |
| `Icon(Icons.error_outline_rounded)` | Simbol error putih ukuran 56. |
| `Text` + `TextStyle` | Judul putih ukuran 22/tebal 700 dan pesan putih transparan ukuran 14, keduanya rata tengah. |
| `FilledButton.icon` | Tombol Material berisi ikon refresh dan label “Coba lagi”. |
| `FilledButton.styleFrom` | Menetapkan latar tombol `AppColors.secondary` dan warna isi `AppColors.primary`. |

### Bedah kode dan alasan pemakaiannya

```dart
width: (constraints.maxWidth - 2 * (32)).clamp(
  0.0,
  double.infinity,
),
```

Lebar konten dikurangi 32 di kedua sisi. `clamp` mencegah perhitungan menjadi negatif jika ruang parent sangat kecil. `double.infinity` di sini adalah batas atas operasi pembatasan, bukan permintaan agar lebar konten menjadi tak terhingga.

```dart
FilledButton.icon(
  onPressed: onRetry,
  // ...
  icon: const Icon(Icons.refresh_rounded),
  label: const Text('Coba lagi'),
)
```

Menekan tombol menjalankan callback parent. Parent-lah yang menghapus error, mengembalikan progres ke nol, dan memulai loader. Dengan pemisahan ini, tampilan error tidak perlu mengetahui bagaimana aplikasi menyiapkan resource.

Dua literal string berurutan pada pesan error otomatis digabung Dart menjadi satu string. `Colors.white70` adalah putih dengan transparansi, sehingga teks penjelasan lebih redup daripada judul.

<a id="file-lib-pages-auth-auth-flow-dart"></a>

## `lib/pages/auth/auth_flow.dart`

[Buka sumber](../../lib/pages/auth/auth_flow.dart).

**Peran file:** merangkai navigasi login dan registrasi, sekaligus meneruskan gateway serta pembuat home yang sama ke dua halaman.

### Kode lengkap

<!-- SUMBER:lib/pages/auth/auth_flow.dart SHA256=2db48b5cc3871a04824fb2388a7ca1099e88ce5eeba93b68ac33f8f6aadfbaa9 -->

```dart
import 'package:flutter/material.dart';

import '../../services/auth_gateway.dart';
import 'login_page.dart';
import 'register_page.dart';

class AuthFlow extends StatelessWidget {
  const AuthFlow({
    super.key,
    required this.authGateway,
    required this.homeBuilder,
  });

  final AuthGateway authGateway;
  final WidgetBuilder homeBuilder;

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      authGateway: authGateway,
      homeBuilder: homeBuilder,
      onRegister: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (registerContext) => RegisterPage(
              authGateway: authGateway,
              homeBuilder: homeBuilder,
              onBack: () => Navigator.of(registerContext).pop(),
              onLogin: () => Navigator.of(registerContext).pop(),
            ),
          ),
        );
      },
    );
  }
}
```

### Class, tipe, dan pemanggilan yang digunakan

| Bagian | Kegunaan |
| --- | --- |
| `AuthFlow extends StatelessWidget` | Komponen penghubung; tidak menyimpan input form atau status submit sendiri. |
| `AuthGateway` | Antarmuka proses login, registrasi, dan logout yang disediakan dari luar. |
| `WidgetBuilder homeBuilder` | Fungsi yang menerima konteks dan menghasilkan widget home saat dibutuhkan. |
| `LoginPage` | Halaman pertama yang dikembalikan `build`. |
| `Navigator.push<void>` | Menambahkan rute registrasi di atas rute login; `void` menandakan tidak ada data hasil yang digunakan. |
| `MaterialPageRoute<void>` | Membuat rute halaman registrasi dengan transisi Material. |
| `RegisterPage` | Halaman yang menerima callback kembali ke login. |
| `Navigator.pop` | Mengeluarkan rute registrasi sehingga halaman login sebelumnya kembali terlihat. |

### Bedah kode dan alasan pemakaiannya

```dart
return LoginPage(
  authGateway: authGateway,
  homeBuilder: homeBuilder,
  onRegister: () {
    Navigator.of(context).push<void>(
      // rute RegisterPage
    );
  },
);
```

`onRegister` adalah fungsi yang diberikan kepada tombol “Daftarkeun” melalui beberapa komponen. Penulisannya `() { ... }` membuat callback; kode di dalamnya berjalan ketika callback dipanggil, bukan ketika `build` sedang menyusun widget.

```dart
builder: (registerContext) => RegisterPage(
  authGateway: authGateway,
  homeBuilder: homeBuilder,
  onBack: () => Navigator.of(registerContext).pop(),
  onLogin: () => Navigator.of(registerContext).pop(),
),
```

`registerContext` berasal dari builder rute registrasi. Kedua aksi di registrasi dipasangi perilaku sama: tutup registrasi. Login tetap berada di bawahnya dalam tumpukan rute. `AuthFlow` mengetahui hubungan antarhalaman, sehingga `AuthHeader` dan komponen field tidak perlu mengetahui susunan rute aplikasi.

<a id="file-lib-pages-auth-auth-page-layout-dart"></a>

## `lib/pages/auth/auth_page_layout.dart`

[Buka sumber](../../lib/pages/auth/auth_page_layout.dart).

**Peran file:** membuat kerangka responsif yang digunakan bersama oleh login dan registrasi. Pada layar portrait atau ruang sempit, header berada di atas form. Pada landscape yang cukup lebar, header dan form berdampingan.

### Kode lengkap

<!-- SUMBER:lib/pages/auth/auth_page_layout.dart SHA256=3aee2af4b893a3085f7e250c41d9b590b03ebe3dbbe0d77416e1b0757de503cb -->

```dart
import 'package:flutter/material.dart';

/// Keeps the introduction beside the form in landscape, with one scroll area.
class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.headerBuilder,
    required this.form,
    this.landscapeFormWidthFactor = 1,
  });

  final Widget Function(BuildContext context, double width) headerBuilder;
  final Widget form;
  final double landscapeFormWidthFactor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            size.width > size.height && constraints.maxWidth >= 600;
        final gap = constraints.maxWidth >= 800 ? 48.0 : 24.0;
        final contentWidth = (constraints.maxWidth - 48).clamp(
          0.0,
          sideBySide ? 960.0 : 327.0,
        );
        final columnWidth = sideBySide
            ? (contentWidth - gap) / 2
            : contentWidth;
        final header = headerBuilder(context, columnWidth);
        return SingleChildScrollView(
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
                          const Spacer(),
                          SizedBox(
                            width: contentWidth,
                            child: sideBySide
                                ? Row(
                                    children: [
                                      Expanded(child: header),
                                      SizedBox(width: gap),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width:
                                                  columnWidth *
                                                  landscapeFormWidthFactor,
                                              child: form,
                                            ),
                                            const Spacer(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      header,
                                      const SizedBox(height: 32),
                                      form,
                                    ],
                                  ),
                          ),
                          const Spacer(),
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
        );
      },
    );
  }
}
```

### Class, input, dan widget yang digunakan

| Bagian | Kegunaan |
| --- | --- |
| `AuthPageLayout extends StatelessWidget` | Menghitung susunan dari input dan ukuran tanpa menyimpan state lokal. |
| `headerBuilder` | Fungsi yang menerima konteks serta lebar kolom header; dibutuhkan agar `AuthPrompt` tahu ruang teksnya. |
| `Widget form` | Form dari halaman pemanggil; layout tidak mengetahui field apa saja di dalamnya. |
| `landscapeFormWidthFactor` | Pengali lebar form pada susunan berdampingan. Default `1`; login mengirim `0.9`. |
| `MediaQuery.sizeOf(context)` | Mengambil ukuran view dalam logical pixel untuk membandingkan orientasi lebar dan tinggi. |
| `LayoutBuilder` | Menyediakan batas ruang yang benar-benar diberikan parent, yang bisa berbeda dari ukuran seluruh view. |
| `SingleChildScrollView` | Membuat seluruh header dan form berada dalam satu area gulir. |
| `Column`, `Row` | Menentukan susunan vertikal atau horizontal. |
| `SizedBox` | Mengatur jarak dan lebar konten. |
| `ConstrainedBox` / `BoxConstraints` | Menentukan tinggi minimum isi agar tetap mengisi area yang tersedia. |
| `Spacer` | Mengisi ruang fleksibel untuk meletakkan konten di tengah baris. |
| `Expanded` | Membagi lebar baris landscape menjadi dua bagian dengan flex default yang sama. |

### Bedah kode dan alasan pemakaiannya

**1. Ukuran view dan constraint parent mempunyai tugas berbeda.**

```dart
final size = MediaQuery.sizeOf(context);
final sideBySide =
    size.width > size.height && constraints.maxWidth >= 600;
```

Syarat berdampingan harus memenuhi keduanya: view lebih lebar daripada tinggi, dan ruang parent minimal 600. Jadi, “landscape” saja belum cukup. Ini membantu form tetap vertikal jika ruang yang diberikan sempit.

**2. Lebar konten dibatasi supaya form tidak terlalu melebar.**

```dart
final gap = constraints.maxWidth >= 800 ? 48.0 : 24.0;
final contentWidth = (constraints.maxWidth - 48).clamp(
  0.0,
  sideBySide ? 960.0 : 327.0,
);
```

`? :` adalah operator ternary: pilih nilai berdasarkan kondisi. Ruang 48 dikurangi untuk menyisakan 24 pada tiap sisi. Lebar konten maksimal 327 untuk susunan vertikal, atau 960 untuk susunan berdampingan. Jarak antarbagian menjadi 48 saat ruang minimal 800, selebihnya 24.

```dart
final columnWidth = sideBySide
    ? (contentWidth - gap) / 2
    : contentWidth;
final header = headerBuilder(context, columnWidth);
```

Pada susunan berdampingan, jarak antarkolom dikurangi sebelum sisa lebar dibagi dua. Hasilnya diteruskan ke header agar pengukuran teks dilakukan untuk ruang kolomnya, bukan untuk seluruh layar.

**3. Tinggi minimum menjaga isi tetap mengisi ruang, tanpa memaksa tinggi maksimum.**

```dart
constraints: BoxConstraints(
  minHeight: (constraints.maxHeight - 48).clamp(
    0.0,
    double.infinity,
  ),
),
```

48 di sini mengakomodasi ruang atas dan bawah masing-masing 24. `minHeight` bukan tinggi tetap: bila isi lebih panjang, ia boleh bertambah tinggi dan dapat digulir. Ini penting untuk form saat ruang vertikal menyusut, termasuk ketika keyboard muncul sesuai perilaku `Scaffold` pemanggil.

**4. Hanya susunan dalam yang berganti.**

```dart
child: sideBySide
    ? Row(/* header dan form */)
    : Column(/* header, jarak 32, form */),
```

Pada landscape, `Expanded` memberi ruang kolom untuk header dan form. Form dibungkus `SizedBox` dengan lebar `columnWidth * landscapeFormWidthFactor`; pada login nilainya 90% dari kolom form. Pada portrait, header dan form disusun ke bawah dengan jarak 32. Kedua mode tetap berada di `SingleChildScrollView` yang sama.

`MainAxisSize.min` pada `Column` berarti kolom mengutamakan tinggi yang dibutuhkan anaknya; properti ini tidak mengukur tinggi layar. Ukuran akhir tetap mengikuti constraint parent.

<a id="file-lib-pages-auth-auth-prompt-dart"></a>

## `lib/pages/auth/auth_prompt.dart`

[Buka sumber](../../lib/pages/auth/auth_prompt.dart).

**Peran file:** menampilkan ajakan seperti “Belum punya akun? Daftarkeun”. Jika kalimat dan aksi cukup muat, keduanya sejajar. Jika tidak, aksi diletakkan pada baris berikutnya.

### Kode lengkap

<!-- SUMBER:lib/pages/auth/auth_prompt.dart SHA256=1949c5e32628ddb9f92b3fffad5cf8eecf41c452f3605bd7d03b09b9c6871517 -->

```dart
import 'package:flutter/material.dart';

class AuthPrompt extends StatelessWidget {
  const AuthPrompt({
    super.key,
    required this.message,
    required this.availableWidth,
    required this.action,
    required this.enabled,
    required this.onPressed,
  });

  final String message;
  final double availableWidth;
  final String action;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const messageStyle = TextStyle(
      color: Color(0xFFEEEEEE),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    const actionStyle = TextStyle(
      color: Color(0xFFFFD9BF),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    final messageText = Text(message, style: messageStyle);
    final actionButton = InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 4),
          Text(action, style: actionStyle),
          SizedBox(height: 4),
        ],
      ),
    );

    final measurement = TextPainter(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: message, style: messageStyle),
          TextSpan(text: action, style: actionStyle),
        ],
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final fits = measurement.width + 6 <= availableWidth;
    measurement.dispose();

    return fits
        ? Row(
            children: [
              const Spacer(),
              messageText,
              const SizedBox(width: 6),
              actionButton,
              const Spacer(),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [messageText, actionButton],
          );
  }
}
```

### Class dan widget yang digunakan

| Bagian | Kegunaan |
| --- | --- |
| `AuthPrompt extends StatelessWidget` | Menghitung susunan dari teks, lebar tersedia, dan status `enabled`. |
| `Text` / `TextStyle` | Teks pesan abu terang, aksi peach; ukuran keduanya 14 dengan ketebalan berbeda. |
| `InkWell` | Membuat teks aksi menerima ketukan dan memakai respons sentuhan Material. |
| `BorderRadius.circular(4)` | Membulatkan batas efek sentuhan aksi. |
| `Column(mainAxisSize: MainAxisSize.min)` | Membungkus aksi dengan jarak 4 di atas/bawah atau menyusun seluruh prompt vertikal. |
| `TextPainter` | Mengukur lebar teks dengan gaya, arah, dan skala teks yang diberikan. Ini objek pengukuran, bukan widget yang tampil. |
| `TextSpan` | Menyusun potongan teks bergaya untuk pengukuran. |
| `DefaultTextStyle.of(context)` | Mengambil gaya teks dasar dari ancestor. |
| `Directionality.of(context)` | Mengambil arah penulisan seperti kiri ke kanan dari konteks. |
| `MediaQuery.textScalerOf(context)` | Mengikutkan skala teks aksesibilitas dalam pengukuran. |
| `Row`, `Spacer`, `SizedBox(width: 6)` | Menyusun prompt satu baris, memusatkannya, dan memberi jarak antara pesan dengan aksi. |

### Bedah kode dan alasan pemakaiannya

**1. Callback dapat dinonaktifkan tanpa menghapus teks aksi.**

```dart
onTap: enabled ? onPressed : null,
```

Saat parent sedang submit, `enabled` bernilai `false`, sehingga aksi tidak menjalankan callback. `VoidCallback?` berarti callback boleh `null`; pemanggil dapat menampilkan prompt tanpa perilaku ketukan.

**2. Yang diukur adalah teks, bukan tinggi layar.**

```dart
final measurement = TextPainter(
  text: TextSpan(
    style: DefaultTextStyle.of(context).style,
    children: [
      TextSpan(text: message, style: messageStyle),
      TextSpan(text: action, style: actionStyle),
    ],
  ),
  textDirection: Directionality.of(context),
  textScaler: MediaQuery.textScalerOf(context),
)..layout();
final fits = measurement.width + 6 <= availableWidth;
measurement.dispose();
```

`layout()` meminta `TextPainter` menghitung tata letak teks. Lebarnya ditambah 6 untuk memperhitungkan jarak antarteks di `Row`. Pengukuran memakai text scaler agar keputusan susunan ikut mempertimbangkan ukuran huruf pilihan pengguna. Setelah lebarnya dibaca, `dispose()` membebaskan resource painter karena objek pengukur itu tidak lagi diperlukan.

**3. Keputusan pengukuran memilih satu dari dua pohon widget.**

```dart
return fits
    ? Row(/* pesan dan aksi sejajar */)
    : Column(
        mainAxisSize: MainAxisSize.min,
        children: [messageText, actionButton],
      );
```

Ini contoh responsivitas berdasarkan kebutuhan isi. Komponen tidak hanya memeriksa “HP atau desktop”, tetapi membandingkan panjang teks aktual dengan `availableWidth` dari layout. Pemisahan `AuthPrompt` juga membuat login dan registrasi memakai perilaku penyesuaian yang sama.

<a id="file-lib-pages-auth-widgets-auth-header-dart"></a>

## `lib/pages/auth/widgets/auth_header.dart`

[Buka sumber](../../lib/pages/auth/widgets/auth_header.dart).

**Peran file:** membuat identitas visual bagian atas autentikasi: logo, judul, prompt perpindahan halaman, dan tombol kembali opsional.

### Kode lengkap

<!-- SUMBER:lib/pages/auth/widgets/auth_header.dart SHA256=695961bc23213287c38ed7a55e41aa4ee03a480c9dbac7ceedfab4de231bf1e4 -->

```dart
import 'package:flutter/material.dart';

import '../auth_prompt.dart';

/// Branding dan perpindahan login/register; tombol kembali bersifat opsional.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.availableWidth,
    required this.enabled,
    required this.title,
    required this.message,
    required this.action,
    required this.onPromptPressed,
    this.onBack,
  });

  final double availableWidth;
  final bool enabled;
  final String title;
  final String message;
  final String action;
  final VoidCallback? onPromptPressed;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final branding = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(31),
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: 124,
            height: 124,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEEEEEE),
            fontSize: 32,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.64,
          ),
        ),
        const SizedBox(height: 12),
        AuthPrompt(
          availableWidth: availableWidth,
          message: message,
          action: action,
          enabled: enabled,
          onPressed: onPromptPressed,
        ),
      ],
    );

    if (onBack == null) return branding;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Kembali ke login',
              onPressed: enabled ? onBack : null,
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              color: const Color(0xFFEEEEEE),
              icon: const Icon(Icons.arrow_back, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 32),
        branding,
      ],
    );
  }
}
```

### Class, input, dan widget yang digunakan

`AuthHeader` adalah `StatelessWidget`. Ia menerima `availableWidth`, `enabled`, teks `title/message/action`, callback `onPromptPressed`, dan `onBack` opsional. Semua keputusan halaman tetap dikirim dari parent.

| Widget/properti | Kegunaan |
| --- | --- |
| `Column(mainAxisSize: MainAxisSize.min)` | Menyusun branding sesuai tinggi isi. |
| `ClipRRect` | Memotong gambar menjadi persegi dengan sudut membulat radius 31. |
| `Image.asset(width: 124, height: 124, fit: BoxFit.cover)` | Menampilkan ikon aplikasi dalam area 124 × 124. |
| `SizedBox(height: 16/12/32)` | Jarak logo–judul, judul–prompt, dan tombol kembali–branding. |
| `Text(textAlign: TextAlign.center)` | Memusatkan teks judul dalam kotak teks. |
| `TextStyle` | Warna `0xFFEEEEEE`, font 32, tebal 700, tinggi baris relatif `1.3`, jarak antarhuruf `-0.64`. |
| `AuthPrompt` | Menampilkan pesan/aksi yang menyesuaikan lebar. |
| `Row` + `IconButton` | Menaruh tombol kembali pada awal baris, jika diperlukan. |
| `BoxConstraints.tightFor(width: 24, height: 24)` | Meminta constraint ketat 24 × 24 untuk tombol sesuai kode ini. |
| `Icon(Icons.arrow_back, size: 24)` | Gambar panah kembali. |
| `tooltip` | Label bantuan “Kembali ke login” pada tombol. |

### Bedah kode dan alasan pemakaiannya

```dart
final branding = Column(
  // logo, judul, AuthPrompt
);
if (onBack == null) return branding;
```

`branding` adalah variabel lokal berisi widget, bukan halaman lain. Bila `onBack` tidak disediakan, seperti pada login, hasilnya hanya branding. Bila callback tersedia, seperti pada registrasi, hasilnya kolom tambahan yang berisi tombol kembali, jarak, lalu branding. Pola ini menghindari menulis logo dan judul dua kali.

```dart
onPressed: enabled ? onBack : null,
```

Tombol kembali yang tampak di header dinonaktifkan saat submit. Di sisi halaman registrasi, `_backToLogin` juga memeriksa `_isSubmitting`, sehingga callback kembali memiliki pemeriksaan sendiri. Ini menjelaskan dua lapis pengendalian yang memang ada pada kode, bukan jaminan bahwa semua jenis navigasi sistem dicegah.

Warna literal `Color(0xFFEEEEEE)` memakai format ARGB: `FF` menunjukkan alpha penuh, lalu `EE`, `EE`, `EE` adalah komponen merah, hijau, biru. Warna ini dan warna prompt ditentukan langsung pada komponen, sedangkan latar halaman memakai `AppColors.primary`.

<a id="file-lib-pages-auth-widgets-login-fields-dart"></a>

## `lib/pages/auth/widgets/login_fields.dart`

[Buka sumber](../../lib/pages/auth/widgets/login_fields.dart).

**Peran file:** menyusun dua field login beserta ikon dan kontrol tampil/sembunyikan password. Nilai controller, validator, dan callback seluruhnya dikirim dari `LoginPage`.

### Kode lengkap

<!-- SUMBER:lib/pages/auth/widgets/login_fields.dart SHA256=8b08d7be5979a6d05f6fe314132ae49465d564b04bccc8c11bbd406ab209584e -->

```dart
import 'package:flutter/material.dart';

class LoginFields extends StatelessWidget {
  const LoginFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.enabled,
    required this.validateEmail,
    required this.validatePassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool enabled;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide.none,
    );

    return Column(
      children: [
        TextFormField(
          key: const Key('login_email_field'),
          controller: emailController,
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: validateEmail,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Email',
            prefixIcon: Icon(Icons.mail_outline_rounded),
            border: border,
            enabledBorder: border,
            focusedBorder: border,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('login_password_field'),
          controller: passwordController,
          enabled: enabled,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: validatePassword,
          onFieldSubmitted: enabled ? (_) => onSubmit() : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Kata Sandi',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: obscurePassword
                  ? 'Tampilkan kata sandi'
                  : 'Sembunyikan kata sandi',
              onPressed: enabled ? onTogglePassword : null,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border,
          ),
        ),
      ],
    );
  }
}
```

### Class, tipe, dan widget yang digunakan

| Bagian | Kegunaan |
| --- | --- |
| `LoginFields extends StatelessWidget` | Komponen field yang tidak memiliki state/controller sendiri. |
| `TextEditingController` | Menghubungkan field dengan teks yang dibaca/dikelola parent. |
| `FormFieldValidator<String>` | Fungsi validator input: kembalikan pesan jika tidak valid, atau `null` jika valid. |
| `VoidCallback` | Callback toggle password dan submit. |
| `Column` + `SizedBox(height: 8)` | Menyusun field email dan password dengan jarak 8. |
| `TextFormField` | Field yang menjadi bagian dari `Form` dan mendukung validator. |
| `Key` | Identitas field bernama `login_email_field` dan `login_password_field`. |
| `InputDecoration` | Mengatur isian latar, placeholder, ikon awal/akhir, dan border field. |
| `OutlineInputBorder` | Bentuk batas field, dengan radius 10 dan garis `BorderSide.none`. |
| `Icon` / `IconButton` | Ikon email, gembok, dan tombol visibilitas password. |

### Bedah kode dan alasan pemakaiannya

**1. Border yang sama dipakai dalam beberapa keadaan.**

```dart
const border = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide.none,
);
```

`border`, `enabledBorder`, dan `focusedBorder` pada dekorasi semuanya diisi objek ini. Maka bentuk field normal dan fokus memakai sudut yang sama tanpa garis tepi. Field menggunakan `filled: true` dan `fillColor: Colors.white`; bentuknya tetap terlihat karena latar putih, bukan karena outline. Border khusus error tidak ditentukan dalam file ini.

**2. Field email mempunyai pengaturan input yang sesuai.**

```dart
keyboardType: TextInputType.emailAddress,
textInputAction: TextInputAction.next,
autofillHints: const [AutofillHints.email],
validator: validateEmail,
```

`keyboardType` meminta keyboard yang sesuai email pada platform yang mendukungnya; ia tidak memvalidasi email. `textInputAction.next` menyatakan aksi lanjut pada keyboard. `autofillHints` memberi petunjuk kepada fasilitas isi otomatis sistem. Pemeriksaan isi tetap berasal dari `validateEmail` milik halaman.

**3. Field password membaca state parent.**

```dart
obscureText: obscurePassword,
textInputAction: TextInputAction.done,
autofillHints: const [AutofillHints.password],
onFieldSubmitted: enabled ? (_) => onSubmit() : null,
```

`obscureText` menyamarkan tampilan karakter; ini bukan enkripsi atau pengamanan data ke server. Menekan aksi selesai pada keyboard dapat memanggil submit ketika `enabled` benar. Parameter `_` menandakan teks hasil submit field diterima callback tetapi tidak digunakan, karena halaman membaca controller.

**4. Tombol mata hanya mengirim niat mengubah keadaan.**

```dart
onPressed: enabled ? onTogglePassword : null,
icon: Icon(
  obscurePassword
      ? Icons.visibility_off_outlined
      : Icons.visibility_outlined,
),
```

`LoginFields` tidak membalik variabel sendiri. Ia memanggil `onTogglePassword`; parent membalik boolean dalam `setState`, lalu mengirim nilai terbaru pada rebuild. `tooltip` juga berubah antara “Tampilkan kata sandi” dan “Sembunyikan kata sandi”.

`enabled` diteruskan ke kedua `TextFormField` agar input tidak dapat diedit saat submit. Controller tidak di-`dispose` di file ini karena pemiliknya adalah `LoginPage`.

<a id="file-lib-pages-auth-widgets-register-fields-dart"></a>

## `lib/pages/auth/widgets/register_fields.dart`

[Buka sumber](../../lib/pages/auth/widgets/register_fields.dart).

**Peran file:** menyusun field nama, email, dan password registrasi. Polanya mirip `LoginFields`, tetapi menambahkan input nama dan petunjuk password baru.

### Kode lengkap

<!-- SUMBER:lib/pages/auth/widgets/register_fields.dart SHA256=cced9cf9adb8c7174b868f463ac0c434b750cc7b1980ea4c7d4e54de899b442c -->

```dart
import 'package:flutter/material.dart';

class RegisterFields extends StatelessWidget {
  const RegisterFields({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.enabled,
    required this.validateName,
    required this.validateEmail,
    required this.validatePassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool enabled;
  final FormFieldValidator<String> validateName;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide.none,
    );
    const decoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
    );

    return Column(
      children: [
        TextFormField(
          key: const Key('register_name_field'),
          controller: nameController,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          validator: validateName,
          decoration: decoration.copyWith(
            hintText: 'Nama',
            prefixIcon: const Icon(Icons.account_circle_outlined),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('register_email_field'),
          controller: emailController,
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: validateEmail,
          decoration: decoration.copyWith(
            hintText: 'Email',
            prefixIcon: const Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('register_password_field'),
          controller: passwordController,
          enabled: enabled,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          validator: validatePassword,
          onFieldSubmitted: enabled ? (_) => onSubmit() : null,
          decoration: decoration.copyWith(
            hintText: 'Kata Sandi',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: obscurePassword
                  ? 'Tampilkan kata sandi'
                  : 'Sembunyikan kata sandi',
              onPressed: enabled ? onTogglePassword : null,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

### Class dan widget yang digunakan

`RegisterFields` adalah `StatelessWidget` dengan tiga `TextEditingController`, tiga `FormFieldValidator<String>`, dua boolean (`enabled`, `obscurePassword`), serta callback toggle dan submit. Komponen menggunakan `Column`, `TextFormField`, `SizedBox`, `InputDecoration`, `OutlineInputBorder`, `BorderRadius`, `Radius`, `BorderSide`, `Icon`, `IconButton`, dan `Key` seperti pola field login.

### Bedah kode dan alasan pemakaiannya

**1. Dekorasi dasar dibagi agar tiga field konsisten.**

```dart
const decoration = InputDecoration(
  filled: true,
  fillColor: Colors.white,
  border: border,
  enabledBorder: border,
  focusedBorder: border,
);
```

Ketiga field berbagi latar putih, sudut radius 10, dan batas tanpa garis. Perbedaannya ditambahkan menggunakan `copyWith`:

```dart
decoration: decoration.copyWith(
  hintText: 'Nama',
  prefixIcon: const Icon(Icons.account_circle_outlined),
),
```

`copyWith` membuat dekorasi baru dengan beberapa properti diganti; objek dasar tidak dimodifikasi. Dari bentuk kode ini dapat disimpulkan bahwa tujuannya menghindari pengulangan konfigurasi visual antarfield.

**2. Field nama mengarahkan perilaku keyboard dan isi otomatis.**

```dart
textCapitalization: TextCapitalization.words,
textInputAction: TextInputAction.next,
autofillHints: const [AutofillHints.name],
validator: validateName,
```

`TextCapitalization.words` meminta kapitalisasi awal kata pada keyboard yang mendukungnya, bukan memaksa semua nilai menjadi format nama tertentu. Validator tetap berasal dari parent. Key field ini adalah `register_name_field`.

**3. Email dan password punya perbedaan makna isi otomatis.**

Field email memakai `TextInputType.emailAddress`, aksi `next`, dan `AutofillHints.email`. Password memakai `obscureText`, aksi `done`, dan `AutofillHints.newPassword` karena ini pembuatan akun, bukan pengisian password akun yang sudah ada. Key-nya masing-masing `register_email_field` dan `register_password_field`.

`onFieldSubmitted` password memanggil `onSubmit` jika enabled. `suffixIcon` berisi `IconButton` yang mengirim callback toggle password. Semua field menerima `enabled`; jarak antarnya 8. `prefixIcon` dipakai untuk akun, email, dan gembok, sedangkan `suffixIcon` khusus kontrol visibilitas.

Controller dan boolean tidak dimiliki file ini. `RegisterPage` memiliki, mengubah, serta membersihkannya, sehingga komponen field tetap hanya mengurus tampilan dan penerusan interaksi.

<a id="file-lib-pages-auth-widgets-auth-submit-button-dart"></a>

## `lib/pages/auth/widgets/auth_submit_button.dart`

[Buka sumber](../../lib/pages/auth/widgets/auth_submit_button.dart).

**Peran file:** menampung dua komponen kecil yang dipakai login dan registrasi: tombol submit/loading dan teks error submit.

### Kode lengkap

<!-- SUMBER:lib/pages/auth/widgets/auth_submit_button.dart SHA256=7135ace32c5199a50ef2c4f76956380499dd45f86880c05e6e45b88e219a7201 -->

```dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.fontSize,
    required this.isSubmitting,
    required this.onSubmit,
  });
  final String label;
  final double fontSize;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: isSubmitting ? null : onSubmit,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFD9BF),
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: const Color(0x99FFD9BF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isSubmitting
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class AuthSubmitError extends StatelessWidget {
  const AuthSubmitError({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFFFD9BF)),
      ),
    );
  }
}
```

### Class dan widget yang digunakan

| Bagian | Kegunaan |
| --- | --- |
| `AuthSubmitButton extends StatelessWidget` | Menerima label, ukuran font, status submit, dan callback. |
| `AuthSubmitError extends StatelessWidget` | Menerima pesan error yang ditampilkan parent. |
| `SizedBox(width: double.infinity, height: 48)` | Meminta tombol memenuhi lebar yang disediakan parent dengan tinggi 48. |
| `FilledButton` | Tombol Material untuk aksi utama. |
| `FilledButton.styleFrom` | Menetapkan warna normal/nonaktif dan bentuk tombol. |
| `RoundedRectangleBorder` + `BorderRadius.circular(10)` | Sudut tombol membulat radius 10. |
| `SizedBox.square(dimension: 22)` | Membatasi ukuran indikator loading 22 × 22. |
| `CircularProgressIndicator` | Spinner tak tentu karena tidak diberi `value`. |
| `Text` / `TextStyle` | Label tombol tebal 700 atau pesan error rata tengah. |
| `Semantics(liveRegion: true)` | Menandai pesan error agar pembaca layar dapat mengumumkan perubahannya. |

### Bedah kode dan alasan pemakaiannya

```dart
onPressed: isSubmitting ? null : onSubmit,
```

Callback `null` membuat tombol nonaktif menurut mekanisme `FilledButton`. Ini mencegah ketukan submit berikutnya melalui tombol saat proses masih berjalan. Halaman juga memiliki guard `_isSubmitting`, sehingga pengecekan tidak hanya bergantung pada tampilan tombol.

```dart
child: isSubmitting
    ? const SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primary,
        ),
      )
    : Text(label, /* gaya */),
```

Tombol tetap menempati kotak yang sama; isinya berganti label atau spinner. `strokeWidth` mengatur tebal garis indikator. Karena `value` tidak diberikan, spinner hanya menunjukkan bahwa proses berlangsung, bukan persentase login.

Latar tombol normal `0xFFFFD9BF` berwarna peach dengan alpha penuh. `disabledBackgroundColor: Color(0x99FFD9BF)` menggunakan alpha `99` untuk tampilan lebih transparan saat nonaktif. `foregroundColor: AppColors.primary` menentukan warna isi tombol; `fontSize` dikirim pemanggil, yakni 16 untuk login dan 14 untuk registrasi.

`AuthSubmitError` menampilkan `message` dengan warna peach dan `TextAlign.center`. Komponen ini tidak memutuskan kapan error muncul. Halaman menggunakan `if (_submitError != null)` untuk memasukkannya ke dalam pohon UI hanya ketika ada error.

<a id="file-lib-pages-auth-login-page-dart"></a>

## `lib/pages/auth/login_page.dart`

[Buka sumber](../../lib/pages/auth/login_page.dart).

**Peran file:** memiliki state login, menjalankan validasi dan submit, menampilkan error/loading, serta menuju home saat gateway selesai tanpa error. Komponen visual yang lebih kecil dipanggil dari sini.

### Kode lengkap

<!-- SUMBER:lib/pages/auth/login_page.dart SHA256=fa454e1f9acf0822be61c2fc5a6db59b13f22535447902b2bfe289e3e5586cf8 -->

```dart
import 'package:flutter/material.dart';

import '../../services/auth_gateway.dart';
import '../../theme/app_colors.dart';
import 'auth_page_layout.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/login_fields.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authGateway,
    required this.homeBuilder,
    this.onRegister,
  });

  final AuthGateway authGateway;
  final WidgetBuilder homeBuilder;
  final VoidCallback? onRegister;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await widget.authGateway.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: widget.homeBuilder),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitError = 'Login gagal. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi';

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Kata sandi wajib diisi';
    if (value.length < 8) return 'Kata sandi minimal 8 karakter';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: AuthPageLayout(
          landscapeFormWidthFactor: 0.9,
          headerBuilder: (context, headerWidth) => AuthHeader(
            availableWidth: headerWidth,
            enabled: !_isSubmitting,
            title: 'Loginkeun Kawan!',
            message: 'Belum punya akun?',
            action: 'Daftarkeun',
            onPromptPressed: widget.onRegister,
          ),
          form: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoginFields(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  enabled: !_isSubmitting,
                  validateEmail: _validateEmail,
                  validatePassword: _validatePassword,
                  onTogglePassword: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  onSubmit: _submit,
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  AuthSubmitError(message: _submitError!),
                ],
                const SizedBox(height: 24),
                AuthSubmitButton(
                  label: 'Log In',
                  fontSize: 16,
                  isSubmitting: _isSubmitting,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### Class, state, dan komponen yang digunakan

| Bagian | Kegunaan |
| --- | --- |
| `LoginPage extends StatefulWidget` | Menampung konfigurasi `authGateway`, `homeBuilder`, dan `onRegister` opsional. |
| `_LoginPageState extends State<LoginPage>` | Memiliki state yang berubah karena input, toggle, dan hasil proses asynchronous. |
| `GlobalKey<FormState>` | Memberi akses ke state `Form` agar seluruh field dapat divalidasi bersama. |
| Dua `TextEditingController` | Menyimpan/membaca email dan password. |
| `_obscurePassword` | Awalnya `true`; mengatur penyamaran karakter password. |
| `_isSubmitting` | Awalnya `false`; mengatur guard submit, spinner, dan status enabled. |
| `String? _submitError` | Menampung pesan error proses; `null` berarti tidak ada pesan yang ditampilkan. |
| `Scaffold`, `SafeArea` | Kerangka halaman dan ruang aman terhadap UI sistem. |
| `AuthPageLayout` | Tata letak responsif; login memakai faktor lebar form landscape `0.9`. |
| `AuthHeader` | Logo, judul, dan ajakan ke registrasi. |
| `Form`, `Column` | Kelompok field yang dapat divalidasi bersama dan susunan vertikal. |
| `LoginFields` | Input email/password serta tombol visibilitas. |
| `AuthSubmitError`, `AuthSubmitButton` | Pesan error dan tombol yang berubah menjadi spinner. |
| `Navigator` / `MaterialPageRoute` | Navigasi ke home setelah pemanggilan gateway berhasil. |
| `RegExp` | Pemeriksaan pola email sederhana, bukan widget. |

### Bedah kode dan alasan pemakaiannya

**1. Controller dibuat pada state dan dibersihkan saat state berakhir.**

```dart
final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
```

Ketiganya menjadi field pada objek state, sehingga tidak dibuat ulang setiap `build`. Jika controller dibuat ulang di `build`, mempertahankan input pengguna menjadi sulit. Dalam implementasi ini, `dispose` membersihkan kedua controller lalu memanggil `super.dispose()`. Controller menghubungkan perubahan isi field dan pembacaan/perubahan teks dari kode; pemiliknya perlu membersihkannya ketika selesai digunakan, sesuai [dokumentasi `TextEditingController`](https://api.flutter.dev/flutter/widgets/TextEditingController-class.html).

**2. Guard mencegah submit ganda dan input belum valid.**

```dart
if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
  return;
}
```

Urutan membacanya:

1. Jika sudah submit, langsung berhenti; `||` melakukan short-circuit.
2. Jika belum, ambil state `Form` melalui key dan jalankan `validate()`.
3. `?.` berarti pemanggilan aman jika state belum tersedia; hasilnya bisa `null`.
4. `?? false` menganggap form tidak valid bila state belum tersedia.
5. `!` membalik hasil untuk menentukan kapan harus berhenti.

`validate()` menjalankan validator field di bawah `Form` dan meminta pesan validasi ditampilkan bila perlu. Ini berbeda dari `_submitError`, yang merupakan error dari proses gateway setelah validasi lokal lolos.

**3. UI masuk ke keadaan submit sebelum menunggu gateway.**

```dart
setState(() {
  _isSubmitting = true;
  _submitError = null;
});

await widget.authGateway.login(
  email: _emailController.text.trim(),
  password: _passwordController.text,
);
```

`setState` menghapus pesan error lama dan memicu rebuild: field serta prompt dinonaktifkan, tombol menampilkan spinner. Email di-`trim` untuk menghapus spasi di awal/akhir. Password dikirim apa adanya; spasi mungkin merupakan bagian password.

`AuthGateway` adalah dependency yang dikirim dari luar. Halaman mengurus kapan pemanggilan dilakukan dan bagaimana hasilnya memengaruhi UI. Ia tidak berisi implementasi request HTTP atau pemeriksaan akun server.

**4. Hasil sukses dan error mempunyai jalur berbeda.**

```dart
if (!mounted) return;
Navigator.of(context).pushAndRemoveUntil<void>(
  MaterialPageRoute<void>(builder: widget.homeBuilder),
  (_) => false,
);
```

`mounted` diperiksa sesudah `await` karena selama menunggu, halaman mungkin sudah dilepas. `pushAndRemoveUntil` menambahkan home dan membuang rute sebelumnya sampai predicate bernilai benar. Karena predicate selalu `false`, semua rute sebelumnya dibuang. Dari home, tombol kembali tidak membuka form login lama melalui riwayat tersebut.

```dart
} catch (_) {
  if (!mounted) return;
  setState(() {
    _submitError = 'Login gagal. Silakan coba lagi.';
  });
} finally {
  if (mounted) {
    setState(() {
      _isSubmitting = false;
    });
  }
}
```

`catch` menangkap error proses dan menampilkan pesan umum. `finally` menjalankan pembersihan status sesudah jalur berhasil atau gagal, selama widget masih ada. Pesan validasi email/password dan pesan kegagalan gateway berada pada lapisan yang berbeda.

**5. Validator mengembalikan `null` ketika input diterima.**

```dart
final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
if (!emailPattern.hasMatch(email)) return 'Format email tidak valid';
return null;
```

Email harus tidak kosong setelah `trim`, lalu sesuai pola sederhana: bagian sebelum `@`, bagian sesudahnya, titik, dan bagian akhir, tanpa spasi atau tambahan `@`. Huruf `r` membuat raw string sehingga backslash pada regex ditulis langsung. `^` dan `$` membatasi pencocokan dari awal sampai akhir. Ini pemeriksaan bentuk dasar; tidak membuktikan alamat email ada atau milik pengguna.

Password wajib diisi dan panjangnya minimal 8. Panjang di sini dihitung menggunakan `String.length` sesuai kode. Validator login tidak memeriksa apakah password cocok dengan akun server.

**6. `build` merangkai tampilan dan meneruskan state ke child.**

```dart
onTogglePassword: () {
  setState(() {
    _obscurePassword = !_obscurePassword;
  });
},
```

Menekan tombol mata memanggil callback ini. Boolean dibalik, lalu `LoginFields` dibangun lagi dengan `obscurePassword` terbaru. Field tidak perlu memiliki state duplikat.

```dart
if (_submitError != null) ...[
  const SizedBox(height: 12),
  AuthSubmitError(message: _submitError!),
],
```

Ini gabungan collection `if` dan spread `...`: jika ada pesan, dua widget dimasukkan ke daftar `children`. Tanda `!` setelah `_submitError` menyatakan nilainya tidak null pada titik tersebut; pemeriksaan sebelumnya mendukung asumsi ini. Jarak sebelum tombol tetap 24.

Header menerima `enabled: !_isSubmitting` dan `onPromptPressed: widget.onRegister`. Jadi, rute registrasi dipilih oleh `AuthFlow`, sementara halaman login cukup meneruskan aksi. Latar halaman menggunakan `AppColors.primary`, sedangkan `SafeArea` membungkus kerangka responsif.

<a id="file-lib-pages-auth-register-page-dart"></a>

## `lib/pages/auth/register_page.dart`

[Buka sumber](../../lib/pages/auth/register_page.dart).

**Peran file:** mengatur form registrasi tiga field, validasi, status submit/error, kontrol password, dan aksi kembali ke login. Sukses gateway saat ini membawa pengguna langsung ke home.

### Kode lengkap

<!-- SUMBER:lib/pages/auth/register_page.dart SHA256=9f858c4b42e5287c5e293bb4d1dadd670be0daa08d5ba605abae9b1c8719516c -->

```dart
import 'package:flutter/material.dart';

import '../../services/auth_gateway.dart';
import '../../theme/app_colors.dart';
import 'auth_page_layout.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/register_fields.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.authGateway,
    required this.homeBuilder,
    this.onBack,
    this.onLogin,
  });

  final AuthGateway authGateway;
  final WidgetBuilder homeBuilder;
  final VoidCallback? onBack;
  final VoidCallback? onLogin;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _backToLogin() {
    if (_isSubmitting) return;

    final callback = widget.onLogin ?? widget.onBack;
    if (callback != null) {
      callback();
      return;
    }

    Navigator.of(context).maybePop();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await widget.authGateway.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: widget.homeBuilder),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitError = 'Registrasi gagal. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Nama wajib diisi';
    if (name.length > 100) return 'Nama maksimal 100 karakter';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi';

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Kata sandi wajib diisi';
    if (value.length < 8) return 'Kata sandi minimal 8 karakter';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: AuthPageLayout(
          headerBuilder: (context, headerWidth) => AuthHeader(
            availableWidth: headerWidth,
            enabled: !_isSubmitting,
            title: 'Gaskeun buat akun!',
            message: 'Sudah punya akunnye?',
            action: 'Loginkeun',
            onPromptPressed: _backToLogin,
            onBack: _backToLogin,
          ),
          form: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RegisterFields(
                  nameController: _nameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  enabled: !_isSubmitting,
                  validateName: _validateName,
                  validateEmail: _validateEmail,
                  validatePassword: _validatePassword,
                  onTogglePassword: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  onSubmit: _submit,
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  AuthSubmitError(message: _submitError!),
                ],
                const SizedBox(height: 24),
                AuthSubmitButton(
                  label: 'Register',
                  fontSize: 14,
                  isSubmitting: _isSubmitting,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### Class, state, dan komponen yang digunakan

`RegisterPage` adalah `StatefulWidget` dengan `authGateway`, `homeBuilder`, serta callback opsional `onBack` dan `onLogin`. `_RegisterPageState` memakai `GlobalKey<FormState>`, tiga `TextEditingController`, `_obscurePassword`, `_isSubmitting`, dan `_submitError`. State bertambah satu controller nama dibanding halaman login.

Pohon UI menggunakan `Scaffold`, `SafeArea`, `AuthPageLayout`, `AuthHeader`, `Form`, `Column`, `RegisterFields`, `SizedBox`, `AuthSubmitError`, dan `AuthSubmitButton`. Alur asynchronous menggunakan `Future<void>`, `try/catch/finally`, `mounted`, `Navigator`, serta `MaterialPageRoute<void>`. Validasi email memakai `RegExp` yang sama dengan login.

### Bedah kode dan alasan pemakaiannya

**1. `_backToLogin` menyatukan dua aksi kembali yang terlihat di UI.**

```dart
void _backToLogin() {
  if (_isSubmitting) return;

  final callback = widget.onLogin ?? widget.onBack;
  if (callback != null) {
    callback();
    return;
  }

  Navigator.of(context).maybePop();
}
```

Jika masih submit, fungsi berhenti. `??` memilih `onLogin` jika ada; jika tidak, gunakan `onBack`. Bila callback tersedia, parent yang mengatur navigasi. Jika keduanya tidak tersedia, `maybePop()` meminta navigator menutup rute jika mekanisme rute mengizinkannya. Ini fallback bagi pemakaian `RegisterPage` di luar `AuthFlow`.

Baik tombol panah maupun teks “Loginkeun” pada header menerima `_backToLogin`, sehingga keduanya mengikuti aturan yang sama. Kode ini tidak memasang `PopScope` untuk memblokir semua aksi kembali dari sistem.

**2. Submit mengikuti pola login, dengan tambahan nama.**

```dart
await widget.authGateway.register(
  name: _nameController.text.trim(),
  email: _emailController.text.trim(),
  password: _passwordController.text,
);
```

Guard `_isSubmitting` dan validasi form berjalan lebih dahulu. `setState` mengaktifkan loading dan menghapus error lama. Nama serta email di-`trim`, sedangkan password dipertahankan. Bila gateway selesai tanpa error dan state masih mounted, `pushAndRemoveUntil` membuka home dengan predicate `(_) => false` untuk menghapus riwayat rute sebelumnya.

Saat error, pesan menjadi “Registrasi gagal. Silakan coba lagi.” `finally` memulihkan status submit jika state masih ada. Perilaku ini mendukung feedback UI, tetapi dengan gateway simulasi belum membuktikan akun benar-benar dibuat. Alur file ini juga belum menyisipkan halaman verifikasi email sebelum home.

**3. Validator nama memiliki batas yang berbeda dari email dan password.**

```dart
final name = value?.trim() ?? '';
if (name.isEmpty) return 'Nama wajib diisi';
if (name.length > 100) return 'Nama maksimal 100 karakter';
return null;
```

Nilai `null` diperlakukan sebagai string kosong. Nama berisi spasi saja juga tidak diterima sesudah `trim`. Batas panjangnya 100 menurut `String.length` pada kode. Tidak ada aturan format huruf tertentu atau minimal lebih dari satu kata dalam validator ini.

Email wajib diisi dan sesuai regex sederhana yang sama dengan login. Password wajib diisi dan minimal 8. Ketiga fungsi mengembalikan pesan sebagai `String` bila gagal atau `null` bila lolos. `Form.validate()` mengumpulkan hasil ketiganya.

**4. `build` memakai komponen bersama, dengan konfigurasi registrasi.**

```dart
AuthHeader(
  availableWidth: headerWidth,
  enabled: !_isSubmitting,
  title: 'Gaskeun buat akun!',
  message: 'Sudah punya akunnye?',
  action: 'Loginkeun',
  onPromptPressed: _backToLogin,
  onBack: _backToLogin,
)
```

Adanya `onBack` membuat `AuthHeader` menyertakan tombol panah. `AuthPageLayout` tidak diberi `landscapeFormWidthFactor`, sehingga memakai default `1`. `RegisterFields` menerima semua controller, validator, status enabled, dan callback toggle. Callback toggle membalik `_obscurePassword` dalam `setState` seperti login.

Pesan error disisipkan dengan collection `if` dan spread, lalu tombol memakai label `Register` serta font 14. Saat submit, komponen tombol menampilkan spinner dan field dinonaktifkan. `dispose` membersihkan ketiga controller; komponen child tidak membersihkannya karena halaman ini yang membuat dan memilikinya.

### Cara menelusuri satu interaksi sampai selesai

Untuk mengecek pemahaman, ikuti urutan ini pada kode lengkap:

1. Pengguna mengetik nama → `TextFormField` di `RegisterFields` memperbarui `nameController` yang berasal dari halaman.
2. Pengguna menekan `Register` → `AuthSubmitButton` memanggil `_submit` melalui callback.
3. `_submit` menjalankan `Form.validate()` → masing-masing validator dipanggil melalui `RegisterFields`.
4. Jika valid, `_isSubmitting = true` → rebuild menonaktifkan input/aksi header dan mengganti label tombol menjadi spinner.
5. Halaman menunggu `authGateway.register(...)` → implementasi gateway menentukan pekerjaan autentikasinya.
6. Jika berhasil, navigator membuka home dan membuang rute lama. Jika gagal, halaman menampilkan `AuthSubmitError` dan mengaktifkan kembali form.

Pola yang sama juga berlaku pada login. Bedanya, login memiliki dua field dan memanggil `authGateway.login`, sedangkan registrasi memiliki tiga field dan memanggil `authGateway.register`.
