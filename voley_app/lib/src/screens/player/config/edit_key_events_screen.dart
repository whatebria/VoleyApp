// lib/screens/edit_key_events_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';
import 'package:voley_app/src/screens/player/config/add_key_event_screen.dart'; // Tu modelo

class EditKeyEventsScreen extends ConsumerWidget {
  const EditKeyEventsScreen({super.key});

  // Copiamos la función helper de 'player_profile_screen.dart'
  // (Idealmente, esto estaría en un archivo 'utils'
  String _eventLabel(String type) {
    switch (type) {
      case 'cup':
        return 'Copa';
      case 'playoff':
        return 'Play-offs';
      case 'national_team':
        return 'Selección';
      case 'travel':
        return 'Viaje';
      case 'league':
      default:
        return 'Liga';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usamos 'watch' para que la lista se actualice si cambia
    final keyEvents = ref.watch(playerProfileProvider).asData?.value?.keyEvents ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fechas Clave'),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Añadir Fecha Clave',
        onPressed: () {
          // Navegamos a la pantalla de "Añadir"
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddKeyEventScreen(),
              fullscreenDialog: true, // Buen UX para pantallas de "Añadir"
            ),
          );
        },
      ),
      body: keyEvents.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Aún no has añadido fechas clave (ej. playoffs, copas, viajes).',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: keyEvents.length,
              itemBuilder: (context, index) {
                final event = keyEvents[index];
                return ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(
                      '${_eventLabel(event.type)} - ${DateFormat('dd/MM/yyyy').format(event.date)}'),
                  subtitle: event.description != null && event.description!.isNotEmpty
                      ? Text(event.description!)
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar',
                    onPressed: () {
                      // TODO: Llamar al Notifier para borrar
                      // ref.read(playerProfileProvider.notifier).removeKeyEvent(event.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Simulando eliminación...')),
                      );
                    },
                  ),
                  onTap: () {
                    // Navegar para editar
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddKeyEventScreen(event: event),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}