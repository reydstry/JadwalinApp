import 'package:flutter/material.dart';

import '../../../database/database.dart';
import 'status_jadwal.dart';
import '../../../utils/day_helper.dart';
import 'jadwal_kosong.dart';
import 'kartu_jadwal.dart';

class ListJadwal extends StatelessWidget {
  const ListJadwal({
    super.key,
    required this.snapshot,
    required this.selectedDay,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
    this.showOfflineEmptyState = false,
  });
  final AsyncSnapshot<List<JadwalDenganMataKuliah>> snapshot;
  final int selectedDay;
  final VoidCallback onAdd;
  final ValueChanged<JadwalDenganMataKuliah> onEdit;
  final ValueChanged<JadwalDenganMataKuliah> onDelete;
  final VoidCallback onRetry;
  final bool showOfflineEmptyState;
  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return JadwalLoadError(onRetry: onRetry);
    }
    if (!snapshot.hasData ||
        snapshot.connectionState == ConnectionState.waiting) {
      return const JadwalLoading();
    }
    final allSchedules = snapshot.data!;
    final daySchedules =
        allSchedules.where((data) => data.jadwal.hari == selectedDay).toList()
          ..sort((a, b) {
            final byTime = a.jadwal.jamMulai.compareTo(b.jadwal.jamMulai);
            return byTime != 0 ? byTime : a.jadwal.id.compareTo(b.jadwal.id);
          });
    if (daySchedules.isEmpty) {
      return JadwalKosong(
        dayName: DayHelper.dayNames[selectedDay] ?? '-',
        onAdd: onAdd,
        showOfflineMessage: showOfflineEmptyState && allSchedules.isEmpty,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const sideGap = 19.0;
        final size = MediaQuery.sizeOf(context);
        final columns = size.width > size.height ? 2 : 1;
        final rowCount = (daySchedules.length + columns - 1) ~/ columns;
        final compact =
            (constraints.maxWidth - sideGap * 2 - spacing * (columns - 1)) /
                columns <
            300;

        Widget card(int index) {
          final data = daySchedules[index];
          return KartuJadwal(
            key: ValueKey('schedule_${data.jadwal.id}'),
            data: data,
            compact: compact,
            onEdit: () => onEdit(data),
            onDelete: () => onDelete(data),
          );
        }

        // Build rows lazily while letting their height follow text size/content.
        return Row(
          children: [
            const Spacer(),
            SizedBox(
              width: (constraints.maxWidth - sideGap * 2).clamp(
                0.0,
                double.infinity,
              ),
              child: ListView.separated(
                key: PageStorageKey('schedules_${selectedDay}_$columns'),
                itemCount: rowCount,
                separatorBuilder: (_, _) => const SizedBox(height: spacing),
                itemBuilder: (context, row) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (row == 0) const SizedBox(height: 8),
                    if (columns == 1)
                      card(row)
                    else
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [card(row * 2), const Spacer()],
                              ),
                            ),
                            const SizedBox(width: spacing),
                            Expanded(
                              child: Column(
                                children: [
                                  row * 2 + 1 < daySchedules.length
                                      ? card(row * 2 + 1)
                                      : const SizedBox.shrink(),
                                  const Spacer(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Allow the final card to scroll clear of the floating action.
                    if (row == rowCount - 1) const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        );
      },
    );
  }
}
