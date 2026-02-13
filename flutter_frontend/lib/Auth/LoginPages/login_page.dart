import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:pfe_mes/Auth/ChangePasswordPage/changePassPage.dart';
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

// remove this afterwards typed it so i dont get error
void login(){

}
  /*
  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    

      ___________GET USER INPUTS TEXT___________________

    final userId = userIdController.text.trim(); 
    final password = passwordController.text.trim();

   
   

  ___________USER ID VERIFICATION CONDITION___________________

    if (user do not xist in database) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("User Not Found"),
          content: Text("This User ID does not exist."),
        ),
      );
      return;
    }

     ___________USER PASSWORD VERIFICATION CONDITION___________________
    if (if this user password not the same ) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Login Failed"),
          content: Text("Incorrect password. Please try again."),
        ),
      );
      return;
    }
  ___________ CHECK IF USER IS NEW CONDITION ___________________

    if ( the user is new ) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChnagePasswordPage()),
      );
      return;
    }

    
     Navigator.push(context, MaterialPageRoute(builder: (_) => MachineListPage()));
  }
*/
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 600) {
          return LoginMobileLayout(
            userIdController:
                userIdController, // basically its we just passing it for reference go web layout for more details
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
    );
  }
}
