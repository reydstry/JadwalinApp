import 'package:flutter/material.dart';

class AuthPrompt extends StatelessWidget {
  const AuthPrompt({
    super.key,
    required this.message,
    required this.availableWidth,
    required this.action,
    required this.enabled,
    required this.onPressed,
  });

  final String message;
  final double availableWidth;
  final String action;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const messageStyle = TextStyle(
      color: Color(0xFFEEEEEE),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    const actionStyle = TextStyle(
      color: Color(0xFFFFD9BF),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    final messageText = Text(message, style: messageStyle);
    final actionButton = InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 4),
          Text(action, style: actionStyle),
          SizedBox(height: 4),
        ],
      ),
    );

    final measurement = TextPainter(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: message, style: messageStyle),
          TextSpan(text: action, style: actionStyle),
        ],
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final fits = measurement.width + 6 <= availableWidth;
    measurement.dispose();

    return fits
        ? Row(
            children: [
              const Spacer(),
              messageText,
              const SizedBox(width: 6),
              actionButton,
              const Spacer(),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [messageText, actionButton],
          );
  }
}
