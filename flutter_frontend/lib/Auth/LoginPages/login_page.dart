import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pfe_mes/providers/auth_provider.dart';
import 'layout/mobile.dart';
import 'layout/tablet.dart';
import 'layout/web.dart';

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

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    final userId = userIdController.text.trim();
    final password = passwordController.text.trim();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(userId, password);

    if (!mounted) return;

    if (!success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Login Failed"),
          content: Text(
            authProvider.errorMessage ??
                "Unknown error occurred. Please try again.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
    // On success, main.dart Consumer automatically routes to the correct page
    // based on needsPasswordChange and role — no manual navigation needed here.
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return Stack(
              children: [
                Builder(
                  builder: (context) {
                    if (width < 600) {
                      return LoginMobileLayout(
                        userIdController: userIdController,
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
                ),
                // Loading overlay
                if (auth.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Authenticating...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}