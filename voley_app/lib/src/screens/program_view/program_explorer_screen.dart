import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/screens/create_new_program_screen.dart';
// --- AÑADIDO: Import de la nueva pantalla de detalle ---
import 'package:voley_app/src/screens/program_view/program_detail_screen.dart';

// --- CAMBIO: Nombre de la clase ---
class ProgramExplorerScreen extends ConsumerStatefulWidget {
  const ProgramExplorerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProgramExplorerScreen> createState() =>
      _ProgramExplorerScreenState();
}

class _ProgramExplorerScreenState extends ConsumerState<ProgramExplorerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayerSelection();
    });
  }

  void _initializePlayerSelection() {
    if (!mounted) return;

    final currentUser = ref.read(currentUserAppUserProvider).valueOrNull;
    if (currentUser == null) {
      return;
    }

    final selectedPlayerCombo = ref.read(explorerSelectedPlayerProvider);

    if (selectedPlayerCombo != null) {
      return;
    }

    if (currentUser.isCoach) {
      final playersAsync = ref.read(coachPlayersWithProfilesProvider);

      playersAsync.whenData((players) {
        if (players.isNotEmpty) {
          ref.read(explorerSelectedPlayerProvider.notifier).state =
              players.first;
        }
      });
    } else if (currentUser.isPlayer) {
      final playerProfile = ref.read(playerProfileProvider).valueOrNull;

      if (playerProfile != null) {
        final playerCombo = PlayerWithProfile(currentUser, playerProfile);
        ref.read(explorerSelectedPlayerProvider.notifier).state = playerCombo;
      }
    }
  }

  void _runManualEditor(BuildContext context, PlayerProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNewProgramScreen(profile: profile),
      ),
    );
  }

  // --- WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Program>>>(explorerProgramsProvider, (_, __) {
    });

    final currentUser = ref.watch(currentUserAppUserProvider).valueOrNull;
    final selectedPlayerCombo = ref.watch(explorerSelectedPlayerProvider);
    final selectedProfile = ref.watch(selectedPlayerProfileProvider);
    final coachPlayersAsync = ref.watch(coachPlayersWithProfilesProvider);
    final programsAsync = ref.watch(explorerProgramsProvider);

    return Scaffold(
      body: selectedPlayerCombo == null
          ? coachPlayersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (players) {
                if (players.isEmpty && currentUser?.isCoach == true) {
                  return const Center(
                    child: Text('No tienes jugadores asignados aún.'),
                  );
                }

                if (players.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (ref.read(explorerSelectedPlayerProvider) == null) {
                      ref.read(explorerSelectedPlayerProvider.notifier).state =
                          players.first;
                    }
                  });
                }

                return const Center(child: CircularProgressIndicator());
              },
            )
          // --- CAMBIO: El body ahora llama a _buildProgramList ---
          : programsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (programs) {
                if (programs.isEmpty) {
                  return Center(
                    child: Text(
                      'Este jugador no tiene programas.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  );
                }
                return _buildProgramList(context, programs, selectedProfile);
              },
            ),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Crear Programa Manual',
        child: const Icon(Icons.edit),
        onPressed: () {
          final profile = selectedProfile;
          if (profile != null) {
            _runManualEditor(context, profile);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Selecciona un jugador con un perfil de evaluación.',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // --- CAMBIO: _buildProgramSelector y _buildProgramDetails eliminados ---

  // --- AÑADIDO: Nueva función para construir la lista de Programas ---
  Widget _buildProgramList(
    BuildContext context,
    List<Program> programs,
    PlayerProfile? profile,
  ) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        final totalWeeks = program.mesocycles.fold<int>(
          0,
          (sum, meso) => sum + meso.weeks,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          color: theme.colorScheme.surface, // grisPro
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary, // voltNeon
              foregroundColor: theme.colorScheme.onPrimary, // negroEnfocado
              child: const Icon(Icons.list_alt, size: 20),
            ),
            title: Text(
              program.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${program.mesocycles.length} bloques • $totalWeeks semanas totales\n'
              'Inicia: ${DateFormat('dd/MM/yy').format(program.startDate)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            isThreeLine: true,
            onTap: () {
              if (profile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo cargar el perfil del jugador.'),
                  ),
                );
                return;
              }
              // Navega a la nueva pantalla de detalle
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProgramDetailScreen(
                    program: program,
                    profile: profile, // Pasa el perfil
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- _showWeekDetails y _buildMicrocycleList eliminados ---
  // Esta lógica ahora vive en las nuevas pantallas.
}
