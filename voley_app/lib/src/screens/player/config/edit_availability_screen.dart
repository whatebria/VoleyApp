// lib/screens/edit_availability_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';

class EditAvailabilityScreen extends ConsumerStatefulWidget {
  const EditAvailabilityScreen({super.key});

  @override
  ConsumerState<EditAvailabilityScreen> createState() =>
      _EditAvailabilityScreenState();
}

class _EditAvailabilityScreenState extends ConsumerState<EditAvailabilityScreen> {
  
  // Estado local para los switches
  final Map<String, bool> _trainingDays = {
    'Lunes': false, 'Martes': false, 'Miércoles': false, 'Jueves': false,
    'Viernes': false, 'Sábado': false, 'Domingo': false,
  };
  
  late final TextEditingController _sessionMinutesController;
  late final TextEditingController _injuriesController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(playerProfileProvider).asData?.value;

    // Inicializar switches
    profile?.availability.trainingDays.forEach((day) {
      if (_trainingDays.containsKey(day)) {
        _trainingDays[day] = true;
      }
    });

    // Inicializar controladores
    _sessionMinutesController = TextEditingController(
      text: profile?.availability.sessionMinutes.toString() ?? '60',
    );
    _injuriesController = TextEditingController(
      text: profile?.injuries.join('\n') ?? '', // Unimos con saltos de línea
    );
  }

  @override
  void dispose() {
    _sessionMinutesController.dispose();
    _injuriesController.dispose();
    super.dispose();
  }

  void _saveForm() {
    // Convertir el mapa de switches a una lista de strings
    final selectedDays = _trainingDays.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    final sessionMinutes = int.tryParse(_sessionMinutesController.text) ?? 60;
    
    // Convertir el texto de lesiones a una lista
    final injuries = _injuriesController.text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    // TODO: Llamar al Notifier para guardar
    // ref.read(playerProfileProvider.notifier).updateAvailability(
    //   days: selectedDays,
    //   minutes: sessionMinutes,
    //   injuries: injuries,
    // );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estado guardado (simulado)')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disponibilidad y Estado'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Días de Entrenamiento', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ..._trainingDays.keys.map((day) {
            return SwitchListTile(
              title: Text(day),
              value: _trainingDays[day]!,
              onChanged: (bool value) {
                setState(() {
                  _trainingDays[day] = value;
                });
              },
            );
          }).toList(),
          
          const Divider(height: 32),
          
          Text('Logística', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sessionMinutesController,
            decoration: const InputDecoration(
              labelText: 'Duración de Sesión (minutos)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          
          const Divider(height: 32),

          Text('Lesiones', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Añade lesiones activas o molestias. Una por línea.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _injuriesController,
            decoration: const InputDecoration(
              labelText: 'Lesiones (una por línea)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveForm,
            child: const Text('Guardar Cambios'),
          ),
        ],
      ),
    );
  }
}