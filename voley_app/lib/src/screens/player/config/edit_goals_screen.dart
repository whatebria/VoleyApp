// lib/screens/edit_goals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';

class EditGoalsScreen extends ConsumerStatefulWidget {
  const EditGoalsScreen({super.key});

  @override
  ConsumerState<EditGoalsScreen> createState() => _EditGoalsScreenState();
}

class _EditGoalsScreenState extends ConsumerState<EditGoalsScreen> {
  late final TextEditingController _goalsController;

  @override
  void initState() {
    super.initState();
    final goals = ref.read(playerProfileProvider).asData?.value?.goals;
    // Unimos los objetivos con un salto de línea para el textfield
    _goalsController = TextEditingController(text: goals?.join('\n') ?? '');
  }

  @override
  void dispose() {
    _goalsController.dispose();
    super.dispose();
  }

  void _saveForm() {
    // Convertimos el texto (separado por líneas) en una lista de strings
    final goalsList = _goalsController.text
        .split('\n')
        .where((line) => line.trim().isNotEmpty) // Filtra líneas vacías
        .toList();

    // TODO: Llamar al Notifier para guardar
    // ref.read(playerProfileProvider.notifier).updateGoals(goalsList);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Objetivos guardados (simulado)')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Objetivos'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mis Objetivos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Define tus metas principales para la temporada. Escribe un objetivo por línea.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextFormField(
                controller: _goalsController,
                decoration: const InputDecoration(
                  labelText: 'Objetivos (uno por línea)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null, // Expande
                expands: true, // Expande
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveForm,
              child: const Text('Guardar Objetivos'),
            ),
          ],
        ),
      ),
    );
  }
}