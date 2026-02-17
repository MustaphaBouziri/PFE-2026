import 'package:flutter/material.dart';
import 'package:pfe_mes/Auth/ChangePasswordPage/layout/changePassForm.dart';

class ChangePassTabletLayout extends StatelessWidget {
  final TextEditingController oldPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onChangePassword;

  const ChangePassTabletLayout({
    super.key,
    required this.oldPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.formKey,
    required this.onChangePassword,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
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

                          ChangePasswordSharedForm(
                            oldPasswordController: oldPasswordController,
                            newPasswordController: newPasswordController,
                            confirmPasswordController:
                                confirmPasswordController,
                            formKey: formKey,
                            onChangePassword: onChangePassword,
                            maxWidth: 520,
                          ),

                          const SizedBox(height: 26),

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
            },
          ),
        ),
      ),
    );
  }
}
