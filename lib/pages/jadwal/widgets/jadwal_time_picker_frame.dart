import 'package:flutter/material.dart';

class JadwalTimePickerFrame extends StatelessWidget {
  const JadwalTimePickerFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Row(children: [Expanded(child: child)]),
          ),
        ),
      ),
    );
  }
}
