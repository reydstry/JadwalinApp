import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class SplashError extends StatelessWidget {
  const SplashError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 32),
                          Row(
                            children: [
                              const Spacer(),
                              SizedBox(
                                width: (constraints.maxWidth - 2 * (32)).clamp(
                                  0.0,
                                  double.infinity,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.white,
                                      size: 56,
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Aplikasi belum siap',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Terjadi masalah saat menyiapkan aplikasi. '
                                      'Periksa kembali lalu coba lagi.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: onRetry,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        foregroundColor: AppColors.primary,
                                      ),
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Coba lagi'),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
