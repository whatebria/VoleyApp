// lib/src/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/auth/auth_provider.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/utils/exercise_seeder.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(currentUserAppUserProvider);
    final isLoggingOut = ref.watch(isLoggingOutProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: appUserAsync.when(
          data: (appUser) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¡Hola, ${appUser?.name ?? 'Coach'}!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Bienvenido a tu panel de control.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ],
          ),
          loading: () => const Text('Panel de Coach'),
          error: (e, s) => const Text('Panel de Coach'),
        ),
        toolbarHeight: 70,
        actions: [
          IconButton(
            icon: isLoggingOut
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: isLoggingOut ? null : () => _handleLogout(context, ref),
          ),
          ElevatedButton(
            onPressed: () async {
              await seedMobilityWarmupCooldownExercises();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seeder ejecutado correctamente')),
              );
            },
            child: const Text('Cargar ejercicios'),
          ),
        ],
      ),
      // --- BODY MODIFICADO: Ahora es un ListView ---
      body: appUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (appUser) {
          if (appUser == null) {
            return Center(child: Text('Error al cargar el perfil de usuario.'));
          }

          // La lista de tarjetas
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: _buildCoachMenuCards(context),
          );
        },
      ),
    );
  }

  /// Gestiona la lógica de logout (sin cambios)
  void _handleLogout(BuildContext context, WidgetRef ref) async {
    ref.read(isLoggingOutProvider.notifier).state = true;
    try {
      await ref.read(authServiceProvider).logout();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// --- FUNCIÓN MODIFICADA: Solo 2 tarjetas ---
  List<Widget> _buildCoachMenuCards(BuildContext context) {
    return [
      _buildMenuCard(
        context,
        icon: Icons.group,
        title: 'Mis Atletas',
        subtitle: 'Administrar, crear y evaluar',
        // (Asegúrate de que '/user_management' exista en main.dart y lleve
        // a una pantalla que muestre la lista de jugadores)
        route: '/user_management',
      ),
    ];
  }

  /// --- WIDGET DE TARJETA REDISEÑADO (Lista Vertical) ---
  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16.0), // Espacio entre tarjetas
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icono a la izquierda
              Icon(icon, size: 48, color: theme.colorScheme.primary),
              const SizedBox(width: 20),
              // Textos a la derecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              // Icono de flecha
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
