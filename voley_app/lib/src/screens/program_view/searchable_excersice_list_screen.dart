import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/player_profile/injury.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:voley_app/src/screens/program_view/workout_exercise_editor_screen.dart';

// Enums
import 'package:voley_app/src/catalogos/enums.dart';

class SearchableExerciseListScreen extends ConsumerStatefulWidget {
  final PlayerProfile profile;
  const SearchableExerciseListScreen({super.key, required this.profile});

  @override
  ConsumerState<SearchableExerciseListScreen> createState() =>
      _SearchableExerciseListScreenState();
}

class _SearchableExerciseListScreenState
    extends ConsumerState<SearchableExerciseListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Filtros clave para entrenador en móvil
  CategoryId? _filterCategory;
  VolleyballTransferId? _filterVbTransfer;
  LevelId? _filterLevel;

  bool get _hasFilters =>
      _filterCategory != null || _filterVbTransfer != null || _filterLevel != null;

  int get _activeFiltersCount {
    int c = 0;
    if (_filterCategory != null) c++;
    if (_filterVbTransfer != null) c++;
    if (_filterLevel != null) c++;
    return c;
  }

  void _clearFilters() {
    setState(() {
      _filterCategory = null;
      _filterVbTransfer = null;
      _filterLevel = null;
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

  /// "snake_case" / camelCase → "Bonito"
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

  bool _matchesSearch(Exercise ex, String q) {
    if (q.isEmpty) return true;
    final fields = <String>[
      ex.name,
      ex.slug,
      ex.categoryId.name,
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

    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          _hasFilters ? 'Filtros ($_activeFiltersCount activos)' : 'Filtros',
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          _hasFilters
              ? 'Toca "Limpiar" para ver todos los ejercicios'
              : 'Opcional · Filtra si lo necesitas',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // OBJETIVO (Categoría)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('¿Qué quieres trabajar?', style: labelStyle),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
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

          // TRANSFERENCIA AL VÓLEY
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Transferencia en cancha', style: labelStyle),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
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

          // NIVEL
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Nivel del ejercicio', style: labelStyle),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
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
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _hasFilters ? _clearFilters : null,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Limpiar filtros'),
            ),
          ),
        ],
      ),
    );
  }

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final exercisesAsync = ref.watch(exercisesProvider);

  return Scaffold(
    resizeToAvoidBottomInset: true, // <-- IMPORTANTE PARA TECLADO
    appBar: AppBar(
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Buscar ejercicio...',
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        style: TextStyle(color: theme.colorScheme.onSurface),
        textInputAction: TextInputAction.search,
      ),
      actions: [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _searchController.clear(),
          ),
      ],
    ),

    body: SafeArea(
      child: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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

            final byCategory = _filterCategory == null ||
                ex.categoryId == _filterCategory;
            final byTransfer = _filterVbTransfer == null ||
                ex.vbTransferIds.contains(_filterVbTransfer);
            final byLevel = _filterLevel == null ||
                ex.levelId == _filterLevel;

            return search && safe && byCategory && byTransfer && byLevel;
          }).toList();

          return CustomScrollView(
            slivers: [

              // ---------- FILTROS COMO SLIVER ----------
              SliverToBoxAdapter(
                child: _buildFilters(theme),
              ),

              const SliverPadding(
                padding: EdgeInsets.only(top: 8),
              ),

              // ---------- LISTA ----------
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'No se encontraron ejercicios.\n'
                        'Prueba quitando filtros o cambiando la búsqueda.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ex = filtered[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          ex.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${_pretty(ex.categoryId.name)} • ${_pretty(ex.levelId.name)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => _showAddExerciseDialog(ex),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

}
