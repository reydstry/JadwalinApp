import 'package:flutter/material.dart';

import '../../../utils/day_helper.dart';

class WaktuKuliahForm extends StatelessWidget {
  final int hari;
  final ValueChanged<int> onHariChanged;

  final TimeOfDay? jamMulai;
  final TimeOfDay? jamSelesai;

  final VoidCallback onPilihJamMulai;
  final VoidCallback onPilihJamSelesai;

  final TextEditingController ruanganController;

  const WaktuKuliahForm({
    super.key,
    required this.hari,
    required this.onHariChanged,
    required this.jamMulai,
    required this.jamSelesai,
    required this.onPilihJamMulai,
    required this.onPilihJamSelesai,
    required this.ruanganController,
  });

  String _formatWaktu(TimeOfDay? time) {
    if (time == null) {
      return 'Pilih waktu';
    }

    final jam = time.hour.toString().padLeft(2, '0');
    final menit = time.minute.toString().padLeft(2, '0');

    return '$jam:$menit';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          initialValue: hari,
          decoration: const InputDecoration(
            labelText: 'Hari',
            prefixIcon: Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(),
          ),
          items: DayHelper.dayNames.keys.map((day) {
            return DropdownMenuItem<int>(
              value: day,
              child: Text(DayHelper.dayNames[day] ?? '-'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onHariChanged(value);
            }
          },
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: 'Jam Mulai',
                value: _formatWaktu(jamMulai),
                onTap: onPilihJamMulai,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _TimeField(
                label: 'Jam Selesai',
                value: _formatWaktu(jamSelesai),
                onTap: onPilihJamSelesai,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: ruanganController,
          decoration: const InputDecoration(
            labelText: 'Ruangan',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

// Widget internal untuk menampilkan pilihan jam.
class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time),
          border: const OutlineInputBorder(),
        ),
        child: Text(value),
      ),
    );
  }
}
