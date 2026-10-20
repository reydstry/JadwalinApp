import 'package:flutter/material.dart';

import '../../services/auth_gateway.dart';
import '../../theme/app_colors.dart';

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: SizedBox(
                    width: 327,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(31),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              width: 124,
                              height: 124,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loginkan Kawan!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFEEEEEE),
                              fontSize: 32,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.64,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _RegisterPrompt(
                            enabled: !_isSubmitting,
                            onPressed: widget.onRegister,
                          ),
                          const SizedBox(height: 32),
                          _LoginFields(
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
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _submitError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFFD9BF),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD9BF),
                                foregroundColor: AppColors.primary,
                                disabledBackgroundColor: const Color(
                                  0x99FFD9BF,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : const Text(
                                      'Log In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  const _RegisterPrompt({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        const Text(
          'Belum punya akun?',
          style: TextStyle(
            color: Color(0xFFEEEEEE),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Daftarkeun',
              style: TextStyle(
                color: Color(0xFFFFD9BF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginFields extends StatelessWidget {
  const _LoginFields({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.enabled,
    required this.validateEmail,
    required this.validatePassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool enabled;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide.none,
    );

    return Column(
      children: [
        TextFormField(
          key: const Key('login_email_field'),
          controller: emailController,
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: validateEmail,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Email',
            prefixIcon: Icon(Icons.mail_outline_rounded),
            border: border,
            enabledBorder: border,
            focusedBorder: border,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('login_password_field'),
          controller: passwordController,
          enabled: enabled,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: validatePassword,
          onFieldSubmitted: enabled ? (_) => onSubmit() : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Kata Sandi',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: obscurePassword
                  ? 'Tampilkan kata sandi'
                  : 'Sembunyikan kata sandi',
              onPressed: enabled ? onTogglePassword : null,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
