import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwalin/pages/auth/login_page.dart';
import 'package:jadwalin/services/auth_gateway.dart';

void main() {
  testWidgets('form login menolak data kosong sebelum memanggil gateway', (
    tester,
  ) async {
    final gateway = _FakeAuthGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authGateway: gateway,
          homeBuilder: (_) => const Scaffold(body: Text('Home tujuan')),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(gateway.loginCalls, 0);
  });

  testWidgets('form login memvalidasi format email dan panjang kata sandi', (
    tester,
  ) async {
    final gateway = _FakeAuthGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authGateway: gateway,
          homeBuilder: (_) => const Scaffold(body: Text('Home tujuan')),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'email-salah',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'pendek',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
    await tester.pump();

    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(find.text('Kata sandi minimal 8 karakter'), findsOneWidget);
    expect(gateway.loginCalls, 0);
  });

  testWidgets('pengguna dapat menampilkan dan menyembunyikan kata sandi', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authGateway: _FakeAuthGateway(),
          homeBuilder: (_) => const Scaffold(body: Text('Home tujuan')),
        ),
      ),
    );

    EditableText passwordField() => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('login_password_field')),
        matching: find.byType(EditableText),
      ),
    );

    expect(passwordField().obscureText, isTrue);

    await tester.tap(find.byTooltip('Tampilkan kata sandi'));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);

    await tester.tap(find.byTooltip('Sembunyikan kata sandi'));
    await tester.pump();
    expect(passwordField().obscureText, isTrue);
  });

  testWidgets('submit valid hanya sekali lalu mengganti login dengan home', (
    tester,
  ) async {
    final loginResult = Completer<void>();
    final gateway = _FakeAuthGateway(result: loginResult.future);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authGateway: gateway,
          homeBuilder: (_) => const Scaffold(body: Text('Home tujuan')),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      '  mahasiswa@kampus.ac.id  ',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'rahasia123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(gateway.loginCalls, 1);
    expect(gateway.lastEmail, 'mahasiswa@kampus.ac.id');
    expect(gateway.lastPassword, 'rahasia123');

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(gateway.loginCalls, 1);

    loginResult.complete();
    await tester.pumpAndSettle();

    expect(find.text('Home tujuan'), findsOneWidget);
    expect(find.text('Loginkan Kawan!'), findsNothing);
    expect(
      Navigator.of(tester.element(find.text('Home tujuan'))).canPop(),
      isFalse,
    );
  });

  testWidgets('login gagal mempertahankan input dan dapat dicoba lagi', (
    tester,
  ) async {
    final gateway = _FailOnceAuthGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authGateway: gateway,
          homeBuilder: (_) => const Scaffold(body: Text('Home tujuan')),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'mahasiswa@kampus.ac.id',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'rahasia123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Login gagal. Silakan coba lagi.'), findsOneWidget);
    expect(find.text('mahasiswa@kampus.ac.id'), findsOneWidget);
    expect(find.text('rahasia123'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log In'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(gateway.loginCalls, 2);
    expect(find.text('Home tujuan'), findsOneWidget);
  });
}

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({this.result});

  final Future<void>? result;
  int loginCalls = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<void> login({required String email, required String password}) async {
    loginCalls++;
    lastEmail = email;
    lastPassword = password;
    await (result ?? Future<void>.value());
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {}
}

class _FailOnceAuthGateway implements AuthGateway {
  int loginCalls = 0;

  @override
  Future<void> login({required String email, required String password}) async {
    loginCalls++;
    if (loginCalls == 1) throw Exception('Simulasi gagal');
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {}
}
