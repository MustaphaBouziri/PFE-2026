import 'package:flutter/material.dart';
import 'package:pfe_mes/Auth/ChangePasswordPage/layout/mobile.dart';
import 'package:pfe_mes/Auth/ChangePasswordPage/layout/tablet.dart';
import 'package:pfe_mes/Auth/ChangePasswordPage/layout/web%20.dart';

class ChnagePasswordPage extends StatefulWidget {
  const ChnagePasswordPage({super.key});

  @override
  State<ChnagePasswordPage> createState() => _ChnagePasswordPageState();
}

class _ChnagePasswordPageState extends State<ChnagePasswordPage> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void onChangePassword() {

  if (!formKey.currentState!.validate()) return;

 
  if (newPasswordController.text.trim() != confirmPasswordController.text.trim()) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Password Error"),
        content: const Text("Passwords do not match. Please try again."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  } else {
    
    // Navigator.push(context, MaterialPageRoute(builder: (_) => MachineListPage()));
  }
}

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 600) {
          return ChangePassMobileLayout(
            newPasswordController: newPasswordController,
            confirmPasswordController: confirmPasswordController,
            formKey: formKey,
            onChangePassword: onChangePassword,
          );
        } else if (width < 1024) {
          return ChangePassTabletLayout(
            newPasswordController: newPasswordController,
            confirmPasswordController: confirmPasswordController,
            formKey: formKey,
            onChangePassword: onChangePassword,
          );
        } else {
          return ChangePassWebLayout(
            newPasswordController: newPasswordController,
            confirmPasswordController: confirmPasswordController,
            formKey: formKey,
            onChangePassword: onChangePassword,
          );
        }
      },
    );
  }
}
