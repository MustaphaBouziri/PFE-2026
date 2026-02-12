import 'package:flutter/material.dart';

class LoginSharedForm extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User ID",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w600),),
            SizedBox(height: 8,),
            TextFormField(
              controller: userIdController,
              decoration: InputDecoration(
                
                hintText: "Enter your user id",
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color.fromARGB(255, 212, 212, 212),
                  ), 
                  borderRadius: BorderRadius.circular(16),
                ),

                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color.fromARGB(255, 81, 81, 81),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red,
                    width: 2,
                  ), // when error
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red,
                    width: 2,
                  ), // when focused + error
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
             Text("Password",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w600),),
            SizedBox(height: 8,),
            TextFormField(
              controller: userIdController,
              decoration: InputDecoration(
                
                hintText: "Enter your user id",
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color.fromARGB(255, 212, 212, 212),
                  ), 
                  borderRadius: BorderRadius.circular(16),
                ),

                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color.fromARGB(255, 81, 81, 81),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red,
                    width: 2,
                  ), // when error
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red,
                    width: 2,
                  ), // when focused + error
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter your password";
                }
                if (value.trim().length < 8) {
                  return "password must be at least 8 characters";
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            SizedBox(

              width: double.infinity,
              height: 48,
             
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(16)
                  )
                ),
                onPressed: onLogin,
                child: const Text(
                  "Sign in",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
