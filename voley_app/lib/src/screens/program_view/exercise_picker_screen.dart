import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/screens/program_view/workout_exercise_editor_screen.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:voley_app/src/screens/program_view/searchable_excersice_list_screen.dart';
import 'package:voley_app/src/models/program/intensity.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';

class ExercisePickerScreen extends ConsumerStatefulWidget {
  final TrainingSession session;
  final PlayerProfile profile;

  const ExercisePickerScreen({
    super.key,
    required this.session,
    required this.profile,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ExercisePickerScreenState createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  late DayOfWeek _editableDay;
  late List<WorkoutExercise> _warmUpExercises;
  late List<WorkoutExercise> _trainingExercises;
  late List<WorkoutExercise> _coolDownExercises;

  @override
  void initState() {
    super.initState();
    _editableDay = widget.session.day;
    _warmUpExercises = List.of(widget.session.warmUpExercises);
    _trainingExercises = List.of(widget.session.trainingExercises);
    _coolDownExercises = List.of(widget.session.coolDownExercises);
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// [NUEVO MÉTODO]: Navega a la pantalla de búsqueda y espera un resultado
  Future<void> _navigateAndAddExercise(
    BuildContext context,
    void Function(WorkoutExercise) onAdd,
  ) async {
    final newExercise = await Navigator.push<WorkoutExercise>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SearchableExerciseListScreen(profile: widget.profile),
      ),
    );

    // Si el usuario seleccionó un ejercicio, lo añade al estado local
    if (newExercise != null && mounted) {
      setState(() {
        onAdd(newExercise);
      });
    }
  }

  void _handleSaveAndClose() {
    Navigator.pop(
      context,
      widget.session.copyWith(
        day: _editableDay,
        warmUpExercises: _warmUpExercises,
        trainingExercises: _trainingExercises,
        coolDownExercises: _coolDownExercises,
      ),
    );
  }

  String _formatReps(WorkoutExercise ex) {
    final min = ex.reps.min;
    final max = ex.reps.max;
    if (max == 0 || max == min) return '$min';
    return '$min-$max';
  }

  // --- AÑADIDO: Helper para formatear intensidad ---
  String _formatPrescription(Intensity p) {
    switch (p.type) {
      case IntensityType.rpe:
        return 'RPE ${p.value.toInt()}';
      case IntensityType.percent1rm:
        return '${(p.value * 100).toInt()}% 1RM';
      case IntensityType.loadkg:
        final w = p.value % 1 == 0
            ? p.value.toInt()
            : p.value.toStringAsFixed(1);
        return '$w kg';
      case IntensityType.rpeRange:
        return 'RPE ${p.value.toInt()}-${p.valueMax?.toInt()}';
      case IntensityType.open:
        return p.label ?? 'N/A';
    }
  }

  // --- AÑADIDO: Helper para pre-llenar el diálogo de edición ---
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

  /// [MÉTODO MOVIDO]: Muestra el diálogo para EDITAR series, repeticiones e intensidad.
  /// --- CAMBIO: Actualizado para usar los nuevos modelos ---
  Future<void> _showEditExerciseDialog(
    WorkoutExercise exercise,
    int index,
    List<WorkoutExercise> targetList,
    void Function(List<WorkoutExercise>) onListUpdated,
  ) async {
    final updatedExercise = await Navigator.push<WorkoutExercise>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutExerciseEditorScreen(initial: exercise),
      ),
    );

    if (updatedExercise != null && mounted) {
      // Actualiza el ejercicio en el estado local
      setState(() {
        final updatedList = List<WorkoutExercise>.from(targetList)
          ..[index] = updatedExercise;
        onListUpdated(updatedList);
      });
    }
  }

  Widget _buildExerciseSection(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required List<WorkoutExercise> exercises,
    required VoidCallback onAdd,
    required void Function(int) onEdit,
    required void Function(int) onDelete,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Añadir ejercicio',
                  onPressed: onAdd,
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Aún no hay ejercicios en esta sección.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              )
            else
              ...List.generate(exercises.length, (index) {
                final ex = exercises[index];
                final repsLabel = _formatReps(ex);
                final intensityLabel = _formatPrescription(ex.prescription);

                return Card(
                  elevation: 0,
                  color: theme.colorScheme.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.surface),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      ex.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                          onPressed: () => onEdit(index),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Eliminar ejercicio',
                          onPressed: () => onDelete(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String _dayLabel(DayOfWeek d) => {
      DayOfWeek.mon: 'Lun',
      DayOfWeek.tue: 'Mar',
      DayOfWeek.wed: 'Mié',
      DayOfWeek.thu: 'Jue',
      DayOfWeek.fri: 'Vie',
      DayOfWeek.sat: 'Sáb',
      DayOfWeek.sun: 'Dom',
    }[d]!;

    return Scaffold(
      appBar: AppBar(
        // --- CAMBIO: Título de la sesión ---
        title: Text(_dayLabel(widget.session.day)),

        actions: [
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Ejercicios en Sesión (${_warmUpExercises.length + _trainingExercises.length + _coolDownExercises.length})',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildExerciseSection(
                  theme,
                  title: 'Movilidad / Calentamiento',
                  subtitle: 'Ejercicios para preparar el cuerpo.',
                  exercises: _warmUpExercises,
                  onAdd: () => _navigateAndAddExercise(
                    context,
                    (newExercise) =>
                        _warmUpExercises = [..._warmUpExercises, newExercise],
                  ),
                  onEdit: (index) => _showEditExerciseDialog(
                    _warmUpExercises[index],
                    index,
                    _warmUpExercises,
                    (list) => _warmUpExercises = list,
                  ),
                  onDelete: (index) {
                    setState(() {
                      _warmUpExercises = List.of(_warmUpExercises)
                        ..removeAt(index);
                    });
                  },
                ),
                _buildExerciseSection(
                  theme,
                  title: 'Entrenamiento',
                  subtitle: 'Bloque principal de trabajo.',
                  exercises: _trainingExercises,
                  onAdd: () => _navigateAndAddExercise(
                    context,
                    (newExercise) => _trainingExercises = [
                      ..._trainingExercises,
                      newExercise,
                    ],
                  ),
                  onEdit: (index) => _showEditExerciseDialog(
                    _trainingExercises[index],
                    index,
                    _trainingExercises,
                    (list) => _trainingExercises = list,
                  ),
                  onDelete: (index) {
                    setState(() {
                      _trainingExercises = List.of(_trainingExercises)
                        ..removeAt(index);
                    });
                  },
                ),
                _buildExerciseSection(
                  theme,
                  title: 'Enfriamiento',
                  subtitle: 'Vuelve a la calma y favorece la recuperación.',
                  exercises: _coolDownExercises,
                  onAdd: () => _navigateAndAddExercise(
                    context,
                    (newExercise) => _coolDownExercises = [
                      ..._coolDownExercises,
                      newExercise,
                    ],
                  ),
                  onEdit: (index) => _showEditExerciseDialog(
                    _coolDownExercises[index],
                    index,
                    _coolDownExercises,
                    (list) => _coolDownExercises = list,
                  ),
                  onDelete: (index) {
                    setState(() {
                      _coolDownExercises = List.of(_coolDownExercises)
                        ..removeAt(index);
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
