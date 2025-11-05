import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/exercise_filter_provider.dart';
import 'package:voley_app/providers/providers.dart';

// --- CAMBIO: Convertido a ConsumerWidget ---
class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  static const String _allOption = ExerciseFilterState.allOption;


  // --- CAMBIO: _clearFilters ahora llama al provider ---
  void _clearFilters(WidgetRef ref) {
    ref.read(exerciseFilterProvider.notifier).clearFilters();
  }

  // --- CAMBIO: _formatOptionLabel se mantiene como helper ---
  String _formatOptionLabel(String value) {
    final words = value.split(' ');
    return words
        .map((word) {
          if (word.isEmpty) return word;
          final lower = word.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observa la lista de ejercicios YA FILTRADA
    final exercisesAsync = ref.watch(exercisesProvider);
    final filteredList = ref.watch(filteredExercisesProvider);
    
    // 2. Observa el estado del filtro para la UI
    final filterState = ref.watch(exerciseFilterProvider);
    final theme = Theme.of(context);
    
    // 3. Observa los providers de opciones de filtros
    final categoryEntries = ref.watch(exerciseCategoriesProvider);
    final levelEntries = ref.watch(exerciseLevelsProvider);
    final equipmentEntries = ref.watch(exerciseEquipmentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca de Ejercicios')),
      body: Column(
        children: [
          // 2. Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              // --- CAMBIO: Se usa onChanged para notificar al provider ---
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o tag...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: filterState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          // Llama al provider para limpiar la búsqueda
                          ref.read(exerciseFilterProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(exerciseFilterProvider.notifier).setSearchQuery(value);
              },
            ),
          ),

          // 3. Lista de Ejercicios (manejada por el provider)
          Expanded(
            // --- CAMBIO: Se usa exercisesAsync solo para el wrapper .when ---
            // La lista real (filteredList) viene del provider filtrado.
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Center(child: Text('Error al cargar ejercicios: $e')),
              data: (allExercises) {
                // --- CAMBIO: Toda la lógica de filtrado se ha movido ---
                
                // Resetea los filtros si los datos cambian (ej. por un refresh)
                final selectedCategoryKey = filterState.selectedCategory;
                if (selectedCategoryKey != _allOption &&
                    !categoryEntries.any((e) => e.key == selectedCategoryKey)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(exerciseFilterProvider.notifier).setCategory(_allOption);
                  });
                }
                
                // (Lógica similar para level y equipment)
                
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildFiltersCard(
                        context,
                        ref,
                        theme,
                        categoryEntries,
                        levelEntries,
                        equipmentEntries,
                        filterState,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filteredList.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron ejercicios con los filtros seleccionados.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final exercise = filteredList[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ExpansionTile(
                                    title: Text(
                                      exercise.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(exercise.category),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          theme.colorScheme.primaryContainer,
                                      child: Text(
                                        exercise.level
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(exercise.description),
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 8.0,
                                              runSpacing: 4.0,
                                              children: exercise.tags
                                                  .map(
                                                    (tag) =>
                                                        Chip(label: Text(tag)),
                                                  )
                                                  .toList(),
                                            ),
                                            const Divider(height: 20),
                                            Text(
                                              'Equipamiento: ${exercise.equipment.join(', ')}',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- CAMBIO: El widget de filtros ahora recibe 'ref' y 'filterState' ---
  Widget _buildFiltersCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<MapEntry<String, String>> categoryEntries,
    List<MapEntry<String, String>> levelEntries,
    List<MapEntry<String, String>> equipmentEntries,
    ExerciseFilterState filterState,
  ) {
    String resolveLabel(String key, List<MapEntry<String, String>> entries) {
      if (key == _allOption) return 'Todos';
      final entry = entries.firstWhere(
        (element) => element.key == key,
        orElse: () => MapEntry(key, key),
      );
      return _formatOptionLabel(entry.value);
    }

    final selectedEquipmentLabels = filterState.selectedEquipment.map((key) {
      final entry = equipmentEntries.firstWhere(
        (element) => element.key == key,
        orElse: () => MapEntry(key, key),
      );
      return _formatOptionLabel(entry.value);
    }).toList();
    final truncatedEquipment = selectedEquipmentLabels.take(3).toList();
    final extraEquipment =
        selectedEquipmentLabels.length - truncatedEquipment.length;
    final equipmentSummary =
        truncatedEquipment.join(', ') +
        (extraEquipment > 0 ? ' +$extraEquipment' : '');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              'Filtros',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: TextButton.icon(
              onPressed:
                  (filterState == const ExerciseFilterState())
                  ? null
                  : () => _clearFilters(ref), // --- CAMBIO ---
              icon: const Icon(Icons.refresh),
              label: const Text('Limpiar'),
            ),
          ),
          const Divider(height: 1),
          ExpansionTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categoría'),
            subtitle: Text(resolveLabel(filterState.selectedCategory, categoryEntries)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              RadioListTile<String>(
                title: const Text('Todos'),
                value: _allOption,
                groupValue: filterState.selectedCategory,
                onChanged: (value) {
                  // --- CAMBIO ---
                  if (value == null) return;
                  ref.read(exerciseFilterProvider.notifier).setCategory(value);
                },
              ),
              ...categoryEntries.map(
                (entry) => RadioListTile<String>(
                  title: Text(_formatOptionLabel(entry.value)),
                  value: entry.key,
                  groupValue: filterState.selectedCategory,
                  onChanged: (value) {
                    // --- CAMBIO ---
                    if (value == null) return;
                    ref.read(exerciseFilterProvider.notifier).setCategory(value);
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          ExpansionTile(
            leading: const Icon(Icons.fitness_center_outlined),
            title: const Text('Nivel'),
            subtitle: Text(resolveLabel(filterState.selectedLevel, levelEntries)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              RadioListTile<String>(
                title: const Text('Todos'),
                value: _allOption,
                groupValue: filterState.selectedLevel,
                onChanged: (value) {
                  // --- CAMBIO ---
                  if (value == null) return;
                  ref.read(exerciseFilterProvider.notifier).setLevel(value);
                },
              ),
              ...levelEntries.map(
                (entry) => RadioListTile<String>(
                  title: Text(_formatOptionLabel(entry.value)),
                  value: entry.key,
                  groupValue: filterState.selectedLevel,
                  onChanged: (value) {
                    // --- CAMBIO ---
                    if (value == null) return;
                    ref.read(exerciseFilterProvider.notifier).setLevel(value);
                  },
                ),
              ),
            ],
          ),
          if (equipmentEntries.isNotEmpty) ...[
            const Divider(height: 1),
            ExpansionTile(
              leading: const Icon(Icons.handyman_outlined),
              title: const Text('Equipamiento'),
              subtitle: Text(
                filterState.selectedEquipment.isEmpty
                    ? 'Todos'
                    : '${filterState.selectedEquipment.length} seleccionado(s): $equipmentSummary',
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                CheckboxListTile(
                  title: const Text('Todos'),
                  value: filterState.selectedEquipment.isEmpty,
                  onChanged: (value) {
                    // --- CAMBIO ---
                    if (value == null) return;
                    if (value) {
                      ref.read(exerciseFilterProvider.notifier).clearEquipment();
                    }
                  },
                ),
                ...equipmentEntries.map((entry) {
                  final key = entry.key;
                  final isSelected = filterState.selectedEquipment.contains(key);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(_formatOptionLabel(entry.value)),
                    onChanged: (selected) {
                      // --- CAMBIO ---
                      ref.read(exerciseFilterProvider.notifier).toggleEquipment(key);
                    },
                  );
                }).toList(),
              ],
            ),
          ],
        ],
      ),
    );
  }
}