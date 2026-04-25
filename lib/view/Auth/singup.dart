import 'package:chatapp/model/widgets/Topbaner.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/model/widgets/FromFildSingUp.dart';
import '../../theme/theme.dart';

class Singup extends StatefulWidget {
  const Singup({super.key});

  @override
  State<Singup> createState() => _SingupState();
}

class _SingupState extends State<Singup> {
  String? name, email, password;
  bool isLoading = false;

  void _showTopNotification(String message, bool isError) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => TopToastWidget(
        message: message,
        isError: isError,
        onDismiss: () {
          if (entry != null) {
            entry!.remove();
            entry = null;
          }
        },
      ),
    );
    overlay.insert(entry!);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry != null) {
        entry!.remove();
        entry = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.accent,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(),
                  const SizedBox(height: 32),
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign up to get started",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildGlassCard(),
                  const SizedBox(height: 28),
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              "assets/images/chat.png",
              width: 56,
              height: 56,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Text(
          "LenChat",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Fromfildsingup(
                name: "Sign Up",
                isLoading: isLoading,
                onNameChanged: (val) => name = val,
                onEmailChanged: (val) => email = val,
                onPasswordChanged: (val) => password = val,
                onPressed: _handleSignup,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (name == null || email == null || password == null) {
      _showTopNotification("Fill all fields!", true);
      return;
    }
    setState(() => isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email!.trim(),
            password: password!.trim(),
          );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'name': name!.trim(),
            'email': email!.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
      _showTopNotification("Welcome! Account Created.", false);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pushReplacementNamed(context, "Home");
      });
    } on FirebaseAuthException catch (e) {
      _showTopNotification(e.message ?? "Error", true);
    } catch (e) {
      _showTopNotification("An unexpected error occurred", true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.85)),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            "Sign In",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: .5,
            ),
          ),
        ),
      ],
    );
  }
}
