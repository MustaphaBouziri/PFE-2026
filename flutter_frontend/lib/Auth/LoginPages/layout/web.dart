import 'package:flutter/material.dart';
import 'login_shared_form.dart';

class LoginWebLayout extends StatelessWidget {
  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onLogin;

  const LoginWebLayout({
    super.key,
    required this.userIdController,
    required this.passwordController,
    required this.formKey,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF0F172A);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: 700,
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 50),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                //___________________ LOGO / TITLE ___________________

                Column(
                  children: const [
                    Icon(
                      Icons.factory_outlined,
                      size: 60,
                      color: mainColor,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Login Page",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                   
                  ],
                ),

                const SizedBox(height: 40),

                //___________________ LOGIN FORM ___________________

                LoginSharedForm(
                  userIdController: userIdController,
                  passwordController: passwordController,
                  formKey: formKey,
                  onLogin: onLogin,
                  maxWidth: 450,
                ),

                const SizedBox(height: 30),

                //___________________ FOOTER ___________________

                const Text(
                  "© 2026  - All rights reserved",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}