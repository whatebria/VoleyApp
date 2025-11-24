import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';

class CoachEvaluationsScreen extends ConsumerWidget {
  const CoachEvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(coachPlayersWithProfilesProvider);
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Evaluaciones')),
      body: playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar evaluaciones: $e')),
        data: (players) {
          final items = players
              .where((p) => p.profile?.latestEvaluation != null)
              .map((p) => _EvaluationItem(
                    athleteName: p.profile?.name ?? p.player.name,
                    label: p.profile!.latestEvaluation!.displayLabel,
                    date: p.profile!.latestEvaluation!.date,
                  ))
              .toList();

          return Column(
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.secondary.withOpacity(0.12),
                                child: Icon(Icons.analytics, color: theme.colorScheme.secondary),
                              ),
                              title: Text(item.athleteName),
                              subtitle: Text('${item.label} • ${dateFmt.format(item.date)}'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EvaluationItem {
  const _EvaluationItem({
    required this.athleteName,
    required this.label,
    required this.date,
  });

  final String athleteName;
  final String label;
  final DateTime date;
}