// lib/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/src/auth/login_screen.dart';
import 'package:voley_app/src/screens/program_view_screen.dart'; // Tu explorador de coach
import 'package:voley_app/src/screens/player/player_calendar_screen.dart'; // La nueva pantalla de calendario

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  Future<void> _loadPlayerProfile(WidgetRef ref, String userId) async {
    // Esta función carga el perfil del jugador en el provider 'playerProfileProvider'
    // para que 'generatedProgramProvider' pueda encontrar el programa correcto.
    
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escucha el estado de autenticación (Usuario de Firebase Auth)
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => const Scaffold(body: Center(child: Text('Error de autenticación'))),
      data: (firebaseUser) {
        if (firebaseUser == null) {
          // 2. Si no hay usuario de Auth, va al Login
          return const LoginScreen(); // Reemplaza con tu pantalla de Login
        }

        // 3. Si hay usuario de Auth, busca su perfil en Firestore (app_user.User)
        final appUserAsync = ref.watch(currentUserAppUserProvider);
        
        return appUserAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, s) => const Scaffold(body: Center(child: Text('Error al cargar el perfil de usuario'))),
          data: (appUser) {
            if (appUser == null) {
              // 4. Si tiene Auth pero no perfil en Firestore (error raro)
              return const LoginScreen();
            }

            // 5. ¡AQUÍ ESTÁ LA LÓGICA DE ROL!
            if (appUser.isCoach) {
              // Si es Coach, va al explorador de programas
              return const ProgramViewScreen();
            } else {
              // Si es Jugador, carga su perfil y va al Calendario
              _loadPlayerProfile(ref, appUser.id);
              return const PlayerCalendarScreen();
            }
          },
        );
      },
    );
  }
}