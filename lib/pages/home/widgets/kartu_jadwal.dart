import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../utils/time_helper.dart';
import '../../../theme/app_colors.dart';

class KartuJadwal extends StatelessWidget {
  final JadwalDenganMataKuliah data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const KartuJadwal({
    super.key,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color navy = AppColors.primary;
  static const Color orange = AppColors.secondary;
  static const Color secondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final jadwal = data.jadwal;
    final mataKuliah = data.mataKuliah;

    final ruangan = jadwal.ruangan?.trim();
    final dosen = mataKuliah.dosen?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. JUDUL DAN TOMBOL AKSI
            Row(
              children: [
                Expanded(
                  child: Text(
                    mataKuliah.nama,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: navy,
                    ),
                  ),
                ),

                IconButton(
                  tooltip: 'Edit jadwal',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, color: navy, size: 22),
                ),

                IconButton(
                  tooltip: 'Hapus jadwal',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. BARIS PERTAMA: WAKTU DAN RUANGAN
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoDetail(
                    icon: Icons.access_time,
                    label: 'Waktu',
                    value: TimeHelper.formatRange(
                      jadwal.jamMulai,
                      jadwal.jamSelesai,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _InfoDetail(
                    icon: Icons.location_on_outlined,
                    label: 'Ruangan',
                    value: ruangan == null || ruangan.isEmpty ? '-' : ruangan,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. BARIS KEDUA: DOSEN DAN BOBOT
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoDetail(
                    icon: Icons.person_outline,
                    label: 'Dosen',
                    value: dosen == null || dosen.isEmpty ? '-' : dosen,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _InfoDetail(
                    icon: Icons.school_outlined,
                    label: 'Bobot',
                    value: mataKuliah.sks == null
                        ? '-'
                        : '${mataKuliah.sks} SKS',
                  ),
                ),
              ],
            ),

            // 4. PENGINGAT
            if (jadwal.pengingatAktif) ...[
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E8),
                  borderRadius: BorderRadius.circular(10),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        '${jadwal.menitSebelum} menit sebelum kelas',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget untuk keempat informasi jadwal
class _InfoDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: KartuJadwal.orange, size: 22),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: KartuJadwal.secondary,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KartuJadwal.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
