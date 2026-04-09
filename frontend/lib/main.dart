import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'screens/client_shell.dart';
import 'screens/moto_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..tryAutoLogin()),
      ],
      child: const NossoGasApp(),
    ),
  );
}

class NossoGasApp extends StatelessWidget {
  const NossoGasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOSSO GÁS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            final role = auth.user?['role'];
            if (role == 'MOTOQUEIRO') {
              return const MotoShell();
            }
            return const ClientShell();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
