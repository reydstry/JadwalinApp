import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'jadwal_form_style.dart';

class JadwalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const JadwalAppBar({
    super.key,
    required this.isSaving,
    required this.isEditing,
    required this.onBack,
  });
  final bool isSaving;
  final bool isEditing;
  final VoidCallback onBack;
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        tooltip: 'Kembali',
        onPressed: isSaving ? null : onBack,
        icon: const JadwalFormIcon('back', size: 28),
      ),
      title: Text(
        isEditing ? 'Edit Jadwal' : 'Tambah Jadwal',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      toolbarHeight: 64,
    );
  }
}
