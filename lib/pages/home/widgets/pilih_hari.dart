import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'hari_bubble.dart';
import '../../../utils/day_helper.dart';

class PilihHari extends StatefulWidget {
  const PilihHari({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.scheduleCounts = const {},
  });
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final Map<int, int> scheduleCounts;
  @override
  State<PilihHari> createState() => _PilihHariState();
}

class _PilihHariState extends State<PilihHari> {
  final _dayKeys = {
    for (final day in DayHelper.dayNames.keys) day: GlobalKey(),
  };
  @override
  void initState() {
    super.initState();
    _revealSelectedDay();
  }

  @override
  void didUpdateWidget(covariant PilihHari oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay ||
        !mapEquals(oldWidget.scheduleCounts, widget.scheduleCounts)) {
      _revealSelectedDay();
    }
  }

  void _revealSelectedDay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dayContext = _dayKeys[widget.selectedDay]?.currentContext;
      if (dayContext != null) {
        Scrollable.ensureVisible(dayContext, alignment: 0.5);
      }
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 9),
        Row(
          children: [
            for (final day in DayHelper.dayNames.entries)
              Row(
                key: _dayKeys[day.key],
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HariBubble(
                        day: day.key,
                        label: day.value,
                        count: widget.scheduleCounts[day.key] ?? 0,
                        selected: widget.selectedDay == day.key,
                        onPressed: () => widget.onDaySelected(day.key),
                      ),
                      SizedBox(width: 2),
                    ],
                  ),
                ],
              ),
          ],
        ),
        SizedBox(width: 9),
      ],
    ),
  );
}
