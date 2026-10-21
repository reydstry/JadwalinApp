import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwalin/pages/auth/auth_flow.dart';
import 'package:jadwalin/services/auth_gateway.dart';

void main() {
  testWidgets('login dan registrasi saling terhubung tanpa menumpuk halaman', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthFlow(
          authGateway: _FakeAuthGateway(),
          homeBuilder: (_) => const Scaffold(body: Text('Home tujuan')),
        ),
      ),
    );

    expect(find.text('Loginkeun Kawan!'), findsOneWidget);

    await tester.tap(find.text('Daftarkeun'));
    await tester.pumpAndSettle();
    expect(find.text('Gaskeun buat akun!'), findsOneWidget);

    await tester.tap(find.text('Loginkeun'));
    await tester.pumpAndSettle();
    expect(find.text('Loginkeun Kawan!'), findsOneWidget);

    await tester.tap(find.text('Daftarkeun'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kembali ke login'));
    await tester.pumpAndSettle();

    expect(find.text('Loginkeun Kawan!'), findsOneWidget);
    expect(find.text('Gaskeun buat akun!'), findsNothing);
  });
}

class _FakeAuthGateway implements AuthGateway {
  @override
  Future<void> logout() async {}

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {}
}
