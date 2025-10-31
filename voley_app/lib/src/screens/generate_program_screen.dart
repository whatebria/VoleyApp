// lib/screens/generate_program_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';

class GenerateProgramScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);
    final exercisesAsync = ref.watch(exercisesProvider);
    final generateAction = ref.read(programGeneratorAction);

    return Scaffold(
      appBar: AppBar(title: const Text('Generador Automático')),
      body: Center(
        child: profile == null ? Text('Por favor completa la evaluación primero') : exercisesAsync.when(
          data: (exercises) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Generar programa para ${profile.name}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final prog = await generateAction(profile, exercises);
                  if (prog != null) Navigator.pushNamed(context, '/program');
                },
                child: const Text('Generar'),
              ),
            ],
          ),
          loading: () => CircularProgressIndicator(),
          error: (e, s) => Text('Error cargando ejercicios'),
        ),
      ),
    );
  }
}
