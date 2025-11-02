// lib/src/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/providers/providers.dart';

final isLoggingOutProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Seguimos "observando" esto para obtener el nombre del coach
    final appUserAsync = ref.watch(currentUserAppUserProvider);
    final theme = Theme.of(context);
    
    final isLoggingOut = ref.watch(isLoggingOutProvider);

    return Scaffold(
      appBar: AppBar(
        // Título actualizado, esta es solo la pantalla del Coach
        title: const Text('Panel de Coach'),
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
            onPressed: isLoggingOut
                ? null 
                : () => _handleLogout(context, ref),
          ),
        ],
      ),
      body: appUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar perfil: $e')),
        data: (appUser) {
          if (appUser == null) {
            // Esto es un estado de error, el AuthWrapper no debería permitirlo
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

          // --- LÓGICA DE ROL ELIMINADA ---
          // Ya no es necesario un 'if (appUser.isCoach)'
          // El AuthWrapper garantiza que solo los coaches lleguen aquí.
          final List<Widget> menuCards =
              _buildCoachMenuCards(context); // Llama a la función específica de coach

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, ${appUser.name}!',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  // Texto estático, ya no necesita condicional
                  'Bienvenido a tu panel de control.',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 32),

                // Opciones principales (solo de Coach)
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
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

  /// Gestiona la lógica de logout (sin cambios)
  void _handleLogout(BuildContext context, WidgetRef ref) async {
    ref.read(isLoggingOutProvider.notifier).state = true;
    try {
      await ref.read(authServiceProvider).logout();
    } catch (e) {
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

  /// --- FUNCIÓN SIMPLIFICADA ---
  /// Ya no necesita 'appUser' como parámetro.
  /// Solo devuelve las tarjetas del Coach.
  List<Widget> _buildCoachMenuCards(BuildContext context) {
    // Definimos las rutas para una navegación limpia
    const String routeEvaluation = '/evaluation';
    const String routeProgram = '/program';
    const String routeUserManagement = '/user_management';
    const String routeUserCreate = '/user_create';
    const String routeLibrary = '/library'; 

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
        icon: Icons.group_add,
        title: 'Jugadores',
        subtitle: 'Administrar equipo',
        route: routeUserManagement,
      ),
      _buildMenuCard(
        context,
        icon: Icons.group_add,
        title: 'Jugadores',
        subtitle: 'Crear jugadores',
        route: routeUserCreate,
      ),
      _buildMenuCard(
        context,
        icon: Icons.video_library,
        title: 'Biblioteca',
        subtitle: 'Ejercicios',
        route: routeLibrary,
      ),
      
    ];
    // --- LÓGICA DE JUGADOR ELIMINADA ---
  }

  /// Widget de tarjeta refactorizado (sin cambios)
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