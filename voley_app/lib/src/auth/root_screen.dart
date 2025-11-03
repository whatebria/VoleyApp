import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/auth_provider.dart'; // Tu StreamProvider de Auth
import 'package:voley_app/src/auth/auth_wrapper.dart'; // Importamos el AuthWrapper
import 'package:voley_app/src/auth/login_screen.dart';

/// Este widget decide la ruta de navegación inicial basándose
/// en la persistencia de Firebase Auth.
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observa el StreamProvider de Firebase Auth.
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return authState.when(
      // 2. ESTADO DE CARGA: Esperando que Firebase resuelva la persistencia (CRÍTICO)
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Verificando sesión...',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),

      // 3. ESTADO DE ERROR
      error: (e, s) => Scaffold(
        body: Center(
          child: Text('Error de Autenticación: $e'),
        ),
      ),

      // 4. ESTADO DE DATOS: Persistencia resuelta.
      data: (user) {
        if (user == null) {
          // No hay usuario de Auth: Va directo al login.
          return const LoginScreen();
        } else {
          // Hay usuario de Auth: Delega la decisión de redirección
          // (Coach vs Jugador) al AuthWrapper, que cargará el perfil de Firestore.
          return const AuthWrapper();
        }
      },
    );
  }
}