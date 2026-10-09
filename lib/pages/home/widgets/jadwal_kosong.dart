import 'package:flutter/material.dart';

class JadwalKosong extends StatelessWidget {
  final String dayName;
  final VoidCallback onAdd;

  const JadwalKosong({super.key, required this.dayName, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available_outlined, size: 64),

            const SizedBox(height: 16),

            Text(
              'Tidak ada jadwal',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Belum ada jadwal untuk $dayName.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Jadwal'),
            ),
          ],
        ),
      ),
    );
  }
}
