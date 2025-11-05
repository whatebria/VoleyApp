import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/providers/providers.dart';
// ^ Debe exponer: exercisesProvider (AsyncValue<List<Exercise>>)
// y los mapas de etiquetas (id -> label) opcionales:
//   exerciseCategoryLabelsProvider: Provider<Map<String, String>>
//   exerciseLevelLabelsProvider:    Provider<Map<String, String>>
//   exerciseEquipmentLabelsProvider:Provider<Map<String, String>>
//   exerciseTagLabelsProvider:      Provider<Map<String, String>>

// =====================================================
// 1) Estado del Filtro (ahora con IDs)
// =====================================================

@immutable
class ExerciseFilterState {
  // Usamos un sentinel para "Todos"
  static const String allOptionId = '__all__';

  final String searchQuery; // texto libre
  final String selectedCategoryId; // categoryId o allOptionId
  final String selectedLevelId; // levelId    o allOptionId
  final Set<String>
  selectedEquipmentIds; // equipmentIds requeridos (conjunción)

  const ExerciseFilterState({
    this.searchQuery = '',
    this.selectedCategoryId = allOptionId,
    this.selectedLevelId = allOptionId,
    this.selectedEquipmentIds = const {},
  });

  ExerciseFilterState copyWith({
    String? searchQuery,
    String? selectedCategoryId,
    String? selectedLevelId,
    Set<String>? selectedEquipmentIds,
  }) {
    return ExerciseFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedLevelId: selectedLevelId ?? this.selectedLevelId,
      selectedEquipmentIds: selectedEquipmentIds ?? this.selectedEquipmentIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseFilterState &&
        other.searchQuery == searchQuery &&
        other.selectedCategoryId == selectedCategoryId &&
        other.selectedLevelId == selectedLevelId &&
        const SetEquality<String>().equals(
          other.selectedEquipmentIds,
          selectedEquipmentIds,
        );
  }

  @override
  int get hashCode =>
      searchQuery.hashCode ^
      selectedCategoryId.hashCode ^
      selectedLevelId.hashCode ^
      const SetEquality<String>().hash(selectedEquipmentIds);

  get selectedEquipment => null;
}

// =====================================================
// 2) StateNotifier
// =====================================================

class ExerciseFilterNotifier extends StateNotifier<ExerciseFilterState> {
  ExerciseFilterNotifier() : super(const ExerciseFilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim().toLowerCase());
  }

  void setCategoryId(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  void setLevelId(String levelId) {
    state = state.copyWith(selectedLevelId: levelId);
  }

  // ✅ Método principal que trabaja con IDs
  void toggleEquipmentId(String equipmentId) {
    final next = Set<String>.from(state.selectedEquipmentIds);
    if (next.contains(equipmentId)) {
      next.remove(equipmentId);
    } else {
      next.add(equipmentId);
    }
    state = state.copyWith(selectedEquipmentIds: next);
  }

  // ✅ Alias para compatibilidad con el nombre anterior
  void toggleEquipment(String equipmentId) => toggleEquipmentId(equipmentId);

  void clearEquipment() {
    state = state.copyWith(selectedEquipmentIds: {});
  }

  void clearFilters() {
    state = const ExerciseFilterState();
  }
}

// =====================================================
// 3) Provider del filtro
// =====================================================

final exerciseFilterProvider =
    StateNotifierProvider<ExerciseFilterNotifier, ExerciseFilterState>(
      (ref) => ExerciseFilterNotifier(),
    );

// =====================================================
// 4) Helpers para opciones (id -> label)
// =====================================================

String _labelOrId(Map<String, String> labels, String id) {
  final lbl = labels[id];
  if (lbl == null || lbl.trim().isEmpty) return id;
  return lbl;
}

List<MapEntry<String, String>> _entriesFromIds(
  Iterable<String> ids,
  Map<String, String> labels,
) {
  final unique = ids.toSet().toList();
  unique.sort((a, b) => _labelOrId(labels, a).compareTo(_labelOrId(labels, b)));
  return unique.map((id) => MapEntry(id, _labelOrId(labels, id))).toList();
}

// =====================================================
// 5) Providers Derivados para opciones del filtro
//    (se basan en ejercicios disponibles + mapas de etiquetas)
// =====================================================

final exerciseCategoriesProvider = Provider<List<MapEntry<String, String>>>((
  ref,
) {
  final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
  final labels = ref.watch(
    exerciseCategoryLabelsProvider,
  ); // Map<String, String>
  final ids = exercises.map((e) => e.categoryId);
  return _entriesFromIds(ids, labels);
});

final exerciseLevelsProvider = Provider<List<MapEntry<String, String>>>((ref) {
  final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
  final labels = ref.watch(exerciseLevelLabelsProvider); // Map<String, String>
  final ids = exercises.map((e) => e.levelId);
  return _entriesFromIds(ids, labels);
});

final exerciseEquipmentProvider = Provider<List<MapEntry<String, String>>>((
  ref,
) {
  final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
  final labels = ref.watch(
    exerciseEquipmentLabelsProvider,
  ); // Map<String, String>
  final ids = exercises.expand((e) => e.equipmentIds);
  return _entriesFromIds(ids, labels);
});

// =====================================================
// 6) Lista filtrada
// =====================================================

final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final allExercises = ref.watch(exercisesProvider).valueOrNull ?? [];
  final filters = ref.watch(exerciseFilterProvider);
  final tagLabels = ref.watch(exerciseTagLabelsProvider); // Map<String, String>

  // Si está en estado por defecto -> retorna todo
  if (filters == const ExerciseFilterState()) {
    return allExercises;
  }

  final q = filters.searchQuery;
  final hasQuery = q.isNotEmpty;

  return allExercises.where((ex) {
    // 1) Búsqueda por nombre y tags (usando labels si existen)
    final nameMatch = !hasQuery ? true : ex.name.toLowerCase().contains(q);

    final tagTexts = ex.tagIds
        .map((id) => _labelOrId(tagLabels, id).toLowerCase())
        .toList();

    final tagMatch = !hasQuery ? true : tagTexts.any((t) => t.contains(q));

    final matchesSearch = nameMatch || tagMatch;

    // 2) Categoría (por ID)
    final matchesCategory =
        filters.selectedCategoryId == ExerciseFilterState.allOptionId ||
        ex.categoryId == filters.selectedCategoryId;

    // 3) Nivel (por ID)
    final matchesLevel =
        filters.selectedLevelId == ExerciseFilterState.allOptionId ||
        ex.levelId == filters.selectedLevelId;

    // 4) Equipamiento: todos los seleccionados deben estar presentes
    final exerciseEquip = ex.equipmentIds.toSet();
    final requiredEquip = filters.selectedEquipmentIds;
    final matchesEquipment =
        requiredEquip.isEmpty || exerciseEquip.containsAll(requiredEquip);

    return matchesSearch && matchesCategory && matchesLevel && matchesEquipment;
  }).toList();
});
