// lib/src/screens/exercise_library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  _ExerciseLibraryScreenState createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  static const String _allOption = 'Todos';

  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryKey = _allOption;
  String _selectedLevelKey = _allOption;
  final Set<String> _selectedEquipmentKeys = {};

  @override
  void initState() {
    super.initState();
    // Escucha los cambios en la barra de búsqueda
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

  void _clearFilters() {
    setState(() {
      _selectedCategoryKey = _allOption;
      _selectedLevelKey = _allOption;
      _selectedEquipmentKeys.clear();
    });
  }

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
  Widget build(BuildContext context) {
    // 1. Observa el FutureProvider de ejercicios
    final exercisesAsync = ref.watch(exercisesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca de Ejercicios')),
      body: Column(
        children: [
          // 2. Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o tag...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // Añade un botón para limpiar la búsqueda
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 3. Lista de Ejercicios (manejada por el provider)
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Center(child: Text('Error al cargar ejercicios: $e')),
              data: (allExercises) {
                final categoryMap = <String, String>{};
                final levelMap = <String, String>{};
                final equipmentMap = <String, String>{};

                for (final exercise in allExercises) {
                  final category = exercise.category.trim();
                  final level = exercise.level.trim();

                  if (category.isNotEmpty) {
                    categoryMap.putIfAbsent(
                      category.toLowerCase(),
                      () => category,
                    );
                  }
                  if (level.isNotEmpty) {
                    levelMap.putIfAbsent(level.toLowerCase(), () => level);
                  }
                  for (final equipment in exercise.equipment) {
                    final eq = equipment.trim();
                    if (eq.isNotEmpty) {
                      equipmentMap.putIfAbsent(eq.toLowerCase(), () => eq);
                    }
                  }
                }

                final categoryEntries = categoryMap.entries.toList()
                  ..sort((a, b) => a.value.compareTo(b.value));
                final levelEntries = levelMap.entries.toList()
                  ..sort((a, b) => a.value.compareTo(b.value));
                final equipmentEntries = equipmentMap.entries.toList()
                  ..sort((a, b) => a.value.compareTo(b.value));

                String selectedCategoryKey = _selectedCategoryKey;
                if (selectedCategoryKey != _allOption &&
                    !categoryMap.containsKey(selectedCategoryKey)) {
                  selectedCategoryKey = _allOption;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => _selectedCategoryKey = _allOption);
                  });
                }

                String selectedLevelKey = _selectedLevelKey;
                if (selectedLevelKey != _allOption &&
                    !levelMap.containsKey(selectedLevelKey)) {
                  selectedLevelKey = _allOption;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => _selectedLevelKey = _allOption);
                  });
                }

                final activeEquipmentKeys = _selectedEquipmentKeys
                    .where((key) => equipmentMap.containsKey(key))
                    .toSet();
                if (activeEquipmentKeys.length !=
                    _selectedEquipmentKeys.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedEquipmentKeys
                        ..clear()
                        ..addAll(activeEquipmentKeys);
                    });
                  });
                }

                final filteredList = allExercises.where((ex) {
                  final query = _searchQuery;
                  final nameMatch = query.isEmpty
                      ? true
                      : ex.name.toLowerCase().contains(query);
                  final tagMatch = query.isEmpty
                      ? true
                      : ex.tags.any((tag) => tag.toLowerCase().contains(query));
                  final matchesSearch = nameMatch || tagMatch;

                  final categoryKey = ex.category.trim().toLowerCase();
                  final levelKey = ex.level.trim().toLowerCase();
                  final equipmentKeys = ex.equipment
                      .map((e) => e.trim().toLowerCase())
                      .toSet();

                  final matchesCategory =
                      selectedCategoryKey == _allOption ||
                      categoryKey == selectedCategoryKey;
                  final matchesLevel =
                      selectedLevelKey == _allOption ||
                      levelKey == selectedLevelKey;
                  final matchesEquipment =
                      activeEquipmentKeys.isEmpty ||
                      activeEquipmentKeys.every(
                        (key) => equipmentKeys.contains(key),
                      );

                  return matchesSearch &&
                      matchesCategory &&
                      matchesLevel &&
                      matchesEquipment;
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildFiltersCard(
                        theme,
                        categoryEntries,
                        levelEntries,
                        equipmentEntries,
                        selectedCategoryKey,
                        selectedLevelKey,
                        activeEquipmentKeys,
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

  Widget _buildFiltersCard(
    ThemeData theme,
    List<MapEntry<String, String>> categoryEntries,
    List<MapEntry<String, String>> levelEntries,
    List<MapEntry<String, String>> equipmentEntries,
    String selectedCategoryKey,
    String selectedLevelKey,
    Set<String> activeEquipmentKeys,
  ) {
    String resolveLabel(String key, List<MapEntry<String, String>> entries) {
      if (key == _allOption) return 'Todos';
      final entry = entries.firstWhere(
        (element) => element.key == key,
        orElse: () => MapEntry(key, key),
      );
      return _formatOptionLabel(entry.value);
    }

    final selectedEquipmentLabels = activeEquipmentKeys.map((key) {
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
                  (_selectedCategoryKey == _allOption &&
                      _selectedLevelKey == _allOption &&
                      activeEquipmentKeys.isEmpty)
                  ? null
                  : _clearFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Limpiar'),
            ),
          ),
          const Divider(height: 1),
          ExpansionTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categoría'),
            subtitle: Text(resolveLabel(selectedCategoryKey, categoryEntries)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              RadioListTile<String>(
                title: const Text('Todos'),
                value: _allOption,
                groupValue: selectedCategoryKey,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedCategoryKey = value);
                },
              ),
              ...categoryEntries.map(
                (entry) => RadioListTile<String>(
                  title: Text(_formatOptionLabel(entry.value)),
                  value: entry.key,
                  groupValue: selectedCategoryKey,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedCategoryKey = value);
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          ExpansionTile(
            leading: const Icon(Icons.fitness_center_outlined),
            title: const Text('Nivel'),
            subtitle: Text(resolveLabel(selectedLevelKey, levelEntries)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              RadioListTile<String>(
                title: const Text('Todos'),
                value: _allOption,
                groupValue: selectedLevelKey,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedLevelKey = value);
                },
              ),
              ...levelEntries.map(
                (entry) => RadioListTile<String>(
                  title: Text(_formatOptionLabel(entry.value)),
                  value: entry.key,
                  groupValue: selectedLevelKey,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedLevelKey = value);
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
                activeEquipmentKeys.isEmpty
                    ? 'Todos'
                    : '${activeEquipmentKeys.length} seleccionado(s): $equipmentSummary',
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                CheckboxListTile(
                  title: const Text('Todos'),
                  value: activeEquipmentKeys.isEmpty,
                  onChanged: (value) {
                    if (value == null) return;
                    if (value) {
                      setState(() => _selectedEquipmentKeys.clear());
                    }
                  },
                ),
                ...equipmentEntries.map((entry) {
                  final key = entry.key;
                  final isSelected = activeEquipmentKeys.contains(key);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(_formatOptionLabel(entry.value)),
                    onChanged: (selected) {
                      setState(() {
                        if (selected ?? false) {
                          _selectedEquipmentKeys.add(key);
                        } else {
                          _selectedEquipmentKeys.remove(key);
                        }
                      });
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
