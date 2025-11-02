import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/mesocycles.dart';
import 'package:voley_app/src/models/program/microcicle.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/screens/exercise_picker_screen.dart';
import 'package:uuid/uuid.dart';

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

  // Controladores para el formulario del Mesociclo
  final _mesoFormKey = GlobalKey<FormState>();
  final _mesoNameCtrl = TextEditingController();
  final _mesoFocusCtrl = TextEditingController();
  
  // Estado para los selectores "bonitos"
  int _mesoWeeks = 4;
  int _mesoSessions = 3;
  String _mesoProgressionType = 'lineal';

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

  @override
  void dispose() {
    _mesoNameCtrl.dispose();
    _mesoFocusCtrl.dispose();
    super.dispose();
  }

  // --- LÓGICA DE GUARDADO (Sin cambios) ---
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

  // --- NAVEGACIÓN (Sin cambios) ---
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
    setState(() {}); // Refresca la UI
  }

  // --- LÓGICA DE CREACIÓN (Modificada) ---

  /// Guarda el formulario del nuevo Mesociclo
  void _saveNewMesocycle() {
    if (_mesoFormKey.currentState!.validate()) {
      final int weeks = _mesoWeeks;
      final int sessionsPerWeek = _mesoSessions;

      final microcycles = List.generate(weeks, (i) {
        final sessions = List.generate(sessionsPerWeek, (j) {
          return TrainingSession(
            day: 'Día ${j + 1}',
            objective: _mesoFocusCtrl.text,
            load: 0.5,
            exercises: [],
          );
        });
        return Microcycle(weekNumber: i + 1, sessions: sessions);
      });

      final newMeso = Mesocycle(
        name: _mesoNameCtrl.text,
        weeks: weeks,
        focus: _mesoFocusCtrl.text,
        progressionType: _mesoProgressionType,
        microcycles: microcycles,
      );

      setState(() {
        _program.mesocycles.insert(0, newMeso); // Añade el nuevo meso al INICIO de la lista
        _clearMesoForm(); // Limpia los campos
        // Cierra el teclado
        FocusScope.of(context).unfocus(); 
      });
    }
  }

  /// Limpia los controladores del formulario
  void _clearMesoForm() {
    _mesoFormKey.currentState?.reset();
    _mesoNameCtrl.clear();
    _mesoFocusCtrl.clear();
    setState(() {
       _mesoWeeks = 4;
       _mesoSessions = 3;
       _mesoProgressionType = 'lineal';
    });
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
        key: PageStorageKey(session.day + session.objective),
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

  /// Selector de número con botones +/-
  Widget _buildNumberStepper({
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => onChanged(value - 1),
            ),
            Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }

  /// (MODIFICADO) Construye el formulario "bonito" como un Card
  Widget _buildMesoForm() {
    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Form(
        key: _mesoFormKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crear Nuevo Mesociclo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mesoNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Bloque',
                  helperText: 'Ej: Base, Fuerza, Potencia',
                  prefixIcon: Icon(Icons.label_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mesoFocusCtrl,
                decoration: const InputDecoration(
                  labelText: 'Foco Principal',
                  helperText: 'Ej: Hipertrofia, Salto Vertical',
                  prefixIcon: Icon(Icons.center_focus_strong_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              
              _buildNumberStepper(
                title: 'Semanas:',
                value: _mesoWeeks,
                onChanged: (newValue) {
                  if (newValue > 0 && newValue <= 12) {
                    setState(() => _mesoWeeks = newValue);
                  }
                },
              ),
              
              _buildNumberStepper(
                title: 'Sesiones por Semana:',
                value: _mesoSessions,
                onChanged: (newValue) {
                  if (newValue > 0 && newValue <= 7) {
                    setState(() => _mesoSessions = newValue);
                  }
                },
              ),
              const SizedBox(height: 16),
              
              Text('Tipo de Progresión', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'lineal', label: Text('Lineal'), icon: Icon(Icons.show_chart)),
                  ButtonSegment(value: 'progresiva', label: Text('Progresiva'), icon: Icon(Icons.trending_up)),
                  ButtonSegment(value: 'ondulante', label: Text('Ondulante'), icon: Icon(Icons.waterfall_chart)),
                ],
                selected: {_mesoProgressionType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _mesoProgressionType = newSelection.first);
                },
              ),
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Añadir Mesociclo'),
                onPressed: _saveNewMesocycle,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// (MODIFICADO) Construye la lista de mesociclos (ya no es un widget separado)
  List<Widget> _buildProgramListItems() {
    if (_program.mesocycles.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No hay mesociclos. Añade uno para empezar.', 
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }
    
    // Mapea la lista de mesociclos a una lista de Cards
    return _program.mesocycles.map((meso) {
      final mesoIndex = _program.mesocycles.indexOf(meso);
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        elevation: 2,
        child: ExpansionTile(
          key: PageStorageKey(meso.name + mesoIndex.toString()),
          title: Text(meso.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${meso.weeks} semanas - ${meso.focus}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Eliminar Mesociclo',
            onPressed: () => setState(() => _program.mesocycles.removeAt(mesoIndex)),
          ),
          children: meso.microcycles.map((micro) {
            return ExpansionTile(
              key: PageStorageKey(meso.name + micro.weekNumber.toString()),
              title: Text('  Semana ${micro.weekNumber}', style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('  ${micro.sessions.length} sesiones'),
              children: micro.sessions.map((session) {
                return _buildSessionTile(session);
              }).toList(),
            );
          }).toList(),
        ),
      );
    }).toList();
  }


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
          // --- (NUEVA ESTRUCTURA) ---
          // Un ListView que contiene el formulario y la lista
          ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // 1. El formulario "bonito"
              _buildMesoForm(),
              
              // 2. Título de la lista
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Mesociclos del Programa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 3. La lista de mesociclos creados
              ..._buildProgramListItems(),
            ],
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      // (FAB ELIMINADO)
    );
  }
}
