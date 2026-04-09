import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';
import 'client_shell.dart';
import 'moto_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await auth.login(
      _phoneController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _loading = false);

    if (success) {
      if (mounted) {
        final role = auth.user?['role'];
        if (role == 'MOTOQUEIRO') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MotoShell()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ClientShell()),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Falha no login. Verifique os dados.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(
                child: Icon(Icons.local_gas_station, size: 80, color: AppTheme.primaryOrange),
              ),
              const SizedBox(height: 24),
              const Text(
                "NOSSO GÁS",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                "Gás à porta de casa em Luanda",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Número de Telefone",
                  prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryOrange),
                  filled: true,
                  fillColor: AppTheme.surfaceGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Senha",
                  prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryOrange),
                  filled: true,
                  fillColor: AppTheme.surfaceGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _loading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("ENTRAR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text("Não tem conta? Registe-se", style: TextStyle(color: AppTheme.primaryOrange)),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
