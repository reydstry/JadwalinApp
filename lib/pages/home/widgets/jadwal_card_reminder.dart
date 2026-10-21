import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class JadwalCardReminder extends StatelessWidget {
  const JadwalCardReminder({
    super.key,
    required this.menitSebelum,
    required this.compact,
  });
  final int menitSebelum;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 3),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8),
          Row(
            children: [
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$menitSebelum Menit Sebelumnya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
