import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'home_icon.dart';

class JadwalCardHeader extends StatelessWidget {
  const JadwalCardHeader({
    super.key,
    required this.nama,
    required this.compact,
    required this.onEdit,
    required this.onDelete,
  });
  final String nama;
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final title = Tooltip(
      message: nama,
      child: Text(
        nama,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
    final actions = [
      IconButton(
        tooltip: 'Edit jadwal',
        onPressed: onEdit,
        visualDensity: VisualDensity.compact,
        icon: const HomeIcon('edit', size: 18),
      ),
      IconButton(
        tooltip: 'Hapus jadwal',
        onPressed: onDelete,
        visualDensity: VisualDensity.compact,
        icon: const HomeIcon('delete', size: 18),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: title
                            )
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              ...actions.map(
                (action) => Column(children: [action, const Spacer()]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
