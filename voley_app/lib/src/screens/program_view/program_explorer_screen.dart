import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/program/evaluation_with_profile.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/models/program/program_template.dart';
import 'package:voley_app/src/screens/coach_evaluations_screen.dart';
import 'package:voley_app/src/screens/create_new_program_screen.dart';
import 'package:voley_app/src/screens/program_view/program_detail_screen.dart';

// --- CAMBIO: Nombre de la clase ---
class ProgramExplorerScreen extends ConsumerStatefulWidget {
  const ProgramExplorerScreen({super.key, this.showAllPlayers = false});

  final bool showAllPlayers;

  @override
  ConsumerState<ProgramExplorerScreen> createState() =>
      _ProgramExplorerScreenState();
}

class _ProgramExplorerScreenState extends ConsumerState<ProgramExplorerScreen> {
  final Uuid _uuid = const Uuid();
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

  Future<void> _showCreateOptions(
    BuildContext context,
    PlayerProfile? profile,
  ) async {
    final action = await showModalBottomSheet<_CreateProgramAction>(
      context: context,
      builder: (_) => const _CreateProgramActionSheet(),
    );

    switch (action) {
      case _CreateProgramAction.manual:
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
        break;
      case _CreateProgramAction.template:
        await _pickTemplateAndCreateProgram(context, profile);
        break;
      default:
        break;
    }
  }

  Future<void> _pickTemplateAndCreateProgram(
    BuildContext context,
    PlayerProfile? profile,
  ) async {
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un jugador con un perfil de evaluación.'),
        ),
      );
      return;
    }

    final template = await showModalBottomSheet<ProgramTemplate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ProgramTemplatePickerSheet(),
    );

    if (template == null) return;

    final programFromTemplate = template.program.copyWith(
      id: _uuid.v4(),
      startDate: DateTime.now(),
      title: template.program.title.isNotEmpty
          ? template.program.title
          : template.name,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNewProgramScreen(
          profile: profile,
          template: programFromTemplate,
        ),
      ),
    );
  }


  // --- WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Program>>>(explorerProgramsProvider, (_, __) {});

    final currentUser = ref.watch(currentUserAppUserProvider).valueOrNull;
    final isAllPlayers = widget.showAllPlayers;
    final selectedPlayerCombo = ref.watch(explorerSelectedPlayerProvider);
    final selectedProfile = ref.watch(selectedPlayerProfileProvider);
    final coachPlayersAsync = ref.watch(coachPlayersWithProfilesProvider);
    final programsAsync = ref.watch(explorerProgramsProvider);

    if (isAllPlayers) {
      final programsAsync = ref.watch(coachAllProgramsProvider);

      return Scaffold(
        
        body: programsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
          data: (programs) {
            if (programs.isEmpty) {
              return const Center(
                child: Text('Aún no hay programas para tus jugadores.'),
              );
            }

            return _buildAllProgramsList(context, programs);
          },
        ),
        floatingActionButton: _buildFab(context, selectedProfile),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text('Explorador de Programas'),
        actions: [
          if (!widget.showAllPlayers)
            IconButton(
              tooltip: 'Evaluaciones del jugador',
              icon: const Icon(Icons.assessment_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CoachEvaluationsScreen(
                      showAppBar: false,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
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

      floatingActionButton: _buildFab(context, selectedProfile),
    );
  }

  Widget _buildFab(BuildContext context, PlayerProfile? selectedProfile) {
    return FloatingActionButton(
      heroTag: 'programExplorerManualFab',
      tooltip: 'Crear Programa',
      child: const Icon(Icons.edit),
      onPressed: () => _showCreateOptions(context, selectedProfile),
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

  Widget _buildAllProgramsList(
    BuildContext context,
    List<ProgramWithOwner> programs,
  ) {
    final sortedPrograms = [...programs]
      ..sort((a, b) => b.program.startDate.compareTo(a.program.startDate));
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedPrograms.length,
      itemBuilder: (context, index) {
        final item = sortedPrograms[index];
        final program = item.program;
        final totalWeeks = program.mesocycles.fold<int>(
          0,
          (sum, meso) => sum + meso.weeks,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          color: theme.colorScheme.surface,
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
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.list_alt, size: 20),
            ),
            title: Text(
              program.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.owner.name} • ${program.mesocycles.length} bloques • $totalWeeks semanas\n'
              'Inicia: ${DateFormat('dd/MM/yy').format(program.startDate)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            isThreeLine: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProgramDetailScreen(
                    program: program,
                    profile: item.owner,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
enum _CreateProgramAction { manual, template }

class _CreateProgramActionSheet extends StatelessWidget {
  const _CreateProgramActionSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit, color: theme.colorScheme.primary),
            title: const Text('Crear desde cero'),
            subtitle: const Text('Arma un programa manualmente'),
            onTap: () => Navigator.pop(context, _CreateProgramAction.manual),
          ),
          ListTile(
            leading: Icon(Icons.view_module, color: theme.colorScheme.secondary),
            title: const Text('Usar plantilla'),
            subtitle: const Text('Parte de un diseño guardado'),
            onTap: () => Navigator.pop(context, _CreateProgramAction.template),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ProgramTemplatePickerSheet extends ConsumerWidget {
  const _ProgramTemplatePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(programTemplatesProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: templatesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Error al cargar plantillas: $e'),
          ),
          data: (templates) {
            if (templates.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.info_outline, size: 32),
                    SizedBox(height: 12),
                    Text(
                      'Aún no tienes plantillas guardadas. Guarda tu siguiente programa como plantilla para reutilizarlo.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              itemCount: templates.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final template = templates[index];
                return ListTile(
                  leading: Icon(
                    Icons.view_module,
                    color: theme.colorScheme.primary.withOpacity(0.8),
                  ),
                  title: Text(template.name),
                  subtitle: Text(
                    template.description.isEmpty
                        ? 'Sin descripción'
                        : template.description,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, template),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
