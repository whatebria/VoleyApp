import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/player_profile/injury.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
// --- AÑADIDO: Imports para los nuevos modelos ---
import 'package:voley_app/src/models/program/intensity.dart';

/// Nueva pantalla para buscar y seleccionar un ejercicio de la biblioteca.
class SearchableExerciseListScreen extends ConsumerStatefulWidget {
  final PlayerProfile profile;
  const SearchableExerciseListScreen({super.key, required this.profile});

  @override
  // ignore: library_private_types_in_public_api
  _SearchableExerciseListScreenState createState() =>
      _SearchableExerciseListScreenState();
}

class _SearchableExerciseListScreenState
    extends ConsumerState<SearchableExerciseListScreen> {
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
  /// Si se guarda, cierra esta pantalla y devuelve el WorkoutExercise.
  Future<void> _showAddExerciseDialog(Exercise exercise) async {
    final theme = Theme.of(context);
    final setsCtrl = TextEditingController(text: '3');
    // --- CAMBIO: Reps e Intensity ahora son Strings simples ---
    final repsCtrl = TextEditingController(text: '8-10');
    final intensityCtrl = TextEditingController(text: 'RPE 7');

    final result = await showDialog<WorkoutExercise>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(exercise.name, style: TextStyle(color: theme.colorScheme.primary)),
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
                decoration: const InputDecoration(labelText: 'Repeticiones (Ej: 10 o 8-10)'),
              ),
              TextField(
                controller: intensityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Intensidad (Ej: RPE 7, 80%, 100kg)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).maybePop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // --- CAMBIO: Lógica de creación de WorkoutExercise actualizada ---
                
                // 1. Parsear Reps (lógica copiada de workout_exercise.dart)
                final String oldReps = repsCtrl.text.trim();
                int repsMin = 0;
                int repsMax = 0;
                if (oldReps.contains('-')) {
                  final parts = oldReps.split('-');
                  repsMin = int.tryParse(parts.first.trim()) ?? 0;
                  repsMax = int.tryParse(parts.last.trim()) ?? 0;
                } else {
                  repsMin = int.tryParse(oldReps.trim()) ?? 0;
                  repsMax = repsMin;
                }

                // 2. Parsear Intensidad (usando el helper público)
                final Intensity prescription = 
                  WorkoutExercise.migrateIntensity(intensityCtrl.text);

                // 3. Crear el objeto
                final workoutExercise = WorkoutExercise(
                  exerciseId: exercise.id,
                  name: exercise.name,
                  sets: int.tryParse(setsCtrl.text) ?? 3,
                  repsMin: repsMin,
                  repsMax: repsMax,
                  prescription: prescription,
                );
                // --- FIN DEL CAMBIO ---
                
                // Devuelve el objeto al presionar "Añadir"
                Navigator.of(context, rootNavigator: true).pop(workoutExercise);
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );

    // Si el diálogo devolvió un ejercicio, cerramos esta pantalla
    // y devolvemos el ejercicio a la ExercisePickerScreen.
    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // --- CAMBIO: AppBar con barra de búsqueda ---
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o tag...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6)
            ),
          ),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _searchController.clear(),
            )
        ],
      ),
      body: Column(
        children: [
          // --- LISTA DE EJERCICIOS DISPONIBLES ---
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error al cargar: $e')),
              data: (allExercises) {
                
                // --- CAMBIO: Lógica de filtro de lesiones actualizada ---
                final activeInjuryIds = widget.profile.injuries
                    .where((i) => i.status == InjuryStatus.active)
                    .map((i) => i.id) // Asumiendo que Injury tiene un .id
                    .toSet();

                final filteredList = allExercises.where((ex) {
                  final nameMatch = ex.name.toLowerCase().contains(
                        _searchQuery,
                      );
                  
                  // --- CAMBIO: Filtra por tagIds ---
                  final tagMatch = _searchQuery.isEmpty
                      ? false // No busques en tags si el query está vacío
                      : ex.tagIds.any((tag) => tag.toLowerCase().contains(_searchQuery));

                  final matchesSearch = nameMatch || tagMatch;

                  // --- CAMBIO: Filtra por contraindicationIds ---
                  final notContra = !ex.contraindicationIds.any(
                    (cId) => activeInjuryIds.contains(cId),
                  );
                  // --- FIN DEL CAMBIO ---

                  return matchesSearch && notContra;
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron ejercicios.'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredList[index];
                    return ListTile(
                      title: Text(exercise.name),
                      // --- CAMBIO: Muestra categoryId ---
                      subtitle: Text(exercise.categoryId),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () {
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