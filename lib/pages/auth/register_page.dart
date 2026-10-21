import 'package:flutter/material.dart';

import '../../services/auth_gateway.dart';
import '../../theme/app_colors.dart';
import 'auth_page_layout.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/register_fields.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.authGateway,
    required this.homeBuilder,
    this.onBack,
    this.onLogin,
  });

  final AuthGateway authGateway;
  final WidgetBuilder homeBuilder;
  final VoidCallback? onBack;
  final VoidCallback? onLogin;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _backToLogin() {
    if (_isSubmitting) return;

    final callback = widget.onLogin ?? widget.onBack;
    if (callback != null) {
      callback();
      return;
    }

    Navigator.of(context).maybePop();
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
      await widget.authGateway.register(
        name: _nameController.text.trim(),
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
        _submitError = 'Registrasi gagal. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Nama wajib diisi';
    if (name.length > 100) return 'Nama maksimal 100 karakter';
    return null;
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
          headerBuilder: (context, headerWidth) => AuthHeader(
            availableWidth: headerWidth,
            enabled: !_isSubmitting,
            title: 'Gaskeun buat akun!',
            message: 'Sudah punya akunnye?',
            action: 'Loginkeun',
            onPromptPressed: _backToLogin,
            onBack: _backToLogin,
          ),
          form: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RegisterFields(
                  nameController: _nameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  enabled: !_isSubmitting,
                  validateName: _validateName,
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
                  label: 'Register',
                  fontSize: 14,
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
