import 'package:flutter/material.dart';

class LoginFields extends StatelessWidget {
  const LoginFields({
    super.key,
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
          ),
        ),
      ],
    );
  }
}
