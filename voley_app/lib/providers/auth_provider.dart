import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/auth/auth_service.dart';
import 'package:voley_app/src/models/user.dart' as app_user; // <-- 1. AÑADE EL ALIAS
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// StreamProvider para escuchar cambios en el estado de autenticación

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Provider para obtener el usuario actual

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) => user,

    loading: () => null,

    error: (_, __) => null,

      );
});

final loginControllerProvider =
    AutoDisposeAsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);

/// El Notifier que contiene la LÓGICA de login
class LoginController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> login(String email, String password) async {
    final authService = ref.read(authServiceProvider);
    
    // --- CORRECCIÓN ---
    // state = const AsyncLoading(); // <-- ESTO CAUSA EL ERROR
    
    // Usa AsyncValue.guard para manejar automáticamente 
    // los estados de loading, data y error.
    // Esto permite que el notifier se vuelva a ejecutar sin fallar.
    state = await AsyncValue.guard(() async {
      final result = await authService.login(email, password);
      if (result != "success") {
        throw Exception(result ?? "Error al iniciar sesión");
      }
    });
  }
}

/// Este provider manejará el ESTADO de la acción de registro
final registerControllerProvider =
    AutoDisposeAsyncNotifierProvider<RegisterController, void>(
  RegisterController.new,
);

/// El Notifier que contiene la LÓGICA de registro
class RegisterController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required app_user.UserRole role, 
  }) async {
    final authService = ref.read(authServiceProvider);

    // --- CORRECCIÓN ---
    // state = const AsyncLoading(); // <-- ESTO CAUSA EL ERROR
    
    // Usa AsyncValue.guard aquí también
    state = await AsyncValue.guard(() async {
      final result = await authService.register(
        email,
        password,
        name,
        role, // Pasa el UserRole con alias
      );
      if (result != "success") {
        throw Exception(result ?? "Error al registrarse");
      }
    });
  }
}

