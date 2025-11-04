import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:voley_app/src/screens/searchable_excersice_list_screen.dart';

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
  // [CORRECCIÓN]: ESTADO LOCAL. Mantenemos una lista mutable localmente.
  late TrainingSession _currentSession;

  @override
  void initState() {
    super.initState();
    // [CORRECCIÓN]: Inicializa el estado local como una copia de la sesión inmutable.
    _currentSession = widget.session;
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// [NUEVO MÉTODO]: Navega a la pantalla de búsqueda y espera un resultado
  Future<void> _navigateAndAddExercise(BuildContext context) async {
    final newExercise = await Navigator.push<WorkoutExercise>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchableExerciseListScreen(profile: widget.profile),
      ),
    );

    // Si el usuario seleccionó un ejercicio, lo añade al estado local
    if (newExercise != null && mounted) {
      setState(() {
        final newExercises = List<WorkoutExercise>.from(_currentSession.exercises);
        newExercises.add(newExercise);
        _currentSession = _currentSession.copyWith(exercises: newExercises);
      });
    }
  }


  /// [NUEVO MÉTODO]: Devuelve la sesión modificada y cierra
  void _handleSaveAndClose() {
    // Devuelve la sesión actualizada e inmutable al ProgramEditorScreen
    Navigator.pop(context, _currentSession);
  }

  /// [MÉTODO MOVIDO]: Muestra el diálogo para EDITAR series, repeticiones e intensidad.
  Future<void> _showEditExerciseDialog(
    WorkoutExercise exercise,
    int index,
  ) async {
    final theme = Theme.of(context);
    final setsCtrl = TextEditingController(text: exercise.sets.toString());
    final repsCtrl = TextEditingController(text: exercise.reps);
    final intensityCtrl = TextEditingController(text: exercise.intensity);

    final updatedExercise = await showDialog<WorkoutExercise>(
      context: context,
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
                Navigator.of(dialogContext, rootNavigator: true).pop(updated);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (updatedExercise != null && mounted) {
      // Actualiza el ejercicio en el estado local
      setState(() {
        final newExercises = List<WorkoutExercise>.from(_currentSession.exercises);
        newExercises[index] = updatedExercise;
        _currentSession = _currentSession.copyWith(exercises: newExercises);
      });
    }
    
    setsCtrl.dispose();
    repsCtrl.dispose();
    intensityCtrl.dispose();
  }
  
  /// [NUEVO WIDGET]: Construye la lista principal de ejercicios de la sesión
  Widget _buildExerciseList(ThemeData theme) {
    final exercises = _currentSession.exercises;

    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Sesión vacía.\nPresiona "+" para añadir ejercicios.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7)
            ),
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: exercises.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final ex = exercises[index];
        return Card(
          elevation: 0,
          color: theme.colorScheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.surface)
          ),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            // --- CAMBIO: Añadido número ---
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              child: Text('${index + 1}'),
            ),
            title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${ex.sets}x${ex.reps} @ ${ex.intensity}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.secondary),
                  tooltip: 'Editar series/reps',
                  onPressed: () => _showEditExerciseDialog(ex, index),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  tooltip: 'Eliminar ejercicio',
                  onPressed: () {
                    setState(() {
                      final newList = List<WorkoutExercise>.from(_currentSession.exercises);
                      newList.removeAt(index);
                      _currentSession = _currentSession.copyWith(exercises: newList);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // --- CAMBIO: Título de la sesión ---
        title: Text(widget.session.day),
        actions: [
          // --- CAMBIO: Botón de Añadir ---
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Añadir Ejercicio',
            onPressed: () => _navigateAndAddExercise(context),
          ),
          // --- CAMBIO: Botón de Guardar ---
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Guardar y Cerrar',
            onPressed: _handleSaveAndClose,
          ),
        ],
      ),
      // --- CAMBIO: El body es la lista de ejercicios ---
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Ejercicios en Sesión (${_currentSession.exercises.length})',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // --- CAMBIO: La lista de ejercicios es el contenido principal ---
          Expanded(
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.all(16),
              color: theme.colorScheme.surface, // grisPro
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: _buildExerciseList(theme),
            ),
          ),
        ],
      ),
    );
  }
}
