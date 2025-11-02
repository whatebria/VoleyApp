// lib/src/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- 1. Imports de Providers ---
import 'package:voley_app/providers/auth_provider.dart'; // Para authStateProvider
import 'package:voley_app/providers/providers.dart';     // Para el resto

// --- 2. Imports de Pantallas ---
import 'package:voley_app/src/auth/login_screen.dart';
import 'package:voley_app/src/screens/home_screen.dart';
// (Ajusta estas rutas si son diferentes en tu proyecto)
import 'package:voley_app/src/screens/program_view_screen.dart'; // Pantalla de Coach
import 'package:voley_app/src/screens/player_calendar_screen.dart'; // Pantalla de Jugador

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  // --- 3. (NUEVO) Helper para cargar el perfil del jugador ---
  Future<void> _loadPlayerProfile(WidgetRef ref, String userId) async {
    // Esta función precarga el perfil del jugador en 'playerProfileProvider'
    // para que 'generatedProgramProvider' (que usa el calendario)
    // sepa qué programa buscar.
    
    // Solo carga si el provider está actualmente nulo
    if (ref.read(playerProfileProvider) == null) {
      final firestore = ref.read(firestoreProvider);
      final profile = await firestore.getPlayerProfileByUserId(userId);
      if (profile != null) {
        // Coloca el perfil del jugador en el provider
        ref.read(playerProfileProvider.notifier).state = profile;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 4. Escucha el estado de AUTENTICACIÓN (¿Logueado o no?)
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error de autenticación: $e'))),
      data: (firebaseUser) {
        if (firebaseUser == null) {
          // 5. No está logueado -> va al Login
          return const LoginScreen(); 
        }

        // 6. SÍ está logueado. Ahora revisa su ROL en Firestore.
        //    (currentUserAppUserProvider usa el 'firebaseUser.uid' para buscar
        //     el documento en la colección 'users')
        final appUserAsync = ref.watch(currentUserAppUserProvider);
        
        return appUserAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, s) => Scaffold(body: Center(child: Text('Error al cargar perfil de Firestore: $e'))),
          data: (appUser) {
            if (appUser == null) {
              // (Caso raro: tiene Auth pero no doc en 'users')
              return const LoginScreen();
            }

            // 7. ¡AQUÍ ESTÁ LA LÓGICA DE ROL!
            if (appUser.isCoach) {
              // Es Coach -> va al Explorador de Programas (ProgramViewScreen)
              return const HomeScreen();
            } else {
              // Es Jugador -> va al Calendario
              
              // Precargamos su perfil para que el calendario funcione
              _loadPlayerProfile(ref, appUser.id);
              
              return const PlayerCalendarScreen();
            }
          },
        );
      },
    );
  }
}