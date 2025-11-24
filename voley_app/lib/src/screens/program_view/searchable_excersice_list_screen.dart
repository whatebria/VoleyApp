import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/player_profile/injury.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:voley_app/src/screens/program_view/workout_exercise_editor_screen.dart';

// Importa enums
import 'package:voley_app/src/catalogos/enums.dart';

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

  // Filtros
  LevelId? _filterLevel;
  CategoryId? _filterCategory;
  MovementPatternId? _filterPattern;
  VolleyballTransferId? _filterVbTransfer;

  bool get _hasFilters =>
      _filterLevel != null ||
      _filterCategory != null ||
      _filterPattern != null ||
      _filterVbTransfer != null;

  int get _activeFiltersCount {
    int c = 0;
    if (_filterLevel != null) c++;
    if (_filterCategory != null) c++;
    if (_filterPattern != null) c++;
    if (_filterVbTransfer != null) c++;
    return c;
  }

  void _clearFilters() {
    setState(() {
      _filterLevel = null;
      _filterCategory = null;
      _filterPattern = null;
      _filterVbTransfer = null;
    });
  }

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

  String _pretty(String value) {
    final v = value
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .toLowerCase();
    return v
        .split(' ')
        .map((w) => w.isNotEmpty
            ? w[0].toUpperCase() + w.substring(1)
            : '')
        .join(' ');
  }

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

  bool _passesInjurySafety(Exercise ex, Set<String> activeInj) {
    if (activeInj.isEmpty) return true;

    final norm = <String>{};
    for (final id in activeInj) {
      final s = id.toLowerCase().trim();
      norm.add(s);
      if (s.startsWith("contra_")) {
        norm.add(s.replaceFirst("contra_", ""));
      } else {
        norm.add("contra_$s");
      }
    }

    final contras =
        ex.contraindicationIds.map((c) => c.name.toLowerCase()).toSet();

    return contras.intersection(norm).isEmpty;
  }

  Future<void> _showAddExerciseDialog(Exercise ex) async {
    final result = await Navigator.push<WorkoutExercise>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutExerciseEditorScreen(
          exerciseId: ex.id,
          exerciseName: ex.name,
        ),
      ),
    );
    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  Widget _buildFilters(ThemeData theme) {
    final labelStyle = theme.textTheme.labelMedium;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        _hasFilters ? 'Filtros ($_activeFiltersCount activos)' : 'Filtros',
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        _hasFilters ? 'Toca "Limpiar" para volver a ver todo'
                    : 'Sin filtros aplicados',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      childrenPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // NIVEL
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Nivel', style: labelStyle),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: LevelId.values.map((level) {
            final selected = _filterLevel == level;
            return ChoiceChip(
              label: Text(_pretty(level.name)),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _filterLevel = selected ? null : level;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // CATEGORÍA
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Categoría', style: labelStyle),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: CategoryId.values.map((cat) {
            final selected = _filterCategory == cat;
            return ChoiceChip(
              label: Text(_pretty(cat.name)),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _filterCategory = selected ? null : cat;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // PATRÓN
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Patrón de movimiento', style: labelStyle),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: MovementPatternId.values.map((mp) {
            final selected = _filterPattern == mp;
            return ChoiceChip(
              label: Text(_pretty(mp.name)),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _filterPattern = selected ? null : mp;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // TRANSFERENCIA
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Transferencia al vóley', style: labelStyle),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: VolleyballTransferId.values.map((vt) {
            final selected = _filterVbTransfer == vt;
            return ChoiceChip(
              label: Text(_pretty(vt.name)),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _filterVbTransfer = selected ? null : vt;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _hasFilters ? _clearFilters : null,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Limpiar filtros'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(exercisesProvider);

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
          _buildFilters(theme),

          Expanded(
            child: exercisesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Center(child: Text('Error al cargar ejercicios: $e')),
              data: (allExercises) {
                final activeInj = widget.profile.injuries
                    .where((i) => i.status == InjuryStatus.active)
                    .map((i) => i.id)
                    .toSet();

                final filtered = allExercises.where((ex) {
                  final search = _matchesSearch(ex, _searchQuery);
                  final safe = _passesInjurySafety(ex, activeInj);

                  final fLevel =
                      _filterLevel == null || ex.levelId == _filterLevel;
                  final fCat =
                      _filterCategory == null || ex.categoryId == _filterCategory;
                  final fPat = _filterPattern == null ||
                      ex.movementPatternId == _filterPattern;
                  final fTransfer = _filterVbTransfer == null ||
                      ex.vbTransferIds.contains(_filterVbTransfer);

                  return search && safe && fLevel && fCat && fPat && fTransfer;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No se encontraron ejercicios.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final ex = filtered[i];
                    return ListTile(
                      title: Text(ex.name),
                      subtitle: Text(
                        '${_pretty(ex.categoryId.name)} • ${_pretty(ex.levelId.name)}',
                      ),
                      trailing:
                          const Icon(Icons.add_circle_outline, size: 26),
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
