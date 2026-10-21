import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class HomeDaySummary extends StatelessWidget {
  const HomeDaySummary({
    super.key,
    required this.dayName,
    required this.ready,
    required this.count,
  });

  final String dayName;
  final bool ready;
  final int count;

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    const countStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    final title = DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Jadwal $dayName', style: titleStyle),
          SizedBox(height: 4),
        ],
      ),
    );
    final trailing = ready && count > 0
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Flexible(child: Text('Mata Kuliah', style: countStyle)),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 5),
                        Text(
                          '$count',
                          key: const Key('selected_day_count'),
                          style: countStyle.copyWith(color: AppColors.primary),
                        ),
                        SizedBox(width: 5),
                      ],
                    ),
                    SizedBox(height: 1),
                  ],
                ),
              ),
            ],
          )
        : Text(ready ? 'Kosong' : '...', style: countStyle);

    return LayoutBuilder(
      builder: (context, viewport) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              SizedBox(
                width: (viewport.maxWidth - 2 * (19)).clamp(
                  0.0,
                  double.infinity,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double textWidth(String text, TextStyle style) {
                      final measurement = TextPainter(
                        text: TextSpan(
                          text: text,
                          style: DefaultTextStyle.of(context).style
                              .merge(style),
                        ),
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
                      )..layout();
                      final width = measurement.width;
                      measurement.dispose();
                      return width;
                    }

                    final trailingWidth = ready && count > 0
                        ? textWidth('Mata Kuliah', countStyle) +
                              8 +
                              textWidth('$count', countStyle) +
                              10
                        : textWidth(ready ? 'Kosong' : '...', countStyle);
                    final fits =
                        textWidth('Jadwal $dayName', titleStyle) +
                            20 +
                            trailingWidth <=
                        constraints.maxWidth;

                    return fits
                        ? Row(children: [title, const Spacer(), trailing])
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(children: [Flexible(child: title)]),
                              const SizedBox(height: 8),
                              Row(children: [Flexible(child: trailing)]),
                            ],
                          );
                  },
                ),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 14),
        ],
      ),
    );
  }
}
