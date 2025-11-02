// lib/src/screens/exercise_library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({Key? key}) : super(key: key);

  @override
  _ExerciseLibraryScreenState createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    // 1. Observa el FutureProvider de ejercicios
    final exercisesAsync = ref.watch(exercisesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de Ejercicios'),
      ),
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
              error: (e, s) => Center(child: Text('Error al cargar ejercicios: $e')),
              data: (allExercises) {
                
                // 4. Lógica de Filtrado
                final filteredList = allExercises.where((ex) {
                  // Si no hay búsqueda, muestra todo
                  if (_searchQuery.isEmpty) return true;
                  
                  // Busca en el nombre
                  final nameMatch = ex.name.toLowerCase().contains(_searchQuery);
                  
                  // Busca en los tags
                  final tagMatch = ex.tags.any(
                    (tag) => tag.toLowerCase().contains(_searchQuery)
                  );
                  
                  return nameMatch || tagMatch;
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Text('No se encontraron ejercicios.'));
                }

                // 5. Lista de Resultados
                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(exercise.category),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            exercise.level.substring(0, 1).toUpperCase(),
                            style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
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
                                // Muestra los tags como "chips"
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: exercise.tags
                                      .map((tag) => Chip(label: Text(tag)))
                                      .toList(),
                                ),
                                const Divider(height: 20),
                                // Muestra el equipamiento
                                Text(
                                  'Equipamiento: ${exercise.equipment.join(', ')}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
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