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
