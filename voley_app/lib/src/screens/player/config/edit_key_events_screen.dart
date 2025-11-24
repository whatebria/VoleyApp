import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';
import 'package:voley_app/providers/providers.dart';

class EditKeyEventsScreen extends ConsumerWidget {
  const EditKeyEventsScreen({super.key});

  String _typeLabel(PlayerEventType t) {
    switch (t) {
      case PlayerEventType.league: return 'Liga';
      case PlayerEventType.cup: return 'Copa';
      case PlayerEventType.playoff: return 'Play-offs';
      case PlayerEventType.nationalTeam: return 'Selección';
      case PlayerEventType.travel: return 'Viaje';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Fechas clave')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'editKeyEventsAddFab',
        onPressed: () async {
          final created = await Navigator.pushNamed(context, '/profile_settings/add_key_event');
          if (created != null) {
            ref.invalidate(playerProfileProvider); // o guarda directamente
          }
        },
        child: const Icon(Icons.add),
      ),
      body: profile == null
          ? const Center(child: Text('Sin perfil'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: profile.keyEvents.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final e = profile.keyEvents[i];
                return ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text('${_typeLabel(e.type)} • ${DateFormat('dd/MM/yyyy').format(e.date)}'),
                  subtitle: e.description != null ? Text(e.description!) : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final updated = profile.copyWith(
                        keyEvents: [...profile.keyEvents]..removeAt(i),
                      );
                      // TODO: guardar
                      // await ref.read(firestoreProvider).savePlayerProfile(updated);
                      ref.invalidate(playerProfileProvider);
                    },
                  ),
                );
              },
            ),
    );
  }
}
