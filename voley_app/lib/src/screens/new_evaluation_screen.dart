// lib/screens/new_evaluation_screen.dart (NUEVO ARCHIVO)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:voley_app/src/models/user.dart' as app_user;

class NewEvaluationScreen extends ConsumerStatefulWidget {
  const NewEvaluationScreen({super.key});

  @override
  _NewEvaluationScreenState createState() => _NewEvaluationScreenState();
}

class _NewEvaluationScreenState extends ConsumerState<NewEvaluationScreen> {
  // Estado local para los campos editables
  Map<String, double> _testScores = {};
  List<Tournament> _selectedTournaments = [];
  
  PlayerProfile? _loadedProfile;
  bool _isSubmitting = false;

  /// Carga el perfil del jugador y sus tests/torneos
  void _loadProfileForPlayer(PlayerProfile? profile) {
    if (profile == null) {
      setState(() {
        _loadedProfile = null;
        _testScores = {};
        _selectedTournaments = [];
      });
    } else {
      setState(() {
        _loadedProfile = profile;
        _testScores = profile.evaluation.testScores;
        _selectedTournaments = profile.tournaments;
      });
    }
  }

  /// Muestra el diálogo para añadir una puntuación de test
  Future<void> _showAddTestDialog() async {
    // (Copiado de tu EvaluationScreen anterior)
    final nameController = TextEditingController();
    final scoreController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Puntuación de Test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Test (Ej: Salto Vertical)'),
                autofocus: true,
              ),
              TextField(
                controller: scoreController,
                decoration: const InputDecoration(labelText: 'Puntuación (Ej: 55.5)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final score = double.tryParse(scoreController.text);
                if (nameController.text.isNotEmpty && score != null) {
                  setState(() => _testScores[nameController.text] = score);
                  Navigator.pop(context);
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }
  
  // (Puedes añadir _showAddTournamentDialog aquí si también quieres añadir torneos)

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  /// Envía la actualización del perfil
  Future<void> _handleSubmit() async {
    if (_loadedProfile == null) {
      _showError('Por favor, selecciona un jugador primero.');
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      // Crea una copia actualizada del perfil
      final updatedProfile = _loadedProfile!.copyWith(
        evaluation: _loadedProfile!.evaluation.copyWith(
          testScores: _testScores, // Solo actualiza los tests
        ),
        tournaments: _selectedTournaments, // Y los torneos
      );

      // Guarda el perfil actualizado
      final firestore = ref.read(firestoreProvider);
      await firestore.savePlayerProfile(updatedProfile);

      // Actualiza el provider (para el generador)
      ref.read(playerProfileProvider.notifier).state = updatedProfile;

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluación actualizada'), backgroundColor: Colors.green),
        );
        // (Opcional) Navega al generador si quieres
        // Navigator.pushNamed(context, '/generate');
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('Error al actualizar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escucha a los providers del "Explorador" que ya existen
    final playersAsync = ref.watch(coachPlayersProvider);
    final selectedPlayer = ref.watch(explorerSelectedPlayerProvider);
    final theme = Theme.of(context);

    // Escucha cuándo cambia el jugador seleccionado
    ref.listen(explorerSelectedPlayerProvider, (prev, next) async {
      if (next != null) {
        // Carga el perfil completo de este jugador
        setState(() => _isSubmitting = true);
        final profile = await ref.read(firestoreProvider).getPlayerProfileByUserId(next.id);
        _loadProfileForPlayer(profile);
        setState(() => _isSubmitting = false);
      } else {
        _loadProfileForPlayer(null); // Limpia el formulario
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Nueva Evaluación')),
      body: Stack(
        children: [
          playersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error al cargar jugadores: $e')),
            data: (players) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Selector de Jugador
                    DropdownButtonFormField<app_user.User>(
                      value: selectedPlayer,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Jugador',
                        border: OutlineInputBorder(),
                      ),
                      items: players.map((user) => DropdownMenuItem(
                        value: user,
                        child: Text(user.name),
                      )).toList(),
                      onChanged: (user) {
                        ref.read(explorerSelectedPlayerProvider.notifier).state = user;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 2. Sección de Tests (Editable)
                    if (selectedPlayer != null) ...[
                      Text('Puntuaciones de Test', style: theme.textTheme.titleMedium),
                      const Divider(),
                      if (_testScores.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Añade tests...', style: TextStyle(color: Colors.grey)),
                        ),
                      ..._testScores.entries.map((entry) => ListTile(
                        title: Text(entry.key),
                        trailing: Text(entry.value.toString()),
                        onTap: () => _showAddTestDialog(), // (Podrías pasar el test para editar)
                      )),
                      Center(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Añadir Test'),
                          onPressed: _showAddTestDialog,
                        ),
                      ),
                      
                      // 3. (Opcional) Sección de Torneos
                      // (Añade aquí la UI de torneos si también quieres editarla)
                      
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Actualizar Evaluación'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}