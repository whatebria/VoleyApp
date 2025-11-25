import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/evaluation_editor_provider.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/test_score.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/user.dart';
import 'package:voley_app/src/screens/forms/player_form_screens.dart';

// --- CAMBIO: Convertido a ConsumerWidget ---
class NewEvaluationScreen extends ConsumerWidget {
  const NewEvaluationScreen({super.key});

  Future<void> _navigateToAddTestScreen(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final newTest = await Navigator.push<TestScore>(
      context,
      MaterialPageRoute(builder: (_) => const TestScoreFormScreen()),
    );
    if (newTest != null) {
      ref.read(evaluationEditorProvider.notifier).addTest(newTest);
    }
  }

  void _onPlayerSelected(PlayerWithProfile? player, WidgetRef ref) {
    ref.read(explorerSelectedPlayerProvider.notifier).state = player;
    ref.invalidate(evaluationEditorProvider);
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// [REFACTORIZADO] Llama al provider para guardar
  Future<void> _handleSubmit(BuildContext context, WidgetRef ref) async {
    try {
      final selectedPlayerCombo = ref.read(explorerSelectedPlayerProvider);
      if (selectedPlayerCombo == null) {
        _showError(context, 'Debes seleccionar un jugador.');
        return;
      }

      final User player = selectedPlayerCombo
          .player; // ajusta si tu tipo no es FirebaseAuth.User
      final PlayerProfile? currentProfile = ref.read(
        selectedPlayerProfileProvider,
      );

      await ref
          .read(evaluationEditorProvider.notifier)
          .saveEvaluation(player, currentProfile);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluación guardada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(context, 'Error al guardar: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final playersAsync = ref.watch(coachPlayersWithProfilesProvider);

    // --- CAMBIO: Escucha el provider 'selectedPlayerProfileProvider' ---
    // Esto asegura que el editor se inicialice/actualice si el jugador cambia.
    ref.listen<PlayerProfile?>(selectedPlayerProfileProvider, (prev, next) {
      // (Opcional) Si el jugador cambia, reinicia el estado del editor
      // ref.invalidate(evaluationEditorProvider);
      // O, para una edición en vivo:
      // final newScores = next?.latestEvaluation?.testScores ?? [];
      // ref.read(evaluationEditorProvider.notifier).state = newScores;
    });

    // Observa el jugador seleccionado
    final selectedPlayerCombo = ref.watch(explorerSelectedPlayerProvider);

    // Observa el estado de carga
    final isSubmitting = ref.watch(evaluationIsSavingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Evaluación')),
      body: Stack(
        children: [
          playersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) =>
                Center(child: Text('Error al cargar jugadores: $e')),
            data: (players) {
              if (players.isEmpty) {
                return const Center(
                  child: Text('Aún no tienes jugadores asignados.'),
                );
              }

              return _buildEvaluationForm(
                context,
                ref,
                theme,
                players,
                selectedPlayerCombo,
              );
            },
          ),

          // --- Overlay de Carga ---
          if (isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  /// [REFACTORIZADO] Construye el formulario
  Widget _buildEvaluationForm(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<PlayerWithProfile> players,
    PlayerWithProfile? selectedPlayer,
  ) {
    final currentTestScores = ref.watch(evaluationEditorProvider);
    final isCreating = selectedPlayer?.profile == null;
    final hasSelectedPlayer = selectedPlayer != null;
    final displayName = selectedPlayer?.player.name ?? 'Selecciona un jugador';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Jugador a evaluar', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PlayerWithProfile>(
                    value: selectedPlayer,
                    decoration: const InputDecoration(
                      hintText: 'Selecciona un jugador',
                    ),
                    items: players
                        .map(
                          (player) => DropdownMenuItem(
                            value: player,
                            child: Text(player.player.name),
                          ),
                        )
                        .toList(),
                    onChanged: (player) => _onPlayerSelected(player, ref),
                  ),
                  if (!hasSelectedPlayer)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Selecciona un jugador para registrar su evaluación.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Título
          Text(
            hasSelectedPlayer
                ? (isCreating
                      ? 'Creando Evaluación para'
                      : 'Añadiendo Evaluación para')
                : 'Selecciona un jugador para iniciar',
            style: theme.textTheme.headlineMedium,
          ),
          if (hasSelectedPlayer)
            Text(
              displayName,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          if (isCreating && hasSelectedPlayer)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Este jugador aún no tiene perfil. Al guardar, se creará uno nuevo con estos datos.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // 2. Sección de Tests (Editable)
          Text(
            'Puntuaciones de Test',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.secondary, // azulPro
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),

          // [NUEVO DISEÑO] Lista de Chips
          // --- CAMBIO: Pasa la lista desde el provider ---
          _buildTestList(context, ref, theme, currentTestScores),
          const SizedBox(height: 16),

          // [NUEVO DISEÑO] Botón de añadir
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Añadir Test'),
              onPressed: () => _navigateToAddTestScreen(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),

          const SizedBox(height: 32),
          _EvaluationHistorySection(profile: selectedPlayer?.profile),
          const SizedBox(height: 32),
          // 3. Botón de Enviar
          ElevatedButton(
            // --- CAMBIO: Observa el provider de carga ---
            onPressed: ref.watch(evaluationIsSavingProvider)
                ? null
                : () => _handleSubmit(context, ref),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: ref.watch(evaluationIsSavingProvider)
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Text(
                    isCreating ? 'Crear Perfil y Guardar' : 'Añadir Evaluación',
                  ),
          ),
        ],
      ),
    );
  }

  /// [REFACTORIZADO] Construye la lista de tests
  Widget _buildTestList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<TestScore> testScores,
  ) {
    if (testScores.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: Text(
            'No hay tests registrados para esta nueva evaluación.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // [NUEVO DISEÑO]
    return Wrap(
      spacing: 8.0, // Espacio horizontal entre chips
      runSpacing: 8.0, // Espacio vertical entre filas
      children: testScores.map((test) {
        return Chip(
          backgroundColor: theme.colorScheme.secondary.withOpacity(
            0.8,
          ), // azulPro
          label: Text(
            // --- CAMBIO: Muestra el TestScore ---
            '${test.testId}: ${test.value.toStringAsFixed(1)} ${test.unit}',
            style: TextStyle(
              color: theme.colorScheme.onSecondary, // blancoNeutro
              fontWeight: FontWeight.w600,
            ),
          ),
          onDeleted: () {
            // --- CAMBIO: Llama al provider para eliminar ---
            ref.read(evaluationEditorProvider.notifier).removeTest(test);
          },
          deleteIcon: const Icon(Icons.close, size: 18),
          deleteIconColor: theme.colorScheme.onSecondary.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        );
      }).toList(),
    );
  }
}

class _EvaluationHistorySection extends StatelessWidget {
  const _EvaluationHistorySection({required this.profile});

  final PlayerProfile? profile;

  List<EvaluationResult> get _sortedHistory {
    final history = [
      ...(profile?.evaluationHistory ?? const <EvaluationResult>[]),
    ];
    history.sort((a, b) => b.date.compareTo(a.date));
    return history;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy');
    final history = _sortedHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial de Evaluaciones',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (profile == null)
          Card(
            color: theme.colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Cuando selecciones un jugador verás aquí su historial de evaluaciones.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else if (history.isEmpty)
          Card(
            color: theme.colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Este jugador aún no tiene evaluaciones registradas.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          ...history.map(
            (evaluation) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                  child: Icon(
                    Icons.event_note_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                title: Text(evaluation.displayLabel),
                subtitle: Text(dateFmt.format(evaluation.date)),
                trailing: Text(
                  '${evaluation.testScores.length} tests',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
