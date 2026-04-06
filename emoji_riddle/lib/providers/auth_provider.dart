import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class AuthProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:3000/api/users';
  
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String _errorMsg = '';

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String get errorMsg => _errorMsg;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    
    if (username != null) {
      await login(username);
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('deviceId');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('deviceId', deviceId);
    }
    return deviceId;
  }

  Future<bool> login(String username) async {
    _isLoading = true;
    _errorMsg = '';
    notifyListeners();
    try {
      final deviceId = await _getDeviceId();
      final response = await http.post(
        Uri.parse('$_baseUrl/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'device_id': deviceId}),
      );

      if (response.statusCode == 200) {
        _user = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setInt('userId', _user!['id']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 403) {
        final body = jsonDecode(response.body);
        _errorMsg = body['error'] ?? 'Bu hesap baska bir cihaza bagli.';
      } else {
        _errorMsg = 'Giris yapilamadi!';
      }
    } catch (e) {
      _errorMsg = 'Sunucuya ulasılamadı veya baglanti hatasi.';
    }
    
    _isLoading = false;
    notifyListeners();
    return _user != null;
  }

  Future<bool> updateUsername(String newName) async {
    if (_user == null) return false;
    _isLoading = true;
    _errorMsg = '';
    notifyListeners();
    
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${_user!['id']}/rename'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': newName}),
      );

      if (response.statusCode == 200) {
        _user!['username'] = newName;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', newName);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(response.body);
        _errorMsg = body['error'] ?? 'İsim değiştirilemedi.';
      }
    } catch (e) {
      _errorMsg = 'Sunucuya ulaşılamadı.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> subscribePremium() async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/${_user!['id']}/subscribe'),
      );
      if (response.statusCode == 200) {
        _user!['is_premium'] = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMsg = 'Bağlantı hatası.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    _user = null;
    notifyListeners();
  }
}
