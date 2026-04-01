import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/domain/auth/providers/auth_provider.dart';
import 'layout/mobile.dart';
import 'layout/tablet.dart';
import 'layout/web .dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> onChangePassword() async {
    if (!formKey.currentState!.validate()) return;

    // Check if passwords match
    if (newPasswordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("passwordError".tr()),
          content: Text("passwordsDoNotMatch".tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("ok".tr()),
            ),
          ],
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await authProvider.changePassword(
      oldPasswordController.text.trim(),
      newPasswordController.text.trim(),
    );

    if (!mounted) return;

    // Close loading indicator
    Navigator.of(context).pop();

    if (success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("success".tr()),
          content: Text(
            "passwordChanged".tr(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // The main.dart will handle navigation automatically
                // since needsPasswordChange is now false
              },
              child: Text("ok".tr()),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("error".tr()),
          content: Text(
            authProvider.errorMessage ??
                "passwordChangeFailed".tr(),
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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            // Show loading overlay if processing
            return Stack(
              children: [
                // Main content
                Builder(
                  builder: (context) {
                    if (width < 600) {
                      return ChangePassMobileLayout(
                        oldPasswordController: oldPasswordController,
                        newPasswordController: newPasswordController,
                        confirmPasswordController: confirmPasswordController,
                        formKey: formKey,
                        onChangePassword: onChangePassword,
                      );
                    } else if (width < 1024) {
                      return ChangePassTabletLayout(
                        oldPasswordController: oldPasswordController,
                        newPasswordController: newPasswordController,
                        confirmPasswordController: confirmPasswordController,
                        formKey: formKey,
                        onChangePassword: onChangePassword,
                      );
                    } else {
                      return ChangePassWebLayout(
                        oldPasswordController: oldPasswordController,
                        newPasswordController: newPasswordController,
                        confirmPasswordController: confirmPasswordController,
                        formKey: formKey,
                        onChangePassword: onChangePassword,
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
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('changingPassword'.tr()),
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
