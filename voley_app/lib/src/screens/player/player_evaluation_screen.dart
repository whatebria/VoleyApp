// lib/screens/player_evaluation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';

class PlayerEvaluationScreen extends ConsumerStatefulWidget {
  const PlayerEvaluationScreen({super.key});

  @override
  ConsumerState<PlayerEvaluationScreen> createState() =>
      _PlayerEvaluationScreenState();
}

class _PlayerEvaluationScreenState extends ConsumerState<PlayerEvaluationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los tests
  late final TextEditingController _saltoController;
  late final TextEditingController _agilidadController;
  late final TextEditingController _velocidadController;
  late final TextEditingController _fuerzaController;

  @override
  void initState() {
    super.initState();
    final scores = ref.read(playerProfileProvider).asData?.value?.evaluation.testScores;

    _saltoController = TextEditingController(text: scores?['Salto Vertical']?.toString() ?? '');
    _agilidadController = TextEditingController(text: scores?['Agilidad (T-Test)']?.toString() ?? '');
    _velocidadController = TextEditingController(text: scores?['Velocidad 20m']?.toString() ?? '');
    _fuerzaController = TextEditingController(text: scores?['Fuerza (Press)']?.toString() ?? '');
  }

  @override
  void dispose() {
    _saltoController.dispose();
    _agilidadController.dispose();
    _velocidadController.dispose();
    _fuerzaController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      // Creamos el mapa de scores actualizado
      final updatedScores = {
        'Salto Vertical': double.tryParse(_saltoController.text) ?? 0.0,
        'Agilidad (T-Test)': double.tryParse(_agilidadController.text) ?? 0.0,
        'Velocidad 20m': double.tryParse(_velocidadController.text) ?? 0.0,
        'Fuerza (Press)': double.tryParse(_fuerzaController.text) ?? 0.0,
      };

      // TODO: Llamar al Notifier para guardar
      // ref.read(playerProfileProvider.notifier).updateEvaluation(updatedScores);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluación guardada (simulado)')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Evaluación Física'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
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
              decoration: const InputDecoration(labelText: 'Salto Vertical', suffixText: 'pts/cm'),
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
              decoration: const InputDecoration(labelText: 'Fuerza (Press)', suffixText: 'kg/pts'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveForm,
              child: const Text('Guardar Evaluación'),
            ),
          ],
        ),
      ),
    );
  }
}