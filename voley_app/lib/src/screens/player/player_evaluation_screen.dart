import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/evaluation_editor_provider.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/test_score.dart';
import 'package:collection/collection.dart'; // Para .firstWhereOrNull

class PlayerEvaluationScreen extends ConsumerStatefulWidget {
  const PlayerEvaluationScreen({super.key});

  @override
  ConsumerState<PlayerEvaluationScreen> createState() =>
      _PlayerEvaluationScreenState();
}

class _PlayerEvaluationScreenState extends ConsumerState<PlayerEvaluationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // --- CAMBIO: IDs fijos para los tests ---
  static const String _saltoId = 'salto_vertical';
  static const String _agilidadId = 'agilidad_t_test';
  static const String _velocidadId = 'velocidad_20m';
  static const String _fuerzaId = 'fuerza_press';

  // Controladores para los tests
  late final TextEditingController _saltoController;
  late final TextEditingController _agilidadController;
  late final TextEditingController _velocidadController;
  late final TextEditingController _fuerzaController;
  
  // --- CAMBIO: Helper para parsear de forma segura ---
  double? _parseDouble(String? text) {
    if (text == null) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }
  
  /// Helper para buscar un valor en la lista de TestScore
  String _findScore(List<TestScore>? scores, String testId) {
    if (scores == null) return '';
    final score = scores.firstWhereOrNull((s) => s.testId == testId);
    // Devuelve el valor como string, o un string vacío si no se encuentra
    return score?.value.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    // --- CAMBIO: Lee la lista 'testScores' del 'latestEvaluation' ---
    final scores = ref.read(playerProfileProvider).value?.latestEvaluation?.testScores;

    // Rellena los controladores buscando en la lista
    _saltoController = TextEditingController(text: _findScore(scores, _saltoId));
    _agilidadController = TextEditingController(text: _findScore(scores, _agilidadId));
    _velocidadController = TextEditingController(text: _findScore(scores, _velocidadId));
    _fuerzaController = TextEditingController(text: _findScore(scores, _fuerzaId));
  }

  @override
  void dispose() {
    _saltoController.dispose();
    _agilidadController.dispose();
    _velocidadController.dispose();
    _fuerzaController.dispose();
    super.dispose();
  }

  // --- CAMBIO: _saveForm ahora usa el provider ---
  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      
      // 1. Obtener los datos del jugador (no del coach)
      final player = ref.read(currentUserAppUserProvider).value;
      final currentProfile = ref.read(playerProfileProvider).value;

      if (player == null) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Error: No se pudo encontrar el usuario.'), backgroundColor: Colors.red),
         );
         return;
      }
      
      // 2. Crear la lista de TestScore desde los campos
      final newTestScores = [
        TestScore(
          testId: _saltoId,
          value: _parseDouble(_saltoController.text) ?? 0.0,
          unit: 'cm', // Unidad fija para este campo
        ),
        TestScore(
          testId: _agilidadId,
          value: _parseDouble(_agilidadController.text) ?? 0.0,
          unit: 'seg', // Unidad fija para este campo
        ),
        TestScore(
          testId: _velocidadId,
          value: _parseDouble(_velocidadController.text) ?? 0.0,
          unit: 'seg', // Unidad fija para este campo
        ),
        TestScore(
          testId: _fuerzaId,
          value: _parseDouble(_fuerzaController.text) ?? 0.0,
          unit: 'kg', // Unidad fija para este campo
        ),
      ];
      
      // 3. Actualizar el estado del provider
      // (Esto sobreescribe cualquier test que estuviera en el editor)
      ref.read(evaluationEditorProvider.notifier).state = newTestScores;

      // 4. Llamar a la lógica de guardado centralizada
      try {
        await ref.read(evaluationEditorProvider.notifier).saveEvaluation(
          player,
          currentProfile,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evaluación guardada con éxito'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
          );
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa el estado de carga del provider
    final isSaving = ref.watch(evaluationIsSavingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Evaluación Física'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            // Desactiva el botón si está guardando
            onPressed: isSaving ? null : _saveForm,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('Resultados de Tests', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Ingresa tus resultados más recientes. Usa un punto (.) para decimales.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _saltoController,
              decoration: const InputDecoration(labelText: 'Salto Vertical', suffixText: 'cm'), // Unidad actualizada
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _agilidadController,
              decoration: const InputDecoration(labelText: 'Agilidad (T-Test)', suffixText: 'seg'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _velocidadController,
              decoration: const InputDecoration(labelText: 'Velocidad 20m', suffixText: 'seg'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fuerzaController,
              decoration: const InputDecoration(labelText: 'Fuerza (Press)', suffixText: 'kg'), // Unidad actualizada
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              // Desactiva el botón si está guardando
              onPressed: isSaving ? null : _saveForm,
              child: isSaving 
                ? const SizedBox(
                    height: 24, 
                    width: 24, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Text('Guardar Evaluación'),
            ),
          ],
        ),
      ),
    );
  }
}