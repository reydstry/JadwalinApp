import 'package:flutter/material.dart';

class PengingatForm extends StatelessWidget {
  final bool pengingatAktif;
  final int menitSebelum;

  final ValueChanged<bool> onPengingatChanged;
  final ValueChanged<int> onMenitChanged;

  const PengingatForm({
    super.key,
    required this.pengingatAktif,
    required this.menitSebelum,
    required this.onPengingatChanged,
    required this.onMenitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Aktifkan Pengingat'),
            subtitle: const Text('Ingatkan sebelum jadwal dimulai'),
            value: pengingatAktif,
            onChanged: onPengingatChanged,
          ),

          if (pengingatAktif)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DropdownButtonFormField<int>(
                initialValue: menitSebelum,
                decoration: const InputDecoration(
                  labelText: 'Waktu Pengingat',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5 menit sebelumnya')),
                  DropdownMenuItem(
                    value: 10,
                    child: Text('10 menit sebelumnya'),
                  ),
                  DropdownMenuItem(
                    value: 15,
                    child: Text('15 menit sebelumnya'),
                  ),
                  DropdownMenuItem(
                    value: 30,
                    child: Text('30 menit sebelumnya'),
                  ),
                  DropdownMenuItem(value: 60, child: Text('1 jam sebelumnya')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onMenitChanged(value);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
