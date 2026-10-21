import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

enum _AksiAkun { keluar }

/// Menu profil beserta status proses keluar; navigasi disediakan oleh aplikasi.
class MenuAkunButton extends StatefulWidget {
  const MenuAkunButton({super.key, this.onLogout});

  final Future<void> Function()? onLogout;

  @override
  State<MenuAkunButton> createState() => _MenuAkunButtonState();
}

class _MenuAkunButtonState extends State<MenuAkunButton> {
  bool _sedangKeluar = false;

  Future<void> _keluar() async {
    final logout = widget.onLogout;
    if (_sedangKeluar || logout == null) return;

    setState(() => _sedangKeluar = true);
    try {
      await logout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Gagal keluar akun. Silakan coba lagi.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _sedangKeluar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AksiAkun>(
      tooltip: _sedangKeluar ? 'Sedang keluar akun' : 'Menu akun',
      enabled: !_sedangKeluar && widget.onLogout != null,
      position: PopupMenuPosition.under,
      color: AppColors.peach,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => _keluar(),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _AksiAkun.keluar,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Keluar akun',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      child: SizedBox.square(
        dimension: 48,
        child: Column(
          children: [
            const Spacer(),
            Row(
              children: [
                const Spacer(),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.peach,
                  child: _sedangKeluar
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 22,
                        ),
                ),
                const Spacer(),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
