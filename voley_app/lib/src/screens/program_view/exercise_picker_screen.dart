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
  late List<WorkoutExercise> _exercises;

  @override
  void initState() {
    super.initState();
    _editableDay = widget.session.day;
    _exercises = List.of(widget.session.exercises);
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
        builder: (context) =>
            SearchableExerciseListScreen(profile: widget.profile),
      ),
    );

    // Si el usuario seleccionó un ejercicio, lo añade al estado local
    if (newExercise != null && mounted) {
      setState(() {
        _exercises = List<WorkoutExercise>.from(_exercises)..add(newExercise);
      });
    }
  }

  void _handleSaveAndClose() {
    Navigator.pop(
      context,
      widget.session.copyWith(day: _editableDay, exercises: _exercises),
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
        _exercises = List<WorkoutExercise>.from(_exercises)
          ..[index] = updatedExercise;
      });
    }
  }

  /// [NUEVO WIDGET]: Construye la lista principal de ejercicios de la sesión
  Widget _buildExerciseList(ThemeData theme) {
    final exercises = _exercises;

    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Sesión vacía.\nPresiona "+" para añadir ejercicios.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
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

        // --- CAMBIO: Formatea los valores para el subtítulo ---
        final repsLabel = _formatReps(ex);
        final intensityLabel = _formatPrescription(ex.prescription);
        // --- FIN DEL CAMBIO ---

        return Card(
          elevation: 0,
          color: theme.colorScheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.surface),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            // --- CAMBIO: Añadido número ---
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              child: Text('${index + 1}'),
            ),
            title: Text(
              ex.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // --- CAMBIO: Subtítulo actualizado ---
            subtitle: Text('${ex.sets}x$repsLabel @ $intensityLabel'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.secondary),
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
                      _exercises = List<WorkoutExercise>.from(_exercises)
                        ..removeAt(index);
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
              'Ejercicios en Sesión (${_exercises.length})',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // --- CAMBIO: La lista de ejercicios es el contenido principal ---
          Expanded(
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.all(16),
              color: theme.colorScheme.surface, // grisPro
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildExerciseList(theme),
            ),
          ),
        ],
      ),
    );
  }
}
