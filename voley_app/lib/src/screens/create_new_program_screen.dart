import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/mesocycles.dart';
import 'package:voley_app/src/models/program/microcicle.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart'; // Necesario para la UI
import 'package:voley_app/src/screens/exercise_picker_screen.dart';
import 'package:uuid/uuid.dart';
// --- AÑADIDO: Import de la nueva pantalla ---
import 'package:voley_app/src/screens/create_block_screen.dart'; 

// --- CAMBIO: Nombre de la clase ---
class CreateNewProgramScreen extends ConsumerStatefulWidget {
  final PlayerProfile profile;
  const CreateNewProgramScreen({super.key, required this.profile});

  @override
  _CreateNewProgramScreenState createState() => _CreateNewProgramScreenState();
}

class _CreateNewProgramScreenState extends ConsumerState<CreateNewProgramScreen> {
  Mesocycle? _currentEditingMeso;
  late Program _program;
  bool _isSaving = false;
  final Uuid _uuid = const Uuid();

  // --- AÑADIDO: Controlador para el título del programa ---
  late TextEditingController _programNameCtrl;

  // --- CAMBIO: State del formulario movido a CreateBlockScreen ---


  @override
  void initState() {
    super.initState();
    _program = Program(
      id: _uuid.v4(),
      // --- CAMBIO: Título inicial en blanco ---
      title: '', 
      source: 'Manual',
      startDate: DateTime.now(),
      endDate: DateTime.now(), 
      mesocycles: [],
    );
    // --- AÑADIDO: Inicializar controlador de título ---
    _programNameCtrl = TextEditingController(text: _program.title);
  }
  
  // --- CAMBIO: _generateSessionTemplates, _suggestedLoadFor movidos ---
  // --- CAMBIO: _buildDefaultSegmentExercises movido ---

  @override
  void dispose() {
    _programNameCtrl.dispose(); // --- AÑADIDO ---
    super.dispose();
  }

  // --- LÓGICA DE PROGRAMA Y ACCIONES ---
  Future<void> _saveProgram() async {
    if (_program.mesocycles.isEmpty) {
      _showError(
        'El programa debe contener al menos un Bloque de Entrenamiento.',
      );
      return;
    }

    setState(() => _isSaving = true);
    
    final totalWeeks = _program.mesocycles.fold<int>(0, (sum, meso) => sum + meso.weeks);
    
    // --- CAMBIO: Actualizar título y fecha de fin ---
    _program = _program.copyWith(
      // --- CAMBIO: Guardar el título del programa ---
      title: _programNameCtrl.text.isEmpty 
          ? 'Programa sin título' 
          : _programNameCtrl.text,
      endDate: _program.startDate.add(Duration(days: totalWeeks * 7)),
    );

    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.saveProgram(widget.profile.id, _program);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Programa guardado'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Error al guardar: $e');
      }
    }
  }

  // --- CAMBIO: _saveNewMesocycle eliminado, lógica movida a _navigateToAddBlock ---

  void _navigateToExercisePicker(TrainingSession session) async {
    final updatedSession = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExercisePickerScreen(session: session, profile: widget.profile),
      ),
    );

    if (updatedSession is TrainingSession) {
      setState(() {
        final newMesocycles = _program.mesocycles.map((meso) {
          final microIndex = meso.microcycles.indexWhere(
            (micro) => micro.sessions.any((s) => s.id == updatedSession.id),
          );
          if (microIndex == -1) return meso;

          final newMicrocycles = meso.microcycles.map((micro) {
            if (micro.weekNumber == meso.microcycles[microIndex].weekNumber) {
              final newSessions = micro.sessions
                  .map((s) => s.id == updatedSession.id ? updatedSession : s)
                  .toList();
              return micro.copyWith(sessions: newSessions);
            }
            return micro;
          }).toList();
          return meso.copyWith(microcycles: newMicrocycles);
        }).toList();
        _program = _program.copyWith(mesocycles: newMesocycles);
      });
    }
  }

  // --- HELPER METHODS ---

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
  
  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }


  void _deleteMesocycle(Mesocycle meso) {
    setState(() {
      final updatedMesocycles = _program.mesocycles
          .where((m) => m.id != meso.id)
          .toList();
      _program = _program.copyWith(mesocycles: updatedMesocycles);

      if (_currentEditingMeso == meso) {
        _currentEditingMeso = null;
      }
    });
  }

  // --- CAMBIO: _clearMesoForm eliminado ---
  // --- CAMBIO: _showCreateMesoModal eliminado ---
  
  // --- AÑADIDO: Navegación a la nueva pantalla ---
  void _navigateToAddBlock() async {
    // Navega a la new screen y espera por un Mesocycle
    final newMeso = await Navigator.push<Mesocycle>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBlockScreen(profile: widget.profile),
      ),
    );

    if (newMeso != null && mounted) {
      setState(() {
        final updatedMesocycles = List<Mesocycle>.from(_program.mesocycles);
        updatedMesocycles.insert(0, newMeso); // Add to top
        _program = _program.copyWith(mesocycles: updatedMesocycles);
        _currentEditingMeso = newMeso; // Focus the new one
      });
    }
  }


  // --- WIDGETS DE CONSTRUCCIÓN ---

  // --- CAMBIO: Formularios y helpers de modal eliminados ---
  // _buildMesoForm, _buildSectionHeader, _buildAvailabilityReminder, 
  // _buildNumberStepper han sido movidos a create_block_screen.dart

  
  // --- CAMBIO: Lista de programas rediseñada ---
  List<Widget> _buildProgramListItems() {
    final theme = Theme.of(context);

    // No necesitamos el mensaje de "vacío" aquí, 
    // ya que se maneja en el build() principal.

    // --- CAMBIO: Usar asMap().entries.map() para obtener el índice ---
    return _program.mesocycles.asMap().entries.map((entry) {
      final int index = entry.key;
      final Mesocycle meso = entry.value;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.surface) // Borde grisPro
        ),
        // --- CAMBIO: El Card ya no es un ExpansionTile ---
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CAMBIO: Nuevo Header de la Card ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Bloque ${index + 1}: ${meso.name}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary // voltNeon
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error), // errorRed
                    tooltip: 'Eliminar Bloque',
                    onPressed: () => _deleteMesocycle(meso),
                  ),
                ],
              ),
              Text(
                '${meso.weeks} Semanas',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7)
                ),
              ),
              const SizedBox(height: 12),
              
              // --- CAMBIO: Objetivo del Bloque ---
              if (meso.objective.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OBJETIVO:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary // azulPro
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meso.objective,
                      style: theme.textTheme.bodyMedium
                    ),
                  ],
                ),
              
              const Divider(height: 24),

            ],
          ),
        ),
      );
    }).toList();
  }
  


  // --- CAMBIO: Diseño de la Tarjeta de Sesión ---
  Widget _buildSessionTile(TrainingSession session, Mesocycle meso, Microcycle micro) {
    final theme = Theme.of(context);
    final weekText = 'Semana ${micro.weekNumber}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      color: theme.colorScheme.background, // negroEnfocado
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.surface) // Borde grisPro
      ),
      semanticContainer: true,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
              child: Icon(Icons.fitness_center, color: theme.colorScheme.secondary),
            ),
            title: Text(
              '${session.day} ($weekText)',
              style: theme.textTheme.titleMedium,
            ),
            // --- CAMBIO: Muestra el número de ejercicios ---
            subtitle: Text(
              '${session.exercises.length} ejercicios',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7)
              ),
            ),
            // --- CAMBIO: El trailing ahora es solo el chevron ---
            trailing: const Icon(Icons.chevron_right),
            // --- CAMBIO: El onTap abre el nuevo modal ---
            onTap: () => _showEditSessionModal(meso, micro, session),
          ),
          // --- CAMBIO: El ActionChip y los botones se han movido al modal ---
        ],
      ),
    );
  }

  // --- CAMBIO: _showEditSessionDialog eliminado y reemplazado ---

  // --- AÑADIDO: Nuevo modal para editar sesión y ejercicios ---
  Future<void> _showEditSessionModal(
    Mesocycle meso,
    Microcycle micro,
    TrainingSession session,
  ) async {
    final theme = Theme.of(context);
    final sessionNameCtrl = TextEditingController(text: session.day);
    // Mantenemos una copia local de los ejercicios para el modal
    List<WorkoutExercise> modalExercises = List.from(session.exercises);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface, // grisPro
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        // StatefulBuilder para que el modal maneje su propio estado
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header del Modal
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.background,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // --- CAMBIO DE COLOR ---
                              Icon(Icons.edit, color: theme.colorScheme.secondary), // azulPro
                              const SizedBox(width: 12),
                              Text(
                                'Editar Sesión',
                                style: theme.textTheme.headlineSmall,
                              ),
                            ],
                          ),
                          // Botón de Eliminar Sesión
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                            tooltip: 'Eliminar Sesión',
                            onPressed: () {
                              Navigator.pop(modalContext); // Cierra el modal
                              _deleteSession(meso, micro, session); // Llama a la lógica de borrado
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // 1. Campo para nombrar la sesión
                          TextField(
                            controller: sessionNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la Sesión',
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // 2. Título de la lista de ejercicios
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ejercicios de la Sesión',
                                style: theme.textTheme.titleLarge
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle, color: theme.colorScheme.primary), // voltNeon
                                tooltip: 'Añadir Ejercicio',
                                onPressed: () async {
                                  // 3. Botón para añadir ejercicios
                                  // --- CAMBIO: Llamada a _navigateToExercisePicker ---
                                  // Creamos una sesión temporal para el picker
                                  final tempSession = session.copyWith(exercises: modalExercises);
                                  
                                  final updatedSession = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExercisePickerScreen(
                                        session: tempSession, 
                                        profile: widget.profile
                                      ),
                                    ),
                                  );

                                  if (updatedSession is TrainingSession) {
                                    setModalState(() {
                                      modalExercises = updatedSession.exercises;
                                    });
                                  }
                                },
                              )
                            ],
                          ),
                          const Divider(),
                          
                          // 4. Lista de ejercicios
                          if (modalExercises.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text('No hay ejercicios. Presiona "+" para añadir.'),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: modalExercises.length,
                              itemBuilder: (context, index) {
                                final ex = modalExercises[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.secondary,
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(ex.name),
                                  subtitle: Text('${ex.sets}x${ex.reps} @ ${ex.intensity}'),
                                  // --- CAMBIO: Botones de Editar y Eliminar ---
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: theme.colorScheme.secondary),
                                        tooltip: 'Editar series/reps',
                                        onPressed: () {
                                          _showEditExerciseDialog(
                                            modalContext, 
                                            setModalState, 
                                            ex,
                                            (updatedExercise) {
                                              // Callback para actualizar la lista en el modal
                                              setModalState(() {
                                                modalExercises[index] = updatedExercise;
                                              });
                                            }
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                        tooltip: 'Eliminar ejercicio',
                                        onPressed: () {
                                          setModalState(() {
                                            modalExercises.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    // 5. Botón de Guardar
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Crear la sesión actualizada
                          final updatedSession = session.copyWith(
                            day: sessionNameCtrl.text,
                            exercises: modalExercises,
                          );
                          
                          // Actualizar el estado principal (fuera del modal)
                          _updateSessionInState(meso, micro, updatedSession);
                          
                          Navigator.pop(modalContext); // Cerrar el modal
                        },
                        child: const Text('Guardar Sesión'),
                      ),
                    )
                  ],
                );
              },
            );
          },
        );
      },
    );

    sessionNameCtrl.dispose();
  }
  
  // --- AÑADIDO: Diálogo para editar Reps/Sets/Intensidad ---
  Future<void> _showEditExerciseDialog(
    BuildContext modalContext, // El context del showModalBottomSheet
    StateSetter setModalState, // El setState del StatefulBuilder del modal
    WorkoutExercise exercise,
    Function(WorkoutExercise) onUpdate, // Callback para actualizar la lista
  ) async {
    final theme = Theme.of(context);
    final setsCtrl = TextEditingController(text: exercise.sets.toString());
    final repsCtrl = TextEditingController(text: exercise.reps);
    final intensityCtrl = TextEditingController(text: exercise.intensity);

    final updatedExercise = await showDialog<WorkoutExercise>(
      context: modalContext, // Usa el context del modal
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('Editar ${exercise.name}', style: TextStyle(color: theme.colorScheme.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsCtrl,
                decoration: const InputDecoration(labelText: 'Series'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repsCtrl,
                decoration: const InputDecoration(labelText: 'Repeticiones'),
                keyboardType: TextInputType.text,
              ),
              TextField(
                controller: intensityCtrl,
                decoration: const InputDecoration(labelText: 'Intensidad (RPE)'),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext, rootNavigator: true).maybePop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final updated = exercise.copyWith(
                  sets: int.tryParse(setsCtrl.text) ?? exercise.sets,
                  reps: repsCtrl.text,
                  intensity: intensityCtrl.text,
                );
                // --- CORRECCIÓN: Navigator.pop ---
                Navigator.of(dialogContext, rootNavigator: true).pop(updated);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (updatedExercise != null) {
      // Llama al callback para que el StatefulBuilder del modal
      // actualice su lista interna de ejercicios.
      onUpdate(updatedExercise);
    }
    
    // Dispose de los controllers
    setsCtrl.dispose();
    repsCtrl.dispose();
    intensityCtrl.dispose();
  }
  
  // --- AÑADIDO: Helper para borrar sesión ---
  void _deleteSession(Mesocycle meso, Microcycle micro, TrainingSession session) {
    setState(() {
      final newMesocycles = _program.mesocycles.map((m) {
        if (m.id != meso.id) return m; // No es el meso correcto

        final newMicrocycles = m.microcycles.map((mic) {
          if (mic.id != micro.id) return mic; // No es el micro correcto

          // Filtramos la sesión
          final newSessions = mic.sessions
              .where((s) => s.id != session.id)
              .toList();
          return mic.copyWith(sessions: newSessions);
        }).toList();

        return m.copyWith(microcycles: newMicrocycles);
      }).toList();
      _program = _program.copyWith(mesocycles: newMesocycles);
    });
    _showSuccess('Sesión eliminada');
  }

  // --- AÑADIDO: Helper para actualizar estado desde el modal ---
  void _updateSessionInState(Mesocycle meso, Microcycle micro, TrainingSession updatedSession) {
    setState(() {
      final newMesocycles = _program.mesocycles.map((m) {
        if (m.id != meso.id) return m;

        final newMicrocycles = m.microcycles.map((mic) {
          if (mic.id != micro.id) return mic;
          
          final newSessions = mic.sessions
              .map((s) => s.id == updatedSession.id ? updatedSession : s)
              // --- CORRECCIÓN: Líneas erróneas eliminadas ---
              .toList();
          return mic.copyWith(sessions: newSessions);
        }).toList();
        
        return m.copyWith(microcycles: newMicrocycles);
      }).toList();

      _program = _program.copyWith(mesocycles: newMesocycles);
    });
  }

  // --- AÑADIDO: Widget para el nombre del programa ---
  Widget _buildProgramNameEditor(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextFormField(
        controller: _programNameCtrl,
        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: 'Nombre del Programa',
          // --- CAMBIO: Estilo de diseño ---
          hintText: 'Ej: Plan de Fuerza 2024',
          filled: true,
          fillColor: theme.colorScheme.surface, // grisPro
          border: theme.inputDecorationTheme.border, // Usar borde del tema
          prefixIcon: Icon(Icons.edit, color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  // --- AÑADIDO: Widget para el header de los bloques ---
  Widget _buildBlockHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Bloques',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          // --- CAMBIO: Botón "+ bloque" ---
          FilledButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir'),
            // --- CAMBIO: Navega a la nueva pantalla ---
            onPressed: _isSaving
              ? null
              : _navigateToAddBlock,
            style: FilledButton.styleFrom(
              // Un botón más sutil
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface
            ),
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // --- CAMBIO: Título de AppBar ---
      appBar: AppBar(
        title: const Text('Nuevo Programa'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isSaving 
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Guardar Programa',
                  onPressed: _saveProgram,
                ),
          ),
        ],
      ),
      // --- CAMBIO: Estructura del Body ---
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96), // Espacio para scroll
        children: [
          // 1. Editor de nombre de programa
          _buildProgramNameEditor(theme),
          
          // 2. Header de Bloques
          _buildBlockHeader(theme),
          
          // 3. Lista de Bloques (o mensaje de vacío)
          if (_program.mesocycles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'Añade tu primer Bloque de Entrenamiento para empezar.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7)
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._buildProgramListItems(),
        ],
      ),
      // --- CAMBIO: FAB eliminado ---
    );
  }
}

