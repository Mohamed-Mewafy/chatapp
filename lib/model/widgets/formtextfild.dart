import 'package:chatapp/theme/theme.dart';
import 'package:flutter/material.dart';

class Formtextfild extends StatefulWidget {
  Formtextfild({
    super.key,
    required this.name,
    this.onEmailChanged,
    this.onPasswordChanged,
    this.onPressed,
  });
  final String? name;
  final VoidCallback? onPressed;
  final Function(String)? onEmailChanged;
  final Function(String)? onPasswordChanged;

  @override
  State<Formtextfild> createState() => _FormtextfildState();
}

class _FormtextfildState extends State<Formtextfild> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.name!,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            onChanged: widget.onEmailChanged,
            controller: _emailController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
              hintText: "Enter your email",
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            onChanged: widget.onPasswordChanged,
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_outline),
              hintText: "Enter your password",
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onPressed?.call();
                }
              },
              child: Text(
                widget.name!,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
