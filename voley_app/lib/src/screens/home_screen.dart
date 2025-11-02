// lib/src/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/user.dart' as app_user;

final isLoggingOutProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(currentUserAppUserProvider);
    final theme = Theme.of(context);
    
    // Observamos el estado de carga del logout
    final isLoggingOut = ref.watch(isLoggingOutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VolleyPro Trainer'),
        actions: [
          IconButton(
            // Muestra un loader si se está deslogueando
            icon: isLoggingOut
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.onPrimary, // Color de tema
                    ),
                  )
                : const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: isLoggingOut
                ? null // Deshabilita el botón si ya está en proceso
                : () => _handleLogout(context, ref),
          ),
        ],
      ),
      // Manejamos los estados de carga/error del perfil de usuario
      body: appUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (appUser) {
          if (appUser == null) {
            // Esto puede pasar si el usuario está autenticado (en Firebase)
            // pero su documento en Firestore no existe o no tiene rol.
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Error: No se pudo cargar el perfil de usuario.'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      child: const Text('Reintentar Logout'),
                      onPressed: () => _handleLogout(context, ref),
                    )
                  ],
                ),
              ),
            );
          }

          // Obtenemos las tarjetas correctas para el rol del usuario
          final List<Widget> menuCards =
              _buildMenuCardsForRole(context, appUser);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MEJORA: Saludo personalizado
                Text(
                  '¡Hola, ${appUser.name}!',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  appUser.isCoach
                      ? 'Bienvenido a tu panel de control.'
                      : '¿Listo para tu próxima sesión?',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 32),

                // Opciones principales
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    // MEJORA: Muestra las tarjetas adaptativas
                    children: menuCards,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Gestiona la lógica de logout, incluyendo estados de carga y error
  void _handleLogout(BuildContext context, WidgetRef ref) async {
    ref.read(isLoggingOutProvider.notifier).state = true;
    try {
      await ref.read(authServiceProvider).logout();
      // No necesitamos poner el estado en 'false'
      // porque el AuthWrapper nos redirigirá.
    } catch (e) {
      // Si falla, reactivamos el botón
      ref.read(isLoggingOutProvider.notifier).state = false;
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

  /// MEJORA: Construye la lista de tarjetas basada en el rol del usuario
  List<Widget> _buildMenuCardsForRole(
      BuildContext context, app_user.User appUser) {
    // Definimos las rutas para una navegación limpia
    const String routeEvaluation = '/evaluation';
    const String routeProgram = '/program';
    const String routeUserManagement = '/user_management';
    const String routeLibrary = '/excercise_library'; // Ruta de ejemplo

    if (appUser.isCoach) {
      // --- VISTA PARA EL COACH ---
      return [
        _buildMenuCard(
          context,
          icon: Icons.assessment,
          title: 'Evaluaciones',
          subtitle: 'Crear o ver',
          route: routeEvaluation,
        ),
        _buildMenuCard(
          context,
          icon: Icons.list_alt,
          title: 'Programas',
          subtitle: 'Ver y generar',
          route: routeProgram,
        ),
        _buildMenuCard(
          context,
          icon: Icons.group_add, // Icono más descriptivo
          title: 'Jugadores',
          subtitle: 'Administrar equipo',
          route: routeUserManagement,
        ),
        _buildMenuCard(
          context,
          icon: Icons.video_library,
          title: 'Biblioteca',
          subtitle: 'Ejercicios',
          route: routeLibrary,
        ),
      ];
    } else {
      // --- VISTA PARA EL JUGADOR ---
      return [
        _buildMenuCard(
          context,
          icon: Icons.list_alt,
          title: 'Mi Programa',
          subtitle: 'Ver mi rutina',
          route: routeProgram,
        ),
        _buildMenuCard(
          context,
          icon: Icons.account_circle,
          title: 'Mi Perfil',
          subtitle: 'Ver mi evaluación',
          route: routeEvaluation,
        ),
        _buildMenuCard(
          context,
          icon: Icons.bar_chart,
          title: 'Progreso',
          subtitle: 'Mis estadísticas',
          route: '/progress', // Asumiendo una futura ruta
        ),
        _buildMenuCard(
          context,
          icon: Icons.video_library,
          title: 'Biblioteca',
          subtitle: 'Ejercicios',
          route: routeLibrary,
        ),
      ];
    }
  }

  /// MEJORA: Widget de tarjeta refactorizado para usar el TEMA y rutas nombradas
  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}