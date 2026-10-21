import 'package:flutter/material.dart';

class RegisterFields extends StatelessWidget {
  const RegisterFields({
    super.key,
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
