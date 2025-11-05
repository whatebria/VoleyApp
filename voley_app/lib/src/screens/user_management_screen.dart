import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/screens/coach_player_profile.dart'; 
import 'package:voley_app/src/screens/create_player_screen.dart';
// --- CAMBIO ---

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  /// --- CAMBIO ---
  /// La función _showPlayerOptions ha sido eliminada, ya que ahora
  /// navegaremos directamente.

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
          // --- CAMBIO: Pasa 'context' ---
          return _buildPlayerList(context, theme, ref);
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

  // --- AÑADIDO: Widget para la tarjeta de invitación ---
  Widget _buildInviteCard(BuildContext context, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 1,
      // Usamos el color secundario para que destaque
      color: theme.colorScheme.secondary.withOpacity(0.1), 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Borde con el color secundario
        side: BorderSide(color: theme.colorScheme.secondary) 
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(Icons.person_add_alt_1, color: theme.colorScheme.secondary),
        title: Text(
          'Invitar Atleta',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary
          ),
        ),
        subtitle: Text('Generar código de invitación'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Asumiendo que la ruta '/permiso' está definida en main.dart
          // y lleva a PermissionManagementScreen
          Navigator.pushNamed(context, '/permiso');
        },
      ),
    );
  }

  /// Widget separado para la lista de jugadores
  /// --- CAMBIO: Acepta 'context' ---
  Widget _buildPlayerList(BuildContext context, ThemeData theme, WidgetRef ref) {
    // Observa el nuevo provider que tiene jugadores + perfiles
    final playersWithProfilesAsync = ref.watch(coachPlayersWithProfilesProvider);

    return playersWithProfilesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error al cargar jugadores: $e')),
      data: (playersWithProfiles) {
        
        // --- MEJORA DE UX: RefreshIndicator en la lista ---
        return RefreshIndicator(
          // Invalida el StreamProvider principal para forzar una nueva lectura
          onRefresh: () async {
            ref.invalidate(coachPlayersProvider); 
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- AÑADIDO: Tarjeta de invitación ---
              _buildInviteCard(context, theme),
              
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
                      // [CORRECCIÓN]: El item es PlayerWithProfile
                      final playerCombo = playersWithProfiles[index];
                      final player = playerCombo.player;
                      final profile = playerCombo.profile;

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
                          
                          // --- CAMBIO ---
                          // Lógica de navegación actualizada
                          onTap: () {
                            final profile = playerCombo.profile;

                            // 1. Asignamos el jugador seleccionado para que
                            // las pantallas de destino sepan quién es.
                            ref.read(explorerSelectedPlayerProvider.notifier).state = playerCombo;

                            if (profile != null) {
                              // 2a. Si SÍ hay perfil, vamos a la pantalla de "Ver Perfil"
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CoachPlayerProfile(profile: profile),
                                ),
                              );
                            } else {
                              // 2b. Si NO hay perfil, vamos a la pantalla de "Evaluación"
                              // (que maneja la creación del perfil).
                              Navigator.pushNamed(context, '/evaluation');
                            }
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