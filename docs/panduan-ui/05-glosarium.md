# Glosarium UI, properti, dan sintaks

[Daftar isi](README.md) · [Penjelasan dasar](00-dasar.md)

Gunakan pencarian editor untuk menemukan nama seperti `IntrinsicHeight`, `Expanded`, atau `TextEditingController`. Tabel berikut menerangkan API yang dipakai langsung dan konsep yang diperlukan untuk membaca kode, bukan semua anggota warisan framework yang tidak dipanggil proyek. Class buatan proyek dibahas pada file masing-masing dan dipetakan di [inventaris](README.md#inventaris-file).

## Aplikasi, state, dan dependency

| Istilah | Kegunaan | Contoh konteks di Jadwalin |
|---|---|---|
| `Widget` | Deskripsi bagian UI; dapat berupa tampilan, layout, atau penghubung perilaku. | Semua halaman dan komponen visual. |
| `StatelessWidget` | Widget tanpa objek state lokal yang dapat diubah. | Header, detail kartu, dan tombol yang menerima konfigurasi parent. |
| `StatefulWidget` | Konfigurasi widget yang memiliki pasangan `State`. | Home, form, login, splash, pilihan hari. |
| `State<T>` | Menyimpan kondisi dan lifecycle untuk widget T. | Hari terpilih, loading, controller, flag dialog. |
| `BuildContext` | Lokasi dalam pohon untuk mengakses dependency inherited/navigator. | `Theme.of(context)`, `Navigator.of(context)`. |
| `WidgetBuilder` | Alias fungsi `Widget Function(BuildContext)`. | Membuat halaman tujuan. |
| `WidgetsFlutterBinding` | Penghubung framework Flutter dan lingkungan aplikasi. | `ensureInitialized` sebelum runApp. |
| `runApp` | Memasang widget akar aplikasi. | Menjalankan MyApp. |
| `MaterialApp` | Konfigurasi aplikasi Material dan navigasi tingkat akar. | Judul Jadwalin, tema, SplashPage. |
| `Scaffold` | Struktur halaman Material seperti app bar, body, dan elemen halaman. | Home dan form pengelolaan jadwal. |
| `ScaffoldMessenger` | Menampilkan pesan sementara pada Scaffold terkait. | Hasil simpan, kegagalan, atau pemberitahuan. |
| `initState` | Inisialisasi satu kali pada satu objek State. | Menyiapkan controller/dependency. |
| `didChangeDependencies` | Merespons dependensi inherited yang berubah. | Membaca pengaturan animasi aksesibilitas pada splash. |
| `didUpdateWidget` | Merespons konfigurasi widget baru pada state yang dipertahankan. | Menyesuaikan progress atau pilihan yang datang dari parent. |
| `build` | Menghasilkan deskripsi UI untuk kondisi saat ini. | Membentuk pohon widget halaman/komponen. |
| `setState` | Menandai state berubah dan perlu rebuild. | Hari pilihan, toggle password, proses simpan. |
| `dispose` | Melepas resource milik objek ketika tidak diperlukan lagi. | Controller, focus node, dan animation controller. |
| `mounted` / `context.mounted` | Memastikan state/context masih terpasang. | Guard setelah await sebelum navigasi/pesan/setState. |
| `WidgetsBinding.instance.addPostFrameCallback` | Menjalankan callback setelah frame saat ini selesai diproses. | Menggulir ke pilihan/field setelah layout tersedia. |
| Dependency lewat constructor | Menerima objek/fungsi yang dibutuhkan dari luar. | Database, gateway, repository, callback load. |

## Layout dan ukuran

| Istilah | Kegunaan | Hal yang perlu diperhatikan |
|---|---|---|
| `Row` | Menyusun children secara horizontal. | Main axis horizontal. |
| `Column` | Menyusun children secara vertikal. | Main axis vertikal. |
| `children` / `child` | Daftar anak / satu anak widget. | Konfigurasi komposisi, bukan operasi menjalankan fungsi. |
| `mainAxisAlignment` | Posisi/distribusi anak pada sumbu utama. | `spaceBetween` memberi ruang di antara anak. |
| `crossAxisAlignment` | Posisi anak pada sumbu silang. | `start`, `center`, `stretch` tergantung arah parent. |
| `mainAxisSize` / `MainAxisSize` | Memilih kebutuhan ruang utama min atau max. | Tetap tunduk pada constraints. |
| `Expanded` | Membuat child mengisi jatah ruang flex. | Umumnya anak Row/Column/Flex. |
| `Flexible` / `FlexFit` | Mengalokasikan jatah ruang dengan aturan tight/loose. | Loose memungkinkan child lebih kecil dari jatah. |
| `flex` | Bobot pembagian ruang fleksibel. | Bobot 2 mendapat dua bagian dibanding bobot 1. |
| `Spacer` | Ruang fleksibel kosong pada Flex. | Mendorong kelompok widget saling menjauh. |
| `SizedBox` | Kotak berukuran tertentu atau pemberi jarak. | `width`/`height` masih mengikuti constraints parent. |
| `SizedBox.square` | Kotak dengan sisi sama. | Ikon atau indikator ukuran tetap. |
| `SizedBox.shrink` | Meminta ukuran sekecil mungkin. | Sering menjadi isi kosong pada kondisi tertentu. |
| `Container` | Pembungkus praktis ukuran, padding, margin, alignment, dan dekorasi. | Tidak semua fiturnya harus dipakai sekaligus. |
| `Padding` | Menambahkan ruang di sekeliling child di dalam pembungkus. | Mengurangi ruang yang tersedia untuk isinya. |
| `EdgeInsets` | Besaran inset atas/bawah/kiri/kanan. | `all`, `symmetric`, `only`, `fromLTRB`. |
| `Align` / `Alignment` | Menentukan posisi child relatif pada pembungkus. | Posisi child berbeda dari susunan beberapa children. |
| `Center` | Memusatkan satu child. | Bentuk khusus alignment tengah. |
| `ConstrainedBox` | Menerapkan batas ukuran tambahan. | Berguna untuk lebar maksimum konten. |
| `BoxConstraints` | Batas minimum/maksimum lebar dan tinggi. | `maxWidth` bukan ukuran child yang sudah digambar. |
| `LayoutBuilder` | Membuat widget berdasarkan constraints parent saat layout. | Cocok untuk keputusan lebar lokal. |
| `IntrinsicHeight` | Mengatur tinggi menurut kebutuhan intrinsik anak. | Tidak mengukur layar; penjelasan rinci ada di dasar dan per-file. |
| `Stack` | Menumpuk children pada area yang sama. | Misalnya konten dan tombol yang ditempatkan terpisah. |
| `Positioned` | Memberi posisi pada anak Stack. | `top`, `bottom`, `left`, `right` relatif terhadap Stack. |
| `SafeArea` | Memberi inset untuk bagian sistem yang perlu dihindari. | Membantu konten tidak tertutup area status/notch. |
| `MediaQuery` | Menyediakan informasi lingkungan view. | Data dari ancestor terdekat; dapat diubah oleh pembungkus lokal. |
| `MediaQuery.sizeOf` | Ukuran dari MediaQuery terdekat. | Dipakai membedakan ruang lebar/tinggi/landscape. |
| `MediaQuery.viewInsetsOf` | Bagian view yang tertutup sistem. | Umumnya keyboard mengurangi area terlihat dari bawah. |
| `MediaQuery.textScalerOf` / `TextScaler` | Pengaturan penskalaan teks pengguna. | `scale(fontSize)` membantu estimasi tinggi/lebar teks. |
| `MediaQuery.disableAnimationsOf` | Preferensi mengurangi/menonaktifkan animasi. | Dibaca oleh splash. |
| `MediaQueryData.copyWith` | Salinan konfigurasi dengan beberapa field diubah. | Memaksa time picker menggunakan format 24 jam. |
| `Size` | Sepasang ukuran width/height. | Ukuran view atau area clipper. |
| `Offset` / `Offset.zero` | Posisi/pergeseran dua dimensi. | Offset bayangan atau posisi dasar menggambar path. |
| Breakpoint | Nilai batas keputusan layout yang ditulis proyek. | Memilih susunan satu/dua kolom, bukan class Flutter. |
| Logical pixel | Satuan ukuran UI yang terpisah dari kerapatan panel fisik. | Angka 24 pada ikon tidak selalu 24 pixel fisik. |

`LayoutBuilder` menyediakan constraints parent; `MediaQuery.sizeOf` mengambil ukuran dari ancestor MediaQuery terdekat. Keduanya bisa memberikan angka berbeda pada komponen yang hanya menerima sebagian lebar view. [LayoutBuilder](https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html), [MediaQuery.sizeOf](https://api.flutter.dev/flutter/widgets/MediaQuery/sizeOf.html)

## Scroll, key, dan identitas widget

| Istilah | Kegunaan | Contoh konteks |
|---|---|---|
| `SingleChildScrollView` | Membuat satu subtree dapat digulir. | Form atau baris pilihan hari. |
| `ListView.separated` | Daftar yang membuat item dan sela lewat builder. | Daftar jadwal. |
| `itemBuilder` / `separatorBuilder` / `itemCount` | Pembuat item/sela dan jumlah item. | Mengubah list data menjadi kartu. |
| `scrollDirection` / `Axis` | Menentukan arah scroll. | Horizontal untuk hari, vertikal untuk jadwal. |
| `ScrollController` | Menyimpan/mengatur posisi scroll. | Relevan saat posisi perlu dikendalikan oleh kode. |
| `Scrollable.ensureVisible` | Membawa target context ke area scroll terlihat. | Hari aktif atau field invalid. |
| `Key` | Identitas widget ketika Flutter mencocokkan konfigurasi lama/baru. | Mempertahankan atau mengganti state yang sesuai. |
| `ValueKey<T>` | Identitas berdasarkan nilai dan tipe key. | Identitas jadwal/field berdasarkan nilai. |
| `ObjectKey` | Identitas berdasarkan objek yang sama. | Menghubungkan subtree dengan instance dependency. |
| `GlobalKey<T>` | Identitas unik dan akses ke state/context subtree. | Mengakses FormState atau menjaga identitas grup form. |
| `PageStorageKey` | Identitas untuk penyimpanan state dalam PageStorage. | Membedakan posisi scroll per hari. |
| `PageStorage` | Penyimpanan state widget pada scope terkait. | Membantu pemulihan posisi scroll; bukan database jadwal. |

## Teks, warna, dekorasi, dan gambar

| Istilah | Kegunaan | Contoh konteks |
|---|---|---|
| `Text` | Menampilkan teks. | Nama mata kuliah, judul, label waktu. |
| `TextStyle` | Konfigurasi tampilan teks. | Warna, ukuran, ketebalan, keluarga font. |
| `fontFamily` | Nama keluarga font yang terdaftar. | Inter dan Merriweather Sans. |
| `FontWeight` | Ketebalan teks. | `w500`, `w600`, `bold`. |
| `TextStyle.height` | Faktor tinggi baris relatif ukuran font. | Mengatur ritme vertikal teks. |
| `letterSpacing` | Jarak antarhuruf. | Gaya judul/label. |
| `TextAlign` / `softWrap` / `maxLines` | Perataan, izin membungkus, dan batas baris. | Perilaku teks panjang. |
| `TextOverflow` | Penanganan teks melebihi batas. | `ellipsis` memberi penanda pemotongan. |
| `DefaultTextStyle` | Style default teks dari ancestor. | Menyamakan pengukuran dan teks tampilan. |
| `TextSpan` | Bagian paragraf berisi teks/style. | Input untuk TextPainter. |
| `TextPainter` | Mengukur dan menggambar paragraf setelah layout. | Membaca lebar teks sebelum memilih susunan. |
| `Directionality` | Arah teks/layout dari lingkungan. | Diteruskan ke pengukuran teks. |
| `TextDirection` | Pilihan arah teks seperti ltr/rtl. | Bukan pengaturan lebar layar. |
| `Theme` / `ThemeData` | Tema yang diwariskan ke subtree. | Tema global dan penyesuaian lokal Home/form. |
| `Theme.of(context)` | Mengambil tema terdekat. | Menyalin tema tanpa membangun semuanya dari awal. |
| `ThemeData.copyWith` | Salinan tema dengan perubahan terbatas. | Mengubah font/input/time picker. |
| `textTheme.apply` | Menerapkan perubahan pada kelompok style teks. | Font Inter di Home/form. |
| `Color` | Nilai warna. | Format `0xAARRGGBB`. |
| `Color.withValues(alpha: ...)` | Salinan warna dengan kanal tertentu berubah. | Transparansi warna jika dipanggil file terkait. |
| `Colors` | Kumpulan warna bawaan Material. | Putih/transparan dan warna bawaan lainnya. |
| `ColorScheme` / `ColorScheme.fromSeed` | Peran warna Material, dapat diturunkan dari seed. | Tema utama di main. |
| `AppBarTheme` | Default tampilan AppBar. | Warna foreground dan latar. |
| `DecoratedBox` | Memberi dekorasi pada child. | Bidang kartu/panel. |
| `BoxDecoration` | Konfigurasi bidang, border, radius, dan bayangan. | Bukan widget tersendiri. |
| `Border` / `BorderSide` | Garis tepi seluruh sisi atau satu sisi. | Pembatas komponen dan input. |
| `BorderRadius` | Radius sudut bidang. | Kartu dan tombol membulat. |
| `BoxShadow` | Konfigurasi bayangan. | `blurRadius`, `spreadRadius`, `offset`. |
| `RoundedRectangleBorder` | Bentuk persegi panjang dengan sudut membulat. | Tombol/dialog Material. |
| `CircleBorder` / `StadiumBorder` | Bentuk lingkaran / kapsul. | Tombol bundar atau bubble hari. |
| `CircleAvatar` | Bidang avatar berbentuk lingkaran. | Menu akun. |
| `ColoredBox` | Melukis satu warna di belakang child. | Lapisan warna pada splash. |
| `Icon` / `IconData` / `Icons` | Widget ikon, datanya, dan koleksi ikon Material. | Ikon bawaan pada tombol/indikator. |
| `Image.asset` | Memuat bitmap dari asset bundle. | Logo app_icon.png pada auth/splash. |
| `SvgPicture.asset` | Memuat SVG melalui package flutter_svg. | Ikon kartu/form dan empty state. |
| `BoxFit` | Aturan menempatkan gambar dalam kotak. | `contain` menjaga seluruh gambar; `cover` menutupi kotak dengan potensi crop; `none` tidak menskalakan. |
| `ClipRect` | Memotong gambar ke area persegi panjang. | Mencegah gambar keluar kotak. |
| `ClipRRect` | Memotong ke persegi panjang membulat. | Sudut gambar/bidang. |
| `ClipOval` | Memotong ke bentuk oval/lingkaran. | Logo pada splash. |
| `ClipPath` | Memotong berdasarkan Path khusus. | Permukaan gelombang liquid logo. |

`TextPainter` perlu `layout` sebelum hasil pengukuran dibaca dan `dispose` ketika selesai. Pada proyek, ia membantu keputusan susunan berdasarkan ukuran teks. [Dokumentasi TextPainter](https://api.flutter.dev/flutter/painting/TextPainter-class.html)

## Tombol, interaksi, navigasi, dan pesan

| Istilah | Kegunaan | Contoh konteks |
|---|---|---|
| `TextButton` | Tombol dengan penekanan visual ringan. | Aksi sekunder, pilihan hari, navigasi akun. |
| `FilledButton` / `FilledButton.icon` | Tombol berisi warna, opsional ikon. | Submit, tambah, dan simpan. |
| `IconButton` / `IconButton.filled` | Tombol yang menampilkan ikon. | Edit, hapus, kembali, password visibility. |
| `ButtonStyle` / `styleFrom` | Konfigurasi gaya tombol. | Warna, padding, bentuk, ukuran minimum. |
| `onPressed` | Callback tombol ditekan. | Nilai null menonaktifkan tombol Material. |
| `InkWell` | Area interaksi Material dengan respons tinta. | Dipakai pada komponen auth; bukan pembungkus yang tertulis di semua tombol. |
| `PopupMenuButton<T>` | Tombol pembuka menu pilihan. | Menu akun. |
| `PopupMenuItem<T>` | Satu pilihan menu dengan nilai T. | Aksi logout. |
| `PopupMenuPosition` | Posisi menu relatif terhadap tombol. | Menu di bawah atau menutupi area tombol. |
| `VisualDensity` | Kepadatan visual komponen Material. | Merapikan ukuran/ruang komponen. |
| `Tooltip` / `tooltip` | Petunjuk singkat pada komponen. | Label tombol ikon. |
| `Navigator` | Mengelola tumpukan route. | Berpindah halaman dan menutup dialog. |
| `MaterialPageRoute<T>` | Route dengan perilaku transisi Material dan tipe hasil T. | Form mengembalikan hasil bool; route halaman lain memakai void. |
| `push` | Menambahkan route; mengembalikan Future hasil route. | Membuka form tambah/edit. |
| `pop(result)` | Menutup route teratas dan memberi hasil. | Selesai simpan atau pilihan dialog. |
| `maybePop` | Meminta pop dengan menghormati kebijakan pop route. | Tombol kembali pada alur autentikasi. |
| `pushReplacement` | Mengganti route saat ini dengan route baru. | Berpindah dari splash ke tujuan. |
| `pushAndRemoveUntil` | Menambah route dan membuang route sebelumnya sesuai predicate. | Mencegah kembali ke Home setelah logout. |
| `PopScope<T>` | Mengatur kebijakan pop/back untuk route. | Konfirmasi saat form berubah. |
| `canPop` | Mengizinkan atau menahan upaya pop. | false saat perlu dialog konfirmasi. |
| `onPopInvokedWithResult` | Laporan upaya pop beserta didPop dan hasil. | Membuka konfirmasi jika route belum ditutup. |
| `showDialog<T>` | Membuka dialog dan mengembalikan Future hasilnya. | Konfirmasi hapus/buang perubahan. |
| `AlertDialog` | Isi dialog Material: judul, konten, dan aksi. | Konfirmasi pengguna. |
| `barrierDismissible` | Mengizinkan/menolak penutupan dialog dengan mengetuk area di luar. | Kebijakan dialog tertentu. |
| `SnackBar` | Pesan sementara dalam Scaffold. | Hasil operasi/error. |

`onPopInvokedWithResult` melaporkan upaya navigasi; parameter `didPop` menunjukkan hasilnya. Pencegahan pop dilakukan melalui `canPop`, bukan dengan menganggap callback itu selalu dijalankan sebelum route ditutup. [Dokumentasi PopScope](https://api.flutter.dev/flutter/widgets/PopScope-class.html)

## Form dan input

| Istilah | Kegunaan | Contoh konteks |
|---|---|---|
| `Form` / `FormState` | Mengumpulkan field dan menjalankan validasi. | Login, registrasi, jadwal. |
| `GlobalKey<FormState>` | Akses state form dari halaman. | `currentState` untuk validate. |
| `TextFormField` | Input teks terintegrasi validasi form. | Email, password, mata kuliah, ruangan, dosen, SKS. |
| `FormField<T>` / `FormFieldState<T>` | Field validasi generik dan state nilainya. | Jam mulai/selesai yang bukan input teks biasa. |
| `FormFieldValidator<T>` | Fungsi yang mengembalikan pesan error atau null. | Field wajib dan aturan nilai. |
| `validate()` | Memvalidasi field dan mengembalikan bool keseluruhan. | Form akun. |
| `validateGranularly()` | Memvalidasi dan mengembalikan set field invalid. | Mengarahkan pengguna ke input jadwal invalid. |
| `AutovalidateMode` | Mengatur kapan validasi otomatis dijalankan. | Setelah interaksi atau saat form berubah. |
| `TextEditingController` | Membaca/mengisi text, selection, dan nilai input. | Diisi dari jadwal lama pada mode edit. |
| `addListener` / `removeListener` | Mengamati/menghentikan pengamatan perubahan objek. | Deteksi form berubah. |
| `FocusNode` | Identitas dan kontrol fokus input. | Memindah fokus antar-field. |
| `FocusManager` / `FocusScope` | Mengelola fokus di scope/aplikasi. | Melepas fokus sebelum validasi/simpan. |
| `TextInputType` | Petunjuk keyboard untuk tipe data. | emailAddress atau number. |
| `TextInputAction` | Tombol aksi keyboard. | next atau done. |
| `onFieldSubmitted` | Callback ketika pengguna mengirim dari keyboard. | Memindah fokus atau submit. |
| `AutofillHints` | Petunjuk sistem pengisian otomatis. | Email, password, nama. |
| `TextCapitalization` | Petunjuk kapitalisasi input. | Nama pengguna atau dosen. |
| `obscureText` | Menyamarkan karakter input. | Password. |
| `InputDecorator` | Membungkus tampilan field dalam dekorasi Material. | Field jam dengan pemilih waktu. |
| `InputDecoration` | Konfigurasi label, hint, error, border, dan ikon field. | Prefix/suffix icon dan teks placeholder. |
| `InputDecorationTheme` | Default dekorasi untuk kelompok input. | Konsistensi gaya form jadwal. |
| `OutlineInputBorder` | Border kotak membulat untuk input. | Field normal, focused, error. |
| `DropdownButtonFormField<T>` | Dropdown yang terhubung dengan Form. | Hari dan menit pengingat. |
| `DropdownMenuItem<T>` | Satu opsi nilai/label dropdown. | Senin–Minggu atau 5–60 menit. |
| `initialValue` | Nilai awal state field. | Bukan jaminan nilai terus mengikuti setiap perubahan parent tanpa mempertimbangkan state/key. |
| `onChanged` | Callback saat nilai input berubah. | Meneruskan pilihan ke state halaman. |
| `Switch` | Pilihan boolean aktif/nonaktif. | Toggle pengingat. |
| `showTimePicker` | Dialog pemilih waktu. | Jam mulai dan selesai. |
| `TimeOfDay` | Pasangan hour/minute tanpa tanggal. | Dikonversi ke total menit untuk penyimpanan. |
| `TimePickerEntryMode` | Mode awal pemilih waktu. | Input waktu sesuai pengaturan file. |
| `alwaysUse24HourFormat` | Pengaturan format 24 jam dalam MediaQueryData. | Diberikan pada subtree time picker. |
| `errorText` | Pesan kesalahan di field. | Menjelaskan kenapa input perlu diperbaiki. |

Form harus dibaca bersama urutan submit-nya: validasi field → pemeriksaan aturan jadwal → simpan data → pengaturan pengingat → hasil navigasi/pesan. Detail cabang kegagalan ada di [bab Form](04-form-jadwal.md).

## Animasi dan aksesibilitas

| Istilah | Kegunaan | Contoh konteks |
|---|---|---|
| `AnimationController` | Menghasilkan nilai animasi sepanjang durasi. | Progress isi splash dan fase gelombang. |
| `SingleTickerProviderStateMixin` | Menjadikan State pemberi ticker untuk satu controller. | vsync controller dalam state terkait. |
| `vsync` | Pemberi ticker yang digunakan controller. | Menghubungkan tick dengan lifecycle/render frame. |
| `AnimationBehavior.preserve` | Mempertahankan perilaku waktu controller saat disableAnimations berlaku. | Perlu dibaca bersama penanganan preferensi animasi di SplashPage. |
| `animateTo` / `repeat` | Menganimasikan menuju target / mengulang animasi. | Progress dan gerakan gelombang. |
| `Curves` / `Curve` | Pola perubahan nilai terhadap waktu. | Gerak linear atau percepatan/perlambatan. |
| `TickerFuture` | Hasil operasi animasi yang selesai ketika animasi berhasil selesai. | Menunggu animasi progress penuh. |
| `orCancel` / `TickerCanceled` | Future varian yang error ketika animasi dibatalkan. | Menangani controller dilepas saat menunggu animasi. |
| `AnimatedBuilder` | Memanggil builder ketika listenable berubah. | Menggambar ulang bagian liquid logo. |
| `AnimatedBuilder.child` | Subtree tetap yang diberikan kembali ke builder. | Logo yang tidak perlu dibangun ulang setiap tick. |
| `CustomClipper<Path>` | Menentukan batas potongan Path. | Bentuk gelombang. |
| `getClip(Size)` | Menghasilkan path pemotongan untuk ukuran sekarang. | Menghitung titik-titik gelombang. |
| `shouldReclip` | Menentukan kebutuhan clip ulang ketika delegate diperbarui. | Membandingkan progress/phase. |
| `Path` | Rangkaian titik/segmen bentuk untuk gambar/clip. | Permukaan cairan dalam logo. |
| `dart:math` / `sin` / `pi` | Fungsi matematika dan konstanta. | Gelombang sinus serta periode animasinya. |
| `Semantics` | Informasi UI bagi teknologi bantu. | Label tombol, status loading, progress. |
| `liveRegion` | Menandai perubahan yang layak diumumkan pembaca layar. | Pesan/status tertentu. |
| `ExcludeSemantics` | Mengabaikan informasi semantics subtree. | Mencegah logo dekoratif dibaca berulang. |
| `CircularProgressIndicator` | Indikator sedang bekerja; value dapat determinate/indeterminate. | Submit/login/simpan dan loading daftar. |

Lifecycle animasi: controller dibuat oleh state, diberi vsync, dan dilepas ketika state selesai. Pembatalan melalui dispose dapat membuat `orCancel` menghasilkan `TickerCanceled`. [AnimationController](https://api.flutter.dev/flutter/animation/AnimationController-class.html)

`AnimatedBuilder.child` menyimpan subtree yang tidak bergantung pada animasi agar tidak perlu dibentuk ulang pada tiap tick. Bagian yang memakai nilai animasi tetap dibuat melalui builder. [AnimatedBuilder](https://api.flutter.dev/flutter/widgets/AnimatedBuilder-class.html)

## Data, koleksi, dan operasi umum

| Istilah | Kegunaan di proyek |
|---|---|
| `Future<T>` / `async` / `await` | Satu operasi asinkron, misalnya login atau simpan. |
| `Stream<T>` | Rangkaian pembaruan, misalnya perubahan jadwal database. |
| `StreamBuilder<T>` | Mengubah snapshot stream menjadi widget. |
| `AsyncSnapshot<T>` / `ConnectionState` | Data/error dan status koneksi sumber asinkron. |
| `snapshot.hasData` / `data` / `hasError` / `error` | Memilih cabang tampilan berdasarkan hasil yang tersedia. |
| `List<T>` / `Map<K,V>` / `Set<T>` | Urutan nilai, pasangan kunci/nilai, dan kumpulan unik. |
| `where` / `map` / `toList` | Menyaring hari, mengubah data menjadi widget, membentuk list. |
| `sort` / `compareTo` | Mengurutkan berdasarkan waktu mulai dan nilai pembanding. |
| `mapEquals` | Membandingkan isi map secara dangkal, termasuk pasangan key/value. |
| `DateTime` / `weekday` | Waktu/tanggal dan indeks hari. |
| `Duration` | Lama waktu, bukan tanggal. |
| `clamp` / `ceil` / `round` / `math.max` | Membatasi angka, pembulatan, memilih nilai terbesar. |
| `padLeft` / `~/` / `%` | Membentuk dua digit jam dan memecah jumlah menit. |
| `try/catch/finally` / `Exception` | Menangani kegagalan dan melepas flag loading. |
| `RegExp` | Memeriksa pola input; pemeriksaan bentuk email tidak membuktikan alamat ada. |
| `kIsWeb` / `defaultTargetPlatform` | Membedakan target web dan platform. |
| `JadwalDraft` | Objek input dari state form ke repository. |
| `JadwalDenganMataKuliah` | Pasangan jadwal dan mata kuliah untuk UI. |
| `MataKuliahData` / `JadwalKuliahData` | Model row hasil generator Drift. |
| `transaction` | Menggabungkan perubahan data dalam satu unit transaksi database. |
| `watch` | Memantau query sebagai stream pembaruan. |
| `part` / `.g.dart` | Keterkaitan sumber dengan kode hasil generator. |

Untuk sintaks `required`, `const`, nullable, generics, cascade, record, dan collection if/spread, lihat [tabel sintaks Dart](00-dasar.md#9-sintaks-dart-yang-sering-muncul). Untuk class service/query/platform yang lebih khusus, lihat [pendukung UI](06-pendukung-ui.md).
