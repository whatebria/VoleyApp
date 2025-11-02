// lib/screens/program_view_screen.dart (CORREGIDO)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/microcicle.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/screens/program_editor_screen.dart';

// 1. Convertido a ConsumerStatefulWidget
class ProgramViewScreen extends ConsumerStatefulWidget {
  const ProgramViewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProgramViewScreen> createState() => _ProgramViewScreenState();
}

class _ProgramViewScreenState extends ConsumerState<ProgramViewScreen> {
  // --- ELIMINAMOS _initialPlayerSetup (ver build para la corrección) ---

  @override
  void initState() {
    super.initState();
    // 1. Ya no se necesita _initialPlayerSetup. La lógica de inicialización
    //    es reactiva y se gestiona en el build/listen.
  }

  // --- MÉTODOS DE ACCIÓN (Sin cambios funcionales, usan el estado de carga) ---

  void _showGenerationChoice(BuildContext context, PlayerProfile profile) {
    // ... (Tu implementación de showModalBottomSheet)
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Generar Programa Automático (IA)'),
                subtitle: const Text('Crear un programa basado en el perfil.'),
                onTap: () {
                  Navigator.pop(context);
                  _runAutomaticGenerator(context, profile);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: theme.colorScheme.secondary),
                title: const Text('Crear Programa Manual'),
                subtitle: const Text('Construir el programa paso a paso.'),
                onTap: () {
                  Navigator.pop(context);
                  _runManualEditor(context, profile);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _runAutomaticGenerator(
    BuildContext context,
    PlayerProfile profile,
  ) async {
    // 1. Pone el estado de carga en 'true'
    ref.read(isGeneratingProgramProvider.notifier).state = true;

    try {
      // 2. Llama a la acción
      await ref.read(programGeneratorAction)(profile);

      // ¡Éxito!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Programa automático generado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // 3. Quita el estado de carga
      if (mounted) {
        ref.read(isGeneratingProgramProvider.notifier).state = false;
      }
    }
  }

  void _runManualEditor(BuildContext context, PlayerProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramEditorScreen(profile: profile),
      ),
    );
  }

  // --- WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    // 1. [CORRECCIÓN] Lógica de Sincronización de Programa
    // Se mantiene esta lógica para asegurar que siempre haya un programa seleccionado
    // cuando la lista se actualiza, o que se limpie si la lista está vacía.
    ref.listen<AsyncValue<List<Program>>>(explorerProgramsProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) {
        final programs = next.value!;
        final selectedProgramNotifier = ref.read(
          explorerSelectedProgramProvider.notifier,
        );

        if (programs.isEmpty) {
          selectedProgramNotifier.state = null;
        } else {
          final currentProgram = selectedProgramNotifier.state;
          // [CORRECCIÓN] Usamos la identidad del objeto para la comparación
          if (currentProgram == null ||
              programs.where((p) => p.id == currentProgram.id).isEmpty) {
            selectedProgramNotifier.state = programs.first;
          }
        }
      }
    });

    // 2. Observa todos los providers.
    final currentUserAsync = ref.watch(currentUserAppUserProvider);
    // [CORRECCIÓN] Usamos el provider que agrupa Jugador + Perfil
    final playersWithProfilesAsync = ref.watch(
      coachPlayersWithProfilesProvider,
    );

    // [CORRECCIÓN] El explorador selecciona un PlayerWithProfile
    final selectedPlayerCombo = ref.watch(explorerSelectedPlayerProvider);

    final selectedProfileAsync = ref.watch(selectedPlayerProfileProvider);
    final programsAsync = ref.watch(explorerProgramsProvider);
    final selectedProgram = ref.watch(explorerSelectedProgramProvider);
    final isGenerating = ref.watch(isGeneratingProgramProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Explorador de Programas')),
      body: Stack(
        children: [
          currentUserAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error al cargar usuario: $e')),
            data: (currentUser) {
              if (currentUser == null) {
                return const Center(child: Text('Usuario no encontrado.'));
              }

              // 3. [CORRECCIÓN] LÓGICA DE INICIALIZACIÓN DECLARATIVA
              // Solo corre si es Coach Y no hay un jugador seleccionado.
              if (currentUser.isCoach && selectedPlayerCombo == null) {
                // Si aún no hay jugadores, mostramos un cargador (que PlayersWithProfilesAsync ya hace)
                // Si la lista ya está cargada y no hay selección, intentamos seleccionar el primero.
                playersWithProfilesAsync.whenData((players) {
                  if (players.isNotEmpty) {
                    // [CORRECCIÓN CRÍTICA] Asignamos el objeto PlayerWithProfile
                    ref.read(explorerSelectedPlayerProvider.notifier).state =
                        players.first;
                  }
                });
              } else if (currentUser.isPlayer && selectedPlayerCombo == null) {
                // Si es Jugador y no está seleccionado, forzamos su selección.
                // Necesitamos el perfil para crear el combo PlayerWithProfile.
                final playerProfile = ref
                    .watch(playerProfileProvider)
                    .valueOrNull;

                if (playerProfile != null) {
                  // [CORRECCIÓN CRÍTICA] Creamos el objeto PlayerWithProfile para asignarlo
                  final playerCombo = PlayerWithProfile(
                    currentUser,
                    playerProfile,
                  );
                  ref.read(explorerSelectedPlayerProvider.notifier).state =
                      playerCombo;
                }
              }
              // --- FIN LÓGICA DE INICIALIZACIÓN ---

              return Column(
                children: [
                  // --- Dropdown de Jugadores (Solo para Coaches) ---
                  if (currentUser.isCoach)
                    playersWithProfilesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (e, s) => Center(child: Text('Error: $e')),
                      // [CORRECCIÓN] Usamos playersWithProfiles
                      data: (playersCombos) {
                        if (playersCombos.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text('No tienes jugadores vinculados.'),
                            ),
                          );
                        }
                        // [CORRECCIÓN] Pasamos el combo y el combo seleccionado
                        return _buildPlayerSelector(
                          ref,
                          playersCombos,
                          selectedPlayerCombo,
                        );
                      },
                    ),

                  // --- Dropdown de Programas ---
                  programsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: LinearProgressIndicator()),
                    ),
                    error: (e, s) => Center(child: Text('Error: $e')),
                    data: (programs) {
                      return _buildProgramSelector(
                        ref,
                        programs,
                        selectedProgram,
                      );
                    },
                  ),

                  // --- Detalles del Programa ---
                  Expanded(
                    child: programsAsync.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : selectedProgram == null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                programsAsync.valueOrNull?.isEmpty ?? true
                                    ? 'Este jugador no tiene programas.'
                                    : 'Selecciona un programa para ver.',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : _buildProgramDetails(selectedProgram),
                  ),
                ],
              );
            },
          ),

          // --- Overlay de Carga No-Modal ---
          if (isGenerating)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Generando programa (IA)...',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Crear Programa',
        child: const Icon(Icons.add),
        onPressed: isGenerating
            ? null
            : () {
                // [CORRECCIÓN CRÍTICA 1]: Usamos el valor del AsyncValue que ya observamos
                final profile = selectedProfileAsync;

                // [CORRECCIÓN CRÍTICA 2]: Aseguramos que el perfil sea PlayerProfile
                if (profile != null) {
                  // profile aquí es de tipo PlayerProfile, que es lo que espera la función.
                  _showGenerationChoice(context, profile);
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

  // --- WIDGETS AUXILIARES (Con Tipos Corregidos) ---

  // [CORRECCIÓN] Acepta List<PlayerWithProfile> y PlayerWithProfile?
  Widget _buildPlayerSelector(
    WidgetRef ref,
    List<PlayerWithProfile> playersCombos,
    PlayerWithProfile? selectedPlayerCombo,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      // [CORRECCIÓN] Dropdown para PlayerWithProfile
      child: DropdownButtonFormField<PlayerWithProfile>(
        value: selectedPlayerCombo,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Seleccionar Jugador',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
        items: playersCombos.map((combo) {
          return DropdownMenuItem<PlayerWithProfile>(
            value: combo,
            child: Text(combo.player.name, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (PlayerWithProfile? newValue) {
          // [CORRECCIÓN CRÍTICA] Asignamos el objeto PlayerWithProfile completo
          ref.read(explorerSelectedPlayerProvider.notifier).state = newValue;
          ref.read(explorerSelectedProgramProvider.notifier).state = null;
        },
      ),
    );
  }

  Widget _buildProgramSelector(
    WidgetRef ref,
    List<Program> programs,
    Program? selectedProgram,
  ) {
    final theme = Theme.of(context);

    // El listener en initState se encarga de que 'selectedProgram'
    // sea null si 'programs' está vacío.
    if (programs.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        // --- TEMA ---
        color: theme.colorScheme.secondaryContainer.withOpacity(0.2),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Este jugador no tiene programas.',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: theme.colorScheme.secondaryContainer.withOpacity(0.2),
      child: DropdownButtonFormField<Program>(
        value: selectedProgram,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Seleccionar Programa',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
        items: programs.map((program) {
          return DropdownMenuItem<Program>(
            value: program,
            child: Text(
              '${DateFormat('dd/MM/yy').format(program.startDate)} - ${DateFormat('dd/MM/yy').format(program.endDate)} ',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (Program? newValue) {
          ref.read(explorerSelectedProgramProvider.notifier).state = newValue;
        },
      ),
    );
  }

  Widget _buildProgramDetails(Program program) {
    // ... (Tu implementación de _buildProgramDetails)
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: program.mesocycles.length,
      itemBuilder: (context, i) {
        final m = program.mesocycles[i];
        return Card(
          color: theme.colorScheme.surface,
          surfaceTintColor: theme.colorScheme.surface,
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ExpansionTile(
            title: Text(
              m.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            subtitle: Text('${m.weeks} semanas — Enfoque: ${m.focus}'),
            children: m.microcycles.map((mc) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondary,
                  child: Text(
                    '${mc.weekNumber}',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text('Semana ${mc.weekNumber}'),
                subtitle: Text('${mc.sessions.length} sesiones'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showWeekDetails(context, mc);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showWeekDetails(BuildContext context, Microcycle mc) {
    // ... (Tu implementación de _showWeekDetails)
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(
                      0.3,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Semana ${mc.weekNumber}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: mc.sessions.length,
                    itemBuilder: (context, index) {
                      final s = mc.sessions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: theme.colorScheme.surfaceVariant.withOpacity(
                          0.3,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.fitness_center,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s.day,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Objetivo: ${s.objective}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Carga: ${s.load}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const Divider(height: 16),
                              Text(
                                'Ejercicios:',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...s.exercises.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${e.name} (${e.sets}x${e.reps} @ ${e.intensity})',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
