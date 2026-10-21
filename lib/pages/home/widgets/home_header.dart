import 'package:flutter/material.dart';

import 'menu_akun_button.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onLogout});

  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 16),
          Row(
            children: [
              const Spacer(),
              SizedBox(
                width: (constraints.maxWidth - 2 * (19)).clamp(
                  0.0,
                  double.infinity,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Jadwalin',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    MenuAkunButton(onLogout: onLogout),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
