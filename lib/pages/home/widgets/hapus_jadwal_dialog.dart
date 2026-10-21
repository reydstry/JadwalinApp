import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class HapusJadwalDialog extends StatelessWidget {
  const HapusJadwalDialog({super.key, required this.namaMataKuliah});
  final String namaMataKuliah;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.primary,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
      title: const Text('Hapus Jadwal'),
      content: Text('Hapus jadwal $namaMataKuliah?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('Batal', style: TextStyle(color: Colors.white)),
        ),

        FilledButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.peach,
            foregroundColor: AppColors.primary,
          ),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}
