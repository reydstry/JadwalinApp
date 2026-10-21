import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Original Figma vectors, preserving their aspect ratios.
class HomeIcon extends StatelessWidget {
  const HomeIcon(this.name, {super.key, this.size = 32});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icon/$name.svg',
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
  );
}
