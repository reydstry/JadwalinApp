import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwalin/pages/auth/login_page.dart';
import 'package:jadwalin/pages/auth/register_page.dart';
import 'package:jadwalin/services/auth_gateway.dart';

void main() {
  for (final register in [false, true]) {
    final page = register ? 'register' : 'login';
    testWidgets('$page keeps form state in landscape and with keyboard', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final gateway = _AuthGateway();
      Widget homeBuilder(BuildContext context) => const Scaffold();
      await tester.pumpWidget(
        MaterialApp(
          home: register
              ? RegisterPage(authGateway: gateway, homeBuilder: homeBuilder)
              : LoginPage(authGateway: gateway, homeBuilder: homeBuilder),
        ),
      );

      final heading = find.text(
        register ? 'Gaskeun buat akun!' : 'Loginkeun Kawan!',
      );
      final email = find.byKey(Key('${page}_email_field'));
      final button = find.widgetWithText(
        FilledButton,
        register ? 'Register' : 'Log In',
      );
      expect(
        tester.getBottomLeft(heading).dy,
        lessThan(tester.getTopLeft(email).dy),
      );
      await tester.enterText(email, 'email-salah');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Format email tidak valid'), findsOneWidget);
      final formState = tester.state<FormState>(find.byType(Form));

      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      expect(
        tester.getTopRight(heading).dx,
        lessThan(tester.getTopLeft(email).dx),
      );
      expect(tester.state<FormState>(find.byType(Form)), same(formState));
      expect(find.text('email-salah'), findsOneWidget);
      expect(find.text('Format email tidak valid'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = const FakeViewPadding(bottom: 170);
      await tester.pumpAndSettle();
      expect(
        tester.getTopRight(heading).dx,
        lessThan(tester.getTopLeft(email).dx),
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = const FakeViewPadding();
      tester.view.physicalSize = const Size(640, 360);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(heading).dy,
        lessThan(tester.getTopLeft(email).dy),
      );
      expect(tester.state<FormState>(find.byType(Form)), same(formState));
      expect(find.text('email-salah'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _AuthGateway implements AuthGateway {
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
