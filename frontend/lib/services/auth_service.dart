import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final String baseUrl = "http://127.0.0.1:8000/api";
  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;

  Future<bool> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/token/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        
        // Salvar token localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        
        // Carregar perfil
        await fetchProfile();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String phone, String username, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": phone,
          "username": username,
          "password": password,
          "role": role,
        }),
      );

      if (response.statusCode == 201) {
        return await login(phone, password);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/profile/"),
        headers: {
          "Authorization": "Bearer $_token",
        },
      );
      if (response.statusCode == 200) {
        _user = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      print("Erro ao carregar perfil: $e");
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;
    _token = prefs.getString('token');
    await fetchProfile();
  }

  Future<Map<String, dynamic>?> getMotoProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/moto-profile/"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Erro MotoProfile: $e");
    }
    return null;
  }

  Future<bool> updateMotoStock(int sonangol, int canata) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/moto-profile/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "stock_sonangol": sonangol,
          "stock_canata": canata,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Erro UpdateStock: $e");
      return false;
    }
  }

  Future<bool> acceptOrder(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/orders/$orderId/accept_order/"),
        headers: {"Authorization": "Bearer $token"},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Erro AcceptOrder: $e");
      return false;
    }
  }
}
