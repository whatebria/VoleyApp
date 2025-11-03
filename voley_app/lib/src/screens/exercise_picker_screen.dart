// lib/src/screens/exercise_picker_screen.dart (CORREGIDO)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';

class ExercisePickerScreen extends ConsumerStatefulWidget {
  final TrainingSession session;
  final PlayerProfile profile;

  const ExercisePickerScreen({
    super.key,
    required this.session,
    required this.profile,
  });

  @override
  _ExercisePickerScreenState createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  // [CORRECCIÓN]: ESTADO LOCAL. Mantenemos una lista mutable localmente.
  late TrainingSession _currentSession; 

  @override
  void initState() {
    super.initState();
    // [CORRECCIÓN]: Inicializa el estado local como una copia de la sesión inmutable.
    _currentSession = widget.session; 
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// [CORRECCIÓN]: Agrega el ejercicio al estado local (_currentSession)
  void _addExerciseToSession(WorkoutExercise workoutExercise) {
    setState(() {
      // 1. Clonar la lista de ejercicios existente a una mutable temporal
      final newExercises = List<WorkoutExercise>.from(_currentSession.exercises);
      
      // 2. Añadir el nuevo ejercicio a la lista mutable
      newExercises.add(workoutExercise);
      
      // 3. Clonar la sesión completa con la nueva lista inmutable (patrón copyWith)
      _currentSession = _currentSession.copyWith(exercises: newExercises);
    });
    
    // Opcional: Mostrar notificación de que se añadió
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${workoutExercise.name} añadido a la sesión.'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  /// [NUEVO MÉTODO]: Devuelve la sesión modificada y cierra
  void _handleSaveAndClose() {
    // Devuelve la sesión actualizada e inmutable al ProgramEditorScreen
    Navigator.pop(context, _currentSession);
  }


  /// Muestra el diálogo para añadir series, repeticiones e intensidad.
  Future<void> _showAddExerciseDialog(Exercise exercise) async {
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');
    final intensityCtrl = TextEditingController(text: 'RPE 7');

    final result = await showDialog<WorkoutExercise>(
      context: context,
      // ... (Tu implementación del diálogo sigue siendo la misma)
      builder: (context) {
        return AlertDialog(
          title: Text(exercise.name),
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
              ),
              TextField(
                controller: intensityCtrl,
                decoration: const InputDecoration(labelText: 'Intensidad (RPE, %...)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // 1. Crear el objeto WorkoutExercise
                final workoutExercise = WorkoutExercise(
                  exerciseId: exercise.id,
                  name: exercise.name,
                  sets: int.tryParse(setsCtrl.text) ?? 3,
                  reps: repsCtrl.text,
                  intensity: intensityCtrl.text,
                );
                // 2. Devolver el objeto al presionar "Añadir"
                Navigator.pop(context, workoutExercise);
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );

    // 3. Si el diálogo devolvió un ejercicio, añadirlo
    if (result != null && mounted) {
      _addExerciseToSession(result); // [CORRECCIÓN]: Usamos el método inmutable.
    }
  }
  
  // --- WIDGETS AUXILIARES ---
  
  // [NUEVO WIDGET]: Lista de Ejercicios Añadidos (para visualización y eliminación)
  Widget _buildCurrentWorkoutList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Ejercicios en Sesión (${_currentSession.exercises.length})',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 180, // Altura fija para la lista de ejercicios actuales
          child: _currentSession.exercises.isEmpty
              ? Center(child: Text('Sesión vacía. Añade ejercicios abajo.'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _currentSession.exercises.length,
                  itemBuilder: (context, index) {
                    final ex = _currentSession.exercises[index];
                    return Card(
                      margin: const EdgeInsets.only(right: 12.0),
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(ex.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      // [CORRECCIÓN]: Clonación para eliminar
                                      final newList = List<WorkoutExercise>.from(_currentSession.exercises);
                                      newList.removeAt(index);
                                      _currentSession = _currentSession.copyWith(exercises: newList);
                                    });
                                  },
                                ),
                              ],
                            ),
                            Text('${ex.sets} sets x ${ex.reps}', style: theme.textTheme.bodyMedium),
                            Text('Intensidad: ${ex.intensity}', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Ejercicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Guardar y Cerrar',
            onPressed: _handleSaveAndClose, // [CORRECCIÓN]: Botón de guardar
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Lista de ejercicios actuales (horizontal)
          _buildCurrentWorkoutList(theme),
          
          // --- BARRA DE BÚSQUEDA ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // --- LISTA DE EJERCICIOS DISPONIBLES ---
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error al cargar: $e')),
              data: (allExercises) {
                final profileInjuries = widget.profile.injuries;
                
                final filteredList = allExercises.where((ex) {
                  final nameMatch = ex.name.toLowerCase().contains(_searchQuery);
                  
                  final notContra = !ex.contraindicatedFor.any(
                    (c) => profileInjuries.contains(c)
                  );
                  
                  return nameMatch && notContra;
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Text('No se encontraron ejercicios.'));
                }

                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredList[index];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle: Text(exercise.category),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () {
                        _showAddExerciseDialog(exercise);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}