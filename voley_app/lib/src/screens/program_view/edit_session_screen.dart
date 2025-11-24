import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
// --- CAMBIO: Imports para los nuevos modelos ---
import 'package:voley_app/src/models/program/intensity.dart';
import 'package:voley_app/src/screens/program_view/searchable_excersice_list_screen.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';
import 'package:voley_app/src/screens/program_view/workout_exercise_editor_screen.dart';

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
  // ignore: library_private_types_in_public_api
  _EditSessionScreenState createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends ConsumerState<EditSessionScreen> {
  late TextEditingController _sessionNameCtrl;
  late List<WorkoutExercise> _warmUpExercises;
  late List<WorkoutExercise> _trainingExercises;
  late List<WorkoutExercise> _coolDownExercises;
  late DayOfWeek _editableDay;

  @override
  void initState() {
    super.initState();
    _sessionNameCtrl = TextEditingController(
      text: _dayLabel(widget.session.day),
    );
    _editableDay = widget.session.day;
    _warmUpExercises = List.of(widget.session.warmUpExercises);
    _trainingExercises = List.of(widget.session.trainingExercises);
    _coolDownExercises = List.of(widget.session.coolDownExercises);
  }

  @override
  void dispose() {
    _sessionNameCtrl.dispose();
    super.dispose();
  }

  /// Navega a la pantalla de búsqueda de ejercicios
  Future<void> _navigateToExercisePicker(
    void Function(WorkoutExercise) onAdd,
  ) async {
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
        onAdd(newExercise);
      });
    }
  }

  /// Muestra el diálogo para editar Reps/Sets/Intensidad
  /// --- CAMBIO: Lógica interna actualizada para el nuevo modelo ---
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

    if (updatedExercise != null) {
      setState(() {
        // Actualiza la lista inmutablemente
        final updatedList = List<WorkoutExercise>.from(targetList)
          ..[index] = updatedExercise;
        onListUpdated(updatedList);
      });
    }
  }

  /// Guarda la sesión actualizada y la devuelve a la pantalla anterior
  void _handleSave() {
    // Crea una nueva sesión con el nombre de sesión y la lista de ejercicios actualizada
    final updatedSession = widget.session.copyWith(
      day: _editableDay, // ✅ enum
      warmUpExercises: _warmUpExercises,
      trainingExercises: _trainingExercises,
      coolDownExercises: _coolDownExercises,
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

          // 3. Lista de ejercicios dividida por secciones
          _buildExerciseSection(
            context,
            title: 'Movilidad / Calentamiento',
            subtitle: 'Prepara el cuerpo antes de la carga.',
            exercises: _warmUpExercises,
            onAdd: () => _navigateToExercisePicker(
              (exercise) => _warmUpExercises = [..._warmUpExercises, exercise],
            ),
            onEdit: (index) => _showEditExerciseDialog(
              _warmUpExercises[index],
              index,
              _warmUpExercises,
              (list) => _warmUpExercises = list,
            ),
            onDelete: (index) {
              setState(() {
                final newList = List<WorkoutExercise>.from(_warmUpExercises)
                  ..removeAt(index);
                _warmUpExercises = newList;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildExerciseSection(
            context,
            title: 'Entrenamiento',
            subtitle: 'Bloque principal de trabajo.',
            exercises: _trainingExercises,
            onAdd: () => _navigateToExercisePicker(
              (exercise) =>
                  _trainingExercises = [..._trainingExercises, exercise],
            ),
            onEdit: (index) => _showEditExerciseDialog(
              _trainingExercises[index],
              index,
              _trainingExercises,
              (list) => _trainingExercises = list,
            ),
            onDelete: (index) {
              setState(() {
                final newList = List<WorkoutExercise>.from(_trainingExercises)
                  ..removeAt(index);
                _trainingExercises = newList;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildExerciseSection(
            context,
            title: 'Enfriamiento',
            subtitle: 'Vuelve a la calma y facilita la recuperación.',
            exercises: _coolDownExercises,
            onAdd: () => _navigateToExercisePicker(
              (exercise) =>
                  _coolDownExercises = [..._coolDownExercises, exercise],
            ),
            onEdit: (index) => _showEditExerciseDialog(
              _coolDownExercises[index],
              index,
              _coolDownExercises,
              (list) => _coolDownExercises = list,
            ),
            onDelete: (index) {
              setState(() {
                final newList = List<WorkoutExercise>.from(_coolDownExercises)
                  ..removeAt(index);
                _coolDownExercises = newList;
              });
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildExerciseSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<WorkoutExercise> exercises,
    required VoidCallback onAdd,
    required void Function(int) onEdit,
    required void Function(int) onDelete,
  }) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
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
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                  color: theme.colorScheme.secondary,
                  tooltip: 'Añadir ejercicio',
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

                // --- CAMBIO: Formatea el subtítulo ---
                final repsLabel = _formatReps(ex);
                final intensityLabel = _formatPrescription(ex.prescription);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: theme.colorScheme.surface,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(ex.name),
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
}
