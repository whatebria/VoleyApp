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
  State<WorkoutExerciseEditorScreen> createState() =>
      _WorkoutExerciseEditorScreenState();
}

class _WorkoutExerciseEditorScreenState
    extends State<WorkoutExerciseEditorScreen> {
  late final TextEditingController _setsCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _intensityCtrl;

  @override
  void initState() {
    super.initState();
    _setsCtrl = TextEditingController(
      text: (widget.initial?.sets ?? 3).toString(),
    );
    _repsCtrl = TextEditingController(
      text: _formatReps(widget.initial?.reps),
    );
    _intensityCtrl = TextEditingController(
      text: _formatPrescription(widget.initial?.prescription),
    );
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
      final numValue =
          double.tryParse(text.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 0;
      return Intensity(type: IntensityType.rpe, value: numValue);
    }
    if (text.contains('%')) {
      final numValue =
          double.tryParse(text.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 0;
      return Intensity(type: IntensityType.percent1rm, value: numValue);
    }
    if (text.contains('kg')) {
      final numValue =
          double.tryParse(text.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 0;
      return Intensity(type: IntensityType.loadkg, value: numValue);
    }
    return const Intensity(type: IntensityType.open, value: 0);
  }

  void _save() {
    final sets =
        int.tryParse(_setsCtrl.text.trim()) ?? (widget.initial?.sets ?? 3);
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
    final theme = Theme.of(context);
    final exerciseName =
        widget.exerciseName ?? widget.initial?.name ?? 'Ejercicio';

    final title =
        widget.initial == null ? 'Configurar ejercicio' : 'Editar ejercicio';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del ejercicio
              Text(
                exerciseName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Ajusta rápido y seguimos.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              // SERIES
              const _SectionLabel(label: 'Series'),
              const SizedBox(height: 8),
              _HeroNumberRow(
                controller: _setsCtrl,
                keyboardType: TextInputType.number,
                onMinus: () {
                  final current =
                      int.tryParse(_setsCtrl.text.trim()) ?? 3;
                  if (current > 1) {
                    setState(() {
                      _setsCtrl.text = (current - 1).toString();
                    });
                  }
                },
                onPlus: () {
                  final current =
                      int.tryParse(_setsCtrl.text.trim()) ?? 3;
                  setState(() {
                    _setsCtrl.text = (current + 1).toString();
                  });
                },
              ),
              const SizedBox(height: 6),
              _PresetScroller(
                presets: const ['2', '3', '4', '5'],
                getCurrent: () => _setsCtrl.text.trim(),
                onTap: (v) {
                  setState(() {
                    _setsCtrl.text = v;
                  });
                },
              ),

              const SizedBox(height: 20),
              Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
              const SizedBox(height: 20),

              // REPS
              const _SectionLabel(label: 'Repeticiones'),
              const SizedBox(height: 8),
              _HeroTextField(
                controller: _repsCtrl,
                hint: '8-10',
              ),
              const SizedBox(height: 6),
              _PresetScroller(
                presets: const ['5', '6-8', '8-10', '10-12'],
                getCurrent: () => _repsCtrl.text.trim(),
                onTap: (v) {
                  setState(() {
                    _repsCtrl.text = v;
                  });
                },
              ),

              const SizedBox(height: 20),
              Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
              const SizedBox(height: 20),

              // INTENSIDAD
              const _SectionLabel(label: 'Intensidad'),
              const SizedBox(height: 8),
              _HeroTextField(
                controller: _intensityCtrl,
                hint: 'RPE 7',
              ),
              const SizedBox(height: 6),
              _PresetScroller(
                presets: const ['RPE 7', 'RPE 8', 'Libre'],
                getCurrent: () => _intensityCtrl.text.trim(),
                onTap: (v) {
                  setState(() {
                    _intensityCtrl.text = v;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------------- Widgets auxiliares ---------------------- */

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Número hero centrado con +/- redondeados, sin cajas pesadas
class _HeroNumberRow extends StatelessWidget {
  const _HeroNumberRow({
    required this.controller,
    required this.onMinus,
    required this.onPlus,
    this.keyboardType,
  });

  final TextEditingController controller;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.remove,
          onTap: onMinus,
        ),
        Expanded(
          child: Center(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: keyboardType ?? TextInputType.number,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        _CircleIconButton(
          icon: Icons.add,
          onTap: onPlus,
        ),
      ],
    );
  }
}

/// Hero text para reps / intensidad, centrado, sin borde (solo texto grande)
class _HeroTextField extends StatelessWidget {
  const _HeroTextField({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: hint,
            hintStyle: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón circular sutil para + y -
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkResponse(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        ),
        child: Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Presets en scroll horizontal, suaves y redondeados
class _PresetScroller extends StatelessWidget {
  const _PresetScroller({
    required this.presets,
    required this.getCurrent,
    required this.onTap,
  });

  final List<String> presets;
  final String Function() getCurrent;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = getCurrent().toLowerCase();

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = presets[index];
          final selected = current == p.toLowerCase();
          return ChoiceChip(
            label: Text(
              p,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            selected: selected,
            onSelected: (_) => onTap(p),
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            backgroundColor:
                theme.colorScheme.surface.withOpacity(selected ? 0.55 : 0.2),
            selectedColor: theme.colorScheme.primary.withOpacity(0.26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withOpacity(0.4),
            ),
          );
        },
      ),
    );
  }
}
