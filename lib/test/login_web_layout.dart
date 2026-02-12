import 'package:flutter/material.dart';
import 'login_shared_form.dart';

class LoginWebLayout extends StatelessWidget {
  final TextEditingController userIdController; // now this layout reference to the login text editing contoller 
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
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          padding: const EdgeInsets.all(40),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade900,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.factory, size: 80, color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        "Manufacturing Execution System",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Login to access production orders, work centers and machine monitoring.",
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Center(
                  child: LoginSharedForm(
                    userIdController: userIdController,
                    passwordController: passwordController,
                    formKey: formKey,
                    onLogin: onLogin,
                    maxWidth: 450,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
