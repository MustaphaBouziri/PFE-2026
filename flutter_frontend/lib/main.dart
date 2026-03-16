import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/domain/admin/providers/erp_workCenter_provider.dart';
import '/domain/admin/providers/mes_user_provider.dart';
import '/domain/auth/providers/auth_provider.dart';
import '/domain/machines/providers/machineOrders_provider.dart';
import 'domain/admin/providers/erp_employee_provider.dart';
import 'domain/machines/providers/mes_machines_provider.dart';
import 'presentation/admin/AddUserPage.dart';
import 'presentation/auth/ChangePassword/changePassPage.dart';
import 'presentation/auth/Login/login_page.dart';
import 'presentation/machine/machine_List/machineListPage.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: false, // Set to false in production
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => MesUserProvider()),
          ChangeNotifierProvider(create: (_) => ErpEmployeeProvider()),
          ChangeNotifierProvider(create: (_) => ErpWorkcenterProvider()),
          ChangeNotifierProvider(create: (_) => MachineordersProvider()),
          Provider(create: (_) => MesMachinesProvider()),
        
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
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),

        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
        ),
      ),
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
          return const Machinelistpage();
        }
        return const LoginPage();
      },
    );
    return Machinelistpage();
  }
}
