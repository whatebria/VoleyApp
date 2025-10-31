import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/user.dart' as app_user;

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<String?> register(
    String email,
    String password,
    String name,
    app_user.UserRole role,
  ) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final user = app_user.User(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.id).set(user.toJson());

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
