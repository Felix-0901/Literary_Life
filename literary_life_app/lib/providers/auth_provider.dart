import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/app_api_client.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AppApiClient? apiClient})
    : _apiClient = apiClient ?? const DefaultAppApiClient();

  final AppApiClient _apiClient;
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  Future<bool> tryAutoLogin() async {
    final token = await _apiClient.getToken();
    if (token == null) return false;

    try {
      final data = await _apiClient.get('${ApiConfig.authUrl}/me');
      _user = User.fromJson(data);
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      // Don't store error - auto-login failure is expected when token expires,
      // and we don't want this message to appear on the login page.
      _error = null;
      await _apiClient.clearToken();
      _user = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String nickname,
    String email,
    String password,
    String confirmPassword,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiClient.post(
        '${ApiConfig.authUrl}/register',
        body: {
          'nickname': nickname,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );
      await _apiClient.setToken(data['access_token']);
      _user = User.fromJson(data['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiClient.post(
        '${ApiConfig.authUrl}/login',
        body: {'email': email, 'password': password},
      );
      await _apiClient.setToken(data['access_token']);
      _user = User.fromJson(data['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({String? nickname, String? bio}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiClient.updateProfile(nickname: nickname, bio: bio);
      _user = User.fromJson(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
