import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/app_bootstrapper.dart';
import '../../theme/app_colors.dart';

typedef SplashLoader = Future<AppBootstrapResult> Function(
  BootstrapProgressCallback onProgress,
);
typedef SplashDestinationBuilder = Widget Function(
  BuildContext context,
  AppBootstrapResult result,
);

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.load,
    required this.destinationBuilder,
  });

  final SplashLoader load;
  final SplashDestinationBuilder destinationBuilder;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _progress = 0;
  bool _hasNavigated = false;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _runLoading();
  }

  Future<void> _runLoading() async {
    try {
      final result = await widget.load(_reportProgress);

      if (!mounted || _hasNavigated) return;

      _reportProgress(1);
      _hasNavigated = true;
      _isLoading = false;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => widget.destinationBuilder(context, result),
        ),
      );
    } catch (_) {
      if (!mounted || _hasNavigated) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _reportProgress(double progress) {
    if (!mounted || _hasNavigated || !_isLoading) return;

    setState(() {
      _progress = progress.clamp(0, 1).toDouble();
    });
  }

  void _retry() {
    if (_isLoading || _hasNavigated) return;

    setState(() {
      _progress = 0;
      _hasError = false;
      _isLoading = true;
    });

    _runLoading();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _SplashError(onRetry: _retry);
    }

    final percentage = (_progress * 100).round();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Semantics(
          label: 'Memuat aplikasi $percentage%',
          value: '$percentage%',
          child: ExcludeSemantics(child: _LiquidLogo(progress: _progress)),
        ),
      ),
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.all(32),
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
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
          ),
        ),
      ),
    );
  }
}

class _LiquidLogo extends StatefulWidget {
  const _LiquidLogo({required this.progress});

  final double progress;

  @override
  State<_LiquidLogo> createState() => _LiquidLogoState();
}

class _LiquidLogoState extends State<_LiquidLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _waveController.stop();
    } else if (!_waveController.isAnimating) {
      _waveController.repeat();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 201.0;

    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: ColoredBox(
          color: Colors.white,
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _LiquidPainter(
                      progress: widget.progress,
                      phase: _waveController.value,
                    ),
                  ),
                  Opacity(
                    opacity: widget.progress,
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      key: const ValueKey('splash-logo'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  const _LiquidPainter({required this.progress, required this.phase});

  final double progress;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final surfaceY = size.height * (1 - progress);
    final wavePath = Path()..moveTo(0, surfaceY);

    for (var x = 0.0; x <= size.width; x += 2) {
      final angle = ((x / size.width) * math.pi * 2) + (phase * math.pi * 2);
      wavePath.lineTo(x, surfaceY + (math.sin(angle) * 5));
    }

    wavePath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      wavePath,
      Paint()
        ..color = const Color(0xFFFFD9BF)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.phase != phase;
  }
}
