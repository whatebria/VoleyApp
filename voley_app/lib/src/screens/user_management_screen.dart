// lib/src/screens/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/providers/providers.dart'; 
import 'package:voley_app/src/screens/create_player_screen.dart';


class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  /// --- MEJORA DE UX: Muestra las opciones del jugador ---
  void _showPlayerOptions(
      BuildContext context, WidgetRef ref, app_user.User player) {
    final theme = Theme.of(context);
    ref.read(explorerSelectedPlayerProvider.notifier).state = player;

    // 2. MUESTRA EL MENÚ
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              // --- Opción 1: Ir a Evaluación/Perfil ---
              ListTile(
                leading:
                    Icon(Icons.assessment, color: theme.colorScheme.primary), // Volt
                title: const Text('Ver/Editar Evaluación'),
                subtitle: const Text('Perfil, posición, tests, lesiones...'),
                onTap: () {
                  Navigator.pop(ctx); // Cierra el menú
                  Navigator.pushNamed(context, '/evaluation');
                },
              ),
              // --- Opción 2: Ir a Programas ---
              ListTile(
                leading:
                    Icon(Icons.list_alt, color: theme.colorScheme.secondary), // Azul Pro
                title: const Text('Ver/Gestionar Programas'),
                subtitle: const Text('Calendario, mesociclos, sesiones...'),
                onTap: () {
                  Navigator.pop(ctx); // Cierra el menú
                  Navigator.pushNamed(context, '/program');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coachUserAsync = ref.watch(currentUserAppUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Jugadores'),
      ),
      body: coachUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar usuario: $e')),
        data: (coachUser) {
          // Manejo de permisos
          if (coachUser == null || !coachUser.isCoach) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Esta funcionalidad solo está disponible para coaches.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          // El body es SOLO la lista de jugadores
          return _buildPlayerList(theme, ref);
        },
      ),
      // --- MEJORA DE UX: FAB para la acción de "Crear" ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navega a la nueva pantalla de formulario
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePlayerScreen()),
          );
        },
        child: const Icon(Icons.person_add),
        tooltip: 'Crear Jugador',
      ),
    );
  }

  /// Widget separado para la lista de jugadores
  Widget _buildPlayerList(ThemeData theme, WidgetRef ref) {
    // Observa el nuevo provider que tiene jugadores + perfiles
    final playersWithProfilesAsync = ref.watch(coachPlayersWithProfilesProvider);

    return playersWithProfilesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error al cargar jugadores: $e')),
      data: (playersWithProfiles) {
        // --- MEJORA DE UX: RefreshIndicator en la lista ---
        return RefreshIndicator(
          onRefresh: () async {
            // Invalida ambos providers para forzar la recarga
            ref.invalidate(coachPlayersProvider);
            ref.invalidate(coachPlayersWithProfilesProvider);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text(
                  'Jugadores Vinculados (${playersWithProfiles.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (playersWithProfiles.isEmpty)
                Expanded( // Para que el texto se centre en el espacio restante
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No tienes jugadores vinculados. Presiona el botón "+" para crear uno.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: theme.textTheme.bodySmall?.color),
                      ),
                    ),
                  ),
                )
              else
                // --- MEJORA DE RENDIMIENTO: ListView.builder ---
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80.0), // Espacio para el FAB
                    itemCount: playersWithProfiles.length,
                    itemBuilder: (context, index) {
                      final item = playersWithProfiles[index];
                      final player = item.player;
                      final profile = item.profile;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 6.0),
                        elevation: 0,
                        color:
                            theme.colorScheme.surfaceVariant.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary, // Volt
                            child: Text(
                              player.name[0].toUpperCase(),
                              style: TextStyle(
                                  color: theme.colorScheme.onPrimary), // Texto oscuro
                            ),
                          ),
                          title: Text(
                            player.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            // Muestra info clave: Posición (si existe) o email
                            profile?.position ?? player.email,
                            style: TextStyle(
                                color: theme.textTheme.bodySmall?.color),
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // --- ¡AQUÍ ESTÁ LA MEJORA DE UX! ---
                            // Al tocar un jugador, muestra el menú de opciones
                            _showPlayerOptions(context, ref, player);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}