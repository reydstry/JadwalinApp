import 'package:flutter/material.dart';

import 'jadwal_form_style.dart';

class JamKuliahField extends StatelessWidget {
  const JamKuliahField({
    super.key,
    required this.label,
    required this.time,
    required this.onTap,
    this.validator,
  });
  final String label;
  final TimeOfDay? time;
  final VoidCallback? onTap;
  final FormFieldValidator<TimeOfDay>? validator;
  @override
  Widget build(BuildContext context) => JadwalField(
    label: label,
    child: FormField<TimeOfDay>(
      // Update the FormField value when a time is selected, without controller text.
      key: ValueKey('$label-$time'),
      initialValue: time,
      validator:
          validator ??
          (value) => value == null ? 'Jam mulai wajib dipilih' : null,
      builder: (state) => InkWell(
        key: ValueKey(label == 'Jam Mulai' ? 'schedule_start' : 'schedule_end'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Semantics(
          button: true,
          label: label,
          child: InputDecorator(
            isEmpty: false,
            decoration: InputDecoration(
              errorText: state.errorText,
              enabled: onTap != null,
              prefixIcon: const SizedBox.square(
                dimension: 48,
                child: Column(
                  children: [
                    Spacer(),
                    Row(
                      children: [Spacer(), JadwalFormIcon('clock'), Spacer()],
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ),
            child: Text(
              time == null
                  ? 'Pilih waktu'
                  : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: time == null
                    ? const Color(0xFF757575)
                    : const Color(0xFF1E3A5F),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
