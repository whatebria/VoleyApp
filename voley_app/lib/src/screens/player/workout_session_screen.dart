import 'dart:async'; // Importa 'Timer'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/program/logged_excercise.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:voley_app/src/models/program/session_log.dart';
import 'package:voley_app/src/models/program/intensity.dart';
import 'package:collection/collection.dart'; // Para .firstWhereOrNull
import 'package:uuid/uuid.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';
import 'package:voley_app/src/screens/forms/player_form_screens.dart';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _exercises = widget.session.allExercises;
    _workoutData = {
      for (var ex in _exercises)
        ex.exerciseId: List.generate(ex.sets, (_) => null),
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    _restTimer?.cancel();
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

  String _sectionLabelForExercise(WorkoutExercise exercise) {
    final id = exercise.exerciseId;

    if (widget.session.warmUpExercises.any(
      (element) => element.exerciseId == id,
    )) {
      return 'Movilidad / Calentamiento';
    }
    if (widget.session.trainingExercises.any(
      (element) => element.exerciseId == id,
    )) {
      return 'Entrenamiento';
    }
    if (widget.session.coolDownExercises.any(
      (element) => element.exerciseId == id,
    )) {
      return 'Enfriamiento';
    }

    return 'Ejercicio';
  }

  /// Añade o quita segundos del temporizador de descanso actual
  void _adjustRestTime(int seconds) {
    setState(() {
      _restTimeRemaining = (_restTimeRemaining + seconds).clamp(0, 9999);
      if (_restTimeRemaining == 0) {
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

    final feedback = await _navigateToFeedbackScreen();
    if (feedback == null) return; // El usuario canceló

    ref.read(isSubmittingWorkoutProvider.notifier).state = true;
    final profile = ref.read(playerProfileProvider).value;

    if (profile == null) {
      ref.read(isSubmittingWorkoutProvider.notifier).state = false;
      return;
    }

    // Convertir el Map a List<LoggedExercise>
    final List<LoggedExercise> finalLoggedExercises = [];
    _workoutData.forEach((exerciseId, sets) {
      final loggedSets = sets.whereType<SetLog>().toList();
      if (loggedSets.isNotEmpty) {
        finalLoggedExercises.add(
          LoggedExercise(exerciseId: exerciseId, sets: loggedSets),
        );
      }
    });

    final log = SessionLog(
      id: const Uuid().v4(),
      profileId: profile.id,
      sessionId: widget.session.id,
      completedAt: DateTime.now(),
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
    } finally {
      if (mounted) {
        ref.read(isSubmittingWorkoutProvider.notifier).state = false;
      }
    }
  }

  /// Pantalla de Feedback final
  Future<Map<String, dynamic>?> _navigateToFeedbackScreen() async {
    return Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const _FeedbackScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubmitting = ref.watch(isSubmittingWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesión de entrenamiento'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSessionHeader(theme),
            const SizedBox(height: 4),
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
                    sectionLabel: _sectionLabelForExercise(exercise),
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
      ),
    );
  }

  /// Header superior con día, nombre de ejercicio actual y progreso
  Widget _buildSessionHeader(ThemeData theme) {
    if (_exercises.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _dayLabel(widget.session.day),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final progress = (_currentExerciseIndex + 1) / _exercises.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [

              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Sesión activa',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Ejercicio ${_currentExerciseIndex + 1} / ${_exercises.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
            ),
          ),
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
          color: theme.colorScheme.surfaceVariant.withOpacity(0.9),
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

  Widget _buildRestControls(
    ThemeData theme,
    String timerText,
    bool isCompact,
  ) {
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

    final bool canGoNext =
        _isLastSetRest && _currentExerciseIndex < _exercises.length - 1;

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
        if (canGoNext) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Siguiente ejercicio'),
              onPressed: () {
                _cancelRestTimer();
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              },
            ),
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
        minimumSize: const Size(140, 44),
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

/// --- Tarjeta de Ejercicio ---
class _WorkoutExerciseCard extends ConsumerWidget {
  final WorkoutExercise exercise;
  final List<SetLog?> loggedSets;
  final Function(int, SetLog) onSetLogged;
  final String sectionLabel;

  const _WorkoutExerciseCard({
    required this.exercise,
    required this.loggedSets,
    required this.onSetLogged,
    required this.sectionLabel,
  });

  String _formatReps(WorkoutExercise ex) {
    final min = ex.reps.min;
    final max = ex.reps.max;
    if (max == 0 || max == min) return '$min';
    return '$min-$max';
  }

  String _formatPrescription(Intensity p) {
    switch (p.type) {
      case IntensityType.rpe:
        return 'RPE ${p.value.toInt()}';
      case IntensityType.percent1rm:
        return '${(p.value * 100).toInt()}% 1RM';
      case IntensityType.loadkg:
        final weight =
            p.value % 1 == 0 ? p.value.toInt() : p.value.toStringAsFixed(1);
        return '$weight kg';
      case IntensityType.rpeRange:
        return 'RPE ${p.value.toInt()}-${p.valueMax?.toInt()}';
      case IntensityType.open:
        return p.label ?? 'N/A';
    }
  }

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

        for (final log in history) {
          final loggedEx = log.loggedExercises.firstWhereOrNull(
            (ex) => ex.exerciseId == exercise.exerciseId,
          );
          if (loggedEx != null) {
            final sets = loggedEx.sets;
            if (sets.isNotEmpty) {
              final bestSet =
                  sets.reduce((a, b) => a.weight > b.weight ? a : b);
              lastTimeText = "${bestSet.weight} kg x ${bestSet.reps} reps";
              break;
            }
          }
        }

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

    final String repsLabel = _formatReps(exercise);
    final String intensityLabel = _formatPrescription(exercise.prescription);

    final bool isFixedLoad = exercise.prescription.type == IntensityType.loadkg;
    final double initialWeight = isFixedLoad ? exercise.prescription.value : 0.0;
    final int initialReps = exercise.reps.min;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 420;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(
                label: Text(
                  sectionLabel,
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor:
                    theme.colorScheme.secondaryContainer.withOpacity(0.6),
                side: BorderSide.none,
              ),
              const SizedBox(height: 8),
              Text(
                exercise.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  'OBJETIVO: ${exercise.sets} x $repsLabel @ $intensityLabel',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                backgroundColor:
                    theme.colorScheme.secondaryContainer.withOpacity(0.6),
                side: BorderSide.none,
              ),
              const SizedBox(height: 8),
              _buildLastTime(context, ref, theme),
              const Divider(height: 24),
              if (!isCompact) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text('Set', style: theme.textTheme.bodySmall),
                    ),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Text(
                          'Peso (kg)',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Text('Reps', style: theme.textTheme.bodySmall),
                      ),
                    ),
                    Expanded(
                      flex: 1,
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
                  'Registra peso y repeticiones para cada set.',
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
                    targetRepsLabel: repsLabel,
                    targetIntensityLabel: intensityLabel,
                    initialReps: initialReps,
                    initialWeight: initialWeight,
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

class _SetRow extends StatefulWidget {
  final int setIndex;
  final String targetRepsLabel;
  final String targetIntensityLabel;
  final int initialReps;
  final double initialWeight;
  final SetLog? completedLog;
  final bool isCompact;
  final Function(SetLog) onSetLogged;

  const _SetRow({
    Key? key,
    required this.setIndex,
    required this.targetRepsLabel,
    required this.targetIntensityLabel,
    required this.initialReps,
    required this.initialWeight,
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

    final content = isCompact
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
              Expanded(
                flex: 1,
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
                flex: 3,
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
                flex: 3,
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
                flex: 1,
                child: Center(
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      _isCompleted
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    onPressed: _isCompleted ? _unlogSet : _logSet,
                  ),
                ),
              ),
            ],
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isCompleted ? _unlogSet : _logSet,
        child: Container(
          height: isCompact ? null : 60,
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
              : const EdgeInsets.symmetric(horizontal: 12.0),
          child: content,
        ),
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
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60),
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: !isEnabled
                ? null
                : () async {
                    final newValue =
                        await _showNumberPad(value.toDouble());
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

  Future<double?> _showNumberPad(double initialValue) {
    return Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => NumberPadScreen(initialValue: initialValue),
      ),
    );
  }
}

class _FeedbackScreen extends StatefulWidget {
  const _FeedbackScreen();

  @override
  State<_FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<_FeedbackScreen> {
  double _rpeValue = 5;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback de la Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué tan difícil fue? (RPE)',
              style: theme.textTheme.titleMedium,
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
                    onChanged: (value) => setState(() => _rpeValue = value),
                  ),
                ),
                Text(
                  _rpeValue.round().toString(),
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas de la sesión (opcional)',
                hintText: '¿Cómo te sentiste? ¿Algún dolor?',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
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
                  onPressed: () {
                    Navigator.pop<Map<String, dynamic>>(context, {
                      'rpe': _rpeValue.round(),
                      'notes': _notesController.text.trim(),
                    });
                  },
                  child: const Text('Guardar y Terminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
