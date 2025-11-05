// lib/screens/edit_tournaments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/screens/player/config/add_tournament_screen.dart'; // Asegúrate que el modelo exista

class EditTournamentsScreen extends ConsumerWidget {
  const EditTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usamos 'watch' para que la lista se actualice si cambia
    final tournaments = ref.watch(playerProfileProvider).asData?.value?.tournaments ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Torneos'),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Añadir Torneo',
        onPressed: () {
          // Navegamos a la pantalla de "Añadir"
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTournamentScreen(),
              fullscreenDialog: true, // Buen UX para pantallas de "Añadir"
            ),
          );
        },
      ),
      body: tournaments.isEmpty
          ? const Center(
              child: Text('Aún no has añadido torneos.'),
            )
          : ListView.builder(
              itemCount: tournaments.length,
              itemBuilder: (context, index) {
                final tournament = tournaments[index];
                return ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: Text(tournament.name),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(tournament.date)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      // TODO: Llamar al Notifier para borrar
                      // ref.read(playerProfileProvider.notifier).removeTournament(tournament.id);
                    },
                  ),
                  onTap: () {
                    // Opcional: Navegar para editar
                    // Navigator.push(context, MaterialPageRoute(
                    //   builder: (context) => AddTournamentScreen(tournament: tournament),
                    // ));
                  },
                );
              },
            ),
    );
  }
}