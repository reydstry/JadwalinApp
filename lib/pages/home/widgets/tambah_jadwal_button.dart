import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class TambahJadwalButton extends StatelessWidget {
  const TambahJadwalButton({
    super.key,
    required this.onPressed,
    this.showLabel = false,
  });
  final VoidCallback onPressed;
  final bool showLabel;
  @override
  Widget build(BuildContext context) => showLabel
      ? FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.peach,
            foregroundColor: AppColors.primary,
            minimumSize: const Size(236, 50),
            visualDensity: VisualDensity.standard,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: const Icon(Icons.add, size: 28),
          label: const Text('Tambah Jadwal'),
        )
      : IconButton.filled(
          tooltip: 'Tambah Jadwal',
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.peach,
            fixedSize: const Size(56, 56),
            visualDensity: VisualDensity.standard,
            shape: const CircleBorder(),
            side: const BorderSide(color: AppColors.peach),
            elevation: 4,
            shadowColor: Colors.black45,
          ),
          icon: const Icon(Icons.add, size: 28),
        );
}
