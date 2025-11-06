import 'dart:async'; // Importa 'Timer'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/program/logged_excercise.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:voley_app/src/models/program/session_log.dart';
// --- AÑADIDO: Imports para los nuevos modelos ---
import 'package:voley_app/src/models/program/intensity.dart';
import 'package:collection/collection.dart'; // Para .firstWhereOrNull
// --- FIN AÑADIDO ---
import 'package:uuid/uuid.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';


final isSubmittingWorkoutProvider = StateProvider<bool>((ref) => false);
const int DEFAULT_REST_TIME_SECONDS = 90; // 90 segundos de descanso

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final TrainingSession session;
  const WorkoutSessionScreen({super.key, required this.session});

  @override
  _WorkoutSessionScreenState createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  late PageController _pageController;
  late List<WorkoutExercise> _exercises;
  int _currentExerciseIndex = 0;
  late Map<String, List<SetLog?>> _workoutData;

  Timer? _restTimer;
  int _restTimeRemaining = DEFAULT_REST_TIME_SECONDS;
  bool _isResting = false;
  bool _isLastSetRest = false;

  final _notesController = TextEditingController();
  double _rpeValue = 5;
    String _dayLabel(DayOfWeek d) {
    switch (d) {
      case DayOfWeek.mon: return 'Lun';
      case DayOfWeek.tue: return 'Mar';
      case DayOfWeek.wed: return 'Mié';
      case DayOfWeek.thu: return 'Jue';
      case DayOfWeek.fri: return 'Vie';
      case DayOfWeek.sat: return 'Sáb';
      case DayOfWeek.sun: return 'Dom';
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _exercises = widget.session.exercises;
    _workoutData = {
      for (var ex in _exercises)
        ex.exerciseId: List.generate(ex.sets, (_) => null),
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    _restTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  /// Inicia el temporizador de descanso
  void _startRestTimer({bool isLastSet = false}) {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _isLastSetRest = isLastSet;
      _restTimeRemaining = DEFAULT_REST_TIME_SECONDS;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining > 0) {
        setState(() {
          _restTimeRemaining--;
        });
      } else {
        timer.cancel();
        bool wasLastSet = _isLastSetRest;
        setState(() {
          _isResting = false;
          _isLastSetRest = false;
        });

        if (wasLastSet && _currentExerciseIndex < _exercises.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      }
    });
  }

  void _cancelRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _isLastSetRest = false;
    });
  }

  // --- ¡NUEVO MÉTODO! ---
  /// Añade o quita segundos del temporizador de descanso actual
  void _adjustRestTime(int seconds) {
    setState(() {
      // Usa clamp() para asegurar que el tiempo no sea negativo
      _restTimeRemaining = (_restTimeRemaining + seconds).clamp(0, 9999);

      if (_restTimeRemaining == 0) {
        // Si el usuario lo baja a 0, cancela el timer
        _cancelRestTimer();
      }
    });
  }

  void _onSetLogged(String exerciseId, int setIndex, SetLog log) {
    setState(() {
      _workoutData[exerciseId]![setIndex] = log;
    });
    FocusScope.of(context).unfocus();

    bool isLastSet = setIndex == _exercises[_currentExerciseIndex].sets - 1;
    _startRestTimer(isLastSet: isLastSet);
  }

  /// Lógica de "Terminar" (Pide feedback y luego guarda)
  Future<void> _finishWorkout() async {
    _restTimer?.cancel();

    final feedback = await _showFeedbackDialog();
    if (feedback == null) return; // El usuario canceló

    ref.read(isSubmittingWorkoutProvider.notifier).state = true;
    final profile = ref.read(playerProfileProvider).value;

    if (profile == null) {
      _showError('Error: No se encontró el perfil');
      ref.read(isSubmittingWorkoutProvider.notifier).state = false;
      return;
    }

    // --- CAMBIO: Convertir el Map a List<LoggedExercise> ---
    final List<LoggedExercise> finalLoggedExercises = [];
    _workoutData.forEach((exerciseId, sets) {
      // Filtra solo los sets que fueron completados (no nulos)
      final loggedSets = sets.whereType<SetLog>().toList();
      if (loggedSets.isNotEmpty) {
        // Añade un nuevo LoggedExercise a la lista
        finalLoggedExercises.add(LoggedExercise(
          exerciseId: exerciseId,
          sets: loggedSets,
        ));
      }
    });
    // --- FIN DEL CAMBIO ---

    final log = SessionLog(
      id: const Uuid().v4(),
      profileId: profile.id,
      sessionId: widget.session.id,
      completedAt: DateTime.now(),
      // --- CAMBIO: Pasa la List<LoggedExercise> ---
      loggedExercises: finalLoggedExercises,
      rpe: (feedback['rpe'] as num?)?.toDouble() ?? 0.0,
      notes: feedback['notes'] as String,
    );

    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.saveSessionLog(log);
      ref.invalidate(sessionLogHistoryProvider);

      if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
    } catch (e) {
      _showError('Error al guardar: $e');
    } finally {
      if (mounted) {
        ref.read(isSubmittingWorkoutProvider.notifier).state = false;
      }
    }
  }

  /// Diálogo de Feedback
  Future<Map<String, dynamic>?> _showFeedbackDialog() async {
    _rpeValue = 5;
    _notesController.clear();

    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback de la Sesión',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¿Qué tan difícil fue? (RPE)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _rpeValue,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: _rpeValue.round().toString(),
                          onChanged: (value) =>
                              setModalState(() => _rpeValue = value),
                        ),
                      ),
                      Text(
                        _rpeValue.round().toString(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas de la sesión (opcional)',
                      hintText: '¿Cómo te sentiste? ¿Algún dolor?',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: const Text('Guardar y Terminar'),
                      onPressed: () {
                        Navigator.pop(context, {
                          'rpe': _rpeValue.round(),
                          'notes': _notesController.text.trim(),
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubmitting = ref.watch(isSubmittingWorkoutProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_dayLabel(widget.session.day))),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _exercises.length,
              onPageChanged: (index) {
                setState(() => _currentExerciseIndex = index);
              },
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                final loggedSets = _workoutData[exercise.exerciseId]!;

                return _WorkoutExerciseCard(
                  exercise: exercise,
                  loggedSets: loggedSets,
                  onSetLogged: (setIndex, log) {
                    _onSetLogged(exercise.exerciseId, setIndex, log);
                  },
                );
              },
            ),
          ),

          _buildBottomNavBar(theme, isSubmitting),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(ThemeData theme, bool isSubmitting) {
    final bool isLastPage = _currentExerciseIndex == _exercises.length - 1;
    final String timerText =
        '${(_restTimeRemaining ~/ 60)}:${(_restTimeRemaining % 60).toString().padLeft(2, '0')}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 420;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12.0),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isResting
                ? _buildRestControls(theme, timerText, isCompact)
                : _buildNavigationControls(
                    theme,
                    isSubmitting,
                    isLastPage,
                    isCompact,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildRestControls(ThemeData theme, String timerText, bool isCompact) {
    final skipButton = TextButton(
      onPressed: _cancelRestTimer,
      child: const Text('Saltar'),
    );

    final decreaseButton = OutlinedButton.icon(
      icon: const Icon(Icons.remove, size: 20),
      label: const Text('30s'),
      onPressed: () => _adjustRestTime(-30),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.secondary,
        side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5)),
      ),
    );

    final increaseButton = OutlinedButton.icon(
      icon: const Icon(Icons.add, size: 20),
      label: const Text('30s'),
      onPressed: () => _adjustRestTime(30),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.secondary,
        side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.timer, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isLastSetRest ? 'EJERCICIO COMPLETO' : 'DESCANSANDO',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            skipButton,
          ],
        ),
        const SizedBox(height: 12),
        if (isCompact) ...[
          Text(
            timerText,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: decreaseButton),
              const SizedBox(width: 12),
              Expanded(child: increaseButton),
            ],
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              decreaseButton,
              Text(
                timerText,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              increaseButton,
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationControls(
    ThemeData theme,
    bool isSubmitting,
    bool isLastPage,
    bool isCompact,
  ) {
    final previousButton = TextButton(
      onPressed: _currentExerciseIndex == 0
          ? null
          : () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            },
      child: const Text('Anterior'),
    );

    final actionButton = _buildPrimaryActionButton(
      theme,
      isLastPage,
      isSubmitting,
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              previousButton,
              Text(
                '${_currentExerciseIndex + 1} / ${_exercises.length}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: actionButton),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        previousButton,
        Text(
          '${_currentExerciseIndex + 1} / ${_exercises.length}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actionButton,
      ],
    );
  }

  Widget _buildPrimaryActionButton(
    ThemeData theme,
    bool isLastPage,
    bool isSubmitting,
  ) {
    return ElevatedButton(
      onPressed: isSubmitting
          ? null
          : () {
              if (isLastPage) {
                _finishWorkout();
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isLastPage
            ? theme.colorScheme.secondary
            : theme.colorScheme.primary,
        foregroundColor: isLastPage
            ? theme.colorScheme.onSecondary
            : theme.colorScheme.onPrimary,
      ),
      child: isSubmitting && isLastPage
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSecondary,
              ),
            )
          : Text(isLastPage ? 'Terminar' : 'Siguiente'),
    );
  }
}

/// --- Tarjeta de Ejercicio (ConsumerWidget para el Historial) ---
class _WorkoutExerciseCard extends ConsumerWidget {
  final WorkoutExercise exercise;
  final List<SetLog?> loggedSets;
  final Function(int, SetLog) onSetLogged;

  const _WorkoutExerciseCard({
    required this.exercise,
    required this.loggedSets,
    required this.onSetLogged,
  });

  // --- AÑADIDO: Helper para formatear reps ---
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
    case IntensityType.percent1rm: // <- sin guión bajo
      return '${(p.value * 100).toInt()}% 1RM';
    case IntensityType.loadkg:
      final weight = p.value % 1 == 0 ? p.value.toInt() : p.value.toStringAsFixed(1);
      return '$weight kg';
    case IntensityType.rpeRange:
      return 'RPE ${p.value.toInt()}-${p.valueMax?.toInt()}';
    case IntensityType.open:
    return p.label ?? 'N/A';
  }
}


  /// Widget para "Última vez"
  Widget _buildLastTime(BuildContext context, WidgetRef ref, ThemeData theme) {
    final historyAsync = ref.watch(sessionLogHistoryProvider);

    return historyAsync.when(
      loading: () => const Text(
        'Buscando historial...',
        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      ),
      error: (e, s) => Text(
        'Error al cargar historial',
        style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
      ),
      data: (history) {
        String lastTimeText = "¡A por un récord!";

        // --- CAMBIO: Lógica actualizada para List<LoggedExercise> ---
        for (final log in history) {
          // 1. Busca el ejercicio logueado por su ID
          final loggedEx = log.loggedExercises.firstWhereOrNull(
            (ex) => ex.exerciseId == exercise.exerciseId
          );

          // 2. Si existe y tiene series, encuentra la mejor
          if (loggedEx != null) {
            final sets = loggedEx.sets; // Es List<SetLog>
            if (sets.isNotEmpty) {
              final bestSet = sets.reduce(
                (a, b) => a.weight > b.weight ? a : b,
              );
              lastTimeText = "${bestSet.weight} kg x ${bestSet.reps} reps";
              break; // Rompe el bucle 'for'
            }
          }
        }
        // --- FIN DEL CAMBIO ---

        return Row(
          children: [
            Icon(
              Icons.history,
              size: 16,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Text('Última vez: ', style: theme.textTheme.bodySmall),
            Text(
              lastTimeText,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // --- CAMBIO: Formatea los nuevos valores ---
    final String repsLabel = _formatReps(exercise);
    final String intensityLabel = _formatPrescription(exercise.prescription);
    
    // Determina los valores iniciales para _SetRow
    final bool isFixedLoad = exercise.prescription.type == IntensityType.loadkg;
final double initialWeight = isFixedLoad ? exercise.prescription.value : 0.0;

    final int initialReps = exercise.reps.min;

    // --- FIN DEL CAMBIO ---

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 420;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                // --- CAMBIO: Usa los labels formateados ---
                label: Text(
                  'OBJETIVO: ${exercise.sets} series x $repsLabel @ $intensityLabel',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                backgroundColor: theme.colorScheme.secondaryContainer
                    .withOpacity(0.6),
                side: BorderSide.none,
              ),
              const SizedBox(height: 8),
              _buildLastTime(context, ref, theme),
              const Divider(height: 24),

              if (!isCompact) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 1, // Columna angosta
                      child: Text('Set', style: theme.textTheme.bodySmall),
                    ),
                    Expanded(
                      flex: 3, // Columna ancha
                      child: Center(
                        child: Text(
                          'Peso (kg)',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3, // Columna ancha
                      child: Center(
                        child: Text('Reps', style: theme.textTheme.bodySmall),
                      ),
                    ),
                    Expanded(
                      flex: 1, // Columna angosta
                      child: Center(
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else ...[
                Text(
                  'Registra peso y repeticiones para cada set debajo.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
              ],
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercise.sets,
                itemBuilder: (context, setIndex) {
                  return _SetRow(
                    key: ValueKey('${exercise.exerciseId}_$setIndex'),
                    setIndex: setIndex,
                    // --- CAMBIO: Pasa los nuevos props ---
                    targetRepsLabel: repsLabel,
                    targetIntensityLabel: intensityLabel,
                    initialReps: initialReps,
                    initialWeight: initialWeight,
                    // --- FIN DEL CAMBIO ---
                    completedLog: loggedSets[setIndex],
                    isCompact: isCompact,
                    onSetLogged: (log) {
                      onSetLogged(setIndex, log);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// --- MEJORA DE UX: Fila de Set con Contadores Verticales (Amigables) ---
/// --- MEJORA: Fila de Set ahora es StatefulWidget (no necesita Consumer) ---
class _SetRow extends StatefulWidget {
  final int setIndex;
  // --- CAMBIO: Propiedades de String actualizadas ---
  final String targetRepsLabel;
  final String targetIntensityLabel;
  // --- AÑADIDO: Propiedades para pre-llenar ---
  final int initialReps;
  final double initialWeight;
  // --- FIN DE CAMBIOS ---
  final SetLog? completedLog;
  final bool isCompact;
  final Function(SetLog) onSetLogged;

  const _SetRow({
    Key? key,
    required this.setIndex,
    // --- CAMBIO: Constructor actualizado ---
    required this.targetRepsLabel,
    required this.targetIntensityLabel,
    required this.initialReps,
    required this.initialWeight,
    // --- FIN DE CAMBIOS ---
    this.completedLog,
    required this.isCompact,
    required this.onSetLogged,
  }) : super(key: key);

  @override
  __SetRowState createState() => __SetRowState();
}

class __SetRowState extends State<_SetRow> {
  double _currentWeight = 0;
  int _currentReps = 0;
  bool _isCompleted = false;

  final double _weightIncrement = 2.5;
  final int _repsIncrement = 1;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.completedLog != null;

    if (_isCompleted) {
      _currentWeight = widget.completedLog!.weight;
      _currentReps = widget.completedLog!.reps;
    } else {
      // --- CAMBIO: Usar los nuevos props para inicializar ---
      _currentWeight = widget.initialWeight;
      _currentReps = widget.initialReps;
    }
  }

  void _logSet() {
    final log = SetLog(
      setNumber: widget.setIndex + 1,
      weight: _currentWeight,
      reps: _currentReps,
    );
    widget.onSetLogged(log);
    setState(() => _isCompleted = true);
  }

  void _unlogSet() {
    setState(() => _isCompleted = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = widget.isCompact;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: isCompact ? null : 60, // Altura adaptable en pantallas compactas
      decoration: BoxDecoration(
        color: _isCompleted
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCompleted
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant,
          width: 1,
        ),
      ),
      padding: isCompact
          ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0)
          : null,
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Set ${widget.setIndex + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _isCompleted
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      onPressed: _isCompleted ? _unlogSet : _logSet,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildLabeledStepper(
                  theme,
                  label: 'Peso (kg)',
                  child: _buildCompactStepper(
                    theme,
                    value: _currentWeight,
                    increment: _weightIncrement,
                    isEnabled: !_isCompleted,
                    onChanged: (newValue) =>
                        setState(() => _currentWeight = newValue),
                  ),
                ),
                const SizedBox(height: 12),
                _buildLabeledStepper(
                  theme,
                  label: 'Reps',
                  child: _buildCompactStepper(
                    theme,
                    value: _currentReps,
                    increment: _repsIncrement,
                    isEnabled: !_isCompleted,
                    onChanged: (newValue) =>
                        setState(() => _currentReps = newValue.toInt()),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --- MEJORA DE UI/UX: Layout Responsivo con Expanded/Flex ---
                Expanded(
                  flex: 1, // Columna angosta
                  child: Center(
                    child: Text(
                      '${widget.setIndex + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  flex: 3, // Columna ancha
                  child: _buildCompactStepper(
                    theme,
                    value: _currentWeight,
                    increment: _weightIncrement,
                    isEnabled: !_isCompleted,
                    onChanged: (newValue) =>
                        setState(() => _currentWeight = newValue),
                  ),
                ),

                Expanded(
                  flex: 3, // Columna ancha
                  child: _buildCompactStepper(
                    theme,
                    value: _currentReps,
                    increment: _repsIncrement,
                    isEnabled: !_isCompleted,
                    onChanged: (newValue) =>
                        setState(() => _currentReps = newValue.toInt()),
                  ),
                ),

                Expanded(
                  flex: 1, // Columna angosta
                  child: Center(
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _isCompleted
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: theme.colorScheme.primary, // Volt
                        size: 28,
                      ),
                      onPressed: _isCompleted ? _unlogSet : _logSet,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLabeledStepper(
    ThemeData theme, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  /// --- MEJORA DE UI/UX: Stepper Híbrido SÚPER COMPACTO ---
  Widget _buildCompactStepper(
    ThemeData theme, {
    required num value,
    required num increment,
    required bool isEnabled,
    required ValueChanged<double> onChanged,
  }) {
    final String valueString = (value % 1 == 0)
        ? value.toInt().toString()
        : value.toStringAsFixed(1).replaceAll('.0', '');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // --- Botón de Restar ---
        IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.remove,
            size: 20,
            color: theme.colorScheme.secondary,
          ),
          onPressed: !isEnabled
              ? null
              : () {
                  onChanged((value - increment).toDouble());
                  HapticFeedback.lightImpact();
                },
        ),

        // --- Valor (Botón para entrada manual) ---
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60),
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: !isEnabled
                ? null
                : () async {
                    final newValue = await _showNumberPad(value.toDouble());
                    if (newValue != null) {
                      onChanged(newValue);
                    }
                  },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                valueString,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isEnabled
                      ? theme.colorScheme.onSurface
                      : theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
        ),

        // --- Botón de Sumar ---
        IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(Icons.add, size: 20, color: theme.colorScheme.secondary),
          onPressed: !isEnabled
              ? null
              : () {
                  onChanged((value + increment).toDouble());
                  HapticFeedback.lightImpact();
                },
        ),
      ],
    );
  }

  /// Helper para mostrar un NumberPad para entrada manual
  Future<double?> _showNumberPad(double initialValue) {
    final controller = TextEditingController(text: initialValue.toString());
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Valor'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).maybePop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pop(double.tryParse(controller.text));
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}