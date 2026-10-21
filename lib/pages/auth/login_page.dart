import 'package:flutter/material.dart';

import '../../services/auth_gateway.dart';
import '../../theme/app_colors.dart';
import 'auth_page_layout.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/login_fields.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authGateway,
    required this.homeBuilder,
    this.onRegister,
  });

  final AuthGateway authGateway;
  final WidgetBuilder homeBuilder;
  final VoidCallback? onRegister;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await widget.authGateway.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: widget.homeBuilder),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitError = 'Login gagal. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi';

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Kata sandi wajib diisi';
    if (value.length < 8) return 'Kata sandi minimal 8 karakter';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: AuthPageLayout(
          landscapeFormWidthFactor: 0.9,
          headerBuilder: (context, headerWidth) => AuthHeader(
            availableWidth: headerWidth,
            enabled: !_isSubmitting,
            title: 'Loginkeun Kawan!',
            message: 'Belum punya akun?',
            action: 'Daftarkeun',
            onPromptPressed: widget.onRegister,
          ),
          form: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoginFields(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  enabled: !_isSubmitting,
                  validateEmail: _validateEmail,
                  validatePassword: _validatePassword,
                  onTogglePassword: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  onSubmit: _submit,
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  AuthSubmitError(message: _submitError!),
                ],
                const SizedBox(height: 24),
                AuthSubmitButton(
                  label: 'Log In',
                  fontSize: 16,
                  isSubmitting: _isSubmitting,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
