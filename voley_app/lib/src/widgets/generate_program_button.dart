// lib/src/widgets/generate_program_button.dart
import 'package:flutter/material.dart';
import 'package:voley_app/src/models/athlete/athlete.dart';
import 'package:voley_app/src/services/training_program_service.dart';
import '../models/evaluation.dart';

class GenerateProgramButton extends StatefulWidget {
  final Athlete athlete;
  final Evaluation? lastEvaluation;

  const GenerateProgramButton({
    super.key,
    required this.athlete,
    this.lastEvaluation,
  });

  @override
  State<GenerateProgramButton> createState() => _GenerateProgramButtonState();
}

class _GenerateProgramButtonState extends State<GenerateProgramButton> {
  bool _loading = false;
  Map<String, dynamic>? _lastProgram;

  final _service = TrainingProgramService();

  Future<void> _onGenerate() async {
    setState(() => _loading = true);
    try {
      final result = await _service.generateAndSaveProgram(
        athlete: widget.athlete,
        lastEvaluation: widget.lastEvaluation,
      );
      setState(() => _lastProgram = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Programa generado: ${result['name']}')),
      );
    } catch (e, st) {
      debugPrint('Error generando programa: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generando programa: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _loading ? null : _onGenerate,
          icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_fix_high),
          label: Text(_loading ? 'Generando...' : 'Generar Programa'),
        ),
        const SizedBox(height: 12),
        if (_lastProgram != null) _buildProgramPreview(_lastProgram!),
      ],
    );
  }

  Widget _buildProgramPreview(Map<String, dynamic> program) {
    final exercises = List<Map<String, dynamic>>.from(program['exercises'] ?? []);
    final recs = List<String>.from(program['recommendations'] ?? []);

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(program['name'] ?? 'Programa', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Focus: ${program['focus']} • Intensidad: ${program['intensity']}'),
            const SizedBox(height: 8),
            Text('Ejercicios (${exercises.length}):', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 6),
            ...exercises.take(8).map((e) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e['name'] ?? e['title'] ?? 'Sin nombre'),
                  subtitle: Text((e['tags'] ?? []).join(', ')),
                )),
            if (exercises.length > 8) Text('... y ${exercises.length - 8} más'),
            const SizedBox(height: 8),
            Text('Recomendaciones:', style: Theme.of(context).textTheme.bodyLarge),
            ...recs.map((r) => Text('• $r')),
          ],
        ),
      ),
    );
  }
}
