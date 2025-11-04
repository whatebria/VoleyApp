import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/microcicle.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/screens/manual_program_create_screen.dart';
// Asumo que PlayerWithProfile se define en providers.dart o un modelo importado por él
// (basado en la lógica de _initializePlayerSelection)

class ProgramViewScreen extends ConsumerStatefulWidget {
  const ProgramViewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProgramViewScreen> createState() => _ProgramViewScreenState();
}

class _ProgramViewScreenState extends ConsumerState<ProgramViewScreen> {

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
          ref.read(explorerSelectedPlayerProvider.notifier).state = players.first;
        }
      });

    } else if (currentUser.isPlayer) {
      final playerProfile = ref.read(playerProfileProvider).valueOrNull;

      if (playerProfile != null) {
        final playerCombo = PlayerWithProfile(
          currentUser,
          playerProfile,
        );
        ref.read(explorerSelectedPlayerProvider.notifier).state = playerCombo;
      }
    }
  }

  // --- CAMBIO ---
  // La función _showGenerationChoice y _runAutomaticGenerator han sido eliminadas
  // ya que el FAB ahora solo tiene una acción.

  void _runManualEditor(BuildContext context, PlayerProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualProgramCreateScreen(profile: profile),
      ),
    );
  }

  // --- WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
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
          if (currentProgram == null ||
              programs.where((p) => p.id == currentProgram.id).isEmpty) {
            selectedProgramNotifier.state = programs.first;
          }
        }
      }
    });

    final selectedPlayerCombo = ref.watch(explorerSelectedPlayerProvider);
    
    // Observamos el perfil, que es un PlayerProfile? (no un AsyncValue)
    final selectedProfile = ref.watch(selectedPlayerProfileProvider);
    
    final programsAsync = ref.watch(explorerProgramsProvider);
    final selectedProgram = ref.watch(explorerSelectedProgramProvider);
    
    // --- CAMBIO ---
    // 'isGenerating' y el 'Stack' han sido eliminados.
    
    return Scaffold(
      appBar: AppBar(title: const Text('Explorador de Programas')),
      body: selectedPlayerCombo == null
            // Muestra un cargador mientras 'initState' y '_initializePlayerSelection'
            // seleccionan al jugador inicial.
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
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
              ),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Crear Programa Manual',
        child: const Icon(Icons.edit), // Icono cambiado a 'edit'
        // --- CAMBIO ---
        // 'onPressed' ahora llama directamente a _runManualEditor
        onPressed: () {
                // Usamos el perfil (PlayerProfile?) que ya observamos
                final profile = selectedProfile;

                if (profile != null) {
                  // 'profile' es un PlayerProfile
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

  Widget _buildProgramSelector(
    WidgetRef ref,
    List<Program> programs,
    Program? selectedProgram,
  ) {
    final theme = Theme.of(context);
    
    if (programs.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          // Usamos el estilo del tema
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

  // --- CAMBIO: Diseño de la lista de Mesociclos ---
  Widget _buildProgramDetails(Program program) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: program.mesocycles.length,
      itemBuilder: (context, i) {
        final m = program.mesocycles[i];
        // Reemplazamos Card por un ExpansionTile estilizado
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ExpansionTile(
            // Estilo Moderno
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: theme.colorScheme.surface, // grisPro
            collapsedBackgroundColor: theme.colorScheme.surface, // grisPro
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            clipBehavior: Clip.antiAlias,
            // fin de Estilo
            
            title: Text(
              m.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary, // voltNeon
                fontSize: 18
              ),
            ),
            subtitle: Text('${m.weeks} semanas — Enfoque: ${m.focus}'),
            children: m.microcycles.map((mc) {
              // ListTile estilizado para las semanas
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ListTile(
                  tileColor: theme.colorScheme.background, // negroEnfocado
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondary, // azulPro
                    foregroundColor: theme.colorScheme.onSecondary, // blancoNeutro
                    child: Text(
                      '${mc.weekNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('Semana ${mc.weekNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${mc.sessions.length} sesiones'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showWeekDetails(context, mc);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // --- CAMBIO: Diseño del Modal de Sesiones ---
  void _showWeekDetails(BuildContext context, Microcycle mc) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface, // grisPro
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
                // Header del Modal
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: theme.colorScheme.primary, // voltNeon
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: mc.sessions.length,
                    itemBuilder: (context, index) {
                      final s = mc.sessions[index];
                      // Card de Sesión Estilizada
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: theme.colorScheme.background, // negroEnfocado
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.surface, // Borde grisPro
                            )
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
                                    color: theme.colorScheme.secondary, // azulPro
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
                                  color: theme.colorScheme.onSurface.withOpacity(0.7)
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Carga: ${s.load}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const Divider(height: 24),
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
                                          color: theme.colorScheme.primary, // voltNeon
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${e.name} (${e.sets}x${e.reps} @ ${e.intensity})',
                                          style: theme.textTheme.bodyMedium,
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

