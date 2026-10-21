import 'package:flutter/material.dart';

import '../auth_prompt.dart';

/// Branding dan perpindahan login/register; tombol kembali bersifat opsional.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.availableWidth,
    required this.enabled,
    required this.title,
    required this.message,
    required this.action,
    required this.onPromptPressed,
    this.onBack,
  });

  final double availableWidth;
  final bool enabled;
  final String title;
  final String message;
  final String action;
  final VoidCallback? onPromptPressed;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final branding = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(31),
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: 124,
            height: 124,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEEEEEE),
            fontSize: 32,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.64,
          ),
        ),
        const SizedBox(height: 12),
        AuthPrompt(
          availableWidth: availableWidth,
          message: message,
          action: action,
          enabled: enabled,
          onPressed: onPromptPressed,
        ),
      ],
    );

    if (onBack == null) return branding;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Kembali ke login',
              onPressed: enabled ? onBack : null,
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              color: const Color(0xFFEEEEEE),
              icon: const Icon(Icons.arrow_back, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 32),
        branding,
      ],
    );
  }
}
