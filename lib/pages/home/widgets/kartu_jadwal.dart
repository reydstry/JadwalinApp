import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../theme/app_colors.dart';
import 'jadwal_card_header.dart';
import 'jadwal_card_details.dart';
import 'jadwal_card_reminder.dart';

/// Menyusun header, rincian kuliah, dan pengingat sesuai konten jadwal.
class KartuJadwal extends StatelessWidget {
  const KartuJadwal({
    super.key,
    required this.data,
    required this.onEdit,
    required this.onDelete,
    this.compact = false,
  });
  final JadwalDenganMataKuliah data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final jadwal = data.jadwal;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 2),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.0),
          Row(
            children: [
              SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  children: [
                    JadwalCardHeader(
                      nama: data.mataKuliah.nama,
                      compact: compact,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                    const SizedBox(height: 12),
                    JadwalCardDetails(data: data, compact: compact),
                    if (jadwal.pengingatAktif) ...[
                      const SizedBox(height: 12),
                      JadwalCardReminder(
                        menitSebelum: jadwal.menitSebelum,
                        compact: compact,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 16.0),
            ],
          ),
          SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
