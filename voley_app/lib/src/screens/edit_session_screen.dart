import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:voley_app/src/screens/searchable_excersice_list_screen.dart';

/// Nueva pantalla para editar una sesión (nombre y lista de ejercicios).
class EditSessionScreen extends ConsumerStatefulWidget {
  final TrainingSession session;
  final PlayerProfile profile;

  const EditSessionScreen({
    super.key,
    required this.session,
    required this.profile,
  });

  @override
  _EditSessionScreenState createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends ConsumerState<EditSessionScreen> {
  late TextEditingController _sessionNameCtrl;
  late List<WorkoutExercise> _exercises;

  @override
  void initState() {
    super.initState();
    _sessionNameCtrl = TextEditingController(text: widget.session.day);
    _exercises = List.from(widget.session.exercises);
  }

  @override
  void dispose() {
    _sessionNameCtrl.dispose();
    super.dispose();
  }

  /// Navega a la pantalla de búsqueda de ejercicios
  Future<void> _navigateToExercisePicker() async {
    // Navega a la pantalla de búsqueda
    final newExercise = await Navigator.push<WorkoutExercise>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchableExerciseListScreen(
          profile: widget.profile,
        ),
      ),
    );

    if (newExercise != null && mounted) {
      setState(() {
        _exercises.add(newExercise);
      });
    }
  }

  /// Muestra el diálogo para editar Reps/Sets/Intensidad
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
          title: Text('Editar ${exercise.name}',
              style: TextStyle(color: theme.colorScheme.primary)),
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
              onPressed: () =>
                  Navigator.of(dialogContext, rootNavigator: true).maybePop(),
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

    if (updatedExercise != null) {
      setState(() {
        _exercises[index] = updatedExercise;
      });
    }

    setsCtrl.dispose();
    repsCtrl.dispose();
    intensityCtrl.dispose();
  }

  /// Guarda la sesión actualizada y la devuelve a la pantalla anterior
  void _handleSave() {
    final updatedSession = widget.session.copyWith(
      day: _sessionNameCtrl.text,
      exercises: _exercises,
    );
    Navigator.pop(context, updatedSession);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Sesión'),
        actions: [
          // Botón de Añadir Ejercicio
          IconButton(
            icon: Icon(Icons.add, color: theme.colorScheme.primary),
            tooltip: 'Añadir Ejercicio',
            onPressed: _navigateToExercisePicker,
          ),
          // Botón de Guardar
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Guardar Sesión',
            onPressed: _handleSave,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Campo para nombrar la sesión
          TextField(
            controller: _sessionNameCtrl,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Nombre de la Sesión',
              border: InputBorder.none,
              filled: false,
            ),
          ),
          const Divider(height: 24),

          // 2. Título de la lista de ejercicios
          Text(
            'Ejercicios de la Sesión',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // 3. Lista de ejercicios
          if (_exercises.isEmpty)
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
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final ex = _exercises[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: theme.colorScheme.surface,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(ex.name),
                    subtitle: Text('${ex.sets}x${ex.reps} @ ${ex.intensity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit,
                              color: theme.colorScheme.secondary),
                          tooltip: 'Editar series/reps',
                          onPressed: () => _showEditExerciseDialog(ex, index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: theme.colorScheme.error),
                          tooltip: 'Eliminar ejercicio',
                          onPressed: () {
                            setState(() {
                              _exercises.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

