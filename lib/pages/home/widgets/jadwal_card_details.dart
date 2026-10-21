import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/time_helper.dart';
import 'home_icon.dart';

class JadwalCardDetails extends StatelessWidget {
  const JadwalCardDetails({
    super.key,
    required this.data,
    required this.compact,
  });
  final JadwalDenganMataKuliah data;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final jadwal = data.jadwal;
    final mataKuliah = data.mataKuliah;
    return Column(
      children: [
        _detailPair(
          _InfoDetail(
            icon: 'clock',
            label: 'Waktu Kuliah',
            value: TimeHelper.formatRange(jadwal.jamMulai, jadwal.jamSelesai),
          ),
          _InfoDetail(
            icon: 'room',
            label: 'Ruangan',
            value: _value(jadwal.ruangan),
          ),
        ),
        const SizedBox(height: 14),
        _detailPair(
          _InfoDetail(
            icon: 'lecturer',
            label: 'Dosen',
            value: _value(mataKuliah.dosen),
          ),
          _InfoDetail(
            icon: 'credits',
            label: 'SKS',
            value: mataKuliah.sks?.toString() ?? '-',
          ),
        ),
      ],
    );
  }

  Widget _detailPair(Widget first, Widget second) => compact
      ? Column(children: [first, const SizedBox(height: 10), second])
      : IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(children: [first, const Spacer()]),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(children: [second, const Spacer()]),
              ),
            ],
          ),
        );

  String _value(String? value) =>
      value == null || value.trim().isEmpty ? '-' : value.trim();
}

class _InfoDetail extends StatelessWidget {
  const _InfoDetail({
    required this.icon,
    required this.label,
    required this.value,
  });
  final String icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      children: [
        Column(children: [HomeIcon(icon), const Spacer()]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    ),
  );
}
