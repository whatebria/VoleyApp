import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/exercise_filter_provider.dart';
import 'package:voley_app/providers/providers.dart';

class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  static const String _allOption = ExerciseFilterState.allOptionId;

  // Limpia filtros vía provider
  void _clearFilters(WidgetRef ref) {
    ref.read(exerciseFilterProvider.notifier).clearFilters();
  }

  // Formatea "snake/camel" -> "Bonito"
  String _formatOptionLabel(String value) {
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

  // Mapea lista de enums a chips
  List<Widget> _enumListToChips<T>(Iterable<T> enums) {
    return enums
        .map((e) => Chip(label: Text(_formatOptionLabel(e.toString().split('.').last))))
        .toList();
  }

  // Un solo chip
  Widget _enumToChip<T>(T e) {
    return Chip(label: Text(_formatOptionLabel(e.toString().split('.').last)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) Datos
    final exercisesAsync = ref.watch(exercisesProvider);            // carga remota
    final filteredList = ref.watch(filteredExercisesProvider);      // lista filtrada

    // 2) Estado de filtros
    final filterState = ref.watch(exerciseFilterProvider);
    final theme = Theme.of(context);

    // 3) Opciones de filtros (claves String = enum.name)
    final categoryEntries = ref.watch(exerciseCategoriesProvider);  // List<MapEntry<key,value>>
    final levelEntries = ref.watch(exerciseLevelsProvider);
    final equipmentEntries = ref.watch(exerciseEquipmentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca de Ejercicios')),
      body: Column(
        children: [
          // Búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o palabra clave...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: filterState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
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

          // Lista
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error al cargar ejercicios: $e')),
              data: (allExercises) {
                // Si cambian opciones (por ejemplo, primera carga), asegura IDs válidos
                final selectedCategoryIdKey = filterState.selectedCategoryId;
                if (selectedCategoryIdKey != _allOption &&
                    !categoryEntries.any((e) => e.key == selectedCategoryIdKey)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(exerciseFilterProvider.notifier).setCategoryId(_allOption);
                  });
                }
                final selectedLevelIdKey = filterState.selectedLevelId;
                if (selectedLevelIdKey != _allOption &&
                    !levelEntries.any((e) => e.key == selectedLevelIdKey)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(exerciseFilterProvider.notifier).setLevelId(_allOption);
                  });
                }
                // (Opcional) validar equipamiento seleccionado contra entries

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

                                // NOTA: exercise es V4 con enums (en tu código se llama Exercise)
                                final levelLabel = _formatOptionLabel(exercise.levelId.name);
                                final categoryLabel = _formatOptionLabel(exercise.categoryId.name);

                                final equipmentLabels = exercise.equipmentIds
                                    .map((e) => _formatOptionLabel(e.name))
                                    .toList();

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ExpansionTile(
                                    title: Text(
                                      exercise.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(categoryLabel),
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Text(
                                        levelLabel.characters.first.toUpperCase(),
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(exercise.description),
                                            const SizedBox(height: 12),

                                            // Chips informativos (V4)
                                            Wrap(
                                              spacing: 8.0,
                                              runSpacing: 4.0,
                                              children: [
                                                _enumToChip(exercise.movementPatternId),
                                                ..._enumListToChips(exercise.qualityIds),
                                                ..._enumListToChips(exercise.vbTransferIds),
                                              ],
                                            ),

                                            const Divider(height: 20),
                                            Text(
                                              equipmentLabels.isEmpty
                                                  ? 'Equipamiento: —'
                                                  : 'Equipamiento: ${equipmentLabels.join(', ')}',
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

  // Tarjeta de filtros
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
    final extraEquipment = selectedEquipmentLabels.length - truncatedEquipment.length;
    final equipmentSummary =
        truncatedEquipment.join(', ') + (extraEquipment > 0 ? ' +$extraEquipment' : '');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              'Filtros',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            trailing: TextButton.icon(
              onPressed: (filterState == const ExerciseFilterState())
                  ? null
                  : () => _clearFilters(ref),
              icon: const Icon(Icons.refresh),
              label: const Text('Limpiar'),
            ),
          ),
          const Divider(height: 1),

          // Categoría
          ExpansionTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categoría'),
            subtitle: Text(resolveLabel(filterState.selectedCategoryId, categoryEntries)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              RadioListTile<String>(
                title: const Text('Todos'),
                value: _allOption,
                groupValue: filterState.selectedCategoryId,
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(exerciseFilterProvider.notifier).setCategoryId(value);
                },
              ),
              ...categoryEntries.map(
                (entry) => RadioListTile<String>(
                  title: Text(_formatOptionLabel(entry.value)),
                  value: entry.key,
                  groupValue: filterState.selectedCategoryId,
                  onChanged: (value) {
                    if (value == null) return;
                    ref.read(exerciseFilterProvider.notifier).setCategoryId(value);
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 1),

          // Nivel
          ExpansionTile(
            leading: const Icon(Icons.fitness_center_outlined),
            title: const Text('Nivel'),
            subtitle: Text(resolveLabel(filterState.selectedLevelId, levelEntries)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              RadioListTile<String>(
                title: const Text('Todos'),
                value: _allOption,
                groupValue: filterState.selectedLevelId,
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(exerciseFilterProvider.notifier).setLevelId(value);
                },
              ),
              ...levelEntries.map(
                (entry) => RadioListTile<String>(
                  title: Text(_formatOptionLabel(entry.value)),
                  value: entry.key,
                  groupValue: filterState.selectedLevelId,
                  onChanged: (value) {
                    if (value == null) return;
                    ref.read(exerciseFilterProvider.notifier).setLevelId(value);
                  },
                ),
              ),
            ],
          ),

          // Equipamiento (opcional)
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
                    if (value == null) return;
                    if (value) {
                      ref.read(exerciseFilterProvider.notifier).clearEquipment();
                    }
                  },
                ),
                ...equipmentEntries.map((entry) {
                  final key = entry.key; // string: enum.name
                  final isSelected = filterState.selectedEquipment.contains(key);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(_formatOptionLabel(entry.value)),
                    onChanged: (selected) {
                      if (selected == null) return;
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
