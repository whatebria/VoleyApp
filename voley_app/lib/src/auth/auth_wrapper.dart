import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/auth/login_screen.dart';
import 'package:voley_app/src/screens/home_screen.dart';
import 'package:voley_app/src/screens/player/player_home_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    // El resto de tu lógica no cambia: observa el perfil de Firestore
    final appUserAsync = ref.watch(currentUserAppUserProvider);

    return appUserAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error al cargar perfil de app: $e'))),
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
