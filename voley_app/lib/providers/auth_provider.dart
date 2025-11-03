// lib/providers/auth_provider.dart

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
    state = const AsyncLoading();
    final authService = ref.read(authServiceProvider);
    try {
      final result = await authService.login(email, password);
      if (result == "success") {
        state = const AsyncData(null);
      } else {
        throw Exception(result ?? "Error al iniciar sesión");
      }
    } catch (e, s) {
      state = AsyncError(e, s);
    }
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
    state = const AsyncLoading();
    final authService = ref.read(authServiceProvider);

    try {
      final result = await authService.register(
        email,
        password,
        name,
        role, // Pasa el UserRole con alias
      );
      if (result == "success") {
        state = const AsyncData(null);
      } else {
        throw Exception(result ?? "Error al registrarse");
      }
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}