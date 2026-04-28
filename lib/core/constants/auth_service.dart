import 'package:firebase_auth/firebase_auth.dart';
import 'package:plantcare/core/constants/firebase_options.dart';

/// Servicio para gestionar la autenticación de usuarios con Firebase
class AuthService {
  static final AuthService instance = AuthService._init();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService._init();

  /// Obtiene el usuario actual
  User? get currentUser => _auth.currentUser;

  /// Obtiene el stream de cambios de estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Inicializa Firebase Auth
  static Future<void> initialize() async {
    // La inicialización se hace en main.dart con Firebase.initializeApp
  }

  /// Registra un nuevo usuario con email y contraseña
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Inicia sesión con email y contraseña
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Envía un email para restablecer la contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Actualiza el perfil del usuario (displayName)
  Future<void> updateProfile({String? displayName}) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
    }
  }

  /// Maneja las excepciones de Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este email ya está registrado';
      case 'invalid-email':
        return 'El email no es válido';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'wrong-password':
        return 'La contraseña es incorrecta';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      case 'invalid-login-credentials':
        return 'Email o contraseña incorrectos';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}