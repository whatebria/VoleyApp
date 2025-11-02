// lib/src/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 'auth_provider.dart' ya no es necesario aquí si 'currentUserAppUserProvider'
// ya depende de 'authStateProvider' (lo cual es probable).
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/auth/login_screen.dart';
import 'package:voley_app/src/screens/home_screen.dart';
import 'package:voley_app/src/screens/player_calendar_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  // --- El método _loadPlayerProfile() se ha ELIMINADO ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          return const PlayerCalendarScreen();
        }
      },
    );
  }
}