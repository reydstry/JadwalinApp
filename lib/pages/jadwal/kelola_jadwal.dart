import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../repositories/jadwal_repository.dart';
import '../../services/notification_service.dart';

import 'widgets/mata_kuliah_form.dart';
import 'widgets/waktu_kuliah_form.dart';
import 'widgets/pengingat_form.dart';

class KelolaJadwalPage extends StatefulWidget {
  final AppDatabase database;
  final JadwalDenganMataKuliah? jadwalAwal;

  const KelolaJadwalPage({super.key, required this.database, this.jadwalAwal});

  @override
  State<KelolaJadwalPage> createState() => _KelolaJadwalPageState();
}

class _KelolaJadwalPageState extends State<KelolaJadwalPage> {
  // ============================================
  // FORM DAN CONTROLLER
  // ============================================

  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _dosenController = TextEditingController();
  final _sksController = TextEditingController();
  final _ruanganController = TextEditingController();

  // ============================================
  // STATE
  // ============================================

  int _hari = DateTime.monday;

  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;

  bool _pengingatAktif = false;
  int _menitSebelum = 15;

  bool _sedangMenyimpan = false;

  late JadwalRepository _repository;

  bool get _modeEdit => widget.jadwalAwal != null;

  // ============================================
  // INITIALIZATION
  // ============================================

  @override
  void initState() {
    super.initState();

    _repository = JadwalRepository(database: widget.database);

    _isiDataAwal();
  }

  void _isiDataAwal() {
    final data = widget.jadwalAwal;

    // Mode tambah: biarkan formulir kosong.
    if (data == null) return;

    final mataKuliah = data.mataKuliah;
    final jadwal = data.jadwal;

    // Mengisi data mata kuliah.
    _namaController.text = mataKuliah.nama;
    _dosenController.text = mataKuliah.dosen ?? '';
    _sksController.text = mataKuliah.sks?.toString() ?? '';

    // Mengisi data jadwal.
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

    // Mengisi pengaturan pengingat.
    _pengingatAktif = jadwal.pengingatAktif;
    _menitSebelum = jadwal.menitSebelum;
  }

  // ============================================
  // DISPOSE
  // ============================================

  @override
  void dispose() {
    _namaController.dispose();
    _dosenController.dispose();
    _sksController.dispose();
    _ruanganController.dispose();

    super.dispose();
  }

  // ============================================
  // HELPER
  // ============================================

  int _timeToMinutes(TimeOfDay time) {
    return (time.hour * 60) + time.minute;
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================
  // TIME PICKER
  // ============================================

  Future<void> _pilihJamMulai() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _jamMulai ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (!mounted || result == null) return;

    setState(() {
      _jamMulai = result;
    });
  }

  Future<void> _pilihJamSelesai() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _jamSelesai ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (!mounted || result == null) return;

    setState(() {
      _jamSelesai = result;
    });
  }

  // ============================================
  // MEMBUAT DATA FORMULIR
  // ============================================

  JadwalDraft _buatDraft(int jamMulai, int jamSelesai) {
    final sksText = _sksController.text.trim();

    return JadwalDraft(
      namaMataKuliah: _namaController.text.trim(),
      dosen: _optionalText(_dosenController),
      sks: sksText.isEmpty ? null : int.parse(sksText),
      hari: _hari,
      jamMulai: jamMulai,
      jamSelesai: jamSelesai,
      ruangan: _optionalText(_ruanganController),
      pengingatAktif: _pengingatAktif,
      menitSebelum: _menitSebelum,
    );
  }

  // ============================================
  // PROSES PENYIMPANAN
  // ============================================

  Future<void> _simpan() async {
    // Mencegah penyimpanan ganda.
    if (_sedangMenyimpan) return;

    // Validasi semua TextFormField.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Jam mulai dan selesai wajib dipilih.
    if (_jamMulai == null || _jamSelesai == null) {
      _showMessage('Jam mulai dan jam selesai harus dipilih.');

      return;
    }

    final jamMulai = _timeToMinutes(_jamMulai!);
    final jamSelesai = _timeToMinutes(_jamSelesai!);

    // Validasi urutan waktu.
    if (jamSelesai <= jamMulai) {
      _showMessage('Jam selesai harus setelah jam mulai.');

      return;
    }

    // Mengunci tombol agar tidak ada dua operasi simpan.
    setState(() {
      _sedangMenyimpan = true;
    });

    try {
      final draft = _buatDraft(jamMulai, jamSelesai);

      // ========================================
      // 1. CEK BENTROK JADWAL
      // ========================================

      final bentrok = await _repository.hasConflict(
        draft,
        exceptScheduleId: _modeEdit ? widget.jadwalAwal!.jadwal.id : null,
      );

      if (!mounted) return;

      if (bentrok) {
        _showMessage(
          'Jadwal bentrok dengan jadwal lain '
          'pada hari dan waktu tersebut.',
        );

        return;
      }

      // ========================================
      // 2. PERIKSA IZIN PENGINGAT
      // ========================================

      if (_pengingatAktif &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
        final izin = await NotificationService.ensureReminderPermissions();

        if (!mounted) return;

        if (!izin) {
          _showMessage(
            'Aktifkan izin Notifikasi dan '
            'Alarm & pengingat untuk menggunakan reminder.',
          );

          return;
        }
      }

      // ========================================
      // 3. SIMPAN KE DATABASE
      // ========================================

      final jadwalId = await _repository.save(
        draft,
        jadwalAwal: widget.jadwalAwal,
      );

      if (!mounted) return;

      // ========================================
      // 4. SINKRONKAN NOTIFIKASI ANDROID
      // ========================================

      String? peringatanNotifikasi;

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
        } catch (error) {
          peringatanNotifikasi =
              'Jadwal berhasil disimpan, '
              'tetapi pengingat gagal diperbarui: $error';
        }
      }

      if (!mounted) return;

      // ========================================
      // 5. TAMPILKAN HASIL DAN KEMBALI
      // ========================================

      if (peringatanNotifikasi != null) {
        _showMessage(peringatanNotifikasi);
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      _showMessage('Gagal menyimpan jadwal: $error');
    } finally {
      if (mounted) {
        setState(() {
          _sedangMenyimpan = false;
        });
      }
    }
  }

  // ============================================
  // BUILD UI
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_modeEdit ? 'Edit Jadwal' : 'Tambah Jadwal')),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ==================================
              // DATA MATA KULIAH
              // ==================================

              MataKuliahForm(
                namaController: _namaController,
                dosenController: _dosenController,
                sksController: _sksController,
              ),

              const SizedBox(height: 16),

              // ==================================
              // HARI DAN WAKTU KULIAH
              // ==================================
              WaktuKuliahForm(
                hari: _hari,
                onHariChanged: (value) {
                  setState(() {
                    _hari = value;
                  });
                },
                jamMulai: _jamMulai,
                jamSelesai: _jamSelesai,
                onPilihJamMulai: _pilihJamMulai,
                onPilihJamSelesai: _pilihJamSelesai,
                ruanganController: _ruanganController,
              ),

              const SizedBox(height: 20),

              // ==================================
              // PENGATURAN PENGINGAT
              // ==================================
              PengingatForm(
                pengingatAktif: _pengingatAktif,
                menitSebelum: _menitSebelum,
                onPengingatChanged: (value) {
                  setState(() {
                    _pengingatAktif = value;
                  });
                },
                onMenitChanged: (value) {
                  setState(() {
                    _menitSebelum = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // ==================================
              // TOMBOL SIMPAN
              // ==================================
              FilledButton.icon(
                onPressed: _sedangMenyimpan ? null : _simpan,
                icon: _sedangMenyimpan
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _sedangMenyimpan
                      ? 'Menyimpan...'
                      : _modeEdit
                      ? 'Simpan Perubahan'
                      : 'Simpan Jadwal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
