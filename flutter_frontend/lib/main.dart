import 'package:device_preview/device_preview.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe_mes/core/storage/session_storage.dart';
import 'package:provider/provider.dart';

// Providers
import 'package:pfe_mes/domain/auth/providers/auth_provider.dart';
import 'package:pfe_mes/domain/admin/providers/mes_user_provider.dart';
import 'package:pfe_mes/domain/admin/providers/erp_employee_provider.dart';
import 'package:pfe_mes/domain/admin/providers/erp_workCenter_provider.dart';
import 'package:pfe_mes/domain/admin/providers/mes_log_provider.dart';
import 'package:pfe_mes/domain/machines/providers/machineOrders_provider.dart';
import 'package:pfe_mes/domain/machines/providers/mes_machines_provider.dart';
import 'package:pfe_mes/domain/machines/providers/mes_componentConsumption_provider.dart';
import 'package:pfe_mes/domain/machines/providers/mes_scrap_provider.dart';
import 'package:pfe_mes/domain/machines/barCode/provider/mes_barCode_provider.dart';
import 'domain/ai/providers/ai_chat_provider.dart';

// Pages
import 'package:pfe_mes/presentation/admin/adminPage.dart';
import 'package:pfe_mes/presentation/auth/ChangePassword/changePassPage.dart';
import 'package:pfe_mes/presentation/auth/Login/login_page.dart';
import 'package:pfe_mes/presentation/machine/machine_List/machineListPage.dart';


//this is a global navigation listener it watched pages push,pop or pages that r covered by other pages (stacked)
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  await SessionStorage.init();
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: DevicePreview(
        enabled: true,
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => MesUserProvider()),
            ChangeNotifierProvider(create: (_) => ErpEmployeeProvider()),
            ChangeNotifierProvider(create: (_) => ErpWorkcenterProvider()),
            ChangeNotifierProvider(create: (_) => MachineordersProvider()),
            ChangeNotifierProvider(create: (_) => MesBarcodeProvider()),
            ChangeNotifierProvider(create: (_) => MesScrapProvider()),
            ChangeNotifierProvider(create: (_) => LogProvider()),
            ChangeNotifierProvider(create: (_) => AiChatProvider()),
            Provider(create: (_) => MesMachinesProvider()),
            Provider(create: (_) => MesComponentconsumptionProvider()),
          ],
          child: const MyApp(),
        ),
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

      // DevicePreview
      useInheritedMediaQuery: true,
      builder: DevicePreview.appBuilder,

      // Localization (handles RTL automatically ✅)
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,

      title: 'MES System',

      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          shape: Border(
            bottom: BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
        ),
      ),
// global route observer 
// this connects the observer to flutter navigation system and allows it to listen to route changes across the entire app
//witch out it pages will never receive navigations events(pop push stacked ..)
      navigatorObservers: [routeObserver],

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
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final SessionStorage _sessionStorage = SessionStorage();
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          if (auth.needsPasswordChange) {
            return const ChangePasswordPage();
          }

          final role = _sessionStorage.getRole().toString();

          if (role == 'Admin') {
            return const AdminPage();
          }

          return const Machinelistpage();
        }

        return const LoginPage();
      },
    );
  }
}