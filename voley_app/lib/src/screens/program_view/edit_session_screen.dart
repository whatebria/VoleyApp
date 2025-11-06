import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
// --- CAMBIO: Imports para los nuevos modelos ---
import 'package:voley_app/src/models/program/intensity.dart';
import 'package:voley_app/src/screens/program_view/searchable_excersice_list_screen.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';

// --- WIDGETS HELPER DE FORMATO ---
// Se añaden al archivo para mantener la pantalla limpia.
String _dayLabel(DayOfWeek d) {
  switch (d) {
    case DayOfWeek.mon:
      return 'Lun';
    case DayOfWeek.tue:
      return 'Mar';
    case DayOfWeek.wed:
      return 'Mié';
    case DayOfWeek.thu:
      return 'Jue';
    case DayOfWeek.fri:
      return 'Vie';
    case DayOfWeek.sat:
      return 'Sáb';
    case DayOfWeek.sun:
      return 'Dom';
  }
}

/// Helper para formatear reps (Ej: 8-10)
String _formatReps(WorkoutExercise ex) {
  final min = ex.reps.min;
  final max = ex.reps.max;
  if (max == 0 || max == min) return '$min';
  return '$min-$max';
}

/// Helper para formatear intensidad para la vista (Ej: RPE 8)
String _formatPrescription(Intensity p) {
  switch (p.type) {
    case IntensityType.rpe:
      return 'RPE ${p.value.toInt()}';
    case IntensityType.percent1rm:
      return '${(p.value * 100).toInt()}% 1RM';
    case IntensityType.loadkg:
      final weight = p.value % 1 == 0
          ? p.value.toInt()
          : p.value.toStringAsFixed(1);
      return '$weight kg';
    case IntensityType.rpeRange:
      return 'RPE ${p.value.toInt()}-${p.valueMax?.toInt()}';
    case IntensityType.open:
      return p.label ?? 'N/A';
  }
}

/// Helper para pre-llenar el diálogo de edición (Ej: 'RPE 8' o '80%')
String _formatPrescriptionForEdit(Intensity p) {
  switch (p.type) {
    case IntensityType.rpe:
      return 'RPE ${p.value.toInt()}';
    case IntensityType.percent1rm:
      return '${(p.value * 100).toInt()}%';
    case IntensityType.loadkg:
      final weight = p.value % 1 == 0
          ? p.value.toInt()
          : p.value.toStringAsFixed(1);
      return '$weight kg';
    case IntensityType.rpeRange:
      return 'RPE ${p.value.toInt()}-${p.valueMax?.toInt()}';
    case IntensityType.open:
      return p.label ?? '';
  }
}




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
  late DayOfWeek _editableDay;

  @override
  @override
  void initState() {
    super.initState();
    _editableDay = widget.session.day;
    _exercises = List.of(widget.session.exercises);

    DropdownButtonFormField<DayOfWeek>(
      value: _editableDay,
      decoration: const InputDecoration(labelText: 'Día de la semana'),
      items: DayOfWeek.values
          .map((d) => DropdownMenuItem(value: d, child: Text(_dayLabel(d))))
          .toList(),
      onChanged: (v) => setState(() => _editableDay = v ?? _editableDay),
    );

    // Al guardar:
    final updatedSession = widget.session.copyWith(
      day: _editableDay, // ✅ guarda enum
      exercises: _exercises,
    );

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
        builder: (context) =>
            SearchableExerciseListScreen(profile: widget.profile),
      ),
    );

    if (newExercise != null && mounted) {
      setState(() {
        final newExercises = List<WorkoutExercise>.from(_exercises);
        newExercises.add(newExercise);
        _exercises = newExercises; // Actualiza el estado
      });
    }
  }

  /// Muestra el diálogo para editar Reps/Sets/Intensidad
  /// --- CAMBIO: Lógica interna actualizada para el nuevo modelo ---
  Future<void> _showEditExerciseDialog(
    WorkoutExercise exercise,
    int index,
  ) async {
    final theme = Theme.of(context);
    // Pre-llenar con los valores actuales del objeto WorkoutExercise
    final setsCtrl = TextEditingController(text: exercise.sets.toString());
    final repsCtrl = TextEditingController(text: _formatReps(exercise));
    final intensityCtrl = TextEditingController(
      text: _formatPrescriptionForEdit(exercise.prescription),
    );
    final updatedExercise = await showDialog<WorkoutExercise>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Editar ${exercise.name}',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
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
                decoration: const InputDecoration(
                  labelText: 'Repeticiones (Ej: 10 o 8-10)',
                ),
                keyboardType: TextInputType.text,
              ),
              TextField(
                controller: intensityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Intensidad (Ej: RPE 7, 80%, 100kg)',
                ),
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
                // --- LÓGICA DE PARSEO DE VUELTA AL MODELO ---
                final String rawReps = repsCtrl.text.trim();
                int repsMin = 0;
                int repsMax = 0;
                if (rawReps.contains('-')) {
                  final parts = rawReps.split('-');
                  repsMin = int.tryParse(parts.first.trim()) ?? 0;
                  repsMax = int.tryParse(parts.last.trim()) ?? 0;
                } else {
                  repsMin = int.tryParse(rawReps) ?? 0;
                  repsMax = repsMin;
                }
                final updatedSession = widget.session.copyWith(
                  day: _editableDay,
                  exercises: _exercises,
                );
                Navigator.pop(context, updatedSession);

                // --- FIN LÓGICA ---

                Navigator.of(
                  dialogContext,
                  rootNavigator: true,
                ).pop(updatedSession);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (updatedExercise != null) {
      setState(() {
        // Actualiza la lista inmutablemente
        _exercises[index] = updatedExercise;
      });
    }

    setsCtrl.dispose();
    repsCtrl.dispose();
    intensityCtrl.dispose();
  }

  /// Guarda la sesión actualizada y la devuelve a la pantalla anterior
  void _handleSave() {
    // Crea una nueva sesión con el nombre de sesión y la lista de ejercicios actualizada
    final updatedSession = widget.session.copyWith(
      day: _editableDay, // ✅ enum
      exercises: _exercises,
    );

    // Devuelve el objeto inmutable actualizado
    Navigator.pop(context, updatedSession);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_dayLabel(widget.session.day)),
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
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              labelText: 'Nombre de la Sesión',
              border: InputBorder.none,
              filled: false,
            ),
          ),
          const Divider(height: 24),

          // 2. Título de la lista de ejercicios
          Text('Ejercicios de la Sesión', style: theme.textTheme.titleLarge),
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

                // --- CAMBIO: Formatea el subtítulo ---
                final repsLabel = _formatReps(ex);
                final intensityLabel = _formatPrescription(ex.prescription);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: theme.colorScheme.surface,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(ex.name),
                    // --- CAMBIO: Subtítulo actualizado ---
                    subtitle: Text('${ex.sets}x$repsLabel @ $intensityLabel'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: theme.colorScheme.secondary,
                          ),
                          tooltip: 'Editar series/reps',
                          onPressed: () => _showEditExerciseDialog(ex, index),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Eliminar ejercicio',
                          onPressed: () {
                            setState(() {
                              final newList = List<WorkoutExercise>.from(
                                _exercises,
                              );
                              newList.removeAt(index);
                              _exercises = newList;
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
