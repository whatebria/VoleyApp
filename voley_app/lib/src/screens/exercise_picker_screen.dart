import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';

class ExercisePickerScreen extends ConsumerStatefulWidget {
  /// La sesión a la que estamos añadiendo ejercicios.
  final TrainingSession session;
  /// El perfil del jugador, usado para filtrar ejercicios contraindicados.
  final PlayerProfile profile;

  const ExercisePickerScreen({
    Key? key,
    required this.session,
    required this.profile,
  }) : super(key: key);

  @override
  _ExercisePickerScreenState createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Muestra el diálogo para añadir series, repeticiones e intensidad.
  Future<void> _showAddExerciseDialog(Exercise exercise) async {
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');
    final intensityCtrl = TextEditingController(text: 'RPE 7');

    final result = await showDialog<WorkoutExercise>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(exercise.name),
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
                decoration: const InputDecoration(labelText: 'Repeticiones'),
              ),
              TextField(
                controller: intensityCtrl,
                decoration: const InputDecoration(labelText: 'Intensidad (RPE, %...)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // 1. Crear el objeto WorkoutExercise
                final workoutExercise = WorkoutExercise(
                  exerciseId: exercise.id,
                  name: exercise.name,
                  sets: int.tryParse(setsCtrl.text) ?? 3,
                  reps: repsCtrl.text,
                  intensity: intensityCtrl.text,
                );
                // 2. Devolver el objeto al presionar "Añadir"
                Navigator.pop(context, workoutExercise);
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );

    // 3. Si el diálogo devolvió un ejercicio, añadirlo a la sesión
    if (result != null && mounted) {
      // (Opcional) Notificar al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.name} añadido a la sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // ¡Importante! Añadimos el ejercicio al objeto 'session'
      // Esto modifica el estado de la pantalla ANTERIOR (ProgramEditorScreen)
      setState(() {
        widget.session.exercises.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa el provider de ejercicios
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Ejercicio'),
      ),
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // --- LISTA DE EJERCICIOS (del Provider) ---
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error al cargar: $e')),
              data: (allExercises) {
                
                // --- LÓGICA DE FILTRADO ---
                final profileInjuries = widget.profile.injuries;
                
                final filteredList = allExercises.where((ex) {
                  // Filtro 1: Búsqueda por nombre
                  final nameMatch = ex.name.toLowerCase().contains(_searchQuery);
                  
                  // Filtro 2: Contraindicaciones (basado en el perfil)
                  final notContra = !ex.contraindicatedFor.any(
                    (c) => profileInjuries.contains(c)
                  );
                  
                  return nameMatch && notContra;
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Text('No se encontraron ejercicios.'));
                }

                // --- LISTA DE RESULTADOS ---
                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredList[index];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle: Text(exercise.category),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () {
                        // Al tocar, mostrar el diálogo para añadir series/reps
                        _showAddExerciseDialog(exercise);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}