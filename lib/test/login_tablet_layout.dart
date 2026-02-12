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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.factory, size: 110),
                  const SizedBox(height: 20),
                  const Text(
                    "MES Login",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 35),
                  LoginSharedForm(
                    userIdController: userIdController,
                    passwordController: passwordController,
                    formKey: formKey,
                    onLogin: onLogin,
                    maxWidth: 520,
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
