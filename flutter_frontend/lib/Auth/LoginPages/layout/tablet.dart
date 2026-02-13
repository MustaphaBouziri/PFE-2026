import 'package:flutter/material.dart';
import 'login_shared_form.dart';

class LoginTabletLayout extends StatelessWidget {
  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onLogin;

  const LoginTabletLayout({
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [

                    //___________________ HEADER ___________________

                    const Icon(
                      Icons.factory_outlined,
                      size: 80,
                      color: mainColor,
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Login Page",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),

                    const SizedBox(height: 40),

                    //___________________ FORM ___________________

                    LoginSharedForm(
                      userIdController: userIdController,
                      passwordController: passwordController,
                      formKey: formKey,
                      onLogin: onLogin,
                      maxWidth: 520,
                    ),
                    SizedBox(height: 26,),
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
        ),
      ),
    );
  }
}