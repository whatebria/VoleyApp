// lib/src/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/src/auth/login_screen.dart';
import 'package:voley_app/src/screens/home_screen.dart';
import 'package:voley_app/src/screens/onboarding/evaluation_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        // Si el usuario está autenticado, mostrar la pantalla principal

        if (user != null) {
          return const HomeScreen();
        }

        // Si no está autenticado, mostrar login

        return const LoginScreen();
      },

      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),

              const SizedBox(height: 16),

              Text('Error: $error'),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  // Intentar recargar

                  ref.invalidate(authStateProvider);
                },

                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
