import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'jadwal_form_style.dart';

class SimpanJadwalButton extends StatelessWidget {
  const SimpanJadwalButton({
    super.key,
    required this.isSaving,
    required this.isEditing,
    required this.onSave,
  });
  final bool isSaving;
  final bool isEditing;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('schedule_save'),
          onPressed: isSaving ? null : onSave,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            disabledBackgroundColor: Colors.white70,
            minimumSize: const Size(0, 52),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : (isEditing
                    ? const Icon(Icons.check)
                    : const JadwalFormIcon('add')),
          label: Text(
            isSaving
                ? 'Menyimpan...'
                : isEditing
                ? 'Simpan Perubahan'
                : 'Tambah Jadwal',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
