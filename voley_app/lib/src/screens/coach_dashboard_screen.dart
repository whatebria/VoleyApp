import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/providers/providers.dart';

class CoachDashboardScreen extends ConsumerWidget {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(coachPlayersWithProfilesProvider);
    final theme = Theme.of(context);

    return playersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error al cargar atletas: $e')),
      data: (players) {
        if (players.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aún no tienes atletas asignados. Crea o invita uno nuevo.'),
            ),
          );
        }

        final highlighted = players.take(3).toList();
        final evaluations = players
            .where((p) => p.profile?.latestEvaluation != null)
            .toList(growable: false);
        final latestEvaluations = evaluations
            .map((p) => _EvaluationSummary(
                  name: p.profile?.name ?? p.player.name,
                  date: p.profile!.latestEvaluation!.date,
                  label: p.profile!.latestEvaluation!.displayLabel,
                ))
            .toList(growable: false);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(coachPlayersProvider);
            await playersAsync.maybeWhen(orElse: () async {}, data: (_) async {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Atletas destacados', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final athlete in highlighted)
                  _AthleteHighlightCard(
                    name: athlete.profile?.name ?? athlete.player.name,
                    level: athlete.profile?.level.name ?? 'sin nivel',
                    latestEvaluation: athlete.profile?.latestEvaluation?.displayLabel,
                  ),
                const SizedBox(height: 20),
                Text('Indicadores', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      title: 'Atletas activos con programa',
                      value: players.length.toString(),
                      icon: Icons.group,
                    ),
                    _MetricCard(
                      title: 'Evaluaciones registradas',
                      value: evaluations.length.toString(),
                      icon: Icons.assessment,
                    ),
                    _MetricCard(
                      title: 'Picos de forma',
                      value: players
                          .fold<int>(0, (sum, p) => sum + (p.profile?.formPeaks.length ?? 0))
                          .toString(),
                      icon: Icons.trending_up,
                    ),
                    _MetricCard(
                      title: 'Eventos próximos',
                      value: players
                          .fold<int>(0, (sum, p) => sum + (p.profile?.tournaments.length ?? 0))
                          .toString(),
                      icon: Icons.event,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Últimas evaluaciones', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                if (latestEvaluations.isEmpty)
                  const Text('Aún no tienes evaluaciones registradas.')
                else
                  Column(
                    children: latestEvaluations
                        .map((e) => _EvaluationCard(summary: e))
                        .toList(growable: false),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EvaluationSummary {
  const _EvaluationSummary({
    required this.name,
    required this.date,
    required this.label,
  });

  final String name;
  final DateTime date;
  final String label;
}

class _AthleteHighlightCard extends StatelessWidget {
  const _AthleteHighlightCard({
    required this.name,
    required this.level,
    this.latestEvaluation,
  });

  final String name;
  final String level;
  final String? latestEvaluation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.sports_volleyball, color: theme.colorScheme.primary),
        ),
        title: Text(name, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nivel: $level'),

          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 180,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                    child: Icon(icon, color: theme.colorScheme.primary),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.summary});

  final _EvaluationSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.12),
          child: Icon(Icons.assessment, color: theme.colorScheme.secondary),
        ),
        title: Text(summary.name, style: theme.textTheme.titleMedium),
        subtitle: Text('${summary.label} • ${dateFmt.format(summary.date)}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}