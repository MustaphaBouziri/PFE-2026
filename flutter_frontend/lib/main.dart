import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe_mes/Auth/ChangePasswordPage/changePassPage.dart';
import 'package:pfe_mes/Auth/LoginPages/login_page.dart';
import 'package:pfe_mes/admin/AddUserPage.dart';
import 'package:pfe_mes/providers/auth_provider.dart';
import 'package:pfe_mes/providers/erp_employee_provider.dart';
import 'package:pfe_mes/providers/erp_workCenter_provider.dart';
import 'package:pfe_mes/providers/mes_user_provider.dart';
import 'package:pfe_mes/user/userDashboard.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true, // Set to false in production
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => MesUserProvider()),
          ChangeNotifierProvider(create: (_) => ErpEmployeeProvider()),
          ChangeNotifierProvider(create: (_) => ErpWorkcenterProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      // Important for DevicePreview
      locale: DevicePreview.locale(context),
      // Important for DevicePreview
      builder: DevicePreview.appBuilder,
      // Important for DevicePreview
      title: 'MES System',
      theme: ThemeData(textTheme: GoogleFonts.interTextTheme()),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus(); // fires ONCE only
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          if (auth.needsPasswordChange) return const ChangePasswordPage();
          final role = auth.userData?['role']?.toString() ?? '';
          if (role == 'Admin') return const AddUserPage();
          return const UserDashboard();
        }
        return const LoginPage();
      },
    );
  }
}
