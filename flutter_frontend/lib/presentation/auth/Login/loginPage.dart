import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/domain/auth/providers/auth_provider.dart';
import 'layout/mobile.dart';
import 'layout/tablet.dart';
import 'layout/web.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController authIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    authIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    final userId = authIdController.text.trim();
    final password = passwordController.text.trim();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(userId, password);

    if (!mounted) return;

    if (!success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("loginFailed".tr()),
          content: Text(
            authProvider.errorMessage ??
                "unknownError".tr(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("ok".tr()),
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
                        authIdController: authIdController,
                        passwordController: passwordController,
                        formKey: formKey,
                        onLogin: login,
                      );
                    } else if (width < 1024) {
                      return LoginTabletLayout(
                        authIdController: authIdController,
                        passwordController: passwordController,
                        formKey: formKey,
                        onLogin: login,
                      );
                    } else {
                      return LoginWebLayout(
                        authIdController: authIdController,
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
                    child:  Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text('authenticating'.tr()),
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
