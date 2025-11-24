import 'package:flutter/material.dart';
import 'package:voley_app/src/models/program/intensity.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';

class WorkoutExerciseEditorScreen extends StatefulWidget {
  final WorkoutExercise? initial;
  final String? exerciseId;
  final String? exerciseName;

  const WorkoutExerciseEditorScreen({
    super.key,
    this.initial,
    this.exerciseId,
    this.exerciseName,
  });

  @override
  State<WorkoutExerciseEditorScreen> createState() => _WorkoutExerciseEditorScreenState();
}

class _WorkoutExerciseEditorScreenState extends State<WorkoutExerciseEditorScreen> {
  late final TextEditingController _setsCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _intensityCtrl;

  @override
  void initState() {
    super.initState();
    _setsCtrl = TextEditingController(text: (widget.initial?.sets ?? 3).toString());
    _repsCtrl = TextEditingController(text: _formatReps(widget.initial?.reps));
    _intensityCtrl = TextEditingController(text: _formatPrescription(widget.initial?.prescription));
  }

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _intensityCtrl.dispose();
    super.dispose();
  }

  String _formatReps(RepsRange? reps) {
    if (reps == null) return '8-10';
    if (reps.min == reps.max) return '${reps.min}';
    return '${reps.min}-${reps.max}';
  }

  String _formatPrescription(Intensity? p) {
    if (p == null) return 'RPE 7';
    switch (p.type) {
      case IntensityType.rpe:
        return 'RPE ${p.value.toStringAsFixed(0)}';
      case IntensityType.percent1rm:
        return '${p.value.toStringAsFixed(0)}%';
      case IntensityType.loadkg:
        return '${p.value.toStringAsFixed(0)} kg';
      case IntensityType.rpeRange:
        return 'RPE ${p.value}';
      case IntensityType.open:
        return 'Libre';
    }
  }

  Intensity _parseIntensity(String raw) {
    final text = raw.trim().toLowerCase();
    if (text.startsWith('rpe')) {
      final numValue = double.tryParse(text.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 0;
      return Intensity(type: IntensityType.rpe, value: numValue);
    }
    if (text.contains('%')) {
      final numValue = double.tryParse(text.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 0;
      return Intensity(type: IntensityType.percent1rm, value: numValue);
    }
    if (text.contains('kg')) {
      final numValue = double.tryParse(text.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 0;
      return Intensity(type: IntensityType.loadkg, value: numValue);
    }
    return const Intensity(type: IntensityType.open, value: 0);
  }

  void _save() {
    final sets = int.tryParse(_setsCtrl.text.trim()) ?? (widget.initial?.sets ?? 3);
    final reps = RepsRange.parseLoose(_repsCtrl.text);
    final prescription = _parseIntensity(_intensityCtrl.text);

    final exercise = WorkoutExercise(
      exerciseId: widget.exerciseId ?? widget.initial?.exerciseId ?? '',
      name: widget.exerciseName ?? widget.initial?.name ?? 'Ejercicio',
      sets: sets,
      reps: reps,
      prescription: prescription,
    );

    Navigator.pop(context, exercise);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.initial == null
        ? 'Configurar ejercicio'
        : 'Editar ${widget.initial!.name}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _setsCtrl,
              decoration: const InputDecoration(labelText: 'Series'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repsCtrl,
              decoration: const InputDecoration(
                labelText: 'Repeticiones (Ej: 10 o 8-10)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _intensityCtrl,
              decoration: const InputDecoration(
                labelText: 'Intensidad (Ej: RPE 7, 80%, 100kg)',
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Guardar'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}