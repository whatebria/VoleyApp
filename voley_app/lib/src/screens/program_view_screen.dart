import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/microcicle.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/screens/create_new_program_screen.dart';
// Asumo que PlayerWithProfile se define en providers.dart o un modelo importado por él
// (basado en la lógica de _initializePlayerSelection)

class ProgramViewScreen extends ConsumerStatefulWidget {
  const ProgramViewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProgramViewScreen> createState() => _ProgramViewScreenState();
}

// --- CAMBIO ---
// No se necesita TickerProviderStateMixin si usamos DefaultTabController
// de forma inteligente.
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
    final selectedProfile = ref.watch(selectedPlayerProfileProvider);
    final programsAsync = ref.watch(explorerProgramsProvider);
    final selectedProgram = ref.watch(explorerSelectedProgramProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Explorador de Programas')),
      body: selectedPlayerCombo == null
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
                      // --- CAMBIO: De Dropdown a Chips Horizontales ---
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
                            // --- CAMBIO: De ExpansionTile a TabBar ---
                            : _buildProgramDetails(selectedProgram),
                  ),
                ],
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

  // --- CAMBIO: Selector de Programa rediseñado a Chips ---
  Widget _buildProgramSelector(
    WidgetRef ref,
    List<Program> programs,
    Program? selectedProgram,
  ) {
    final theme = Theme.of(context);

    if (programs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Text(
          'Este jugador no tiene programas.',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
      );
    }

    // Un scroll horizontal de Chips
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: theme.colorScheme.surface.withOpacity(0.5), // grisPro transparente
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: programs.map((program) {
            final isSelected = selectedProgram?.id == program.id;
            final label = '${DateFormat('dd/MM/yy').format(program.startDate)} - ${DateFormat('dd/MM/yy').format(program.endDate)}';
            
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(explorerSelectedProgramProvider.notifier).state = program;
                  }
                },
                // --- Estilo del Tema ---
                selectedColor: theme.colorScheme.primary, // voltNeon
                backgroundColor: theme.colorScheme.surface, // grisPro
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface, // Borde voltNeon
                  )
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- CAMBIO: Diseño de la lista de Mesociclos a TabBar ---
  Widget _buildProgramDetails(Program program) {
    final theme = Theme.of(context);

    if (program.mesocycles.isEmpty) {
      return const Center(
        child: Text(
          'Este programa aún no tiene mesociclos.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    // --- CAMBIO: Usamos DefaultTabController ---
    // La 'key' asegura que el controlador se reinicie si cambiamos de programa
    return DefaultTabController(
      key: ValueKey(program.id),
      length: program.mesocycles.length,
      child: Column(
        children: [
          // 1. EL PANORAMA (Pestañas de Mesociclos)
          Container(
            color: theme.colorScheme.surface, // grisPro
            child: TabBar(
              isScrollable: true,
              indicatorColor: theme.colorScheme.primary, // voltNeon
              labelColor: theme.colorScheme.primary, // voltNeon
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
              tabs: program.mesocycles.map((m) {
                return Tab(
                  child: Text(
                    m.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // 2. EL DETALLE (Vistas de Pestañas)
          Expanded(
            child: TabBarView(
              children: program.mesocycles.map((mesocycle) {
                // Devolvemos la lista de semanas (microciclos)
                return _buildMicrocycleList(context, theme, mesocycle.microcycles);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- NUEVO WIDGET: Lista de Microciclos (Semanas) ---
  /// Construye la lista de microciclos (semanas) para una pestaña
  Widget _buildMicrocycleList(BuildContext context, ThemeData theme, List<Microcycle> microcycles) {
    
    if (microcycles.isEmpty) {
      return const Center(
        child: Text(
          'Este mesociclo no tiene semanas.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: microcycles.length,
      itemBuilder: (context, i) {
        final mc = microcycles[i];
        // ListTile estilizado para las semanas (extraído del diseño anterior)
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            tileColor: theme.colorScheme.surface, // grisPro
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      },
    );
  }


  // --- Sin cambios en el Modal de Sesiones ---
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
                              
                              // --- CAMBIO: Lista de Ejercicios más dinámica ---
                              ...s.exercises.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.bolt, // Icono "Volt"
                                      color: theme.colorScheme.primary, // voltNeon
                                    ),
                                    title: Text(
                                      e.name,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${e.sets}x${e.reps} @ ${e.intensity}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                                      ),
                                    ),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero, // Lo hace más compacto
                                  ),
                                ),
                              ),
                              // --- FIN DEL CAMBIO ---
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


