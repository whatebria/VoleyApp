// lib/src/screens/program_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _SessionTemplate {
  const _SessionTemplate({required this.dayOffset, required this.focus});

  final int dayOffset;
  final String focus;
}

class ProgramEditorScreen extends ConsumerStatefulWidget {
  final PlayerProfile profile;
  const ProgramEditorScreen({super.key, required this.profile});

  @override
  _ProgramEditorScreenState createState() => _ProgramEditorScreenState();
}

class _ProgramEditorScreenState extends ConsumerState<ProgramEditorScreen> {
  Mesocycle? _currentEditingMeso;
  late Program _program;
  bool _isSaving = false;
  final Uuid _uuid = const Uuid();
  late Map<MacroPhase, int> _macroWeeks;

  final _mesoFormKey = GlobalKey<FormState>();
  final _mesoNameCtrl = TextEditingController();
  final _mesoFocusCtrl = TextEditingController();
  int _mesoWeeks = 4;
  int _mesoSessions = 3;
  String _mesoProgressionType = 'lineal';
  MacroPhase _selectedMacroPhase = MacroPhase.pretemporada;
  int _selectedMatchDayIndex = 5;
  final List<String> _allDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _macroWeeks = {
      for (final phase in MacroPhase.values) phase: phase.defaultWeeks,
    };
    _program = Program(
      id: _uuid.v4(),
      title: 'Nuevo Programa para ${widget.profile.name}',
      source: 'Manual',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: _totalSeasonWeeks() * 7)),
      mesocycles: [],
    );
  }

  int _totalSeasonWeeks() {
    return _macroWeeks.values.fold<int>(0, (total, weeks) => total + weeks);
  }

  void _refreshProgramDuration() {
    _program = _program.copyWith(
      endDate: _program.startDate.add(Duration(days: _totalSeasonWeeks() * 7)),
    );
  }

  int _usedWeeksFor(MacroPhase phase) {
    return _program.mesocycles
        .where((meso) => meso.macroPhase == phase)
        .fold<int>(0, (total, meso) => total + meso.weeks);
  }

  int _remainingWeeksFor(MacroPhase phase) {
    final configured = _macroWeeks[phase] ?? phase.defaultWeeks;
    return configured - _usedWeeksFor(phase);
  }

  int _normalizeDayIndex(int index) {
    var normalized = index % 7;
    if (normalized < 0) normalized += 7;
    return normalized;
  }

  List<_SessionTemplate> _generateSessionTemplates(int sessionsPerWeek) {
    const templates = [
      _SessionTemplate(
        dayOffset: 1,
        focus: 'Recuperación activa y movilidad post-partido',
      ),
      _SessionTemplate(dayOffset: 2, focus: 'Fuerza general y estabilidad'),
      _SessionTemplate(
        dayOffset: 3,
        focus: 'Fuerza máxima y técnica específica',
      ),
      _SessionTemplate(dayOffset: 4, focus: 'Potencia, salto y velocidad'),
      _SessionTemplate(
        dayOffset: -2,
        focus: 'Carga moderada con énfasis táctico',
      ),
      _SessionTemplate(
        dayOffset: -1,
        focus: 'Activación ligera y estrategia de partido',
      ),
      _SessionTemplate(dayOffset: 0, focus: 'Partido o simulación competitiva'),
    ];

    final count = sessionsPerWeek.clamp(1, templates.length).toInt();
    return templates.take(count).toList();
  }

  double _suggestedLoadFor(MacroPhase phase, int weekIndex, int totalWeeks) {
    final normalizedIndex = totalWeeks <= 1 ? 0 : weekIndex / (totalWeeks - 1);
    switch (phase) {
      case MacroPhase.pretemporada:
        return double.parse((0.5 + 0.3 * normalizedIndex).toStringAsFixed(2));
      case MacroPhase.competicion:
        const pattern = [0.75, 0.7, 0.8, 0.65];
        return pattern[weekIndex % pattern.length];
      case MacroPhase.transicion:
        return double.parse((0.4 + 0.1 * normalizedIndex).toStringAsFixed(2));
    }
  }

  List<WorkoutExercise> _buildDefaultSegmentExercises(String focus) {
    return [
      WorkoutExercise(
        exerciseId: _uuid.v4(),
        name: 'Calentamiento y movilidad',
        sets: 1,
        reps: '10-15 minutos',
        intensity: 'Suave',
      ),
      WorkoutExercise(
        exerciseId: _uuid.v4(),
        name: 'Bloque físico - $focus',
        sets: 3,
        reps: 'Personalizar',
        intensity: 'Moderado/Alto',
      ),
      WorkoutExercise(
        exerciseId: _uuid.v4(),
        name: 'Estiramiento y vuelta a la calma',
        sets: 1,
        reps: '10 minutos',
        intensity: 'Ligero',
      ),
    ];
  }

  @override
  void dispose() {
    _mesoNameCtrl.dispose();
    _mesoFocusCtrl.dispose();
    super.dispose();
  }

  // --- LÓGICA DE PROGRAMA Y ACCIONES (Sin cambios, solo simplificados) ---
  Future<void> _saveProgram() async {
    if (_program.mesocycles.isEmpty) {
      _showError(
        'El programa debe contener al menos un Bloque de Entrenamiento.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final firestore = ref.read(firestoreProvider);
      // Guardar el programa asociado al perfil del jugador
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

  void _saveNewMesocycle() {
    // ESTA FUNCIÓN AHORA SE LLAMA DESDE EL MODAL
    if (_mesoFormKey.currentState!.validate()) {
      final weeks = _mesoWeeks;
      final sessionsPerWeek = _mesoSessions;

      final remainingWeeks = _remainingWeeksFor(_selectedMacroPhase);
      if (weeks > remainingWeeks) {
        _showError(
          'El macro ${_selectedMacroPhase.label} solo tiene $remainingWeeks semanas disponibles.',
        );
        return;
      }

      final templates = _generateSessionTemplates(sessionsPerWeek);

      final microcycles = List.generate(weeks, (i) {
        final sessions = templates.map((template) {
          final dayIndex = _normalizeDayIndex(
            _selectedMatchDayIndex + template.dayOffset,
          );
          final dayName = _allDays[dayIndex];
          final combinedFocus =
              '${template.focus} • Enfoque: ${_mesoFocusCtrl.text}';
          final objective =
              '$combinedFocus. Incluye calentamiento con movilidad, bloque físico y estiramiento.';

          return TrainingSession(
            id: _uuid.v4(),
            day: dayName,
            objective: objective,
            load: _suggestedLoadFor(_selectedMacroPhase, i, weeks),
            exercises: _buildDefaultSegmentExercises(template.focus),
          );
        }).toList();
        return Microcycle(
          weekNumber: i + 1,
          sessions: sessions,
          id: _uuid.v4(),
        );
      });

      final newMeso = Mesocycle(
        id: _uuid.v4(),
        name: _mesoNameCtrl.text,
        weeks: weeks,
        focus: _mesoFocusCtrl.text,
        progressionType: _mesoProgressionType,
        macroPhase: _selectedMacroPhase,
        matchDayIndex: _selectedMatchDayIndex,
        microcycles: microcycles,
      );

      setState(() {
        final updatedMesocycles = List<Mesocycle>.from(_program.mesocycles);
        updatedMesocycles.insert(0, newMeso);
        _program = _program.copyWith(mesocycles: updatedMesocycles);
        _clearMesoForm();
        _currentEditingMeso = newMeso;
      });
    }
  }

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

  void _clearMesoForm() {
    _mesoFormKey.currentState?.reset();
    _mesoNameCtrl.clear();
    _mesoFocusCtrl.clear();
    // No necesitamos setState si no usamos el scrollController
    _mesoWeeks = 4;
    _mesoSessions = 3;
    _mesoProgressionType = 'lineal';
    _selectedMacroPhase = MacroPhase.values.firstWhere(
      (phase) => _remainingWeeksFor(phase) > 0,
      orElse: () => MacroPhase.pretemporada,
    );
    _selectedMatchDayIndex = 5;
  }

  // --- MEJORA DE UX: Diálogo de Creación (Modal) ---
  void _showCreateMesoModal(BuildContext context, ThemeData theme) {
    // Limpiamos el estado del formulario antes de abrir el modal
    _clearMesoForm();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: _buildMesoForm(
                context,
                theme,
                setModalState,
              ), // Llama al formulario con setModalState
            );
          },
        );
      },
    ).then((_) {
      // Opcional: enfoca el bloque recién creado
    });
  }

  // --- WIDGETS DE CONSTRUCCIÓN ---

  /// [NUEVO] Construye el formulario como un widget
  Widget _buildMesoForm(
    BuildContext context,
    ThemeData theme,
    StateSetter setModalState,
  ) {
    return Form(
      key: _mesoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Crear Bloque de Entrenamiento',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El programa creará ${_mesoWeeks} semanas con ${_mesoSessions} sesiones base.',
            style: theme.textTheme.bodyMedium,
          ),
          const Divider(height: 24),

          TextFormField(
            controller: _mesoNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del Bloque',
              helperText: 'Ej: Bloque de Fuerza, Base',
              prefixIcon: Icon(Icons.label_outline),
            ),
            validator: (val) => val!.isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MacroPhase>(
            value: _selectedMacroPhase,
            decoration: const InputDecoration(
              labelText: 'Fase Macro',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            items: MacroPhase.values
                .map(
                  (phase) =>
                      DropdownMenuItem(value: phase, child: Text(phase.label)),
                )
                .toList(),
            onChanged: (phase) {
              if (phase == null) return;
              setModalState(() {
                _selectedMacroPhase = phase;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Semanas disponibles en ${_selectedMacroPhase.label}: '
            '${_remainingWeeksFor(_selectedMacroPhase)} / '
            '${_macroWeeks[_selectedMacroPhase]}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedMatchDayIndex,
            decoration: const InputDecoration(
              labelText: 'Día habitual de partido',
              prefixIcon: Icon(Icons.sports_volleyball_outlined),
            ),
            items: List.generate(
              _allDays.length,
              (index) =>
                  DropdownMenuItem(value: index, child: Text(_allDays[index])),
            ),
            onChanged: (value) {
              if (value == null) return;
              setModalState(() => _selectedMatchDayIndex = value);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _mesoFocusCtrl,
            decoration: const InputDecoration(
              labelText: 'Foco Principal',
              helperText: 'Ej: Hipertrofia, Salto Vertical',
              prefixIcon: Icon(Icons.center_focus_strong_outlined),
            ),
            validator: (val) => val!.isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),

          _buildNumberStepper(
            theme: theme,
            title: 'Duración (Semanas):',
            value: _mesoWeeks,
            onChanged: (newValue) => setModalState(() => _mesoWeeks = newValue),
            max: 12,
          ),

          _buildNumberStepper(
            theme: theme,
            title: 'Sesiones por Semana:',
            value: _mesoSessions,
            onChanged: (newValue) =>
                setModalState(() => _mesoSessions = newValue),
            min: 1,
            max: 7,
          ),
          const SizedBox(height: 16),

          // [MEJORA DE DISEÑO]: Selector de Progresión
          Text('Tipo de Progresión', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'lineal', label: Text('Lineal')),
              ButtonSegment(value: 'progresiva', label: Text('Progresiva')),
              ButtonSegment(value: 'ondulante', label: Text('Ondulante')),
            ],
            selected: {_mesoProgressionType},
            onSelectionChanged: (Set<String> newSelection) =>
                setModalState(() => _mesoProgressionType = newSelection.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: theme.colorScheme.secondary,
              selectedForegroundColor: theme.colorScheme.onSecondary,
            ),
            emptySelectionAllowed: false,
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Crear Bloque'),
            // Esta función guardará y luego cerrará el modal
            onPressed: () {
              if (_mesoFormKey.currentState!.validate()) {
                _saveNewMesocycle();
                Navigator.pop(context); // Cierra el modal al guardar
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberStepper({
    required ThemeData theme,
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
    int min = 1,
    int max = 12,
  }) {
    // ... (Tu implementación de Stepper) ...
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: theme.colorScheme.secondary,
                ),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  value.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: theme.colorScheme.secondary,
                ),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPlannerCard(ThemeData theme) {
    final totalConfiguredWeeks = _totalSeasonWeeks();
    final totalAllocatedWeeks = _program.mesocycles.fold<int>(
      0,
      (sum, meso) => sum + meso.weeks,
    );
    final seasonMonths = (totalConfiguredWeeks / 4).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Periodización Macro',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total: $totalConfiguredWeeks semanas (≈ $seasonMonths meses). '
              'Asignadas en bloques: $totalAllocatedWeeks semanas.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...MacroPhase.values.map((phase) {
              final configured = _macroWeeks[phase] ?? phase.defaultWeeks;
              final used = _usedWeeksFor(phase);
              final remaining = _remainingWeeksFor(phase);
              final hasOverflow = remaining < 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(phase.label, style: theme.textTheme.titleMedium),
                        Chip(
                          label: Text('$used / $configured semanas'),
                          backgroundColor: theme.colorScheme.surfaceVariant,
                        ),
                      ],
                    ),
                    if (hasOverflow)
                      Text(
                        'Has asignado ${used - configured} semanas adicionales a esta fase.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      )
                    else
                      Text(
                        'Disponible: ${remaining.clamp(0, configured)} semanas.',
                        style: theme.textTheme.bodySmall,
                      ),
                    _buildNumberStepper(
                      theme: theme,
                      title: 'Semanas planificadas',
                      value: configured,
                      min: phase.minWeeks,
                      max: phase.maxWeeks,
                      onChanged: (newValue) {
                        setState(() {
                          _macroWeeks[phase] = newValue;
                          _refreshProgramDuration();
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
            if (totalAllocatedWeeks > totalConfiguredWeeks)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'Advertencia: tus bloques superan las semanas planificadas para la temporada.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProgramListItems() {
    final theme = Theme.of(context);

    if (_program.mesocycles.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'Añade tu primer Bloque de Entrenamiento para empezar.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return _program.mesocycles.map((meso) {
      final matchDay = _allDays[_normalizeDayIndex(meso.matchDayIndex)];
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ExpansionTile(
          key: ValueKey(meso.id),
          initiallyExpanded: meso == _currentEditingMeso,
          onExpansionChanged: (isExpanded) {
            setState(() {
              _currentEditingMeso = isExpanded ? meso : null;
            });
          },
          leading: Icon(Icons.timeline, color: theme.colorScheme.primary),
          title: Text(
            meso.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${meso.weeks} Semanas • Macro: ${meso.macroPhase.label} • Partido: $matchDay',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Eliminar Bloque',
            onPressed: () => _deleteMesocycle(meso),
          ),
          children: meso.microcycles.map((micro) {
            return ExpansionTile(
              key: ValueKey('${meso.id}_${micro.weekNumber}'),
              leading: Icon(
                Icons.date_range,
                color: theme.colorScheme.secondary.withOpacity(0.7),
              ),
              title: Text(
                'Semana ${micro.weekNumber}',
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text('${micro.sessions.length} sesiones'),
              childrenPadding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              children: micro.sessions.map((session) {
                return _buildSessionTile(session, meso);
              }).toList(),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  /// Construye la UI para una sola sesión
  Widget _buildSessionTile(TrainingSession session, Mesocycle meso) {
    final theme = Theme.of(context);

    final micro = meso.microcycles.firstWhere(
      (m) => m.sessions.any((s) => s.id == session.id),
      orElse: () => meso.microcycles.first,
    );
    final weekText = 'Semana ${micro.weekNumber}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
          child: Icon(Icons.fitness_center, color: theme.colorScheme.secondary),
        ),
        title: Text(
          '${session.day} ($weekText)',
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(session.objective, style: theme.textTheme.bodyMedium),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón de Eliminar Sesión
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Eliminar Sesión',
              onPressed: () {
                // Lógica de borrado INMUTABLE
                setState(() {
                  final newMesocycles = _program.mesocycles.map((m) {
                    if (m.id != meso.id) return m;

                    final newMicrocycles = m.microcycles.map((micro) {
                      if (micro.id != micro.id) return micro;

                      final newSessions = micro.sessions
                          .where((s) => s.id != session.id)
                          .toList();
                      return micro.copyWith(sessions: newSessions);
                    }).toList();

                    return m.copyWith(microcycles: newMicrocycles);
                  }).toList();
                  _program = _program.copyWith(mesocycles: newMesocycles);
                });
              },
            ),
            // Botón de Editar Día/Objetivo
            IconButton(
              icon: Icon(Icons.settings, color: theme.colorScheme.secondary),
              tooltip: 'Editar Día/Objetivo',
              onPressed: () => _showEditSessionDialog(session),
            ),
            // Chip/Botón de Ejercicios
            Chip(
              label: Text('${session.exercises.length} Ejercicios'),
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(color: theme.colorScheme.primary),
            ),
          ],
        ),
        onTap: () => _navigateToExercisePicker(session), // Tap para editar
      ),
    );
  }

  Future<void> _showEditSessionDialog(TrainingSession session) async {
    final objectiveCtrl = TextEditingController(text: session.objective);
    // Usa un índice para manejar el Dropdown
    int selectedDayIndex = _allDays.indexOf(session.day) != -1
        ? _allDays.indexOf(session.day)
        : 0;

    final result = await showDialog<TrainingSession>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Sesión'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedDayIndex,
                    decoration: const InputDecoration(
                      labelText: 'Día de la Semana',
                    ),
                    items: List.generate(
                      _allDays.length,
                      (i) =>
                          DropdownMenuItem(value: i, child: Text(_allDays[i])),
                    ),
                    onChanged: (val) =>
                        setDialogState(() => selectedDayIndex = val!),
                  ),
                  TextFormField(
                    controller: objectiveCtrl,
                    decoration: const InputDecoration(labelText: 'Objetivo'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).maybePop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(
                  session.copyWith(
                    day: _allDays[selectedDayIndex],
                    objective: objectiveCtrl.text,
                  ),
                );
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      // Lógica de actualización INMUTABLE (similar a _navigateToExercisePicker)
      setState(() {
        final newMesocycles = _program.mesocycles.map((meso) {
          final microIndex = meso.microcycles.indexWhere(
            (micro) => micro.sessions.any((s) => s.id == result.id),
          );
          if (microIndex == -1) return meso;

          final newMicrocycles = meso.microcycles.map((micro) {
            if (micro.weekNumber == meso.microcycles[microIndex].weekNumber) {
              final newSessions = micro.sessions
                  .map((s) => s.id == result.id ? result : s)
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
    objectiveCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Planificación: ${widget.profile.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar Programa',
            onPressed: _isSaving ? null : _saveProgram,
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- Contenido Principal ---
          ListView(
            // No necesitamos controller ya que el FAB maneja la creación
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Plan de Temporada',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              _buildMacroPlannerCard(theme),
              const SizedBox(height: 16),
              // 1. Título de la lista (sustituye al formulario fijo)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Bloques de Entrenamiento',
                  style: theme.textTheme.headlineSmall,
                ),
              ),

              // 2. La lista de mesociclos creados
              ..._buildProgramListItems(),
            ],
          ),

          // --- MEJORA DE UX: FAB para Agregar Bloque ---
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton.extended(
                label: const Text('Agregar Bloque +'),
                icon: const Icon(Icons.add_road), // Icono más temático
                onPressed: _isSaving
                    ? null
                    : () => _showCreateMesoModal(context, theme),
                tooltip: 'Crear un nuevo Bloque de Entrenamiento',
              ),
            ),
          ),

          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
