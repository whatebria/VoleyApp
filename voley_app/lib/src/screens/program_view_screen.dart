// lib/screens/program_view_screen.dart
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
  @override
  void initState() {
    super.initState();
    
    // 1. Llama a la configuración inicial del jugador
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialPlayerSetup();
    });

    // 
  }

  /// Configura el jugador seleccionado al entrar a la pantalla
  void _initialPlayerSetup() async {
    // Evita configurar si ya hay un jugador
    if (ref.read(explorerSelectedPlayerProvider) != null) return;
    
    final currentUser = ref.read(currentUserAppUserProvider).valueOrNull;
    if (currentUser == null) return; // Aún no carga

    if (currentUser.isPlayer) {
      // Es Jugador: seleccionarse a sí mismo
      ref.read(explorerSelectedPlayerProvider.notifier).state = currentUser;
    } else {
      // Es Coach: seleccionar el primer jugador de la lista
      try {
        final players = await ref.read(coachPlayersProvider.future);
        if (players.isNotEmpty) {
          ref.read(explorerSelectedPlayerProvider.notifier).state = players.first;
        }
      } catch (e) {
        debugPrint("Error al cargar jugadores iniciales: $e");
      }
    }
  }

  // --- MÉTODOS DE ACCIÓN (Ahora gestionan el estado de carga) ---

  void _showGenerationChoice(BuildContext context, PlayerProfile profile) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
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

  void _runAutomaticGenerator(BuildContext context, PlayerProfile profile) async {
    // 1. Pone el estado de carga en 'true'
    ref.read(isGeneratingProgramProvider.notifier).state = true;

    try {
      // 2. Llama a la acción
      // Asumiendo que 'programGeneratorAction' es un Provider<Future Function(PlayerProfile)>
      await ref.read(programGeneratorAction)(profile);
      
      // ¡Éxito!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Programa automático generado!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // Error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar: $e'), backgroundColor: Theme.of(context).colorScheme.error),
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
        builder: (context) => ProgramEditorScreen(
          profile: profile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    ref.listen<AsyncValue<List<Program>>>(explorerProgramsProvider, (previous, next) {
      // Solo reacciona cuando hay un nuevo valor
      if (next.hasValue) {
        final programs = next.value!;
        final selectedProgramNotifier = ref.read(explorerSelectedProgramProvider.notifier);
        
        if (programs.isEmpty) {
          // Si la nueva lista está vacía, fuerza el programa seleccionado a null.
          selectedProgramNotifier.state = null;
        } else {
          // Si la lista no está vacía, comprueba si el programa actual
          // sigue siendo válido. Si no, selecciona el primero.
          final currentProgram = selectedProgramNotifier.state;
          if (currentProgram == null || !programs.contains(currentProgram)) {
            selectedProgramNotifier.state = programs.first;
          }
        }
      }
    });
    // Observa todos los providers. La UI será 100% reactiva.
    final currentUserAsync = ref.watch(currentUserAppUserProvider);
    final playersAsync = ref.watch(coachPlayersProvider);
    final selectedPlayer = ref.watch(explorerSelectedPlayerProvider);
    
    // --- NUEVOS PROVIDERS REACTIVOS ---
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

              return Column(
                children: [
                  // --- Dropdown de Jugadores (Solo para Coaches) ---
                  if (currentUser.isCoach)
                    playersAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (e, s) => Center(child: Text('Error: $e')),
                      data: (players) {
                        if (players.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: Text('No tienes jugadores vinculados.')),
                          );
                        }
                        return _buildPlayerSelector(ref, players, selectedPlayer);
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
                      // Ya no hay 'ref.listen' aquí.
                      // El listener en initState se encarga de la lógica.
                      return _buildProgramSelector(ref, programs, selectedProgram);
                    },
                  ),

                  // --- Detalles del Programa ---
                  Expanded(
                    // La lógica ahora es simple: si selectedProgram es null,
                    // muestra el texto. Si no, muestra los detalles.
                    // El listener de initState se encarga de que
                    // selectedProgram esté siempre sincronizado.
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
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Theme.of(context).textTheme.bodySmall?.color,
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
          
          // --- NUEVO: Overlay de Carga No-Modal ---
          if (isGenerating)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Generando programa (IA)...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
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
        onPressed: isGenerating ? null : () { // Deshabilitado si ya está generando
          
          // --- LÓGICA DE PERFIL SIMPLIFICADA ---
          // Ahora leemos el FutureProvider reactivo
          final profile = selectedProfileAsync.valueOrNull;

          if (profile != null) {
            _showGenerationChoice(context, profile);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Este jugador no tiene un perfil de evaluación.')),
            );
          }
        },
      ),
    );
  }

  // --- Widgets de UI (Refactorizados con Colores de Tema) ---

  Widget _buildPlayerSelector(WidgetRef ref, List<app_user.User> players, app_user.User? selectedPlayer) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      // --- TEMA ---
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3), 
      child: DropdownButtonFormField<app_user.User>(
        value: selectedPlayer,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Seleccionar Jugador',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          // --- TEMA ---
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
        items: players.map((user) {
          return DropdownMenuItem<app_user.User>(
            value: user,
            child: Text(user.name, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (app_user.User? newValue) {
          // --- LÓGICA SIMPLIFICADA ---
          // 1. Actualiza el jugador
          ref.read(explorerSelectedPlayerProvider.notifier).state = newValue;
          // 2. Resetea el programa
          ref.read(explorerSelectedProgramProvider.notifier).state = null;
          
          // ¡Y YA ESTÁ! Los otros providers (perfil y programas) 
          // reaccionarán automáticamente a este cambio.
        },
      ),
    );
  }

  Widget _buildProgramSelector(WidgetRef ref, List<Program> programs, Program? selectedProgram) {
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
      // --- TEMA ---
      color: theme.colorScheme.secondaryContainer.withOpacity(0.2),
      child: DropdownButtonFormField<Program>(
        value: selectedProgram,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Seleccionar Programa',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          // --- TEMA ---
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
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: program.mesocycles.length,
      itemBuilder: (context, i) {
        final m = program.mesocycles[i];
        return Card(
          // --- TEMA ---
          color: theme.colorScheme.surface,
          surfaceTintColor: theme.colorScheme.surface,
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ExpansionTile(
            title: Text(
              m.name,
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
            subtitle: Text('${m.weeks} semanas — Enfoque: ${m.focus}'),
            children: m.microcycles.map((mc) {
              return ListTile(
                leading: CircleAvatar(
                  // --- TEMA ---
                  backgroundColor: theme.colorScheme.secondary,
                  child: Text(
                    '${mc.weekNumber}',
                    // --- TEMA ---
                    style: TextStyle(color: theme.colorScheme.onSecondary, fontSize: 12),
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
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // --- TEMA ---
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
                    // --- TEMA ---
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, color: theme.colorScheme.secondary),
                      const SizedBox(width: 12),
                      Text(
                        'Semana ${mc.weekNumber}',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                        // --- TEMA ---
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.fitness_center,
                                    // --- TEMA ---
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s.day,
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Objetivo: ${s.objective}',
                                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Carga: ${s.load}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const Divider(height: 16),
                              Text(
                                'Ejercicios:',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...s.exercises.map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('• ', style: TextStyle(fontSize: 16, color: theme.colorScheme.primary)),
                                        Expanded(child: Text('${e.name} (${e.sets}x${e.reps} @ ${e.intensity})')),
                                      ],
                                    ),
                                  )),
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