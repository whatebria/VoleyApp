import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/evaluation_editor_provider.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/test_score.dart';
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
    final playerName = selectedPlayerCombo?.player.name ?? 'Jugador';

    // Observa el estado de carga
    final isSubmitting = ref.watch(evaluationIsSavingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Evaluación')),
      body: Stack(
        children: [
          // --- CAMBIO: Simplificado ---
          if (selectedPlayerCombo == null)
            const Center(
              child: Text('Por favor, selecciona un jugador primero.'),
            )
          else
            _buildEvaluationForm(context, ref, theme, playerName),

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
    String playerName,
  ) {
    // --- CAMBIO: Lee el estado del provider ---
    final currentTestScores = ref.watch(evaluationEditorProvider);
    final isCreating = ref.watch(selectedPlayerProfileProvider) == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Título
          Text(
            isCreating
                ? 'Creando Evaluación para'
                : 'Añadiendo Evaluación para',
            style: theme.textTheme.headlineMedium,
          ),
          Text(
            playerName,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
            ), // voltNeon
          ),
          if (isCreating)
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
