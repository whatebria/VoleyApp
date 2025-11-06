import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/bd/exercise.dart'; // <- V4 con enums (tu clase se llama Exercise)
import 'package:voley_app/src/models/player_profile/injury.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';

/// Pantalla para buscar y seleccionar un ejercicio (compatible con Exercise V4/enums).
class SearchableExerciseListScreen extends ConsumerStatefulWidget {
  final PlayerProfile profile;
  const SearchableExerciseListScreen({super.key, required this.profile});

  @override
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
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// UI helper: "snake/camel" → "Bonito"
  String _pretty(String value) {
    final v = value
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .toLowerCase();
    return v
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  bool _containsQuery(String source, String q) {
    if (q.isEmpty) return true;
    return source.toLowerCase().contains(q);
  }

  /// Busca el query en múltiples campos/enums del ejercicio V4.
  bool _matchesSearch(Exercise ex, String q) {
    if (q.isEmpty) return true;
    final fields = <String>[
      ex.name,
      ex.slug,
      ex.categoryId.name,
      ex.movementPatternId.name,
      ...ex.qualityIds.map((e) => e.name),
      ...ex.vbTransferIds.map((e) => e.name),
      ...ex.equipmentIds.map((e) => e.name),
    ];
    return fields.any((f) => f.toLowerCase().contains(q));
  }

  /// Compara lesiones activas del perfil con contraindicaciones del ejercicio (por enum.name).
  bool _passesInjurySafety(Exercise ex, Set<String> activeInjuryIds) {
    if (activeInjuryIds.isEmpty) return true;

    // Normaliza lesiones activas (acepta "rodilla" y "contra_rodilla").
    final normalizedInj = <String>{};
    for (final id in activeInjuryIds) {
      final s = id.toLowerCase().trim();
      normalizedInj.add(s);
      if (s.startsWith('contra_')) {
        normalizedInj.add(s.replaceFirst('contra_', ''));
      } else {
        normalizedInj.add('contra_$s');
      }
    }

    // Compara con las contraindicaciones por name del enum
    final contras = ex.contraindicationIds
        .map((c) => c.name.toLowerCase())
        .toSet();
    // Si hay intersección, NO pasa
    return contras.intersection(normalizedInj).isEmpty;
  }

  /// Diálogo para añadir series, reps e intensidad (RPE/%/kg) y devolver WorkoutExercise.
  Future<void> _showAddExerciseDialog(Exercise exercise) async {
    final theme = Theme.of(context);
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '8-10'); // 10 o 8-10
    final intensityCtrl = TextEditingController(
      text: 'RPE 7',
    ); // RPE 7 / 80% / 100kg

    final result = await showDialog<WorkoutExercise>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            exercise.name,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
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
                decoration: const InputDecoration(
                  labelText: 'Repeticiones (Ej: 10 o 8-10)',
                ),
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
                // 1) Parseo de reps
                final String oldReps = repsCtrl.text.trim();
                if (oldReps.contains('-')) {
                  final parts = oldReps.split('-');
                } else {
                }

                // 3) Crear objeto WorkoutExercise
                String formatReps(WorkoutExercise ex) {
                  final min = ex.reps.min;
                  final max = ex.reps.max;
                  if (max == 0 || max == min) return '$min';
                  return '$min-$max';
                }

                Navigator.of(context, rootNavigator: true).pop(formatReps);
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );

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
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o palabra clave...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _searchController.clear(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error al cargar: $e')),
              data: (allExercises) {
                // Lesiones activas del perfil
                final activeInjuryIds = widget.profile.injuries
                    .where((i) => i.status == InjuryStatus.active)
                    .map((i) => i.id) // asegúrate que Injury.id es String
                    .toSet();

                // Filtrado por búsqueda + seguridad (lesiones/contraindicaciones)
                final filteredList = allExercises.where((ex) {
                  final matchesSearch = _matchesSearch(ex, _searchQuery);
                  final safe = _passesInjurySafety(ex, activeInjuryIds);
                  return matchesSearch && safe;
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron ejercicios.'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final ex = filteredList[index];
                    final category = _pretty(ex.categoryId.name);
                    final level = _pretty(ex.levelId.name);

                    return ListTile(
                      title: Text(ex.name),
                      subtitle: Text('$category • $level'),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => _showAddExerciseDialog(ex),
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
