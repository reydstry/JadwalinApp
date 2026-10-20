import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../repositories/jadwal_repository.dart';
import '../../services/notification_service.dart';
import '../../utils/day_helper.dart';

import '../jadwal/kelola_jadwal.dart';

import 'widgets/pilih_hari.dart';
import 'widgets/list_jadwal.dart';

import '../../theme/app_colors.dart';

class HomePage extends StatefulWidget {
  final AppDatabase database;
  final bool showOfflineEmptyState;

  const HomePage({
    super.key,
    required this.database,
    this.showOfflineEmptyState = false,
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

    _jadwalStream = _repository.watchAll();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Jika instance database dari parent berubah,
    // perbarui repository dan stream.
    if (oldWidget.database != widget.database) {
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
        return AlertDialog(
          title: const Text('Hapus Jadwal'),
          content: Text('Hapus jadwal ${data.mataKuliah.nama}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jadwalin',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            fontFamily: 'Poppins',
            color: AppColors.primary,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Akun Saya',
            onPressed: () {
              // Hubungkan ke halaman akun
              // setelah halaman akun tersedia.
            },
            icon: const Icon(
              Icons.account_circle_outlined,
              size: 30,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),
        ],
      ),

      // KONTEN
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigasi hari yang sudah ada
          PilihHari(selectedDay: _hariDipilih, onDaySelected: _pilihHari),

          // Judul jadwal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Jadwal ${DayHelper.dayNames[_hariDipilih] ?? '-'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1.3,
              ),
            ),
          ),

          // Daftar jadwal dari database
          Expanded(
            child: ListJadwal(
              stream: _jadwalStream,
              selectedDay: _hariDipilih,
              onAdd: _bukaTambahJadwal,
              onEdit: _bukaEditJadwal,
              onDelete: _hapusJadwal,
              showOfflineEmptyState: widget.showOfflineEmptyState,
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _bukaTambahJadwal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
