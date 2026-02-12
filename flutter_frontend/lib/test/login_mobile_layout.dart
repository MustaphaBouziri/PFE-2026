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
                          child: LoginSharedForm(
                            userIdController: userIdController,
                            passwordController: passwordController,
                            formKey: formKey,
                            onLogin: onLogin,
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