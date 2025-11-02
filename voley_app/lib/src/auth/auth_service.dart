import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    bool keepCurrentSession = false,
  }) async {
    User? currentUser;
    
    try {
      // Si queremos mantener la sesión actual (coach creando player)
      if (keepCurrentSession) {
        currentUser = _auth.currentUser;
      }

      // 1. Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Crear el objeto de usuario para Firestore
      final user = app_user.User(
        id: userCredential.user!.uid, // Usar el UID de Auth
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
        coachId: coachId,
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

      // 5. Si debemos mantener la sesión actual, cerrar sesión del nuevo usuario
      // y volver a iniciar sesión con el usuario anterior
      if (keepCurrentSession && currentUser != null) {
        await _auth.signOut();
        // Note: We can't directly sign back in without credentials
        // The caller should handle re-authentication if needed
        // For now, we'll just sign out the new user
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
}