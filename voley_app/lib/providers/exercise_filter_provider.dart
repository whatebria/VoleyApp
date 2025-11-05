import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/providers/providers.dart'; // Para exercisesProvider

// --- 1. Definición del Estado del Filtro ---

@immutable
class ExerciseFilterState {
  static const String allOption = 'Todos';

  final String searchQuery;
  final String selectedCategory;
  final String selectedLevel;
  final Set<String> selectedEquipment;

  const ExerciseFilterState({
    this.searchQuery = '',
    this.selectedCategory = allOption,
    this.selectedLevel = allOption,
    this.selectedEquipment = const {},
  });

  ExerciseFilterState copyWith({
    String? searchQuery,
    String? selectedCategory,
    String? selectedLevel,
    Set<String>? selectedEquipment,
  }) {
    return ExerciseFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
    );
  }
}

// --- 2. El StateNotifier ---

class ExerciseFilterNotifier extends StateNotifier<ExerciseFilterState> {
  // Inicializa el estado
  ExerciseFilterNotifier() : super(const ExerciseFilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.toLowerCase());
  }

  void setCategory(String categoryKey) {
    state = state.copyWith(selectedCategory: categoryKey);
  }

  void setLevel(String levelKey) {
    state = state.copyWith(selectedLevel: levelKey);
  }

  void toggleEquipment(String equipmentKey) {
    final newSet = Set<String>.from(state.selectedEquipment);
    if (newSet.contains(equipmentKey)) {
      newSet.remove(equipmentKey);
    } else {
      newSet.add(equipmentKey);
    }
    state = state.copyWith(selectedEquipment: newSet);
  }

  void clearEquipment() {
    state = state.copyWith(selectedEquipment: {});
  }

  void clearFilters() {
    state = const ExerciseFilterState();
  }
}

// --- 3. El Provider ---

final exerciseFilterProvider =
    StateNotifierProvider<ExerciseFilterNotifier, ExerciseFilterState>(
  (ref) => ExerciseFilterNotifier(),
);

// --- 4. Providers Derivados (para las opciones del filtro) ---

// Un helper para formatear y ordenar
List<MapEntry<String, String>> _createFilterMap(
    List<Exercise> exercises, String Function(Exercise) getKey, String Function(Exercise) getValue) {
  final map = <String, String>{};
  for (final exercise in exercises) {
    final key = getKey(exercise).trim().toLowerCase();
    final value = getValue(exercise).trim();
    if (key.isNotEmpty && value.isNotEmpty) {
      map.putIfAbsent(key, () => value);
    }
  }
  final entries = map.entries.toList();
  entries.sort((a, b) => a.value.compareTo(b.value));
  return entries;
}

final exerciseCategoriesProvider = Provider<List<MapEntry<String, String>>>((ref) {
  final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
  return _createFilterMap(exercises, (e) => e.category, (e) => e.category);
});

final exerciseLevelsProvider = Provider<List<MapEntry<String, String>>>((ref) {
  final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
  return _createFilterMap(exercises, (e) => e.level, (e) => e.level);
});

final exerciseEquipmentProvider = Provider<List<MapEntry<String, String>>>((ref) {
  final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
  final map = <String, String>{};
  for (final exercise in exercises) {
    for (final eq in exercise.equipment) {
      final key = eq.trim().toLowerCase();
      final value = eq.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        map.putIfAbsent(key, () => value);
      }
    }
  }
  final entries = map.entries.toList();
  entries.sort((a, b) => a.value.compareTo(b.value));
  return entries;
});


// --- 5. El Provider de la Lista Filtrada ---

final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  // Observa la lista completa de ejercicios
  final allExercises = ref.watch(exercisesProvider).valueOrNull ?? [];
  // Observa el estado actual de los filtros
  final filters = ref.watch(exerciseFilterProvider);

  // Si no hay filtros, devuelve la lista completa
  if (filters == const ExerciseFilterState()) {
    return allExercises;
  }

  // Aplica la lógica de filtrado
  return allExercises.where((ex) {
    // 1. Filtrar por Búsqueda (Nombre o Tag)
    final query = filters.searchQuery;
    final nameMatch = query.isEmpty 
      ? true 
      : ex.name.toLowerCase().contains(query);
    final tagMatch = query.isEmpty 
      ? true 
      : ex.tags.any((tag) => tag.toLowerCase().contains(query));
    final matchesSearch = nameMatch || tagMatch;

    // 2. Filtrar por Categoría
    final categoryKey = ex.category.trim().toLowerCase();
    final matchesCategory =
        filters.selectedCategory == ExerciseFilterState.allOption ||
        categoryKey == filters.selectedCategory;

    // 3. Filtrar por Nivel
    final levelKey = ex.level.trim().toLowerCase();
    final matchesLevel =
        filters.selectedLevel == ExerciseFilterState.allOption ||
        levelKey == filters.selectedLevel;

    // 4. Filtrar por Equipamiento
    final equipmentKeys = ex.equipment.map((e) => e.trim().toLowerCase()).toSet();
    final matchesEquipment =
        filters.selectedEquipment.isEmpty ||
        filters.selectedEquipment.every(
          (key) => equipmentKeys.contains(key),
        );

    // Devuelve true solo si todas las condiciones se cumplen
    return matchesSearch &&
        matchesCategory &&
        matchesLevel &&
        matchesEquipment;
  }).toList();
});