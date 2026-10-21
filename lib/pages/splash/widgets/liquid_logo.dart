import 'dart:math' as math;

import 'package:flutter/material.dart';

class LiquidLogo extends StatefulWidget {
  const LiquidLogo({super.key, required this.progress});

  final double progress;

  @override
  State<LiquidLogo> createState() => _LiquidLogoState();
}

class _LiquidLogoState extends State<LiquidLogo>
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
            child: Image.asset(
              'assets/icon/app_icon.png',
              key: const ValueKey('splash-logo'),
              fit: BoxFit.cover,
            ),
            builder: (context, child) {
              return ClipPath(
                key: const ValueKey('splash-logo-reveal'),
                clipper: _LogoWaveClipper(
                  progress: widget.progress,
                  phase: _waveController.value,
                ),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LogoWaveClipper extends CustomClipper<Path> {
  const _LogoWaveClipper({required this.progress, required this.phase});

  final double progress;
  final double phase;

  @override
  Path getClip(Size size) {
    if (progress <= 0) return Path();
    if (progress >= 1) return Path()..addRect(Offset.zero & size);

    final surfaceY = size.height * (1 - progress);
    final amplitude = 5 * math.sin(math.pi * progress);
    final wavePath = Path()
      ..moveTo(0, surfaceY + math.sin(phase * math.pi * 2) * amplitude);

    for (var x = 0.0; x <= size.width; x += 2) {
      final angle = ((x / size.width) * math.pi * 2) + (phase * math.pi * 2);
      wavePath.lineTo(x, surfaceY + math.sin(angle) * amplitude);
    }

    wavePath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    return wavePath;
  }

  @override
  bool shouldReclip(covariant _LogoWaveClipper oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.phase != phase;
  }
}
