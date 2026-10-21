import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.fontSize,
    required this.isSubmitting,
    required this.onSubmit,
  });
  final String label;
  final double fontSize;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: isSubmitting ? null : onSubmit,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFD9BF),
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: const Color(0x99FFD9BF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isSubmitting
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class AuthSubmitError extends StatelessWidget {
  const AuthSubmitError({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFFFD9BF)),
      ),
    );
  }
}
