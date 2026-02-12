import 'package:flutter/material.dart';
import 'login_shared_form.dart';

class LoginMobileLayout extends StatelessWidget {
  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onLogin;

  const LoginMobileLayout({
    super.key,
    required this.userIdController,
    required this.passwordController,
    required this.formKey,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Icon(Icons.factory, size: 90),
                  const SizedBox(height: 20),
                  const Text(
                    "MES Login",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  LoginSharedForm(
                    userIdController: userIdController,
                    passwordController: passwordController,
                    formKey: formKey,
                    onLogin: onLogin,
                    maxWidth: 420,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
