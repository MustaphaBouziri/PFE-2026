import 'package:flutter/material.dart';

class LoginSharedForm extends StatefulWidget {
  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onLogin;
  final double maxWidth;

  const LoginSharedForm({
    super.key,
    required this.userIdController,
    required this.passwordController,
    required this.formKey,
    required this.onLogin,
    required this.maxWidth,
  });

  @override
  State<LoginSharedForm> createState() => _LoginSharedFormState();
}

class _LoginSharedFormState extends State<LoginSharedForm> {
  bool _obscurePassword = true;

  static const Color mainColor = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //___________________ USER ID LABEL ___________________

            const Text(
              "User ID",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 8),

            //___________________ USER ID INPUT ___________________

            TextFormField(
              controller: widget.userIdController,
              decoration: InputDecoration(
                hintText: "Enter your user id",
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                ),
                suffixIcon: const Icon(
                  Icons.person,
                  color: mainColor,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 212, 212, 212),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: mainColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter your User ID";
                }
                if (value.trim().length < 8) {
                  return "User ID must be at least 8 characters";
                }
                return null;
              },
            ),

            const SizedBox(height: 36),

            //___________________ PASSWORD LABEL ___________________

            const Text(
              "Password",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 8),

            //___________________ PASSWORD INPUT ___________________

            TextFormField(
              controller: widget.passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: "Enter your password",
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: mainColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 212, 212, 212),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: mainColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter your password";
                }
                if (value.trim().length < 8) {
                  return "Password must be at least 8 characters";
                }
                return null;
              },
            ),

            const SizedBox(height: 22),

            //___________________ LOGIN BUTTON ___________________

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: widget.onLogin,
                child: const Text(
                  "Sign in",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}