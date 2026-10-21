import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'jadwal_form_style.dart';

class PengingatForm extends StatelessWidget {
  const PengingatForm({
    super.key,
    required this.pengingatAktif,
    required this.menitSebelum,
    required this.onPengingatChanged,
    required this.onMenitChanged,
    this.enabled = true,
  });
  final bool pengingatAktif;
  final int menitSebelum;
  final ValueChanged<bool> onPengingatChanged;
  final ValueChanged<int> onMenitChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Row(
              children: [
                SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Column(
                            children: [
                              Spacer(),
                              Row(
                                children: [
                                  Spacer(),
                                  JadwalFormIcon('bell', size: 24),
                                  Spacer(),
                                ],
                              ),
                              Spacer(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Aktifkan Pengingat',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Notifikasi sebelum kelas dimulai',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        key: const Key('schedule_reminder'),
                        value: pengingatAktif,
                        onChanged: enabled ? onPengingatChanged : null,
                        activeTrackColor: AppColors.primary,
                        activeThumbColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
              ],
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
      if (pengingatAktif) ...[
        const SizedBox(height: 14),
        Semantics(
          label: 'Waktu pengingat',
          child: DropdownButtonFormField<int>(
            key: ValueKey('reminder_minutes_$menitSebelum'),
            initialValue: menitSebelum,
            isExpanded: true,
            dropdownColor: Colors.white,
            items: [
              for (var minutes = 5; minutes <= 60; minutes += 5)
                DropdownMenuItem(
                  value: minutes,
                  child: Text('$minutes menit sebelumnya'),
                ),
            ],
            onChanged: enabled
                ? (value) {
                    if (value != null) onMenitChanged(value);
                  }
                : null,
          ),
        ),
      ],
    ],
  );
}
