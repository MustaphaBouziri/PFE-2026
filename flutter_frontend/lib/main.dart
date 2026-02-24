// =============================================================================
// main.dart
// Purpose: App entry point. Loads YAML config, wires DI, starts the app.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/admin/data/admin_repository.dart';
import 'features/machines/data/machines_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load app_config.yaml before anything else.
  // AppConfig will throw a clear error message if a required key is missing.
  await AppConfig.load();

  runApp(const MesApp());
}

class MesApp extends StatelessWidget {
  const MesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositories — singleton instances injected into providers.
        // Swap these for mock implementations in widget tests.
        Provider<AuthRepository>(
          create: (_) => AuthRepository(client: ApiClient.instance),
        ),
        Provider<AdminRepository>(
          create: (_) => AdminRepository(client: ApiClient.instance),
        ),
        Provider<MachinesRepository>(
          create: (_) => MachinesRepository(client: ApiClient.instance),
        ),

        // AuthProvider — depends on AuthRepository via ProxyProvider.
        ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
          create: (ctx) => AuthProvider(repository: ctx.read<AuthRepository>()),
          update: (ctx, repo, prev) => prev ?? AuthProvider(repository: repo),
        ),
      ],
      child: MaterialApp(
        title: 'MES',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
          useMaterial3: true,
        ),
        // TODO: replace with GoRouter or auto_route and point to login route
        home: const Scaffold(
          body: Center(child: Text('MES — configure your router in main.dart')),
        ),
      ),
    );
  }
}
