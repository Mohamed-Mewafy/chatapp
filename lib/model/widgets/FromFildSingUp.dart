import 'package:chatapp/theme/theme.dart';
import 'package:flutter/material.dart';

class Fromfildsingup extends StatelessWidget {
  final String name;
  final VoidCallback? onPressed;
  final Function(String)? onNameChanged;
  final Function(String)? onEmailChanged;
  final Function(String)? onPasswordChanged;
  final bool isLoading;

  Fromfildsingup({
    required this.name,
    this.onPressed,
    this.onNameChanged,
    this.onEmailChanged,
    this.onPasswordChanged,
    this.isLoading = false,
    super.key,
  });

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildField("Name", Icons.person_outline, onNameChanged, false),
          const SizedBox(height: 14),
          _buildField("Email", Icons.email_outlined, onEmailChanged, false),
          const SizedBox(height: 14),
          _buildField("Password", Icons.lock_outline, onPasswordChanged, true),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        onPressed?.call();
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      name,
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

  Widget _buildField(
    String hint,
    IconData icon,
    Function(String)? onChange,
    bool isPass,
  ) {
    return TextFormField(
      onChanged: (val) => onChange?.call(val),
      obscureText: isPass,
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.chatBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
