import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/app_bootstrapper.dart';
import '../../theme/app_colors.dart';

typedef SplashLoader = Future<void> Function(
  BootstrapProgressCallback onProgress,
);

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.load,
    required this.destinationBuilder,
  });

  final SplashLoader load;
  final WidgetBuilder destinationBuilder;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _progress = 0;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    try {
      await widget.load(_reportProgress);

      if (!mounted || _hasNavigated) return;

      _reportProgress(1);
      _hasNavigated = true;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: widget.destinationBuilder),
      );
    } catch (error, stackTrace) {
      debugPrint('Persiapan aplikasi gagal: $error\n$stackTrace');
    }
  }

  void _reportProgress(double progress) {
    if (!mounted || _hasNavigated) return;

    setState(() {
      _progress = progress.clamp(0, 1).toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
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
