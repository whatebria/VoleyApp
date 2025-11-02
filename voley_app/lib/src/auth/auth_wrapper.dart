// lib/src/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/auth/login_screen.dart';
import 'package:voley_app/src/screens/home_screen.dart';
import 'package:voley_app/src/screens/player_home_screen.dart';
// 1. Importa el auth_provider para acceder al authStateProvider
import 'package:voley_app/providers/auth_provider.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    // --- 2. ¡AQUÍ ESTÁ LA CORRECCIÓN DEL BUG! ---
    // "Escuchamos" el estado de autenticación.
    ref.listen(authStateProvider, (previous, next) {
      // 'next' es un AsyncValue<User?>
      // Si no está cargando Y el valor es null, significa que se cerró sesión.
      if (!next.isLoading && next.value == null) {
        // Resetea el provider del loader a 'false'.
        ref.read(isLoggingOutProvider.notifier).state = false;
      }
    });
    // --- FIN DE LA CORRECCIÓN ---

    // El resto de tu lógica no cambia
    final appUserAsync = ref.watch(currentUserAppUserProvider);

    return appUserAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error al iniciar: $e'))),
      data: (appUser) {
        if (appUser == null) {
          return const LoginScreen();
        }
        if (appUser.isCoach) {
          return const HomeScreen();
        } else {
          return const PlayerHomeScreen();
        }
      },
    );
  }
}