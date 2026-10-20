import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../utils/day_helper.dart';
import 'jadwal_kosong.dart';
import 'kartu_jadwal.dart';

class ListJadwal extends StatelessWidget {
  final Stream<List<JadwalDenganMataKuliah>> stream;
  final int selectedDay;
  final VoidCallback onAdd;
  final ValueChanged<JadwalDenganMataKuliah> onEdit;
  final ValueChanged<JadwalDenganMataKuliah> onDelete;
  final bool showOfflineEmptyState;

  const ListJadwal({
    super.key,
    required this.stream,
    required this.selectedDay,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.showOfflineEmptyState = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JadwalDenganMataKuliah>>(
      stream: stream,
      builder: (context, snapshot) {
        // Error database atau stream.
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Terjadi kesalahan:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Menunggu data pertama.
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allSchedules = snapshot.data!;

        // Filter berdasarkan hari terpilih.
        final daySchedules = allSchedules.where((data) {
          return data.jadwal.hari == selectedDay;
        }).toList();

        // Tampilan jika tidak ada jadwal.
        if (daySchedules.isEmpty) {
          return JadwalKosong(
            dayName: DayHelper.dayNames[selectedDay] ?? '-',
            onAdd: onAdd,
            showOfflineMessage: showOfflineEmptyState && allSchedules.isEmpty,
          );
        }

        // Menampilkan daftar jadwal.
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: daySchedules.length,
          separatorBuilder: (_, _) {
            return const SizedBox(height: 12);
          },
          itemBuilder: (context, index) {
            final data = daySchedules[index];

            return KartuJadwal(
              data: data,
              onEdit: () => onEdit(data),
              onDelete: () => onDelete(data),
            );
          },
        );
      },
    );
  }
}
