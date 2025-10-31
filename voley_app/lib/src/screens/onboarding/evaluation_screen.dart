// lib/screens/evaluation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:uuid/uuid.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';

class EvaluationScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  final nameCtrl = TextEditingController();
  final positionCtrl = TextEditingController();
  final levelCtrl = TextEditingController();
  final testScoreCtrl = TextEditingController();
  final tournamentCtrl = TextEditingController();
  final uuid = Uuid();

  String selectedPosition = 'Central';
  String selectedLevel = 'Competitivo';
  List<String> selectedDays = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluación Inicial')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Nombre')),
          DropdownButtonFormField<String>(
            initialValue: selectedPosition,
            items: ['Central', 'Libero', 'Punta', 'Opuesto'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedPosition = newValue!;
              });
            },
            decoration: InputDecoration(labelText: 'Posición'),
          ),
          DropdownButtonFormField<String>(
            initialValue: selectedLevel,
            items: ['Competitivo', 'Recreativo'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedLevel = newValue!;
              });
            },
            decoration: InputDecoration(labelText: 'Nivel'),
          ),
          CheckboxListTile(
            title: const Text('Lunes'),
            value: selectedDays.contains('Lunes'),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedDays.add('Lunes');
                } else {
                  selectedDays.remove('Lunes');
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Miércoles'),
            value: selectedDays.contains('Miércoles'),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedDays.add('Miércoles');
                } else {
                  selectedDays.remove('Miércoles');
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Viernes'),
            value: selectedDays.contains('Viernes'),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedDays.add('Viernes');
                } else {
                  selectedDays.remove('Viernes');
                }
              });
            },
          ),
          TextField(controller: tournamentCtrl, decoration: InputDecoration(labelText: 'Torneos')),
          TextField(controller: testScoreCtrl, decoration: InputDecoration(labelText: 'Puntuación de Test')),
          const SizedBox(height: 12),
          
          // --- INICIO DE LA SECCIÓN CORREGIDA ---
          ElevatedButton(
            onPressed: () {

              // 1. Obtener los nombres del TextField
              final List<String> tournamentNames = tournamentCtrl.text
                  .split(',')
                  .where((name) => name.trim().isNotEmpty) // Filtra nombres vacíos
                  .toList();

              // 2. Convertir List<String> en List<Tournament>
              //    (Usando una fecha de ejemplo, ya que el TextField no la provee)
              final List<Tournament> tournaments = tournamentNames.map((name) {
                return Tournament(
                  name: name.trim(), // Limpia espacios
                  date: DateTime.now().add(const Duration(days: 90)), // Fecha de ejemplo
                );
              }).toList();
              
              // 3. Crear el perfil con la lista de torneos CORREGIDA
              final profile = PlayerProfile(
                id: uuid.v4(),
                name: nameCtrl.text.isEmpty ? 'Jugadora Demo' : nameCtrl.text,
                position: selectedPosition,
                level: selectedLevel,
                goals: ['salto', 'fuerza'],
                injuries: [],
                availability: Availability(trainingDays: selectedDays, sessionMinutes: 90),
                evaluation: EvaluationResult(testScores: {'salto': double.tryParse(testScoreCtrl.text) ?? 0.0}, strengths: ['potencia'], weaknesses: ['resistencia']),
                tournaments: tournaments, // <-- ¡CORREGIDO!
              );
              
              ref.read(playerProfileProvider.notifier).state = profile;
              Navigator.pushNamed(context, '/generate');
            },
            child: Text('Guardar evaluación y generar programa'),
          ),
          // --- FIN DE LA SECCIÓN CORREGIDA ---
          
        ]),
      ),
    );
  }
}