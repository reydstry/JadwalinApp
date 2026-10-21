import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';

ThemeData jadwalFormTheme(ThemeData base) => base.copyWith(
  scaffoldBackgroundColor: AppColors.primary,
  textTheme: base.textTheme.apply(fontFamily: 'Inter'),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 16),
    errorStyle: const TextStyle(color: AppColors.peach, fontSize: 12),
    errorMaxLines: 3,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0xFFACB5BB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.peach, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.peach, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.peach, width: 2),
    ),
  ),
);

class JadwalFormIcon extends StatelessWidget {
  const JadwalFormIcon(this.name, {super.key, this.size = 20});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: SvgPicture.asset(
      'assets/icon/form_$name.svg',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
  );
}

class JadwalField extends StatelessWidget {
  const JadwalField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class JadwalSection extends StatelessWidget {
  const JadwalSection({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const JadwalFormIcon('section'),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      child,
    ],
  );
}
