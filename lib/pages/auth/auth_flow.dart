import 'package:flutter/material.dart';

import '../../services/auth_gateway.dart';
import 'login_page.dart';
import 'register_page.dart';

class AuthFlow extends StatelessWidget {
  const AuthFlow({
    super.key,
    required this.authGateway,
    required this.homeBuilder,
  });

  final AuthGateway authGateway;
  final WidgetBuilder homeBuilder;

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      authGateway: authGateway,
      homeBuilder: homeBuilder,
      onRegister: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (registerContext) => RegisterPage(
              authGateway: authGateway,
              homeBuilder: homeBuilder,
              onBack: () => Navigator.of(registerContext).pop(),
              onLogin: () => Navigator.of(registerContext).pop(),
            ),
          ),
        );
      },
    );
  }
}
