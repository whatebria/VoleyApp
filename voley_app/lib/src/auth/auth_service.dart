import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voley_app/src/models/user.dart' as app_user;

class AuthService {
  // --- Definiciones de las instancias ---
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance; // <-- ARREGLO 1

  // --- Método de Registro ---
  Future<String?> register(
    String email,
    String password,
    String name,
    app_user.UserRole role, {
    String? coachId,
  }) async {
    try {
      // 1. Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final linkCode = await _generateUniqueLinkCode();

      // 2. Crear el objeto de usuario para Firestore
      final user = app_user.User(
        id: userCredential.user!.uid, // Usar el UID de Auth
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
        coachId: coachId,
        linkCode: linkCode,
      );

      // 3. Guardar el usuario en la colección 'users' de Firestore
      await _firestore.collection('users').doc(user.id).set(user.toJson());

      // 4. Si se proporciona coachId y el rol es player, crear permiso aceptado
      if (coachId != null && role == app_user.UserRole.player) {
        final permission = {
          'id': '${coachId}_${user.id}',
          'coachId': coachId,
          'playerId': user.id,
          'status': 'accepted',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };
        await _firestore
            .collection('coach_player_permissions')
            .doc(permission['id'] as String)
            .set(permission);
      }

      return "success";
    } on FirebaseAuthException catch (e) {
      // 5. Manejo de errores de REGISTRO (eran de login)
      switch (e.code) {
        case 'email-already-in-use':
          return "El correo ya está en uso.";
        case 'weak-password':
          return "Contraseña muy débil.";
        case 'invalid-email':
          return "Correo no válido.";
        default:
          return "Error: ${e.message}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  // --- Método de Login (separado) ---
  Future<String?> login(String email, String password) async {
    try {
      // Iniciar sesión con Auth
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "success";
    } on FirebaseAuthException catch (e) {
      // Manejo de errores de LOGIN
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

  // --- Método de Logout (separado) ---
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String> _generateUniqueLinkCode() async {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    String _generateCode() {
      return List.generate(
        6,
        (_) => characters[random.nextInt(characters.length)],
      ).join();
    }

    String code;
    bool exists = true;

    while (exists) {
      code = _generateCode();
      final snapshot = await _firestore
          .collection('users')
          .where('linkCode', isEqualTo: code)
          .limit(1)
          .get();
      exists = snapshot.docs.isNotEmpty;
      if (!exists) {
        return code;
      }
    }

    // No debería llegar aquí, pero Dart requiere inicialización
    return _generateCode();
  }
}
