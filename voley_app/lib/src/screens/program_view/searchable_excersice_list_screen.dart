import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/player_profile/injury.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:voley_app/src/screens/program_view/workout_exercise_editor_screen.dart';
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
  Timer? _debounce;

  // Filtros
  CategoryId? _filterCategory;
  VolleyballTransferId? _filterVbTransfer;
  LevelId? _filterLevel;

  bool get _hasFilters =>
      _filterCategory != null ||
      _filterVbTransfer != null ||
      _filterLevel != null;

  int get _activeFiltersCount => [
    _filterCategory,
    _filterVbTransfer,
    _filterLevel,
  ].where((e) => e != null).length;

  // Atajos rápidos
  final List<CategoryId> _quickCategories = const [
    CategoryId.fuerza,
    CategoryId.potencia,
    CategoryId.pliometria,
    CategoryId.core,
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  void _clearFilters() {
    setState(() {
      _filterCategory = null;
      _filterVbTransfer = null;
      _filterLevel = null;
    });
  }

  // "snake_case" / camelCase → "Bonito"
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
      if (s.startsWith('contra_')) {
        norm.add(s.replaceFirst('contra_', ''));
      } else {
        norm.add('contra_$s');
      }
    }

    final contras = ex.contraindicationIds
        .map((c) => c.name.toLowerCase())
        .toSet();
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

  Future<void> _openFiltersSheet(ThemeData theme) async {
    final selectedCategory = _filterCategory;
    final selectedTransfer = _filterVbTransfer;
    final selectedLevel = _filterLevel;

    final result = await showModalBottomSheet<_FiltersResult>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FiltersSheet(
        initialCategory: selectedCategory,
        initialTransfer: selectedTransfer,
        initialLevel: selectedLevel,
        pretty: _pretty,
      ),
    );

    if (result == null) return;

    setState(() {
      _filterCategory = result.category;
      _filterVbTransfer = result.transfer;
      _filterLevel = result.level;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(exercisesProvider);

    final activeInj = widget.profile.injuries
        .where((i) => i.status == InjuryStatus.active)
        .map((i) => i.id)
        .toSet();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: _SearchBar(
            controller: _searchController,
            hint: 'Buscar ejercicio…',
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filtros',
            onPressed: () => _openFiltersSheet(theme),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list_rounded),
                if (_activeFiltersCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        '$_activeFiltersCount',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            _QuickFiltersRow(
              categories: _quickCategories,
              current: _filterCategory,
              pretty: _pretty,
              onTap: (c) => setState(() {
                _filterCategory = (_filterCategory == c) ? null : c;
              }),
            ),
            const SizedBox(height: 4),

            Expanded(
              child: exercisesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error al cargar ejercicios: $e',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (all) {
                  final filtered = all.where((ex) {
                    final search = _matchesSearch(ex, _searchQuery);
                    final safe = _passesInjurySafety(ex, activeInj);
                    final byCategory =
                        _filterCategory == null ||
                        ex.categoryId == _filterCategory;
                    final byTransfer =
                        _filterVbTransfer == null ||
                        ex.vbTransferIds.contains(_filterVbTransfer);
                    final byLevel =
                        _filterLevel == null || ex.levelId == _filterLevel;
                    return search &&
                        safe &&
                        byCategory &&
                        byTransfer &&
                        byLevel;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _EmptyState(
                      title: 'Sin resultados',
                      message: _hasFilters
                          ? 'No hay ejercicios con esos filtros. Intenta limpiar o ajustar tu búsqueda.'
                          : 'No encontramos ejercicios para tu búsqueda.',
                      onClearFilters: _hasFilters ? _clearFilters : null,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final ex = filtered[i];
                      return _ExerciseCard(
                        exercise: ex,
                        pretty: _pretty,
                        onAdd: () => _showAddExerciseDialog(ex),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _hasFilters
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Limpiar filtros'),
                ),
              ),
            )
          : null,
    );
  }
}

/* -------------------------- Widgets auxiliares -------------------------- */

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.search_rounded),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 10),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
                tooltip: 'Limpiar',
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickFiltersRow extends StatelessWidget {
  const _QuickFiltersRow({
    required this.categories,
    required this.current,
    required this.pretty,
    required this.onTap,
  });

  final List<CategoryId> categories;
  final CategoryId? current;
  final String Function(String) pretty;
  final void Function(CategoryId) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, i) {
          final c = categories[i];
          final selected = c == current;
          return Center(
            child: ChoiceChip(
              label: Text(pretty(c.name)),
              selected: selected,
              onSelected: (_) => onTap(c),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.pretty,
    required this.onAdd,
  });

  final Exercise exercise;
  final String Function(String) pretty;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final secondaryLine =
        '${pretty(exercise.categoryId.name)} • ${pretty(exercise.levelId.name)}';

    // Tags base
    final baseTags = <String>[
      ...exercise.vbTransferIds.map((e) => pretty(e.name)),
      if (exercise.qualityIds.isNotEmpty)
        pretty(exercise.qualityIds.first.name),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        // En pantallas muy estrechas, muestra menos tags para que respiren
        final maxTags = isCompact ? 2 : 3;
        final tags = baseTags.take(maxTags).toList();

        final cardContent = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondaryLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4, // ← ahora separa verticalmente
                      children: tags
                          .map(
                            (t) => Chip(
                              label: Text(
                                t,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: theme.textTheme.labelSmall,
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              backgroundColor: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.7),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (isCompact) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Agregar'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar'),
              ),
            ],
          ],
        );

        return Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onAdd,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: cardContent,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    this.onClearFilters,
  });
  final String title;
  final String message;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (onClearFilters != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* -------------------------- BottomSheet de filtros -------------------------- */

class _FiltersResult {
  final CategoryId? category;
  final VolleyballTransferId? transfer;
  final LevelId? level;
  const _FiltersResult({this.category, this.transfer, this.level});
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({
    required this.initialCategory,
    required this.initialTransfer,
    required this.initialLevel,
    required this.pretty,
  });

  final CategoryId? initialCategory;
  final VolleyballTransferId? initialTransfer;
  final LevelId? initialLevel;
  final String Function(String) pretty;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  CategoryId? _category;
  VolleyballTransferId? _transfer;
  LevelId? _level;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _transfer = widget.initialTransfer;
    _level = widget.initialLevel;
  }

  void _apply() {
    Navigator.pop(
      context,
      _FiltersResult(category: _category, transfer: _transfer, level: _level),
    );
  }

  void _clear() {
    setState(() {
      _category = null;
      _transfer = null;
      _level = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Filtros',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _clear,
                        icon: const Icon(Icons.filter_alt_off),
                        label: const Text('Limpiar'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _Section(title: '¿Qué quieres trabajar?'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: CategoryId.values.map((c) {
                          final selected = _category == c;
                          return ChoiceChip(
                            label: Text(widget.pretty(c.name)),
                            selected: selected,
                            onSelected: (_) => setState(() {
                              _category = selected ? null : c;
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _Section(title: 'Transferencia en cancha'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: VolleyballTransferId.values.map((t) {
                          final selected = _transfer == t;
                          return ChoiceChip(
                            label: Text(widget.pretty(t.name)),
                            selected: selected,
                            onSelected: (_) => setState(() {
                              _transfer = selected ? null : t;
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _Section(title: 'Nivel del ejercicio'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: LevelId.values.map((l) {
                          final selected = _level == l;
                          return ChoiceChip(
                            label: Text(widget.pretty(l.name)),
                            selected: selected,
                            onSelected: (_) => setState(() {
                              _level = selected ? null : l;
                            }),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton.icon(
                    onPressed: _apply,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Aplicar filtros'),
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

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
