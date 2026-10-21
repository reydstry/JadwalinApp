# Fondasi aplikasi dan tema

[Daftar isi](README.md) · [Dasar Flutter/Dart](00-dasar.md) · [Home](02-home.md)

Kedua file ini menjelaskan bagaimana aplikasi dimulai dan bagaimana warna bersama tersedia untuk halaman-halaman UI.

<a id="file-lib-main-dart"></a>

## `lib/main.dart`

[Buka sumber](../../lib/main.dart)

**Peran:** entry point aplikasi, penyusunan dependency awal, tema global, halaman splash, dan hubungan alur autentikasi dengan Home.

### Kode lengkap

<!-- SUMBER:lib/main.dart SHA256=3b3d7a4e0bc9c2c368558f6090a7448e3cbaff55897238a830c34a53f32c5f6c -->

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'database/database.dart';
import 'pages/auth/auth_flow.dart';
import 'pages/home/home.dart';
import 'pages/splash/splash_page.dart';
import 'services/app_bootstrapper.dart';
import 'services/auth_gateway.dart';
import 'services/notification_service.dart';

import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();

  runApp(MyApp(database: database));
}

class MyApp extends StatefulWidget {
  final AppDatabase database;
  final AppBootstrapper? bootstrapper;
  final AuthGateway? authGateway;

  const MyApp({
    super.key,
    required this.database,
    this.bootstrapper,
    this.authGateway,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppBootstrapper _bootstrapper;
  late final AuthGateway _authGateway;

  @override
  void initState() {
    super.initState();
    _authGateway = widget.authGateway ?? const SimulatedAuthGateway();
    _bootstrapper =
        widget.bootstrapper ??
        DefaultAppBootstrapper(
          database: widget.database,
          // Sesi persisten akan disambungkan bersama backend.
          hasStoredSession: () async => false,
          // Diganti dengan status koneksi pada milestone integrasi API.
          isOffline: () async => false,
          initializeNotifications: () async {
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
              await NotificationService.initialize();
            }
          },
        );
  }

  Widget _buildAuthFlow(BuildContext context) =>
      AuthFlow(authGateway: _authGateway, homeBuilder: _buildHome);

  Widget _buildHome(
    BuildContext context, {
    bool showOfflineEmptyState = false,
  }) => HomePage(
    database: widget.database,
    showOfflineEmptyState: showOfflineEmptyState,
    onLogout: () => _logout(context),
  );

  Future<void> _logout(BuildContext context) async {
    await _authGateway.logout();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: _buildAuthFlow),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jadwalin',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primary,
        ),
      ),
      home: SplashPage(
        load: _bootstrapper.load,
        destinationBuilder: (context, result) {
          return switch (result.destination) {
            AppLaunchDestination.login => _buildAuthFlow(context),
            AppLaunchDestination.home => _buildHome(
              context,
              showOfflineEmptyState: result.showOfflineEmptyState,
            ),
          };
        },
      ),
    );
  }
}
```

### Class, fungsi, dan objek yang dipakai

| Bagian | Fungsi dan alasan di file ini |
|---|---|
| `main`, `Future<void>`, `async` | Titik masuk program. Bentuk async tersedia walaupun kode saat ini tidak mempunyai await langsung di main. |
| `WidgetsFlutterBinding.ensureInitialized` | Memastikan binding Flutter siap sebelum dependency dibuat dan aplikasi dijalankan. |
| `AppDatabase` | Dependency penyimpanan lokal yang diteruskan ke aplikasi dan halaman yang memerlukannya. |
| `runApp` | Memasang widget akar `MyApp` ke Flutter. |
| `MyApp` / `_MyAppState` | Widget stateful dan state miliknya; menyiapkan bootstrapper/gateway sekali pada initState. |
| `AppBootstrapper` / `DefaultAppBootstrapper` | Kontrak dan implementasi pemuatan resource awal; hasilnya menentukan destinasi setelah splash. |
| `AuthGateway` / `SimulatedAuthGateway` | Kontrak operasi akun dan implementasi simulasi yang dipakai secara default. |
| `kIsWeb`, `defaultTargetPlatform`, `TargetPlatform.android` | Membatasi inisialisasi notifikasi untuk target Android di luar web. |
| `MaterialApp` | Akar konfigurasi aplikasi Material: judul, tema, navigator, dan halaman awal. |
| `ThemeData`, `ColorScheme.fromSeed`, `AppBarTheme` | Menentukan Material 3 dan warna global; app bar memakai latar serta foreground konsisten. |
| `AppColors` | Sumber warna proyek agar nilai yang sama tidak ditulis berulang. |
| `SplashPage` | Menampilkan pemuatan awal dan menerima fungsi load serta pembuat destinasi. |
| `AuthFlow` / `HomePage` | Cabang halaman setelah bootstrap/login. |
| `AppLaunchDestination` dan switch expression | Memetakan hasil bootstrap ke widget yang ditampilkan. |
| `Navigator`, `MaterialPageRoute<void>` | Menampilkan rute Material saat logout. Parameter `void` berarti rute ini tidak diharapkan mengembalikan hasil bertipe tertentu. |
| `BuildContext` / `context.mounted` | Menemukan navigator dan memastikan context masih valid setelah menunggu logout. |

### Membaca kode per bagian

1. **Import dan main:** API Flutter, database, halaman, dan service diambil. `AppDatabase` dibuat sekali di main, lalu diberikan melalui `MyApp(database: database)`. Ini membuat objek data yang digunakan halaman berasal dari sumber yang sama.
2. **Konfigurasi MyApp:** `database` wajib diisi. `bootstrapper` dan `authGateway` opsional; pembuat widget dapat memberikan implementasi lain. Kegunaan yang terlihat dari bentuk ini adalah dependency dapat diganti tanpa mengganti susunan UI.
3. **initState:** `widget.authGateway ?? const SimulatedAuthGateway()` memilih dependency yang diberikan atau fallback. Pola yang sama digunakan untuk bootstrapper. `late final` memungkinkan pengisian di initState dan mencegah pengisian ulang.
4. **Callback bootstrap:** `hasStoredSession` dan `isOffline` saat ini sama-sama mengembalikan `false`. Karena itu cabang sesi tersimpan/offline yang dimiliki model bootstrap belum otomatis menggambarkan pembacaan sesi/koneksi nyata pada wiring default aplikasi.
5. **Pembuat halaman:** `_buildAuthFlow` memasang gateway dan `homeBuilder`. `_buildHome` memasang database, flag empty state offline, dan callback logout. Pemusatan pembuat halaman menghindari perbedaan dependency pada beberapa jalur navigasi.
6. **Logout:** kode menunggu `_authGateway.logout()`, memeriksa context, lalu `pushAndRemoveUntil` dengan predicate `(_) => false`. Ini menghapus seluruh rute lama di bawah rute autentikasi sehingga tombol kembali tidak membuka Home dari stack tersebut.
7. **Tema:** `useMaterial3: true` memakai komponen Material 3. `ColorScheme.fromSeed` menghasilkan skema warna dari warna dasar dengan beberapa peran warna ditetapkan eksplisit. `scaffoldBackgroundColor` menjadi warna latar default Scaffold.
8. **Splash ke destinasi:** `load: _bootstrapper.load` memberikan fungsi, tidak menjalankannya saat argumen ditulis. `destinationBuilder` baru memutuskan login/Home berdasarkan hasil pemuatan yang diterimanya.

### Yang perlu dipahami dari alasan pemakaiannya

Dependency diberikan melalui constructor dan callback sehingga halaman tampilan tidak perlu memutuskan sendiri bagaimana semua service dibuat. Berdasarkan strukturnya, ini juga menyediakan titik penggantian untuk pengujian atau integrasi backend berikutnya.

`MaterialApp` mengatur default tema. Widget di halaman tetap bisa memakai `TextStyle` atau warna lokal yang menimpa sebagian default. Di file ini belum ada `fontFamily` global di `ThemeData`; deklarasi font pada pubspec membuat font tersedia, tetapi pemakaiannya tetap harus diminta oleh style/tema yang relevan.

**Batas perilaku sekarang:** operasi akun default masih simulasi; sesi persisten dan pemeriksaan koneksi default belum dihubungkan. Pergantian halaman yang berhasil bukan bukti login ke server. Lihat [service pendukung](06-pendukung-ui.md).

<a id="file-lib-theme-app-colors-dart"></a>

## `lib/theme/app_colors.dart`

[Buka sumber](../../lib/theme/app_colors.dart)

**Peran:** menyediakan enam warna sebagai konstanta class.

### Kode lengkap

<!-- SUMBER:lib/theme/app_colors.dart SHA256=2a639c2cf0c92c596dd3a1b7e97dd33ded5faa6aa5953588063e11aae9833e0f -->

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1E3A5F);
  static const Color secondary = Color(0xFFFF8A3D);
  static const Color peach = Color(0xFFFFD9BF);
  static const Color background = Color(0xFFFFF9F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFFCCCCCC);
}
```

### Yang dipakai dan alasan pemakaiannya

| Bagian | Penjelasan |
|---|---|
| `AppColors` | Class buatan proyek untuk mengelompokkan warna. Tidak memperluas Widget sehingga tidak menggambar apa pun sendirian. |
| `static const Color` | Warna diakses lewat nama class dan nilainya tetap. Contoh: `AppColors.primary`. |
| `Color(0xAARRGGBB)` | Warna dalam heksadesimal: alpha, merah, hijau, biru. `FF` pada alpha berarti sepenuhnya opak. |

| Konstanta | Nilai | Peran yang dapat dibaca dari nama/pemakaiannya |
|---|---|---|
| `primary` | `#1E3A5F` | Biru tua untuk warna utama. |
| `secondary` | `#FF8A3D` | Oranye untuk aksen. |
| `peach` | `#FFD9BF` | Oranye muda untuk bidang/aksen lembut. |
| `background` | `#FFF9F5` | Latar halaman terang. |
| `surface` | `#FFFFFF` | Permukaan putih. |
| `grey` | `#CCCCCC` | Abu-abu bersama. |

### Membaca kode dan dampaknya

File mengimpor Material untuk mendapatkan `Color`, lalu mendefinisikan konstanta tanpa method build. Ketika dipakai pada `ThemeData` atau `BoxDecoration`, warna itu baru memengaruhi tampilan.

Alasan memusatkan warna adalah menjaga pemakaian yang konsisten: perubahan konstanta akan memengaruhi seluruh pemanggilnya. Halaman juga masih memiliki beberapa nilai gaya lokal; keberadaan file ini tidak berarti semua warna aplikasi sudah selalu mengambil konstanta dari sini.

Lanjut: [Home dan komponen kartu](02-home.md).
