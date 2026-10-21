import 'package:flutter/material.dart';

import 'jadwal_form_style.dart';

class MataKuliahForm extends StatelessWidget {
  const MataKuliahForm({
    super.key,
    required this.namaController,
    required this.dosenController,
    required this.sksController,
    this.enabled = true,
  });
  final TextEditingController namaController;
  final TextEditingController dosenController;
  final TextEditingController sksController;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      JadwalField(
        label: 'Mata Kuliah',
        child: TextFormField(
          key: const Key('schedule_name'),
          controller: namaController,
          enabled: enabled,
          decoration: const InputDecoration(
            hintText: 'Nama Mata Kuliah',
            prefixIcon: SizedBox.square(
              dimension: 48,
              child: Column(
                children: [
                  Spacer(),
                  Row(children: [Spacer(), JadwalFormIcon('book'), Spacer()]),
                  Spacer(),
                ],
              ),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama mata kuliah wajib diisi';
            }
            if (value.trim().length > 100) {
              return 'Nama mata kuliah maksimal 100 karakter';
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 14),
      JadwalField(
        label: 'Nama Dosen',
        child: TextFormField(
          key: const Key('schedule_lecturer'),
          controller: dosenController,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Nama Dosen Pengampu',
            prefixIcon: SizedBox.square(
              dimension: 48,
              child: Column(
                children: [
                  Spacer(),
                  Row(
                    children: [Spacer(), JadwalFormIcon('lecturer'), Spacer()],
                  ),
                  Spacer(),
                ],
              ),
            ),
          ),
          textInputAction: TextInputAction.next,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Nama dosen wajib diisi'
              : null,
        ),
      ),
      const SizedBox(height: 14),
      JadwalField(
        label: 'Jumlah SKS',
        child: TextFormField(
          key: const Key('schedule_credits'),
          controller: sksController,
          enabled: enabled,
          decoration: const InputDecoration(
            hintText: 'Contoh: 3',
            prefixIcon: SizedBox.square(
              dimension: 48,
              child: Column(
                children: [
                  Spacer(),
                  Row(
                    children: [Spacer(), JadwalFormIcon('credits'), Spacer()],
                  ),
                  Spacer(),
                ],
              ),
            ),
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Jumlah SKS wajib diisi';
            }
            final sks = int.tryParse(value.trim());
            return sks == null || sks <= 0
                ? 'SKS harus berupa bilangan bulat positif'
                : null;
          },
        ),
      ),
    ],
  );
}
