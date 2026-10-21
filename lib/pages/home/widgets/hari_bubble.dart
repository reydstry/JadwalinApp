import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class HariBubble extends StatelessWidget {
  const HariBubble({
    super.key,
    required this.day,
    required this.label,
    required this.count,
    required this.selected,
    required this.onPressed,
  });
  final int day;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: TextButton(
        key: ValueKey('day_$day'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.peach : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white54),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 3),
                      blurRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: selected ? 7 : 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 18),
                  Text(
                    '$label${count > 0 ? ' $count' : ''}',
                    style: TextStyle(
                      fontFamily: 'Merriweather Sans',
                      fontSize: selected ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : Colors.white70,
                    ),
                  ),
                  SizedBox(width: 18),
                ],
              ),
              SizedBox(height: selected ? 7 : 5),
            ],
          ),
        ),
      ),
    );
  }
}
