import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/auth/login_screen.dart';
import 'package:voley_app/src/screens/home_screen.dart';
import 'package:voley_app/src/screens/player/player_home_screen.dart';
import 'package:voley_app/src/screens/player/player_onboarding_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(currentUserAppUserProvider);

    return appUserAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error al cargar perfil de app: $e'))),
      data: (appUser) {
        if (appUser == null) return const LoginScreen();

        if (appUser.isCoach) {
          return const HomeScreen();
        } else {
          // 👇 Cargar el PlayerProfile del jugador
          final profileAsync = ref.watch(playerProfileProvider);

          return profileAsync.when(
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (e, s) => Scaffold(body: Center(child: Text('Error al cargar PlayerProfile: $e'))),
            data: (profile) {
              // Si no hay PlayerProfile -> ir al Onboarding
              if (profile == null) {
                return const PlayerOnboardingScreen(); // <- crea esta pantalla
              }
              // Si ya hay, ir al home normal
              return const PlayerHomeScreen();
            },
          );
        }
      },
    );
  }
}
