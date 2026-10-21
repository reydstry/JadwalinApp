# Dasar untuk membaca UI Jadwalin

[Daftar isi](README.md) · [Fondasi aplikasi](01-fondasi-aplikasi.md) · [Glosarium](05-glosarium.md)

Bab ini menjelaskan cara membaca kode sebelum masuk ke file satu per satu. Semua pembahasan file mengikuti kode proyek pada 21 Oktober 2026. Saat kode berubah, salinan kode dalam panduan perlu diperbarui.

## 1. Dart, Flutter, class, dan widget

**Dart** adalah bahasa yang dipakai untuk menulis proyek. **Flutter** menyediakan kerangka UI, widget, layout, navigasi, dan animasi. **Package** menambahkan kemampuan, misalnya `flutter_svg` untuk membaca ikon SVG.

Class adalah rancangan objek. Tidak semua class adalah widget:

| Contoh dalam proyek | Jenis | Tanggung jawab |
|---|---|---|
| `HomePage`, `KartuJadwal`, `JadwalCardDetails` | Widget buatan proyek | Menyusun bagian UI. |
| `Row`, `Text`, `IntrinsicHeight` | Widget bawaan Flutter | Memberi kemampuan layout atau tampilan. |
| `AppColors` | Kumpulan konstanta | Menyediakan warna bersama. |
| `TextStyle`, `BoxDecoration` | Objek konfigurasi | Menjelaskan gaya; objek ini bukan widget. |
| `TextEditingController` | Controller | Membaca/mengatur isi input dan memberi notifikasi perubahan. |
| `JadwalRepository`, `AppDatabase` | Pengelola data | Menyimpan, membaca, dan memantau jadwal. |
| `TimeHelper` | Helper | Mengubah nilai menit menjadi teks jam. |

Jadi, ketika melihat `Container(decoration: BoxDecoration(...))`, `Container` adalah widget, sedangkan `BoxDecoration` adalah konfigurasi visualnya.

## 2. Membaca pohon widget dari luar ke dalam

Widget membentuk pohon. Widget di luar menjadi **parent**, widget di dalam menjadi **child**. `child:` menerima satu widget; `children:` menerima daftar widget. Satu anak tetap bisa berupa `Column` yang memiliki banyak anak sendiri.

Contoh berikut adalah potongan asli `main.dart`:

```dart
MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'Jadwalin',
  theme: ThemeData(
    useMaterial3: true,
```

Bacanya: aplikasi memakai `MaterialApp`, menyembunyikan banner debug, menetapkan judul, lalu memasang tema. Ini cuplikan awal pemanggilan, bukan program lengkap; kode lengkap ada di [bab fondasi](01-fondasi-aplikasi.md).

Untuk komponen Home, telusuri hubungan berikut:

```text
HomePage
  ├─ HomeHeader
  ├─ PilihHari → HariBubble
  ├─ HomeDaySummary
  ├─ ListJadwal → KartuJadwal
  │                ├─ JadwalCardHeader
  │                ├─ JadwalCardDetails
  │                └─ JadwalCardReminder
  └─ TambahJadwalButton
```

Diagram ini menunjukkan hubungan komposisi. Ia menyederhanakan pembungkus layout seperti `Padding` dan `Column`. Bab Home menjelaskan pembungkus sebenarnya.

Saat membaca widget panjang, cari dulu widget terluar, lalu isi `child`/`children`, kemudian gaya dan callback. Cara ini membantu memisahkan pertanyaan “bagian apa yang ditampilkan”, “bagaimana letaknya”, dan “apa yang terjadi ketika ditekan”.

## 3. StatelessWidget, StatefulWidget, dan build

`StatelessWidget` cocok untuk bagian yang menampilkan konfigurasi/data dari constructor tanpa menyimpan state lokal yang dapat diubah. Contohnya bagian detail kartu menerima teks dan menampilkannya. Ia tetap bisa dibangun ulang ketika parent memberikan konfigurasi baru atau dependensi seperti tema berubah.

`StatefulWidget` mempunyai pasangan objek `State` untuk menyimpan kondisi yang bertahan selama posisi widget itu dipertahankan dalam pohon. Contoh di proyek: hari terpilih, status sedang menyimpan, password disamarkan, dan kemajuan animasi.

Widget `StatefulWidget` sendiri tetap merupakan konfigurasi immutable. Data yang diubah disimpan pada objek `State`, bukan dengan mengubah field konfigurasi widget.

`build(BuildContext context)` mengembalikan deskripsi UI untuk kondisi saat ini. Flutter dapat memanggilnya berkali-kali. `build` bukan tempat yang tepat untuk memulai operasi penyimpanan atau membuat controller berulang kali.

`BuildContext` menunjukkan lokasi widget dalam pohon. Melalui lokasi ini, kode dapat mencari `Theme`, `MediaQuery`, `Navigator`, dan `ScaffoldMessenger` terdekat.

### Lifecycle yang perlu dikenali

| Bagian | Makna | Contoh pemakaian |
|---|---|---|
| `createState()` | Membuat objek state untuk widget stateful. | `MyApp` membuat `_MyAppState`. |
| `initState()` | Inisialisasi satu kali untuk satu objek state. | Menyiapkan dependency, controller, atau subscription/listener. |
| `didChangeDependencies()` | Dipanggil setelah init dan ketika dependensi inherited berubah. | Pelajari hanya pada file yang benar-benar menggunakannya. |
| `didUpdateWidget(oldWidget)` | Parent memberi konfigurasi baru dengan tipe dan key yang cocok. | Menyesuaikan animasi/progress ketika data dari parent berubah. |
| `setState(() { ... })` | Menandai bahwa state berubah sehingga UI perlu dibangun ulang. | Mengubah hari terpilih atau flag loading. |
| `dispose()` | Pelepasan terakhir resource yang dimiliki state. | Melepas animation controller, text controller, atau focus node. |
| `mounted` | Menandakan state/context masih berada dalam pohon. | Dicek setelah `await` sebelum memakai context atau mengubah UI. |

`setState` tidak menjamin seluruh aplikasi dibangun ulang, dan tidak menggambar layar secara sinkron pada baris itu juga. Ia menandai bagian terkait untuk dijadwalkan rebuild. Callback `setState` harus sinkron; pekerjaan `async` dilakukan di luar callback tersebut.

Alur sederhana: pengguna menekan tombol → callback berjalan → state berubah → `setState` menandai rebuild → `build` menghasilkan UI baru. Pada `StreamBuilder` dan `AnimatedBuilder`, perubahan stream/animasi juga dapat memicu pembaruan bagian UI yang mereka kelola.

Rujukan konsep: [State dan lifecycle](https://api.flutter.dev/flutter/widgets/State-class.html), [setState](https://api.flutter.dev/flutter/widgets/State/setState.html).

## 4. Layout: ukuran datang dari batas parent

Flutter memakai aturan layout: parent memberikan **constraints** atau batas ukuran, child memilih ukuran yang diizinkan, lalu parent menentukan posisi child. Angka ukuran pada UI umumnya memakai **logical pixel**, bukan hitungan pixel fisik panel layar.

| Kebutuhan | Yang dipakai dalam proyek | Cara membacanya |
|---|---|---|
| Menyusun mendatar | `Row` | Sumbu utama horizontal; sumbu silang vertikal. |
| Menyusun ke bawah | `Column` | Sumbu utama vertikal; sumbu silang horizontal. |
| Mengisi ruang tersisa | `Expanded` | Child diwajibkan mengisi bagian ruang sesuai `flex` pada `Row`/`Column`. |
| Membagi ruang dengan kelonggaran | `Flexible` | Mengikuti pembagian flex; dengan `FlexFit.loose` child boleh lebih kecil dari jatahnya. |
| Jarak di dalam widget | `Padding` atau `Container.padding` | Memberi ruang antara batas pembungkus dan isinya. |
| Jarak di luar dekorasi | `Container.margin` atau pembungkus padding | Memberi jarak dengan tetangga. |
| Jarak/ukuran tertentu | `SizedBox` | Contoh lebar sela ikon dan teks. |
| Membatasi ukuran | `ConstrainedBox` dan `BoxConstraints` | Membatasi min/max ukuran; tetap tunduk pada batas dari atas. |
| Mengetahui jatah ruang lokal | `LayoutBuilder` | `constraints.maxWidth` adalah batas lebar dari parent, bukan otomatis lebar layar. |
| Mengetahui ukuran view | `MediaQuery.sizeOf(context)` | Memakai ukuran view tempat context berada. |
| Menyamakan kebutuhan tinggi konten | `IntrinsicHeight` | Menghitung tinggi intrinsik anak; dapat membantu anggota `Row` mengikuti anak tertinggi. |

**`IntrinsicHeight` bukan alat mengukur tinggi layar.** Pada kartu jadwal, kegunaannya berkaitan dengan tinggi konten dan susunan di dalam kartu. Hasilnya tetap dipengaruhi constraints parent. Perhitungannya menambah tahap layout sehingga lebih mahal daripada layout biasa; baca alasan pemakaian spesifiknya di bab Home dan Form. [Dokumentasi IntrinsicHeight](https://api.flutter.dev/flutter/widgets/IntrinsicHeight-class.html)

Sebaliknya, `LayoutBuilder` menerima constraints saat layout dan dipakai untuk memutuskan susunan berdasarkan ruang yang tersedia. Misalnya, dua komponen sama-sama berada pada layar lebar tetapi memperoleh lebar lokal berbeda karena salah satunya berada dalam kolom. [Dokumentasi LayoutBuilder](https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html)

`MediaQuery.sizeOf` mengembalikan ukuran view. `MediaQuery.viewInsetsOf` membaca bagian view yang tertutup, contohnya keyboard. `MediaQuery.textScalerOf` membaca pengaturan skala teks, sehingga ukuran teks tidak sebaiknya diasumsikan selalu sama. [Dokumentasi MediaQuery](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html)

## 5. Alignment, scrolling, dan responsivitas

Pada `Row`, `mainAxisAlignment` mengatur posisi mendatar; `crossAxisAlignment` mengatur posisi vertikal. Pada `Column`, arahnya bertukar. Karena itu `CrossAxisAlignment.stretch` pada `Row` berkaitan dengan tinggi, sedangkan pada `Column` berkaitan dengan lebar.

`MainAxisSize.min` meminta ruang utama secukup isi jika constraints mengizinkan. `MainAxisSize.max` meminta ruang utama maksimum yang diizinkan. `Expanded` tetap membutuhkan ruang utama yang terbatas; meletakkannya dalam konteks scroll dengan batas utama tak terhingga memerlukan susunan layout yang benar.

`SingleChildScrollView` membuat satu subtree bisa digulir. `ListView` cocok untuk daftar; constructor `builder`/`separated` membangun item melalui callback. `ScrollController` dapat mengatur posisi gulir. `Scrollable.ensureVisible` membantu membawa widget tertentu masuk area yang terlihat, misalnya input invalid.

“Responsif” pada proyek tidak hanya berarti mengecilkan font. File-file UI memilih `Row` atau `Column`, membatasi lebar konten, menambah scroll saat tinggi terbatas, dan memperhitungkan skala teks/keyboard. Angka breakpoint di tiap file adalah keputusan layout proyek; angka tersebut bukan aturan universal Flutter.

## 6. Data turun, kejadian naik

Parent mengirim **data** melalui constructor, misalnya nama mata kuliah, waktu, flag loading, dan hari terpilih. Child mengirim **kejadian** melalui callback, misalnya `onPressed`, `onChanged`, `onEdit`, atau `onDelete`.

`VoidCallback` berarti fungsi tanpa parameter yang tidak mengembalikan nilai: `void Function()`. `ValueChanged<int>` berarti fungsi yang menerima nilai `int`: `void Function(int)`. `Future<void> Function()` berarti operasi tanpa parameter yang selesai secara asinkron.

Perbedaan penting:

| Bentuk | Makna |
|---|---|
| `onPressed: handler` | Memberikan fungsi untuk dipanggil nanti. |
| `onPressed: () => handler()` | Memberikan fungsi pembungkus untuk dipanggil nanti. |
| `onPressed: null` | Pada tombol Material, menonaktifkan tombol. |
| `handler()` | Langsung menjalankan fungsi pada titik eksekusi itu. |

Dengan callback, widget kecil tidak harus mengurus database sendiri. Contoh: tombol edit melaporkan kejadian; halaman yang memiliki dependency repository mengatur navigasi dan data.

## 7. Future, Stream, loading, dan error

`Future<T>` mewakili satu hasil yang akan tersedia kemudian. `await` menunggu hasilnya tanpa memblokir thread UI seperti operasi sinkron yang lama. `async` memungkinkan fungsi menggunakan `await`. `try/catch/finally` digunakan untuk menangani kegagalan dan memulihkan flag loading.

`Stream<T>` dapat mengirim banyak pembaruan dari waktu ke waktu. Pada Home, database jadwal dipantau melalui stream; `StreamBuilder` menyesuaikan tampilan ketika data berubah. `AsyncSnapshot` membawa data, error, dan status koneksi stream.

Menampilkan indikator loading tidak berarti operasi berhasil. UI harus membedakan kondisi menunggu, berhasil dengan data, berhasil tetapi kosong, dan gagal. Bab tiap halaman memperlihatkan cabang yang benar-benar tersedia.

Setelah `await`, pengguna bisa saja sudah meninggalkan halaman. Pengecekan `mounted` atau `context.mounted` mencegah penggunaan state/context yang sudah dilepas. Pengecekan ini tidak otomatis membatalkan pekerjaan data yang masih berjalan.

## 8. Form dan controller

`Form` mengumpulkan field yang bisa divalidasi. `GlobalKey<FormState>` memberi akses ke state form melalui `currentState`. `TextFormField` menyediakan input teks beserta `validator`.

Validator umumnya mengembalikan `null` ketika valid dan pesan `String` ketika invalid. `FormState.validate()` memberikan hasil boolean. `validateGranularly()` mengembalikan kumpulan state field yang invalid sehingga halaman bisa menyorot atau menggulir ke field tersebut. [Dokumentasi validateGranularly](https://api.flutter.dev/flutter/widgets/FormState/validateGranularly.html)

`TextEditingController` menghubungkan isi input dan kode: `controller.text` dapat dibaca saat submit atau diisi ketika membuka mode edit. `FocusNode` mengatur fokus input. Pembuat/pemilik controller dan focus node bertanggung jawab atas `dispose`; widget child yang hanya menerima controller tidak otomatis menjadi pemiliknya. [Dokumentasi TextEditingController](https://api.flutter.dev/flutter/widgets/TextEditingController-class.html)

Validasi UI, pemeriksaan bentrok di data, dan autentikasi server merupakan tanggung jawab berbeda. Sebuah form yang lolos validator belum membuktikan kredensial sudah diverifikasi oleh server.

## 9. Sintaks Dart yang sering muncul

| Sintaks | Penjelasan dengan konteks proyek |
|---|---|
| `import 'package:flutter/material.dart';` | Mengambil API Material Flutter. Import relatif mengambil file proyek. |
| `class A extends B` | Membuat class turunan, misalnya widget turunan `StatelessWidget`. |
| `implements` | Menyatakan class memenuhi kontrak interface, misalnya gateway autentikasi. |
| `with SingleTickerProviderStateMixin` | Menambahkan kemampuan pemberi ticker untuk animasi. |
| `@override` | Menandai implementasi ulang anggota dari class/interface induk. |
| `const Nama({super.key, required this.data});` | Constructor dengan named parameters; `data` wajib diberikan; `key` diteruskan ke induk. |
| `final` | Variabel hanya boleh diisi sekali; isi objek yang dirujuk belum tentu immutable. |
| `const` | Nilai/objek konstan yang dapat ditentukan saat compile jika konteks dan constructor mendukungnya. |
| `late final` | Diisi sekali setelah deklarasi tetapi sebelum dibaca; sering saat `initState`. |
| `static` | Anggota milik class, dipanggil seperti `AppColors.primary`. |
| `_nama` | Private pada lingkup library Dart; file biasa adalah library kecuali terhubung lewat `part`. |
| `String?` | Nilai boleh `String` atau `null`. `required` tetap bisa digunakan pada parameter nullable. |
| `value ?? fallback` | Memakai fallback hanya jika value null. |
| `value?.method()` | Memanggil method hanya jika value tidak null. |
| `value!` | Menegaskan non-null; akan gagal saat runtime jika ternyata null. |
| `condition ? a : b` | Memilih salah satu nilai berdasarkan kondisi. |
| `=> expression` | Bentuk singkat fungsi/getter yang langsung mengembalikan hasil ekspresi. |
| `get nama` | Getter, dibaca seperti properti walaupun hasilnya dihitung. |
| `<T>` | Tipe generik, misalnya `List<Widget>`, `Future<bool>`, `State<HomePage>`. |
| `if (...)` di dalam list | Menambahkan elemen hanya pada kondisi tertentu. |
| `...items` | Memasukkan elemen-elemen collection ke collection lain. |
| `..method()` | Cascade: menjalankan anggota pada objek yang sama tanpa mengganti hasil ekspresi menjadi hasil method. |
| `(a: ..., b: ...)` | Record dengan named fields; dapat membandingkan kumpulan nilai untuk mendeteksi perubahan form. |
| `enum` dan `switch` | Menamai pilihan terbatas dan memilih perilaku, misalnya destinasi awal aplikasi. |
| `factory` | Constructor yang dapat menentukan cara menghasilkan instance; dipakai saat merumuskan hasil bootstrap. |
| `~/` dan `%` | Pembagian bulat dan sisa bagi, untuk memisahkan jam/menit dari jumlah menit. |
| `'$nama'` | Interpolasi: memasukkan nilai ke string. |
| `.map(...).toList()` | Mengubah setiap elemen lalu membentuk list hasil. |
| `.where(...)` | Menyaring elemen, misalnya jadwal untuk hari yang dipilih. |
| `.trim()` | Menghilangkan whitespace awal/akhir; memengaruhi validasi dan deteksi perubahan. |
| `int.tryParse(text)` | Mencoba membaca angka; mengembalikan null ketika gagal. |
| `RegExp` | Pola teks, misalnya pemeriksaan bentuk email pada UI. |
| `Duration` | Lama waktu, misalnya durasi animasi atau jeda operasi simulasi. |
| `DateTime` | Tanggal/waktu dan konstanta hari; bukan widget. |
| `part 'database.g.dart';` | Menyatukan file kode hasil generator dengan library database. |

## 10. Cara memakai bab berikutnya

Buka file aplikasi di IDE bersamaan dengan bagian panduannya. Baca kode lengkap sekali untuk melihat bentuknya; setelah itu ikuti bedah per bagian. Cocokkan nama widget/properti yang belum dipahami dengan [glosarium](05-glosarium.md).

Untuk setiap file, coba jawab: siapa yang memberikan datanya, state disimpan di mana, bagian mana yang menentukan ukuran, dan callback mana yang mengubah alur. Alasan yang dinyatakan sebagai “dapat dipahami sebagai” adalah penafsiran berdasarkan struktur kode, bukan klaim tentang percakapan awal pembuat desain.

Lanjutkan ke [fondasi aplikasi](01-fondasi-aplikasi.md), lalu [Home](02-home.md).
