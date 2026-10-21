import 'package:flutter/material.dart';

import '../../../utils/day_helper.dart';
import 'jadwal_form_style.dart';
import 'jam_kuliah_field.dart';

class WaktuKuliahForm extends StatelessWidget {
  const WaktuKuliahForm({
    super.key,
    required this.hari,
    required this.onHariChanged,
    required this.jamMulai,
    required this.jamSelesai,
    required this.onPilihJamMulai,
    required this.onPilihJamSelesai,
    required this.ruanganController,
    required this.stackTimes,
    this.enabled = true,
  });
  final int hari;
  final ValueChanged<int> onHariChanged;
  final TimeOfDay? jamMulai;
  final TimeOfDay? jamSelesai;
  final VoidCallback onPilihJamMulai;
  final VoidCallback onPilihJamSelesai;
  final TextEditingController ruanganController;
  final bool enabled;
  final bool stackTimes;

  @override
  Widget build(BuildContext context) {
    final start = JamKuliahField(
      label: 'Jam Mulai',
      time: jamMulai,
      onTap: enabled ? onPilihJamMulai : null,
    );
    final end = JamKuliahField(
      label: 'Jam Selesai',
      time: jamSelesai,
      onTap: enabled ? onPilihJamSelesai : null,
      validator: (value) {
        if (value == null) return 'Jam selesai wajib dipilih';
        if (jamMulai != null &&
            value.hour * 60 + value.minute <=
                jamMulai!.hour * 60 + jamMulai!.minute) {
          return 'Harus setelah jam mulai';
        }
        return null;
      },
    );
    return Column(
      children: [
        JadwalField(
          label: 'Hari Kuliah',
          child: DropdownButtonFormField<int>(
            key: const Key('schedule_day'),
            initialValue: hari,
            isExpanded: true,
            dropdownColor: Colors.white,
            decoration: const InputDecoration(),
            items: DayHelper.dayNames.entries
                .map(
                  (day) =>
                      DropdownMenuItem(value: day.key, child: Text(day.value)),
                )
                .toList(),
            onChanged: enabled
                ? (value) {
                    if (value != null) onHariChanged(value);
                  }
                : null,
          ),
        ),
        const SizedBox(height: 14),
        if (stackTimes)
          Column(children: [start, const SizedBox(height: 14), end])
        else
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: Column(children: [start, const Spacer()])),
                const SizedBox(width: 12),
                Expanded(child: Column(children: [end, const Spacer()])),
              ],
            ),
          ),
        const SizedBox(height: 14),
        JadwalField(
          label: 'Ruangan',
          child: TextFormField(
            key: const Key('schedule_room'),
            controller: ruanganController,
            enabled: enabled,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Contoh: G301',
              prefixIcon: SizedBox.square(
                dimension: 48,
                child: Column(
                  children: [
                    Spacer(),
                    Row(children: [Spacer(), JadwalFormIcon('room'), Spacer()]),
                    Spacer(),
                  ],
                ),
              ),
            ),
            textInputAction: TextInputAction.done,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ruangan wajib diisi'
                : null,
          ),
        ),
      ],
    );
  }
}
