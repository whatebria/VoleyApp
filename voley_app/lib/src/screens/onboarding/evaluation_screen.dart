// lib/screens/evaluation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:uuid/uuid.dart';

class EvaluationScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  final nameCtrl = TextEditingController();
  final uuid = Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluación Inicial')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Nombre')),
          // aquí agregarías campos complejos para tests, nivel, posición, disponibilidad, torneos...
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // crear un profile demo rápido (reemplazar por inputs reales)
              final profile = PlayerProfile(
                id: uuid.v4(),
                name: nameCtrl.text.isEmpty ? 'Jugadora Demo' : nameCtrl.text,
                position: 'Central',
                level: 'Competitivo',
                goals: ['salto', 'fuerza'],
                injuries: [],
                availability: Availability(trainingDays: ['Lunes', 'Miércoles', 'Viernes'], sessionMinutes: 90),
                evaluation: EvaluationResult(testScores: {'salto': 34.0}, strengths: ['potencia'], weaknesses: ['resistencia']),
                tournaments: [],
              );
              ref.read(playerProfileProvider.notifier).state = profile;
              Navigator.pushNamed(context, '/generate');
            },
            child: Text('Guardar evaluación y generar programa'),
          ),
        ]),
      ),
    );
  }
}
