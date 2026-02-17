import 'package:flutter/material.dart';
import 'package:pfe_mes/Auth/ChangePasswordPage/layout/changePassForm.dart';


class ChangePassWebLayout extends StatelessWidget {
    final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onChangePassword;
  final TextEditingController oldPasswordController;

  const ChangePassWebLayout({
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

                 ChangePasswordSharedForm(
                      oldPasswordController: oldPasswordController,
                      newPasswordController: newPasswordController,
                      confirmPasswordController: confirmPasswordController,
                      formKey: formKey,
                      onChangePassword: onChangePassword,
                      maxWidth: 520,
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