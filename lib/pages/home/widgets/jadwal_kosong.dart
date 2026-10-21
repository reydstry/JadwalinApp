import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'tambah_jadwal_button.dart';

class JadwalKosong extends StatelessWidget {
  const JadwalKosong({
    super.key,
    required this.dayName,
    required this.onAdd,
    this.showOfflineMessage = false,
  });
  final String dayName;
  final VoidCallback onAdd;
  final bool showOfflineMessage;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24),
          Row(
            children: [
              const Spacer(),
              SizedBox(
                width: (constraints.maxWidth - 2 * (24)).clamp(
                  0.0,
                  double.infinity,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: (constraints.maxWidth - 48).clamp(
                      0,
                      double.infinity,
                    ),
                    minHeight: (constraints.maxHeight - 48).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            // Preserve the illustration's original geometry and surrounding space.
                            ClipRect(
                              child: SizedBox.square(
                                dimension: 120,
                                child: SvgPicture.asset(
                                  'assets/icon/empty.svg',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.none,
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Tidak Ada Jadwal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (showOfflineMessage) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Kamu sedang offline dan belum memiliki jadwal tersimpan di perangkat ini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                            const SizedBox(height: 14),
                            TambahJadwalButton(
                              onPressed: onAdd,
                              showLabel: true,
                            ),
                            SizedBox(height: constraints.maxHeight * 0.18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
    ),
  );
}
