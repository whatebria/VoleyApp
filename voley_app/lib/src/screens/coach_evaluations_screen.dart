import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/evaluation_with_profile.dart';

class CoachEvaluationsScreen extends ConsumerWidget {
  const CoachEvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluationsAsync = ref.watch(coachAllEvaluationsProvider);
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Evaluaciones')),
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
}
