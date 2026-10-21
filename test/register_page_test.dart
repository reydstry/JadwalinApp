import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwalin/pages/auth/register_page.dart';
import 'package:jadwalin/services/auth_gateway.dart';

void main() {
  testWidgets('form registrasi menolak data kosong sebelum memanggil gateway', (
    tester,
  ) async {
    final gateway = _FakeAuthGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(
          authGateway: gateway,
          homeBuilder: (_) => const Scaffold(body: Text('Home tujuan')),
        ),
      ),
    );

    final registerButton = find.widgetWithText(FilledButton, 'Register');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump();

    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(gateway.registerCalls, 0);
  });

  testWidgets('form registrasi memvalidasi nama email dan kata sandi', (
    tester,
  ) async {
    final gateway = _FakeAuthGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(
          authGateway: gateway,
          homeBuilder: (_) => const Scaffold(body: Text('Home tujuan')),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('register_name_field')),
      List.filled(101, 'A').join(),
    );
    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'email-salah',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      'pendek',
    );

    final registerButton = find.widgetWithText(FilledButton, 'Register');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump();

    expect(find.text('Nama maksimal 100 karakter'), findsOneWidget);
    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(find.text('Kata sandi minimal 8 karakter'), findsOneWidget);
    expect(gateway.registerCalls, 0);
  });

  testWidgets('pengguna dapat menampilkan kata sandi registrasi', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(
          authGateway: _FakeAuthGateway(),
          homeBuilder: (_) => const Scaffold(body: Text('Home tujuan')),
        ),
      ),
    );

    EditableText passwordField() => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('register_password_field')),
        matching: find.byType(EditableText),
      ),
    );

    expect(passwordField().obscureText, isTrue);
    await tester.ensureVisible(find.byTooltip('Tampilkan kata sandi'));
    await tester.tap(find.byTooltip('Tampilkan kata sandi'));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);
  });

  testWidgets(
    'submit registrasi hanya sekali lalu mengganti halaman dengan home',
    (tester) async {
      final registerResult = Completer<void>();
      final gateway = _FakeAuthGateway(result: registerResult.future);

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterPage(
            authGateway: gateway,
            homeBuilder: (_) => const Scaffold(body: Text('Home tujuan')),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('register_name_field')),
        '  Raihan Akbar  ',
      );
      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        '  raihan@kampus.ac.id  ',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'rahasia123',
      );

      final registerButton = find.widgetWithText(FilledButton, 'Register');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(gateway.registerCalls, 1);
      expect(gateway.lastName, 'Raihan Akbar');
      expect(gateway.lastEmail, 'raihan@kampus.ac.id');
      expect(gateway.lastPassword, 'rahasia123');

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(gateway.registerCalls, 1);

      registerResult.complete();
      await tester.pumpAndSettle();

      expect(find.text('Home tujuan'), findsOneWidget);
      expect(find.text('Gaskeun buat akun!'), findsNothing);
      expect(
        Navigator.of(tester.element(find.text('Home tujuan'))).canPop(),
        isFalse,
      );
    },
  );

  testWidgets('registrasi gagal mempertahankan input dan dapat dicoba lagi', (
    tester,
  ) async {
    final gateway = _FailOnceAuthGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(
          authGateway: gateway,
          homeBuilder: (_) => const Scaffold(body: Text('Home tujuan')),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('register_name_field')),
      'Raihan Akbar',
    );
    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'raihan@kampus.ac.id',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      'rahasia123',
    );

    final registerButton = find.widgetWithText(FilledButton, 'Register');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(find.text('Registrasi gagal. Silakan coba lagi.'), findsOneWidget);
    expect(find.text('Raihan Akbar'), findsOneWidget);
    expect(find.text('raihan@kampus.ac.id'), findsOneWidget);
    expect(find.text('rahasia123'), findsOneWidget);

    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(gateway.registerCalls, 2);
    expect(find.text('Home tujuan'), findsOneWidget);
  });
}

class _FakeAuthGateway implements AuthGateway {
  @override
  Future<void> logout() async {}

  _FakeAuthGateway({this.result});

  final Future<void>? result;
  int registerCalls = 0;
  String? lastName;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    lastName = name;
    lastEmail = email;
    lastPassword = password;
    await (result ?? Future<void>.value());
  }
}

class _FailOnceAuthGateway implements AuthGateway {
  @override
  Future<void> logout() async {}

  int registerCalls = 0;

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    if (registerCalls == 1) throw Exception('Simulasi gagal');
  }
}
