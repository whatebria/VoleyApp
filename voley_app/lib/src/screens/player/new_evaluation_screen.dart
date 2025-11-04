import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
// Importamos los modelos necesarios para crear un perfil por defecto
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';

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
  bool _isLoadingProfile = true; // Empezamos cargando por defecto
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Comprobación inicial
    _checkInitialProfile();
  }

  /// Comprueba el perfil al cargar la pantalla
  void _checkInitialProfile() {
    // Usamos 'read' aquí porque es una acción de una sola vez en initState
    final profile = ref.read(selectedPlayerProfileProvider);
    _loadProfileData(profile);
  }

  /// Carga el perfil del jugador y sus tests/torneos al estado local
  void _loadProfileData(PlayerProfile? profile) {
    if (!mounted) return;

    setState(() {
      _currentLoadedProfile = profile;
      if (profile == null) {
        _testScores = {};
        _selectedTournaments = [];
      } else {
        _testScores = Map.from(profile.evaluation.testScores);
        _selectedTournaments = List.from(profile.tournaments);
      }
      _isLoadingProfile = false; // Terminamos de cargar/sincronizar
    });
  }

  /// [NUEVO DISEÑO] Muestra un BottomSheet para añadir un test
  Future<void> _showAddTestBottomSheet() async {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final scoreController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Para que el teclado no tape el sheet
      backgroundColor: theme.colorScheme.surface, // grisPro
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          // Padding para el teclado
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Añadir Nuevo Test',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(color: theme.colorScheme.primary), // voltNeon
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Test'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: scoreController,
                decoration: const InputDecoration(
                    labelText: 'Puntuación (Ej: 55.5)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                // Usa el estilo 'voltNeon' por defecto del tema
                onPressed: () {
                  final score = double.tryParse(scoreController.text);
                  if (nameController.text.isNotEmpty && score != null) {
                    setState(() => _testScores[nameController.text] = score);
                    Navigator.of(context, rootNavigator: true).maybePop(); // Cierra el bottom sheet
                  } else {
                    // Opcional: Mostrar error en el sheet
                  }
                },
                child: const Text('Guardar Test'),
              ),
              const SizedBox(height: 24), // Espacio inferior
            ],
          ),
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

  /// [REFACTOR] Envía la actualización (o creación) del perfil
  Future<void> _handleSubmit() async {
    final selectedPlayerCombo = ref.read(explorerSelectedPlayerProvider);
    
    // Debería ser imposible llegar aquí sin un jugador, pero comprobamos
    if (selectedPlayerCombo == null) {
      _showError("Error fatal: No hay ningún jugador seleccionado.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final PlayerProfile profileToSave;
      final player = selectedPlayerCombo.player;

      if (_currentLoadedProfile == null) {
        // --- MODO CREACIÓN ---
        // Creamos un perfil nuevo con los datos mínimos
        profileToSave = PlayerProfile(
          id: player.id, // Asumimos que el ID del perfil es el UID del jugador
          userId: player.id,
          name: player.name,
          position: 'Sin definir',
          level: 'recreativo',
          goals: [],
          injuries: [],
          // Rellenamos con valores por defecto
          availability: Availability(trainingDays: [], sessionMinutes: 0), 
          evaluation: EvaluationResult(
            testScores: _testScores, // Las puntuaciones que acabamos de añadir
            strengths: [],
            weaknesses: []
          ),
          tournaments: _selectedTournaments,
          equipment: [],
          keyEvents: [],
          formPeaks: [],
        );
      } else {
        // --- MODO EDICIÓN ---
        // Actualizamos solo los campos que esta pantalla maneja
        profileToSave = _currentLoadedProfile!.copyWith(
          evaluation: _currentLoadedProfile!.evaluation.copyWith(
            testScores: _testScores,
          ),
          tournaments: _selectedTournaments,
        );
      }

      // Guardamos en la base de datos
      final firestore = ref.read(firestoreProvider);
      await firestore.savePlayerProfile(profileToSave);

      // Invalidamos los providers para que toda la app se actualice
      ref.invalidate(selectedPlayerProfileProvider);
      ref.invalidate(coachPlayersWithProfilesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluación guardada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        // Opcional: navegar atrás después de guardar
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al guardar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- [REFACTOR] Lógica de Sincronización ---
    // Escuchamos el provider global. Si cambia (ej: por un 'invalidate'),
    // volvemos a cargar los datos en nuestro estado local.
    ref.listen<PlayerProfile?>(selectedPlayerProfileProvider, (_, nextProfile) {
      _loadProfileData(nextProfile);
    });

    // Leemos el jugador seleccionado (sabemos que no es nulo si llegamos aquí)
    final selectedPlayerCombo = ref.watch(explorerSelectedPlayerProvider);
    final playerName = selectedPlayerCombo?.player.name ?? 'Jugador';

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Evaluación')),
      body: Stack(
        children: [
          // --- [REFACTOR] Contenido principal ---
          // Ya no usamos .when() aquí, el 'ref.listen' maneja la carga
          // y `_isLoadingProfile` nos dice si estamos listos.
          if (_isLoadingProfile)
            const Center(child: CircularProgressIndicator())
          else if (selectedPlayerCombo == null)
            const Center(
              child: Text('Por favor, selecciona un jugador primero.'),
            )
          else
            // [NUEVO WIDGET] El formulario real
            _buildEvaluationForm(context, theme, playerName),

          // --- Overlay de Carga ---
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  /// [NUEVO WIDGET] Construye solo el formulario
  Widget _buildEvaluationForm(BuildContext context, ThemeData theme, String playerName) {
    final isCreating = (_currentLoadedProfile == null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Título
          Text(
            isCreating ? 'Creando Evaluación para' : 'Editando Evaluación de',
            style: theme.textTheme.headlineMedium,
          ),
          Text(
            playerName,
            style: theme.textTheme.headlineMedium
                ?.copyWith(color: theme.colorScheme.primary), // voltNeon
          ),
          if (isCreating)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Este jugador aún no tiene perfil. Al guardar, se creará uno nuevo con estos datos.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
          const SizedBox(height: 24),

          // 2. Sección de Tests (Editable)
          Text(
            'Puntuaciones de Test',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.secondary, // azulPro
              fontWeight: FontWeight.bold
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),

          // [NUEVO DISEÑO] Lista de Chips
          _buildTestList(context),
          const SizedBox(height: 16),

          // [NUEVO DISEÑO] Botón de añadir
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Añadir Test'),
              onPressed: _showAddTestBottomSheet,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface.withOpacity(0.8)
              ),
            ),
          ),

          // TODO: Añadir la lógica para _selectedTournaments si es necesario
          // ... (puedes seguir el mismo patrón que los tests)

          const SizedBox(height: 32),

          // 3. Botón de Enviar
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Text(
                    isCreating ? 'Crear y Guardar' : 'Actualizar Evaluación',
                  ),
          ),
        ],
      ),
    );
  }

  /// [NUEVO WIDGET] Construye la lista de tests como Chips
  Widget _buildTestList(BuildContext context) {
    final theme = Theme.of(context);

    if (_testScores.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: Text(
            'No hay tests registrados.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    // [NUEVO DISEÑO]
    return Wrap(
      spacing: 8.0, // Espacio horizontal entre chips
      runSpacing: 8.0, // Espacio vertical entre filas
      children: _testScores.entries.map((entry) {
        return Chip(
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.8), // azulPro
          label: Text(
            '${entry.key}: ${entry.value.toStringAsFixed(1)}',
            style: TextStyle(
              color: theme.colorScheme.onSecondary, // blancoNeutro
              fontWeight: FontWeight.w600,
            ),
          ),
          onDeleted: () {
            setState(() => _testScores.remove(entry.key));
          },
          deleteIcon: const Icon(Icons.close, size: 18),
          deleteIconColor: theme.colorScheme.onSecondary.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        );
      }).toList(),
    );
  }
}
