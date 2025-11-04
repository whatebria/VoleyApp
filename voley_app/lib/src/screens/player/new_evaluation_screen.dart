// lib/screens/new_evaluation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';

class NewEvaluationScreen extends ConsumerStatefulWidget {
  const NewEvaluationScreen({super.key});

  @override
  _NewEvaluationScreenState createState() => _NewEvaluationScreenState();
}

class _NewEvaluationScreenState extends ConsumerState<NewEvaluationScreen> {
  // Estado local para los campos editables
  Map<String, double> _testScores = {};
  List<Tournament> _selectedTournaments = [];
  PlayerProfile? _currentLoadedProfile;
  bool _isLoadingProfile = false;

  /// Carga el perfil del jugador y sus tests/torneos al estado local
  void _loadProfileData(PlayerProfile? profile) {
    if (profile == null) {
      setState(() {
        _testScores = {};
        _selectedTournaments = [];
      });
    } else {
      // Usamos el perfil cargado para inicializar el estado local
      setState(() {
        // Hacemos copias defensivas de los Mapas y Listas
        _testScores = Map.from(profile.evaluation.testScores);
        _selectedTournaments = List.from(profile.tournaments);
      });
    }
  }

  /// Muestra el diálogo para añadir una puntuación de test (Sin cambios funcionales)
  Future<void> _showAddTestDialog() async {
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
                decoration: const InputDecoration(labelText: 'Nombre del Test'),
                autofocus: true,
              ),
              TextField(
                controller: scoreController,
                decoration: const InputDecoration(
                  labelText: 'Puntuación (Ej: 55.5)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).maybePop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final score = double.tryParse(scoreController.text);
                if (nameController.text.isNotEmpty && score != null) {
                  setState(() => _testScores[nameController.text] = score);
                  Navigator.of(context, rootNavigator: true).maybePop();
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  /// [REFACTOR] Envía la actualización del perfil
  Future<void> _handleSubmit(PlayerProfile profileToEdit) async {
    final selectedPlayer = ref.read(explorerSelectedPlayerProvider);

    // Usaremos el provider de carga para el botón
    // No necesitamos _isSubmitting local, pero lo mantengo por simplicidad visual
    // en este widget.
    setState(() => _isSubmitting = true);

    try {
      // Crea una copia actualizada del perfil
      final updatedProfile = profileToEdit.copyWith(
        evaluation: profileToEdit.evaluation.copyWith(testScores: _testScores),
        tournaments: _selectedTournaments,
      );

      final firestore = ref.read(firestoreProvider);
      await firestore.savePlayerProfile(updatedProfile);

      // --- [CORRECCIÓN CRÍTICA] INVALIDACIÓN DE PROVIDERS ---
      // 1. Invalidar el perfil del jugador seleccionado para que la app sepa que cambió.
      ref.invalidate(selectedPlayerProfileProvider);

      // 2. Invalidar la lista de jugadores con perfiles (si este cambio afecta, ej. el perfil se crea por primera vez)
      // Aunque en este caso solo editamos, una invalidación es más segura.
      ref.invalidate(coachPlayersWithProfilesProvider);
      // ----------------------------------------------------

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluación actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al actualizar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Bandera local de carga del botón (lo mantengo para tu lógica de UI)
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    // [REFACTOR] Observar los providers del explorador (que ya son reactivos)
    final playersWithProfilesAsync = ref.watch(
      coachPlayersWithProfilesProvider,
    );
    final selectedPlayerWithProfile = ref.watch(explorerSelectedPlayerProvider);

    final profileFromProvider = ref.watch(selectedPlayerProfileProvider);

    final theme = Theme.of(context);

    // --- [REFACTOR] Lógica de Sincronización de Estado ---
    // Sincroniza el estado local del formulario (_testScores) con el perfil
    // cargado desde el provider global. Esto solo se hace UNA VEZ
    // cuando el perfil cambia y se resuelve.
    ref.listen<PlayerProfile?>(selectedPlayerProfileProvider, (_, nextProfile) {
      setState(() {
        _isLoadingProfile = false; // El valor ya se resolvió/actualizó
        _currentLoadedProfile = nextProfile;
      });
      _loadProfileData(nextProfile);
    });

    ref.listen<PlayerWithProfile?>(explorerSelectedPlayerProvider, (
      prev,
      next,
    ) {
      // Si seleccionamos un jugador, ponemos el indicador de carga mientras
      // esperamos que selectedPlayerProfileProvider se actualice.
      if (next != null) {
        setState(() {
          _isLoadingProfile = true;
        });
      }
    });

    // Extraer el perfil actual para el formulario
    final profileToEdit = _currentLoadedProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Nueva Evaluación')),
      body: Stack(
        children: [
          playersWithProfilesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) =>
                Center(child: Text('Error al cargar jugadores: $e')),
            data: (playersWithProfiles) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Selector de Jugador
                    // [REFACTOR] Usamos PlayerWithProfile para el Dropdown
                    DropdownButtonFormField<PlayerWithProfile>(
                      initialValue: selectedPlayerWithProfile,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Jugador',
                        border: OutlineInputBorder(),
                      ),
                      items: playersWithProfiles
                          .map(
                            (combo) => DropdownMenuItem(
                              value: combo,
                              child: Text(combo.player.name),
                            ),
                          )
                          .toList(),
                      onChanged: (combo) {
                        // [CORREGIDO] Almacenamos el PlayerWithProfile completo
                        ref
                                .read(explorerSelectedPlayerProvider.notifier)
                                .state =
                            combo;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 2. Contenido del Formulario (Solo si hay un jugador seleccionado)
                    if (selectedPlayerWithProfile != null) ...[
                      // 2.A. Indicador de carga del perfil
                      if (_isLoadingProfile) // Usamos el flag local
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (profileToEdit == null)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'El jugador aún no tiene un perfil. Creando uno nuevo al guardar.',
                          ),
                        )
                      else ...[
                        // 2.B. Sección de Tests (Editable)
                        Text(
                          'Puntuaciones de Test',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Divider(),
                        if (_testScores.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Añade tests...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ..._testScores.entries.map(
                          (entry) => ListTile(
                            title: Text(entry.key),
                            trailing: Text(
                              entry.value.toStringAsFixed(2),
                            ), // Mejor formateo
                            // Lógica de onTap simplificada
                            onTap: _showAddTestDialog,
                            // Añade botón de eliminar
                            leading: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _testScores.remove(entry.key));
                              },
                            ),
                          ),
                        ),
                        Center(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Añadir Test'),
                            onPressed: _showAddTestDialog,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // 2.C. Botón de Enviar
                        ElevatedButton(
                          // Pasamos el perfil cargado o el perfil por defecto para el guardado
                          onPressed: _isSubmitting
                              ? null
                              : () => _handleSubmit(profileToEdit),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const Text('Guardando...')
                              : const Text('Actualizar Evaluación'),
                        ),
                      ],
                    ] else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Selecciona un jugador para comenzar la evaluación.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          // Indicador de carga de superposición (solo si no hay indicador interno)
          if (_isSubmitting && selectedPlayerWithProfile == null)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
