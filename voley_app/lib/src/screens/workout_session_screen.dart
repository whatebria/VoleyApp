// lib/src/screens/workout_session_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:voley_app/src/models/program/session_log.dart';
import 'package:uuid/uuid.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final TrainingSession session;
  const WorkoutSessionScreen({Key? key, required this.session}) : super(key: key);

  @override
  _WorkoutSessionScreenState createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  late PageController _pageController;
  late Map<String, List<SetLog>> _workoutData; // Almacena los datos
  late List<WorkoutExercise> _exercises;
  int _currentExerciseIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _exercises = widget.session.exercises;
    
    // Inicializa el mapa de datos
    _workoutData = {
      for (var ex in _exercises) ex.exerciseId : []
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Muestra un diálogo para registrar una serie
  Future<void> _logSet(String exerciseId, int setIndex) async {
    final weightCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    
    final SetLog? newLog = await showDialog<SetLog>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registrar Set ${setIndex + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: repsCtrl,
              decoration: const InputDecoration(labelText: 'Repeticiones'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final log = SetLog(
                setNumber: setIndex + 1,
                weight: double.tryParse(weightCtrl.text) ?? 0.0,
                reps: int.tryParse(repsCtrl.text) ?? 0,
              );
              Navigator.pop(context, log);
            },
            child: const Text('Guardar Set'),
          )
        ],
      )
    );

    if (newLog != null) {
      setState(() {
        _workoutData[exerciseId]!.add(newLog);
      });
      // (Aquí podrías iniciar un temporizador de descanso)
    }
  }

  /// Guarda la sesión completa en Firestore
  Future<void> _finishWorkout() async {
    setState(() => _isSubmitting = true);
    final profile = ref.read(playerProfileProvider);
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se encontró el perfil'), backgroundColor: Colors.red),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final log = SessionLog(
      id: const Uuid().v4(),
      profileId: profile.id,
      sessionId: widget.session.id,
      completedAt: DateTime.now(),
      exercises: _workoutData,
    );

    try {
      final firestore = ref.read(firestoreProvider);
      // (Necesitas añadir 'saveSessionLog' a tu FirestoreService)
      // await firestore.saveSessionLog(log); 
      
      // Simulación de guardado (reemplaza con la línea de arriba)
      await Future.delayed(const Duration(seconds: 1)); 
      print('Log guardado: ${log.toJson()}');
      
      if (mounted) {
        Navigator.pop(context); // Vuelve al calendario
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sesión: ${widget.session.day}'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _finishWorkout,
            child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Terminar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. El Paginador de Ejercicios
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _exercises.length,
              onPageChanged: (index) {
                setState(() {
                  _currentExerciseIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return _buildExercisePage(exercise);
              },
            ),
          ),
          
          // 2. Indicador de Página y Navegación
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón "Anterior"
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                  onPressed: _currentExerciseIndex == 0 ? null : () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
                ),
                // Indicador "Ejercicio 1 de 5"
                Text(
                  '${_currentExerciseIndex + 1} / ${_exercises.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // Botón "Siguiente"
                TextButton.icon(
                  label: const Text('Siguiente'),
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _currentExerciseIndex == _exercises.length - 1 ? null : () {
                     _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Construye la vista para un solo ejercicio (una página del PageView)
  Widget _buildExercisePage(WorkoutExercise exercise) {
    final theme = Theme.of(context);
    final setsTarget = exercise.sets; // Ej: 3 series
    final setsCompleted = _workoutData[exercise.exerciseId]?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del Ejercicio
          Text(
            exercise.name,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Indicador (Sets x Reps @ Intensidad)
          Chip(
            label: Text(
              '${exercise.sets} series x ${exercise.reps} @ ${exercise.intensity}',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
            backgroundColor: theme.colorScheme.secondaryContainer,
          ),
          const Divider(height: 32),
          
          Text(
            'Registro de Series ($setsCompleted / $setsTarget)',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // Lista de botones para registrar series
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exercise.sets, // Muestra 3 botones si sets=3
            itemBuilder: (context, setIndex) {
              
              // Revisa si esta serie ya fue registrada
              final bool isCompleted = setIndex < setsCompleted;
              SetLog? log;
              if (isCompleted) {
                log = _workoutData[exercise.exerciseId]![setIndex];
              }

              return Card(
                color: isCompleted ? Colors.green[50] : Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCompleted ? Colors.green : Colors.grey,
                    child: Text(
                      '${setIndex + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    isCompleted 
                      ? '${log!.weight} kg x ${log.reps} reps' 
                      : 'Pendiente',
                    style: TextStyle(
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    // Abre el diálogo para registrar esta serie
                    // (Podrías deshabilitarlo si ya está completada)
                    _logSet(exercise.exerciseId, setIndex);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}