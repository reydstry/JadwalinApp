import 'package:flutter/material.dart';

class BuangPerubahanDialog extends StatelessWidget {
  const BuangPerubahanDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Buang perubahan?'),
      content: const Text(
        'Perubahan jadwal belum disimpan. Kembali akan membuang perubahan ini.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Lanjut Mengisi'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Buang Perubahan'),
        ),
      ],
    );
  }
}
