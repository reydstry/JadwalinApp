import 'package:flutter/material.dart';

import '../../../utils/day_helper.dart';

import '../../../theme/app_colors.dart';

class PilihHari extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  const PilihHari({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final days = DayHelper.dayNames.entries.toList();

    return SizedBox(
      height: 68,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final day = days[index];

          return ChoiceChip(
            label: Text(
              day.value,
              style: TextStyle(
                color: selectedDay == day.key ? AppColors.primary : Colors.grey.shade600,
                fontWeight: FontWeight.w800,
              ),
            ),

            selected: selectedDay == day.key,

            // Warna latar
            
            selectedColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundColor: Colors.white,

            // Warna dan ketebalan border
            side: BorderSide(
              color: selectedDay == day.key
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.grey.shade300,
              width: 1,
            ),

            // Bentuk kapsul
            shape: const StadiumBorder(),

            // Hilangkan tanda centang
            showCheckmark: false,

            onSelected: (_) {
              onDaySelected(day.key);
            },
          );
        },
      ),
    );
  }
}
