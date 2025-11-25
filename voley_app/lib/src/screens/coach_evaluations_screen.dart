import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/evaluation_with_profile.dart';

class CoachEvaluationsScreen extends ConsumerWidget {
  const CoachEvaluationsScreen({super.key, this.showAllPlayers = true});

  /// Cuando es `true`, se muestran todas las evaluaciones de todos los atletas
  /// del coach. En `false`, se filtra por el jugador seleccionado en el
  /// explorador (útil al navegar desde la vista de programas de un jugador).
  final bool showAllPlayers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluationsAsync = showAllPlayers
        ? ref.watch(coachAllEvaluationsProvider)
        : _selectedPlayerEvaluations(ref);
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(showAllPlayers ? 'Evaluaciones' : 'Evaluaciones del jugador'),
      ),
      body: evaluationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) =>
            Center(child: Text('Error al cargar evaluaciones: $e')),
        data: (items) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/evaluation'),
                  icon: const Icon(Icons.add_task),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Nueva evaluación'),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No hay evaluaciones registradas aún.'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.secondary
                                  .withOpacity(0.12),
                              child: Icon(
                                Icons.analytics,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            title: Text(item.profile.name),
                            subtitle: Text(
                              '${item.evaluation.displayLabel} • ${dateFmt.format(item.evaluation.date)}',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  AsyncValue<List<EvaluationWithProfile>> _selectedPlayerEvaluations(
    WidgetRef ref,
  ) {
    final profile = ref.watch(selectedPlayerProfileProvider);

    if (profile == null) {
      return const AsyncValue.data([]);
    }

    final items = profile.evaluationHistory
        .map(
          (evaluation) => EvaluationWithProfile(
            profile: profile,
            evaluation: evaluation,
          ),
        )
        .toList()
      ..sort((a, b) => b.evaluation.date.compareTo(a.evaluation.date));

    return AsyncValue.data(items);
  }
}
