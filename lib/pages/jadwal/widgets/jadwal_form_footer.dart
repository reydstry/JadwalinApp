import 'package:flutter/material.dart';

class JadwalFormFooter extends StatelessWidget {
  const JadwalFormFooter({super.key, required this.button});
  final Widget button;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12),
          Row(
            children: [
              SizedBox(width: 19),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      const Spacer(),
                      SizedBox(
                        width: constraints.maxWidth.clamp(0.0, 480.0),
                        child: button,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 19),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
