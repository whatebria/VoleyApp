import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/screens/coach_player_profile.dart';

class CoachAthletesScreen extends ConsumerWidget {
  const CoachAthletesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(coachPlayersWithProfilesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar atletas: $e')),
        data: (players) {
          if (players.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tienes atletas asignados aún.'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(coachPlayersProvider);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: players.length + 1,
              itemBuilder: (context, index) {
                // --- INVITAR ATLETA ---
                if (index == 0) {
                  return _InviteCard(
                    onPressed: () => Navigator.pushNamed(context, '/permiso'),
                  );
                }

                final athlete = players[index - 1];
                final hasProfile = athlete.profile != null;
                final subtitle = athlete.profile == null
                    ? 'Sin perfil creado'
                    : 'Nivel: ${athlete.profile!.level.name}';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.person, color: theme.colorScheme.primary),
                    ),
                    title: Text(athlete.profile?.name ?? athlete.player.name),
                    subtitle: Text(subtitle),
                    trailing: ElevatedButton(
                      onPressed: hasProfile
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CoachPlayerProfile(profile: athlete.profile!),
                                ),
                              )
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Este atleta aún no tiene perfil'),
                                ),
                              ),
                      child: const Text('Ver'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),

      // --- NUEVO ATLETA ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/user_create'),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Nuevo atleta'),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.secondary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.mail, color: theme.colorScheme.secondary),
        title: Text(
          'Invitar atleta',
          style: TextStyle(color: theme.colorScheme.secondary),
        ),
        subtitle: const Text('Enviar enlace o código de invitación'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onPressed,
      ),
    );
  }
}
