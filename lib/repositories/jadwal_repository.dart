
import '../database/database.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';

class JadwalDraft {
  final String namaMataKuliah;
  final String? dosen;
  final int? sks;
  final int hari;
  final int jamMulai;
  final int jamSelesai;
  final String? ruangan;
  final bool pengingatAktif;
  final int menitSebelum;

  const JadwalDraft({
    required this.namaMataKuliah,
    required this.dosen,
    required this.sks,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.ruangan,
    required this.pengingatAktif,
    required this.menitSebelum,
  });
}

class JadwalRepository {
  final AppDatabase database;

  const JadwalRepository({
    required this.database,
  });

  // Mendengarkan perubahan jadwal dari Drift.
  Stream<List<JadwalDenganMataKuliah>> watchAll() {
    return database.watchSemuaJadwalLengkap();
  }

  // Mengecek apakah jadwal bertabrakan.
  Future<bool> hasConflict(
    JadwalDraft draft, {
    int? exceptScheduleId,
  }) {
    return database.adaBentrokJadwal(
      hari: draft.hari,
      jamMulai: draft.jamMulai,
      jamSelesai: draft.jamSelesai,
      kecualiJadwalId: exceptScheduleId,
    );
  }

  // Digunakan untuk tambah maupun edit jadwal.
  Future<int> save(
    JadwalDraft draft, {
    JadwalDenganMataKuliah? jadwalAwal,
  }) async {
    if (jadwalAwal != null) {
      final jadwalId = jadwalAwal.jadwal.id;

      await database.updateJadwalLengkap(
        jadwalId: jadwalId,
        mataKuliahId: jadwalAwal.mataKuliah.id,
        namaMataKuliah: draft.namaMataKuliah,
        dosen: draft.dosen,
        sks: draft.sks,
        hari: draft.hari,
        jamMulai: draft.jamMulai,
        jamSelesai: draft.jamSelesai,
        ruangan: draft.ruangan,
        pengingatAktif: draft.pengingatAktif,
        menitSebelum: draft.menitSebelum,
      );

      return jadwalId;
    }

    return database.tambahJadwalLengkap(
      namaMataKuliah: draft.namaMataKuliah,
      dosen: draft.dosen,
      sks: draft.sks,
      hari: draft.hari,
      jamMulai: draft.jamMulai,
      jamSelesai: draft.jamSelesai,
      ruangan: draft.ruangan,
      pengingatAktif: draft.pengingatAktif,
      menitSebelum: draft.menitSebelum,
    );
  }

  // Menghapus jadwal dan membatalkan pengingat.
  Future<void> delete(
    JadwalDenganMataKuliah data,
  ) async {
    final jadwalId = data.jadwal.id;

    await database.hapusJadwalLengkap(
      jadwalId: jadwalId,
      mataKuliahId: data.mataKuliah.id,
    );

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      await NotificationService.batalkanPengingat(jadwalId);
    }
  }
}
