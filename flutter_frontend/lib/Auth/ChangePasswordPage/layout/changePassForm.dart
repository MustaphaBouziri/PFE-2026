import 'package:flutter/material.dart';

class ChangePasswordSharedForm extends StatefulWidget {
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onChangePassword;
  final double maxWidth;

  const ChangePasswordSharedForm({
    super.key,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.formKey,
    required this.onChangePassword,
    required this.maxWidth,
  });

  @override
  State<ChangePasswordSharedForm> createState() =>
      _ChangePasswordSharedFormState();
}

class _ChangePasswordSharedFormState
    extends State<ChangePasswordSharedForm> {
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

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
            //___________________ NEW PASSWORD LABEL ___________________

            const Text(
              "New Password",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 8),

            //___________________ NEW PASSWORD INPUT ___________________

            TextFormField(
              controller: widget.newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                hintText: "Enter your new password",
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: mainColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
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
                  return "Please enter a new password";
                }
                if (value.trim().length < 8) {
                  return "Password must be at least 8 characters";
                }
                if (value.trim().length > 20) {
                  return "Password must be less than 21 characters long";
                }
                return null;
              },
            ),

            const SizedBox(height: 36),

            //___________________ CONFIRM PASSWORD LABEL ___________________

            const Text(
              "Retype Password",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 8),

            //___________________ CONFIRM PASSWORD INPUT ___________________

            TextFormField(
              controller: widget.confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: "Retype your new password",
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: mainColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword =
                          !_obscureConfirmPassword;
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
                  return "Please retype your password";
                }
                if (value != widget.newPasswordController.text) {
                  return "Passwords do not match";
                }
                return null;
              },
            ),

            const SizedBox(height: 22),

            //___________________ Sign in BUTTON ___________________

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
                onPressed: widget.onChangePassword,
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