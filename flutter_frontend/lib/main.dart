import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pfe_mes/providers/auth_provider.dart';
import 'package:pfe_mes/Auth/LoginPages/login_page.dart';
import 'package:pfe_mes/Auth/ChangePasswordPage/changePassPage.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MES System',
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Check auth status on app start
          WidgetsBinding.instance.addPostFrameCallback((_) {
            auth.checkAuthStatus();
          });
          
          if (auth.isAuthenticated) {
            if (auth.needsPasswordChange) {
              return const ChangePasswordPage();
            }
            // TODO: Return your main app page
            return Scaffold(
              appBar: AppBar(
                title: const Text('MES System'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      auth.logout();
                    },
                  ),
                ],
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 80, color: Colors.green),
                    const SizedBox(height: 20),
                    const Text(
                      'Login Successful!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome, ${auth.userData?['name'] ?? 'User'}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        auth.logout();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return const LoginPage();
        },
      ),
    );
  }
}