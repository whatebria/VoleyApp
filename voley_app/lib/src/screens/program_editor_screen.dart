// lib/screens/program_editor_screen.dart (NUEVO ARCHIVO)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/mesocycles.dart';
import 'package:voley_app/src/models/program/microcicle.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:uuid/uuid.dart';
import 'package:voley_app/src/screens/exercise_picker_screen.dart';

class ProgramEditorScreen extends ConsumerStatefulWidget {
  final PlayerProfile profile;
  const ProgramEditorScreen({super.key, required this.profile});

  @override
  _ProgramEditorScreenState createState() => _ProgramEditorScreenState();
}

class _ProgramEditorScreenState extends ConsumerState<ProgramEditorScreen> {
  late Program _program;
  bool _isLoading = false;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _program = Program(
      id: _uuid.v4(),
      source: 'Manual (${widget.profile.name})',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 28)),
      mesocycles: [],
    );
  }

  // --- LÓGICA DE GUARDADO ---
  Future<void> _saveProgram() async {
    setState(() => _isLoading = true);
    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.saveProgram(widget.profile.id, _program);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Programa manual guardado'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error al guardar: $e');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // --- NAVEGACIÓN ---
  void _navigateToExercisePicker(TrainingSession session) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExercisePickerScreen(
          session: session,
          profile: widget.profile,
        ),
      ),
    );
    // Refresca la UI para mostrar los ejercicios añadidos
    setState(() {});
  }

  // --- DIÁLOGOS DE EDICIÓN ---

  /// Muestra el diálogo para AÑADIR un nuevo Mesociclo
  Future<void> _showMesocycleDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final focusCtrl = TextEditingController();
    final weeksCtrl = TextEditingController(text: '4');
    final sessionsPerWeekCtrl = TextEditingController(text: '3');
    String progressionType = 'lineal';

    final result = await showDialog<Mesocycle>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuevo Mesociclo'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre (Ej: Base)'),
                    validator: (val) => val!.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: focusCtrl,
                    decoration: const InputDecoration(labelText: 'Foco (Ej: Fuerza General)'),
                    validator: (val) => val!.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: weeksCtrl,
                    decoration: const InputDecoration(labelText: 'Semanas'),
                    keyboardType: TextInputType.number,
                    validator: (val) => (int.tryParse(val!) == null || int.parse(val) <= 0) ? 'Número inválido' : null,
                  ),
                  TextFormField(
                    controller: sessionsPerWeekCtrl,
                    decoration: const InputDecoration(labelText: 'Sesiones por Semana'),
                    keyboardType: TextInputType.number,
                    validator: (val) => (int.tryParse(val!) == null || int.parse(val) <= 0) ? 'Número inválido' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: progressionType,
                    decoration: const InputDecoration(labelText: 'Progresión'),
                    items: ['lineal', 'progresiva', 'ondulante'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => progressionType = val!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final int weeks = int.parse(weeksCtrl.text);
                  final int sessionsPerWeek = int.parse(sessionsPerWeekCtrl.text);

                  // Crea los microciclos y sesiones vacías
                  final microcycles = List.generate(weeks, (i) {
                    final sessions = List.generate(sessionsPerWeek, (j) {
                      return TrainingSession(
                        day: 'Día ${j + 1}',
                        objective: focusCtrl.text,
                        load: 0.5,
                        exercises: [],
                      );
                    });
                    return Microcycle(weekNumber: i + 1, sessions: sessions);
                  });

                  // Crea el nuevo Mesociclo
                  final newMeso = Mesocycle(
                    name: nameCtrl.text,
                    weeks: weeks,
                    focus: focusCtrl.text,
                    progressionType: progressionType,
                    microcycles: microcycles,
                  );
                  Navigator.pop(context, newMeso);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => _program.mesocycles.add(result));
    }
  }

  /// Muestra el diálogo para EDITAR una Sesión (día y objetivo)
  Future<void> _showEditSessionDialog(TrainingSession session) async {
    final objectiveCtrl = TextEditingController(text: session.objective);
    String selectedDay = session.day;
    if (!_allDays.contains(selectedDay)) {
      selectedDay = _allDays.first;
    }

    final result = await showDialog<TrainingSession>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Sesión'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDay,
                decoration: const InputDecoration(labelText: 'Día de la Semana'),
                items: _allDays.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => selectedDay = val!,
              ),
              TextFormField(
                controller: objectiveCtrl,
                decoration: const InputDecoration(labelText: 'Objetivo'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                // Devuelve una *nueva* instancia de TrainingSession
                Navigator.pop(context, session.copyWith(
                  day: selectedDay,
                  objective: objectiveCtrl.text,
                ));
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      // Reemplaza la sesión antigua por la nueva
      setState(() {
        for (var meso in _program.mesocycles) {
          for (var micro in meso.microcycles) {
            final sessionIndex = micro.sessions.indexOf(session);
            if (sessionIndex != -1) {
              micro.sessions[sessionIndex] = result;
              return;
            }
          }
        }
      });
    }
  }

  // --- WIDGETS DE CONSTRUCCIÓN ---

  /// Construye la UI para una sola sesión
  Widget _buildSessionTile(TrainingSession session) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ExpansionTile(
        title: Text(session.day, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(session.objective),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              tooltip: 'Editar Día/Objetivo',
              onPressed: () => _showEditSessionDialog(session),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              tooltip: 'Eliminar Sesión',
              onPressed: () {
                // Lógica para encontrar y eliminar la sesión
                setState(() {
                   for (var meso in _program.mesocycles) {
                    for (var micro in meso.microcycles) {
                      micro.sessions.remove(session);
                    }
                  }
                });
              },
            ),
          ],
        ),
        children: [
          // Muestra los ejercicios dentro de la sesión
          if (session.exercises.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Añade ejercicios...'),
            ),
          ...session.exercises.map((ex) {
            return ListTile(
              title: Text(ex.name),
              subtitle: Text('${ex.sets}x${ex.reps} @ ${ex.intensity}'),
              dense: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                onPressed: () {
                  setState(() => session.exercises.remove(ex));
                },
              ),
            );
          }),
          // Botón para ir al ExercisePicker
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Añadir/Editar Ejercicios'),
              onPressed: () => _navigateToExercisePicker(session),
            ),
          ),
        ],
      ),
    );
  }

  final List<String> _allDays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editor Manual: ${widget.profile.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar Programa',
            onPressed: _isLoading ? null : _saveProgram,
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
            itemCount: _program.mesocycles.length,
            itemBuilder: (context, mesoIndex) {
              final meso = _program.mesocycles[mesoIndex];
              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 2,
                child: ExpansionTile(
                  key: PageStorageKey(meso.name),
                  title: Text(meso.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${meso.weeks} semanas - ${meso.focus}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => setState(() => _program.mesocycles.removeAt(mesoIndex)),
                  ),
                  children: meso.microcycles.map((micro) {
                    return ExpansionTile(
                      key: PageStorageKey(meso.name + micro.weekNumber.toString()),
                      title: Text('  Semana ${micro.weekNumber}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('  ${micro.sessions.length} sesiones'),
                      // Los hijos son ahora las tarjetas de sesión
                      children: micro.sessions.map((session) {
                        return _buildSessionTile(session);
                      }).toList(),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMesocycleDialog,
        child: const Icon(Icons.add),
        tooltip: 'Añadir Mesociclo',
      ),
    );
  }
}

