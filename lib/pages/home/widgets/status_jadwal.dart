import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class JadwalLoadError extends StatelessWidget {
  const JadwalLoadError({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                      minHeight: (constraints.maxHeight - 48).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off_outlined,
                                color: Colors.white70,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Jadwal belum dapat dimuat',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Silakan coba lagi untuk menampilkan jadwalmu.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: onRetry,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.peach,
                                  foregroundColor: AppColors.primary,
                                ),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba lagi'),
                              ),
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
}

class JadwalLoading extends StatelessWidget {
  const JadwalLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Spacer(),
        Row(
          children: [
            Spacer(),
            CircularProgressIndicator(
              color: AppColors.peach,
              semanticsLabel: 'Memuat jadwal',
            ),
            Spacer(),
          ],
        ),
        Spacer(),
      ],
    );
  }
}
