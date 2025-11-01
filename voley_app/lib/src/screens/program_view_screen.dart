// lib/screens/program_view_screen.dart (REFACTORIZADO)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
// 1. Importa tu modelo 'User' usando el alias 'app_user'
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/models/program/program.dart';
import 'package:intl/intl.dart';

class ProgramViewScreen extends ConsumerWidget {
  const ProgramViewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Lee los providers. Asegúrate de que tus providers
    //    (currentUserAppUserProvider, coachPlayersProvider, etc.)
    //    también usen el alias 'app_user.User'.
    final currentUserAsync = ref.watch(currentUserAppUserProvider);
    final playersAsync = ref.watch(coachPlayersProvider);
    final selectedPlayer = ref.watch(explorerSelectedPlayerProvider);
    final programsAsync = ref.watch(explorerProgramsProvider);
    final selectedProgram = ref.watch(explorerSelectedProgramProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Explorador de Programas')),
      body: currentUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar usuario: $e')),
        data: (currentUser) {
          if (currentUser == null) {
            return const Center(child: Text('Usuario no encontrado.'));
          }
          // Si el usuario es jugador, pre-selecciónalo
          if (currentUser.isPlayer && selectedPlayer == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(explorerSelectedPlayerProvider.notifier).state = currentUser;
            });
          }

          return Column(
            children: [
              // --- Dropdown de Jugadores (para Coaches) ---
              if (currentUser.isCoach)
                playersAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('Cargando jugadores...')),
                  ),
                  error: (e, s) => Text('Error: $e'),
                  data: (players) {
                    if (players.isEmpty) {
                      return const Center(child: Text('No tienes jugadores.'));
                    }
                    if (selectedPlayer == null && players.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.read(explorerSelectedPlayerProvider.notifier).state = players.first;
                      });
                    }
                    // 3. Pasa los tipos 'app_user.User'
                    return _buildPlayerSelector(ref, players, selectedPlayer);
                  },
                ),

              // --- Dropdown de Programas ---
              programsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Cargando programas...')),
                ),
                error: (e, s) => Text('Error: $e'),
                data: (programs) {
                  if (programs.isEmpty) {
                    return const Expanded(
                      child: Center(child: Text('No hay programas generados.'))
                    );
                  }
                  if (selectedProgram == null && programs.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.read(explorerSelectedProgramProvider.notifier).state = programs.first;
                    });
                  }
                  return _buildProgramSelector(ref, programs, selectedProgram);
                },
              ),

              // --- Detalles del Programa ---
              Expanded(
                child: selectedProgram == null
                    ? const Center(child: Text('Selecciona un programa para ver.'))
                    : _buildProgramDetails(selectedProgram),
              ),
            ],
          );
        },
      ),
    );
  }

  // 4. Cambia 'User' por 'app_user.User' en la firma del método
  Widget _buildPlayerSelector(WidgetRef ref, List<app_user.User> players, app_user.User? selectedPlayer) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[100],
      // 5. Cambia el tipo del DropdownButtonFormField
      child: DropdownButtonFormField<app_user.User>(
        value: selectedPlayer,
        decoration: InputDecoration(
          labelText: 'Seleccionar Jugador',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        items: players.map((user) {
          // 6. Cambia el tipo del DropdownMenuItem
          return DropdownMenuItem<app_user.User>(value: user, child: Text(user.name));
        }).toList(),
        onChanged: (app_user.User? newValue) { // 7. Cambia el tipo del 'newValue'
          ref.read(explorerSelectedPlayerProvider.notifier).state = newValue;
          ref.read(explorerSelectedProgramProvider.notifier).state = null;
        },
      ),
    );
  }

  Widget _buildProgramSelector(WidgetRef ref, List<Program> programs, Program? selectedProgram) {
     return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: Colors.blue[50],
      child: DropdownButtonFormField<Program>(
        value: selectedProgram,
        decoration: InputDecoration(
          labelText: 'Seleccionar Programa',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        items: programs.map((program) {
          return DropdownMenuItem<Program>(
            value: program,
            child: Text(
              '${DateFormat('dd/MM/yyyy').format(program.startDate)} - ${DateFormat('dd/MM/yyyy').format(program.endDate)}',
            ),
          );
        }).toList(),
        onChanged: (Program? newValue) {
          ref.read(explorerSelectedProgramProvider.notifier).state = newValue;
        },
      ),
    );
  }

  // El resto del widget _buildProgramDetails no necesita cambios
  // (Asumiendo que 'e.name' viene de 'WorkoutExercise')
  Widget _buildProgramDetails(Program program) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: program.mesocycles.length,
      itemBuilder: (context, i) {
        final m = program.mesocycles[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ExpansionTile(
            title: Text(
              m.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${m.weeks} semanas — Enfoque: ${m.focus}'),
            children: m.microcycles.map((mc) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    '${mc.weekNumber}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text('Semana ${mc.weekNumber}'),
                subtitle: Text('${mc.sessions.length} sesiones'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) {
                      return DraggableScrollableSheet(
                        initialChildSize: 0.7,
                        minChildSize: 0.5,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (context, scrollController) {
                          return Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Semana ${mc.weekNumber}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: mc.sessions.length,
                                  itemBuilder: (context, index) {
                                    final s = mc.sessions[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.fitness_center,
                                                  color: Colors.orange[700],
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    s.day,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Objetivo: ${s.objective}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Carga: ${s.load}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const Divider(height: 16),
                                            const Text(
                                              'Ejercicios:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...s.exercises.map((e) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 4),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('• ', style: TextStyle(fontSize: 16)),
                                                      Expanded(child: Text(e.name)),
                                                    ],
                                                  ),
                                                )),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}