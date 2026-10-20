import 'package:flutter/material.dart';

import '../../services/auth_gateway.dart';
import '../../theme/app_colors.dart';

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            tooltip: 'Kembali ke login',
                            onPressed: _isSubmitting ? null : _backToLogin,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 24,
                              height: 24,
                            ),
                            color: const Color(0xFFEEEEEE),
                            icon: const Icon(Icons.arrow_back, size: 24),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: Column(
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
                                  'Gaskeun buat akun!',
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
                                _LoginPrompt(
                                  enabled: !_isSubmitting,
                                  onPressed: _backToLogin,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          _RegisterFields(
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
                            Center(
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  _submitError!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFFFD9BF),
                                  ),
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
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 14,
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

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        const Text(
          'Sudah punya akunnye?',
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
              'Loginkan',
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

class _RegisterFields extends StatelessWidget {
  const _RegisterFields({
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.enabled,
    required this.validateName,
    required this.validateEmail,
    required this.validatePassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool enabled;
  final FormFieldValidator<String> validateName;
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
    const decoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return Column(
      children: [
        TextFormField(
          key: const Key('register_name_field'),
          controller: nameController,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          validator: validateName,
          decoration: decoration.copyWith(
            hintText: 'Nama',
            prefixIcon: const Icon(Icons.account_circle_outlined),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('register_email_field'),
          controller: emailController,
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: validateEmail,
          decoration: decoration.copyWith(
            hintText: 'Email',
            prefixIcon: const Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('register_password_field'),
          controller: passwordController,
          enabled: enabled,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          validator: validatePassword,
          onFieldSubmitted: enabled ? (_) => onSubmit() : null,
          decoration: decoration.copyWith(
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
          ),
        ),
      ],
    );
  }
}
