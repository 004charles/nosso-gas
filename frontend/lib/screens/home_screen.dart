import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/theme.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedBrand;
  int _quantity = 1;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primaryOrange,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Olá, Bem-vindo", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      auth.user?['username'] ?? "Cliente Nosso Gás",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Qual botija precisa hoje?",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      _buildBottleCard("Sonangol", "assets/images/sonangol.png", "12.000 Kz", "SONANGOL"),
                      const SizedBox(width: 16),
                      _buildBottleCard("Canata/Saip", "assets/images/canata.png", "12.000 Kz", "CANATA"),
                    ],
                  ),

                  const SizedBox(height: 40),
                  
                  if (_selectedBrand != null) ...[
                    const Text("Quantidade de Botijas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceGrey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _quantityButton(Icons.remove, () {
                            if (_quantity > 1) setState(() => _quantity--);
                          }),
                          const SizedBox(width: 32),
                          Text("$_quantity", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 32),
                          _quantityButton(Icons.add, () => setState(() => _quantity++)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_selectedBrand != null)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _loading ? null : _handleOrderPlacement,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _loading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : Text(
                      "PEDIR $_quantity BOTIJAS", 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottleCard(String name, String imagePath, String price, String brandKey) {
    final isSelected = _selectedBrand == brandKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedBrand = brandKey),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryOrange.withOpacity(0.1) : AppTheme.surfaceGrey,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Image.asset(imagePath, height: 120),
              const SizedBox(height: 12),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(price, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: AppTheme.primaryOrange),
      ),
    );
  }

  Future<void> _handleOrderPlacement() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse("${auth.baseUrl}/orders/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth.token}",
        },
        body: jsonEncode({
          "brand": _selectedBrand,
          "quantity": _quantity,
          "delivery_lat": -8.8390, // Simulado para o MVP
          "delivery_lng": 13.2894,
          "delivery_address": "Luanda, Angola",
        }),
      );

      if (response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao fazer pedido. Tente novamente.")),
        );
      }
    } catch (e) {
      print("Erro: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 80),
            const SizedBox(height: 20),
            const Text("Pedido Confirmado!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "O seu pedido já foi recebido. Pode acompanhar o estado no menu Pedidos.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Center(child: Text("OK")),
            ),
          ],
        ),
      ),
    );
  }
}
