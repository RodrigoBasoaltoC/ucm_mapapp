import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Stream para escuchar los cambios de estado de autenticación
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Obtener el usuario actual
  User? get currentUser => _firebaseAuth.currentUser;

  // Cerrar sesión
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}