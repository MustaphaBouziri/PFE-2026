import 'package:flutter/material.dart';
import 'login_mobile_layout.dart';
import 'login_tablet_layout.dart';
import 'login_web_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    userIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() {
    if (!formKey.currentState!.validate()) return;

    final userId = userIdController.text.trim();
    final password = passwordController.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Login clicked: $userId")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 600) {
          return LoginMobileLayout(
            userIdController: userIdController, // basically its we just passing it for reference go web layout for more details
            passwordController: passwordController,
            formKey: formKey,
            onLogin: login,
          );
        } else if (width < 1024) {
          return LoginTabletLayout(
            userIdController: userIdController,
            passwordController: passwordController,
            formKey: formKey,
            onLogin: login,
          );
        } else {
          return LoginWebLayout(
            userIdController: userIdController,
            passwordController: passwordController,
            formKey: formKey,
            onLogin: login,
          );
        }
      },
    );
  }
}
