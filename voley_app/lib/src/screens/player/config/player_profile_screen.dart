import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/injury.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileProvider);
    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) {
        if (profile == null) return const _EmptyState();
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Mi Perfil de Atleta'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.pushNamed(context, '/profile_settings'),
                ),
              ],
              bottom: const TabBar(tabs: [
                Tab(icon: Icon(Icons.person_outline), text: 'Resumen'),
                Tab(icon: Icon(Icons.flag_outlined), text: 'Planificación'),
                Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Historial'),
              ]),
            ),
            body: TabBarView(
              children: [
                _OverviewTab(profile: profile),
                _PlanningTab(profile: profile),
                _HistoryTab(profile: profile),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.pushNamed(context, '/player_evaluation'),
        child: const Text('Completar evaluación'),
      ),
    ),
  );
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.profile});
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final latest = profile.latestEvaluation;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${profile.position.name.toUpperCase()} • ${profile.level.name}'),
          ),
        ),
        const SizedBox(height: 16),
        if (latest != null) ...[
          Text('Última evaluación: ${DateFormat('dd/MM/yyyy').format(latest.date)}'),
          const SizedBox(height: 8),
          ...latest.testScores.map((t) => ListTile(
                title: Text(t.testId.replaceAll('_', ' ').toUpperCase()),
                trailing: Text('${t.value.toStringAsFixed(1)} ${t.unit}'),
              )),
        ] else
          const Text('Aún no registras evaluaciones.'),
      ],
    );
  }
}

class _PlanningTab extends StatelessWidget {
  const _PlanningTab({required this.profile});
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final active = profile.injuries.where((i) => i.status == InjuryStatus.active).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.healing_outlined),
          title: const Text('Lesiones activas'),
          subtitle: Text(active.isEmpty ? 'Ninguna' : active.map((e) => e.description).join(', ')),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today_outlined),
          title: const Text('Días disponibles'),
          subtitle: Text(profile.availability.trainingDays.map((d) => d.name).join(', ')),
        ),
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: const Text('Minutos por sesión'),
          subtitle: Text('${profile.availability.sessionMinutes}'),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.profile});
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: profile.tournaments.isEmpty
          ? const [Text('Sin torneos registrados')]
          : profile.tournaments
              .map((t) => ListTile(
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(t.name),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date)),
                  ))
              .toList(),
    );
  }
}
