import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return "Este correo ya está registrado.";
        case 'invalid-email':
          return "El formato del correo no es válido.";
        case 'weak-password':
          return "La contraseña debe tener al menos 6 caracteres.";
        default:
          return "Error desconocido: ${e.message}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return "No existe una cuenta con este correo.";
        case 'wrong-password':
          return "Contraseña incorrecta.";
        case 'invalid-email':
          return "Correo no válido.";
        default:
          return "Error desconocido: ${e.message}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<void> logout() async => await _auth.signOut();
}
