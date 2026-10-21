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
