import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plantcare/core/constants/auth_service.dart';

/// Provider para gestionar el estado de autenticación
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;

  /// Stream de cambios de autenticación para GoRouter
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Inicializa el provider y escucha cambios de autenticación
  AuthProvider() {
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  /// Registra un nuevo usuario
  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.registerWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Inicia sesión
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cierra sesión
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Restablece la contraseña
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpia el error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}