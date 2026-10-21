import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/app_bootstrapper.dart';
import '../../theme/app_colors.dart';
import 'widgets/splash_error.dart';
import 'widgets/liquid_logo.dart';

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

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _minimumDisplayDuration = Duration(milliseconds: 1500);
  late final AnimationController _progressController;
  double _targetProgress = 0;
  double get _progress => _progressController.value;
  bool _hasNavigated = false;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    )..addListener(() => setState(() {}));
    _runLoading();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  TickerFuture _animateProgress(double target) {
    _targetProgress = target;
    // Limit reveal speed so moving from 0 to 1 takes at least 1.5 seconds.
    final milliseconds = math.max(
      250,
      (_minimumDisplayDuration.inMilliseconds * (target - _progress)).ceil(),
    );
    return _progressController.animateTo(
      target,
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.linear,
    );
  }

  Future<void> _runLoading() async {
    try {
      final result = await widget.load(_reportProgress);

      if (!mounted || _hasNavigated) return;

      await _animateProgress(1).orCancel;
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      _isLoading = false;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => widget.destinationBuilder(context, result),
        ),
      );
    } on TickerCanceled {
      // The page was disposed before its reveal finished.
      return;
    } catch (_) {
      if (!mounted || _hasNavigated) return;

      _progressController.stop();
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _reportProgress(double progress) {
    if (!mounted || _hasNavigated || !_isLoading) return;

    // Reserve the full logo for a successfully completed loader.
    final target = progress.clamp(0.0, 0.9).toDouble();
    if (target > _targetProgress) _animateProgress(target);
  }

  void _retry() {
    if (_isLoading || _hasNavigated) return;

    setState(() {
      _targetProgress = 0;
      _progressController.reset();
      _hasError = false;
      _isLoading = true;
    });

    _runLoading();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return SplashError(onRetry: _retry);
    }

    final percentage = (_progress * 100).round();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          const Spacer(),
          Row(
            children: [
              const Spacer(),
              Semantics(
                label: 'Memuat aplikasi $percentage%',
                value: '$percentage%',
                child: ExcludeSemantics(child: LiquidLogo(progress: _progress)),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
