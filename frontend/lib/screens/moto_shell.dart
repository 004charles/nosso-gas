import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/order_websocket_service.dart';
import '../core/theme.dart';
import 'login_screen.dart';

class MotoShell extends StatefulWidget {
  const MotoShell({super.key});

  @override
  State<MotoShell> createState() => _MotoShellState();
}

class _MotoShellState extends State<MotoShell> {
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  final OrderWebSocketService _socketService = OrderWebSocketService();
  List<Map<String, dynamic>> _newOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.user?['id'];
    if (userId != null) {
      _socketService.connect(userId);
      _socketService.stream.listen((data) {
        if (data['type'] == 'new_order') {
          setState(() {
            _newOrders.insert(0, data['order']);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> _acceptOrder(int orderId) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await auth.acceptOrder(orderId);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pedido aceito com sucesso! Prepare a entrega.")),
      );
      setState(() {
        _newOrders.removeWhere((o) => o['id'] == orderId);
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao aceitar pedido. Talvez já tenha sido levado.")),
      );
    }
  }

  Future<void> _fetchProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      final response = await auth.getMotoProfile();
      if (mounted) {
        setState(() {
          _profile = response;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Widget> get _pages => [
    _buildDashboard(Provider.of<AuthService>(context, listen: false)),
    _buildStockManager(Provider.of<AuthService>(context, listen: false)),
    _buildProfile(Provider.of<AuthService>(context, listen: false)),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.black,
        selectedItemColor: AppTheme.primaryOrange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: "Pedidos"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: "Stock"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
        ],
      ),
    );
  }

  Widget _buildDashboard(AuthService auth) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Entregador Dashboard"),
        backgroundColor: Colors.transparent,
        actions: [
          Switch(
            value: true, // Simulado por agora
            onChanged: (val) {},
            activeColor: Colors.greenAccent,
          ),
          const Center(child: Text("ONLINE", style: TextStyle(fontSize: 10))),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 60, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text("Nenhum pedido novo no momento", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStock(String type, int delta) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    int newSonangol = _profile?['stock_sonangol'] ?? 0;
    int newCanata = _profile?['stock_canata'] ?? 0;

    if (type == 'SONANGOL') {
      newSonangol += delta;
      if (newSonangol < 0) return;
    } else {
      newCanata += delta;
      if (newCanata < 0) return;
    }

    final success = await auth.updateMotoStock(newSonangol, newCanata);
    if (success) {
      _fetchProfile(); // Recarrega dados
    }
  }

  Widget _buildStockManager(AuthService auth) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Gerir Stock"), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Carregamento Atual", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _stockItem("Sonangol (Laranja)", _profile?['stock_sonangol'] ?? 0, Colors.orange, () => _updateStock('SONANGOL', 1), () => _updateStock('SONANGOL', -1)),
            const SizedBox(height: 16),
            _stockItem("Canata (Azul)", _profile?['stock_canata'] ?? 0, Colors.blue, () => _updateStock('CANATA', 1), () => _updateStock('CANATA', -1)),
            const Spacer(),
            const Text("Dica: Mantenha o seu stock atualizado para receber pedidos compatíveis.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _stockItem(String label, int count, Color color, VoidCallback onAdd, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.surfaceGrey, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.gas_meter, color: color),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              _countBtn(Icons.remove, onRemove),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("$count", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              _countBtn(Icons.add, onAdd),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: AppTheme.primaryOrange),
      ),
    );
  }

  Widget _buildProfile(AuthService auth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 40, backgroundColor: AppTheme.primaryOrange, child: Icon(Icons.motorcycle, color: Colors.black)),
          const SizedBox(height: 16),
          Text(auth.user?['username'] ?? "Entregador", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Sonangol Distribuição S.A.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton(
              onPressed: () => auth.logout(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent),
              child: const Center(child: Text("SAIR")),
            ),
          ),
        ],
      ),
    );
  }
}
