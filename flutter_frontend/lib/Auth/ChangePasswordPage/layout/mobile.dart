import 'package:flutter/material.dart';
import 'package:pfe_mes/Auth/ChangePasswordPage/layout/changePassForm.dart';


class ChangePassMobileLayout extends StatelessWidget {
   final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onChangePassword;
  final TextEditingController oldPasswordController;

  const ChangePassMobileLayout({
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [

                    //___________________ LOGO ___________________

                    const Icon(
                      Icons.factory_outlined,
                      size: 70,
                      color: mainColor,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Login Page",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),


                    const SizedBox(height: 40),

                    //___________________ FORM CARD ___________________

                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ChangePasswordSharedForm(
                            oldPasswordController: oldPasswordController,
                            newPasswordController: newPasswordController,
                            confirmPasswordController: confirmPasswordController,
                            formKey: formKey,
                            onChangePassword: onChangePassword,
                            maxWidth: 420,
                          ),
                          

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