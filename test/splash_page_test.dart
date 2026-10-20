import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwalin/pages/splash/splash_page.dart';

void main() {
  testWidgets('menampilkan progres nyata lalu membuka tujuan satu kali', (
    tester,
  ) async {
    final selesaiMemuat = Completer<void>();
    late ValueChanged<double> laporkanProgres;
    var jumlahPembuatanTujuan = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(
          load: (onProgress) {
            laporkanProgres = onProgress;
            return selesaiMemuat.future;
          },
          destinationBuilder: (_) {
            jumlahPembuatanTujuan++;
            return const Scaffold(body: Text('Beranda tujuan'));
          },
        ),
      ),
    );

    expect(find.bySemanticsLabel('Memuat aplikasi 0%'), findsOneWidget);
    expect(find.text('Beranda tujuan'), findsNothing);

    laporkanProgres(0.5);
    await tester.pump();

    expect(find.bySemanticsLabel('Memuat aplikasi 50%'), findsOneWidget);
    expect(find.text('Beranda tujuan'), findsNothing);

    selesaiMemuat.complete();
    await tester.pumpAndSettle();

    expect(find.text('Beranda tujuan'), findsOneWidget);
    expect(jumlahPembuatanTujuan, 1);
  });
}
