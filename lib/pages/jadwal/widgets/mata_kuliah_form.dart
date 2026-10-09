import 'package:flutter/material.dart';

class MataKuliahForm extends StatelessWidget {
  final TextEditingController namaController;
  final TextEditingController dosenController;
  final TextEditingController sksController;

  const MataKuliahForm({
    super.key,
    required this.namaController,
    required this.dosenController,
    required this.sksController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: namaController,
          decoration: const InputDecoration(
            labelText: 'Mata Kuliah',
            prefixIcon: Icon(Icons.menu_book_outlined),
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama mata kuliah wajib diisi';
            }

            return null;
          },
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: dosenController,
          decoration: const InputDecoration(
            labelText: 'Dosen',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: sksController,
          decoration: const InputDecoration(
            labelText: 'SKS',
            prefixIcon: Icon(Icons.numbers),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return null;
            }

            final sks = int.tryParse(value.trim());

            if (sks == null || sks <= 0) {
              return 'SKS harus berupa angka positif';
            }

            return null;
          },
        ),
      ],
    );
  }
}
