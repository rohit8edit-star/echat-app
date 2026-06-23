import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> checkLogin() async {
    final token = await ApiService.getToken();
    if (token == null) return;
    try {
      _user = await ApiService.getProfile();
      if (_user != null) SocketService.connect(token);
      notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.login(phone, password);
      _isLoading = false;
      if (!res['success']) _error = res['message'];
      notifyListeners();
      return res;
    } catch (_) {
      _isLoading = false;
      _error = 'Connection error';
      notifyListeners();
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<bool> verifyLoginOTP(String email, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.verifyLoginOTP(email, otp);
      _isLoading = false;
      if (res['success']) {
        await ApiService.saveToken(res['token']);
        _user = UserModel.fromJson(res['user']);
        SocketService.connect(res['token']);
        notifyListeners();
        return true;
      }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (_) {
      _isLoading = false;
      _error = 'Connection error';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    SocketService.disconnect();
    _user = null;
    notifyListeners();
  }

  void setUser(UserModel u) {
    _user = u;
    notifyListeners();
  }
}
