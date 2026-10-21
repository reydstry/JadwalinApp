# Package, font, aset, dan berkas pendukung platform

[Daftar isi](README.md) · [Glosarium](05-glosarium.md)

Konfigurasi UI tidak hanya berada di class widget. Pubspec mendaftarkan package, font, dan aset yang dipanggil widget. Versi di bawah adalah **constraint yang tertulis di pubspec**, bukan klaim tentang versi Flutter atau seluruh versi package yang terpasang.

<a id="file-pubspec-yaml"></a>

## `pubspec.yaml`

[Buka sumber](../../pubspec.yaml)

### Kode lengkap

<!-- SUMBER:pubspec.yaml SHA256=78d7a92a2086aae2809706ed356fc8bd04a159f300c0942336e0b6cb749840a2 -->

```yaml
name: jadwalin
description: "A new Flutter project."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.13.3

dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  flutter_launcher_icons: ^0.14.4
  drift: ^2.35.0
  drift_flutter: ^0.3.1
  path_provider: ^2.1.6
  flutter_local_notifications: ^22.3.1
  timezone: ^0.11.1
  flutter_timezone: ^5.1.0
  shared_preferences: ^2.5.5
  flutter_svg: ^2.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^6.0.0
  drift_dev: ^2.35.0
  build_runner: ^2.16.1

flutter:
  uses-material-design: true

  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter.ttf
    - family: Merriweather Sans
      fonts:
        - asset: assets/fonts/MerriweatherSans.ttf

  assets:
    - assets/icon/

flutter_launcher_icons:
  android: true
  ios: false
  image_path: 'assets/icon/app_icon.png'
```

### Package yang dipakai dan hubungannya dengan UI

| Dependency | Constraint | Kegunaan yang terlihat dari konfigurasi/import |
|---|---|---|
| `flutter` | SDK | Widget, Material, rendering, navigasi, animasi, foundation. |
| `flutter_svg` | `^2.3.0` | `SvgPicture.asset` pada ikon Home, form, dan empty state. |
| `drift` | `^2.35.0` | Definisi tabel, query, transaksi, dan model data lokal. |
| `drift_flutter` | `^0.3.1` | Pengaturan pembukaan database native/web. |
| `path_provider` | `^2.1.6` | Direktori aplikasi untuk file database native. |
| `flutter_local_notifications` | `^22.3.1` | Pengingat lokal Android melalui NotificationService. |
| `timezone` | `^0.11.1` | Data zona dan waktu berzona untuk penjadwalan pengingat. |
| `flutter_timezone` | `^5.1.0` | Membaca zona waktu perangkat. |
| `shared_preferences` | `^2.5.5` | Flag onboarding izin notifikasi. |
| `cupertino_icons` | `^1.0.8` | Terdaftar sebagai koleksi ikon Cupertino; belum ditemukan import langsung paket ini pada source manual lib yang dibahas. |
| `flutter_launcher_icons` | `^0.14.4` | Terdaftar pada dependencies dan dikonfigurasi untuk menghasilkan ikon launcher Android; bukan widget tampilan halaman. |
| `flutter_test` | SDK, dev dependency | API pengujian Flutter untuk file test. |
| `flutter_lints` | `^6.0.0`, dev dependency | Aturan pemeriksaan gaya/kualitas kode. |
| `drift_dev` | `^2.35.0`, dev dependency | Generator untuk kode database. |
| `build_runner` | `^2.16.1`, dev dependency | Infrastruktur menjalankan generator. |

UI menggunakan state lokal melalui `State`, callback, dan stream database yang ditampilkan `StreamBuilder`. Import source manual yang dibahas menunjukkan pola tersebut.

### Bagian pubspec lainnya

`name: jadwalin` adalah nama package. `publish_to: 'none'` menandai proyek tidak untuk dipublikasikan ke pub.dev melalui konfigurasi ini. `version: 1.0.0+1` adalah versi aplikasi dan build number.

`environment.sdk: ^3.13.3` adalah constraint Dart yang tertulis di proyek. Versi Flutter terpasang tidak ditentukan dari angka tersebut saja.

`uses-material-design: true` mengaktifkan dukungan Material assets termasuk font ikon yang digunakan `Icons`. Daftar `assets` dan `fonts` memberi tahu Flutter berkas mana yang perlu dimasukkan ke bundle.

`flutter_launcher_icons` menetapkan `android: true`, `ios: false`, dan sumber `assets/icon/app_icon.png`. Ini konfigurasi generator launcher, berbeda dari pemanggilan `Image.asset` untuk gambar di halaman.

## Font

| Keluarga | Berkas | Pemakaian dalam kode |
|---|---|---|
| Inter | [Inter.ttf](../../assets/fonts/Inter.ttf) | Diterapkan lewat tema lokal Home/form dan beberapa style eksplisit. |
| Merriweather Sans | [MerriweatherSans.ttf](../../assets/fonts/MerriweatherSans.ttf) | Dipakai eksplisit pada teks HariBubble. |

Nama `fontFamily` harus cocok dengan nama family di pubspec, bukan otomatis nama file. Mendeklarasikan font membuatnya tersedia; itu tidak otomatis menjadikan font tersebut default seluruh aplikasi.

`FontWeight` memberi permintaan ketebalan. Pubspec saat ini mendaftarkan satu file untuk setiap family tanpa daftar entry weight terpisah. Panduan ini tidak menilai isi/axis font hanya berdasarkan nama berkas.

## Gambar dan ikon aset

| Berkas / kelompok | Widget/pemakai | Kegunaan |
|---|---|---|
| [assets/icon/app_icon.png](../../assets/icon/app_icon.png) | AuthHeader, LiquidLogo; konfigurasi launcher | Logo dalam UI dan sumber generator launcher. |
| [empty.svg](../../assets/icon/empty.svg) | JadwalKosong | Ilustrasi jadwal kosong. |
| [clock.svg](../../assets/icon/clock.svg) | HomeIcon melalui nama clock | Waktu/rentang jam. |
| [credits.svg](../../assets/icon/credits.svg) | HomeIcon melalui nama credits | SKS. |
| [lecturer.svg](../../assets/icon/lecturer.svg) | HomeIcon melalui nama lecturer | Dosen. |
| [room.svg](../../assets/icon/room.svg) | HomeIcon melalui nama room | Ruangan. |
| [edit.svg](../../assets/icon/edit.svg), [delete.svg](../../assets/icon/delete.svg) | HomeIcon melalui nama ikon | Aksi edit/hapus. |
| [form_add.svg](../../assets/icon/form_add.svg) | JadwalFormIcon | Identitas/aksi tambah pada form. |
| [form_back.svg](../../assets/icon/form_back.svg) | JadwalFormIcon | Navigasi kembali. |
| [form_bell.svg](../../assets/icon/form_bell.svg) | JadwalFormIcon | Bagian pengingat. |
| [form_book.svg](../../assets/icon/form_book.svg) | JadwalFormIcon | Nama mata kuliah. |
| [form_clock.svg](../../assets/icon/form_clock.svg) | JadwalFormIcon | Waktu kuliah. |
| [form_credits.svg](../../assets/icon/form_credits.svg) | JadwalFormIcon | SKS. |
| [form_lecturer.svg](../../assets/icon/form_lecturer.svg) | JadwalFormIcon | Dosen. |
| [form_room.svg](../../assets/icon/form_room.svg) | JadwalFormIcon | Ruangan. |
| [form_section.svg](../../assets/icon/form_section.svg) | JadwalFormIcon | Penanda bagian form. |

`HomeIcon` membentuk nama asset `assets/icon/$name.svg`. `JadwalFormIcon` membentuk `assets/icon/form_$name.svg`. Pemusatan pola ini membuat pemanggil cukup menyebut nama ikon dan ukuran.

PNG adalah bitmap. SVG menyimpan bentuk vektor dan pada proyek ditampilkan melalui package `flutter_svg`. Ukuran widget, `BoxFit`, dan pemotongan gambar tetap ditentukan oleh kode layout, bukan hanya ukuran berkas.

## Berkas platform, lockfile, dan pengujian

| Berkas/kelompok | Peran dalam memahami UI |
|---|---|
| `pubspec.lock` | Resolusi versi dependency; berbeda dengan rentang versi yang diminta pubspec. |
| `web/index.html`, `web/manifest.json`, `web/icons` | Pembungkus dan metadata saat app Flutter dibuka di web. |
| `web/sqlite3.wasm`, `web/drift_worker.dart.js` | Resource database web yang dirujuk konfigurasi AppDatabase. |
| `android/`, `ios/`, dan direktori platform lain | Host/integrasi platform; komposisi layar yang dijelaskan panduan berada di Dart lib. Target proyek yang dinyatakan adalah Android. |
| `test/` | Pengujian perilaku halaman, form, dan aturan terkait; bukan widget yang ditampilkan ke pengguna. |

File pengujian yang ditemukan: `widget_test.dart`, `splash_page_test.dart`, `auth_flow_test.dart`, `login_page_test.dart`, `register_page_test.dart`, `auth_responsive_test.dart`, `home_page_test.dart`, `kelola_jadwal_test.dart`, `logout_flow_test.dart`, dan `schedule_conflict_test.dart`.

Bab ini memetakan keberadaan dan peran berkas tersebut. Pengujian aplikasi tidak dijalankan untuk tugas penulisan materi ini; hasil pengujian lama ataupun keberhasilan Android tidak disimpulkan dari nama file test.
