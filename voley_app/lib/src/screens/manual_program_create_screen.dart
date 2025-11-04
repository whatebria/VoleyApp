import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/mesocycles.dart';
import 'package:voley_app/src/models/program/microcicle.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart'; // Necesario para la UI
import 'package:voley_app/src/screens/exercise_picker_screen.dart';
import 'package:uuid/uuid.dart';

// --- CAMBIO: _SessionTemplate eliminado ---

class ManualProgramCreateScreen extends ConsumerStatefulWidget {
  final PlayerProfile profile;
  const ManualProgramCreateScreen({super.key, required this.profile});

  @override
  _ManualProgramCreateScreenState createState() => _ManualProgramCreateScreenState();
}

class _ManualProgramCreateScreenState extends ConsumerState<ManualProgramCreateScreen> {
  Mesocycle? _currentEditingMeso;
  late Program _program;
  bool _isSaving = false;
  final Uuid _uuid = const Uuid();

  final _mesoFormKey = GlobalKey<FormState>();
  final _mesoNameCtrl = TextEditingController();
  final _mesoObjectiveCtrl = TextEditingController(); // --- AÑADIDO ---
  int _mesoWeeks = 4;
  int _mesoSessions = 3;
  // --- CAMBIO: 'progressionType' ya no se controla desde la UI ---


  @override
  void initState() {
    super.initState();
    _program = Program(
      id: _uuid.v4(),
      title: 'Nuevo Programa para ${widget.profile.name}',
      source: 'Manual',
      startDate: DateTime.now(),
      endDate: DateTime.now(), 
      mesocycles: [],
    );
  }
  
  // --- CAMBIO: _generateSessionTemplates eliminado ---

  // --- CAMBIO: Lógica de carga simplificada ---
  double _suggestedLoadFor(int weekIndex, int totalWeeks) {
    final normalizedIndex = totalWeeks <= 1 ? 0 : weekIndex / (totalWeeks - 1);
    // Progresión lineal simple de 0.6 a 0.85
    return double.parse((0.6 + 0.25 * normalizedIndex).toStringAsFixed(2));
  }

  // --- CAMBIO: Esta función ya no se usa para crear por defecto ---
  // Se mantiene por si se usa en otro lado, o se puede eliminar.
  List<WorkoutExercise> _buildDefaultSegmentExercises(String focus) {
    return [
      WorkoutExercise(
        exerciseId: _uuid.v4(),
        name: 'Calentamiento y movilidad',
        sets: 1,
        reps: '10-15 minutos',
        intensity: 'Suave',
      ),
      // ...
    ];
  }

  @override
  void dispose() {
    _mesoNameCtrl.dispose();
    _mesoObjectiveCtrl.dispose(); // --- AÑADIDO ---
    super.dispose();
  }

  // --- LÓGICA DE PROGRAMA Y ACCIONES ---
  Future<void> _saveProgram() async {
    if (_program.mesocycles.isEmpty) {
      _showError(
        'El programa debe contener al menos un Bloque de Entrenamiento.',
      );
      return;
    }

    setState(() => _isSaving = true);
    
    final totalWeeks = _program.mesocycles.fold<int>(0, (sum, meso) => sum + meso.weeks);
    _program = _program.copyWith(
      endDate: _program.startDate.add(Duration(days: totalWeeks * 7)),
    );

    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.saveProgram(widget.profile.id, _program);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Programa guardado'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Error al guardar: $e');
      }
    }
  }

  // --- CAMBIO: Lógica de guardado de Mesociclo ---
  void _saveNewMesocycle() {
    if (_mesoFormKey.currentState!.validate()) {
      final weeks = _mesoWeeks;
      final sessionsPerWeek = _mesoSessions;

      // --- CAMBIO: Ya no se usan plantillas ---
      final microcycles = List.generate(weeks, (i) {
        
        // --- CAMBIO: Genera sesiones 'vacías' ---
        final sessions = List.generate(sessionsPerWeek, (sIndex) {
          return TrainingSession(
            id: _uuid.v4(),
            day: 'Sesión ${sIndex + 1}',
            // --- CAMBIO: 'objective' eliminado ---
            load: _suggestedLoadFor(i, weeks), 
            exercises: [], objective: '', // --- CAMBIO: Inicia con 0 ejercicios ---
          );
        });

        return Microcycle(
          weekNumber: i + 1,
          sessions: sessions,
          id: _uuid.v4(),
        );
      });

      final newMeso = Mesocycle(
        id: _uuid.v4(),
        name: _mesoNameCtrl.text,
        objective: _mesoObjectiveCtrl.text, // --- AÑADIDO ---
        weeks: weeks,
        focus: "Personalizado", // 'focus' de Mesocycle (ya no es del form)
        // --- CAMBIO: 'progressionType' y 'matchDayIndex' con valor por defecto ---
        progressionType: 'lineal', 
        matchDayIndex: 5, // 5 = Sábado (valor por defecto)
        microcycles: microcycles,
      );

      setState(() {
        final updatedMesocycles = List<Mesocycle>.from(_program.mesocycles);
        updatedMesocycles.insert(0, newMeso);
        _program = _program.copyWith(mesocycles: updatedMesocycles);
        _clearMesoForm();
        _currentEditingMeso = newMeso;
      });
    }
  }

  void _navigateToExercisePicker(TrainingSession session) async {
    final updatedSession = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExercisePickerScreen(session: session, profile: widget.profile),
      ),
    );

    if (updatedSession is TrainingSession) {
      setState(() {
        final newMesocycles = _program.mesocycles.map((meso) {
          final microIndex = meso.microcycles.indexWhere(
            (micro) => micro.sessions.any((s) => s.id == updatedSession.id),
          );
          if (microIndex == -1) return meso;

          final newMicrocycles = meso.microcycles.map((micro) {
            if (micro.weekNumber == meso.microcycles[microIndex].weekNumber) {
              final newSessions = micro.sessions
                  .map((s) => s.id == updatedSession.id ? updatedSession : s)
                  .toList();
              return micro.copyWith(sessions: newSessions);
            }
            return micro;
          }).toList();
          return meso.copyWith(microcycles: newMicrocycles);
        }).toList();
        _program = _program.copyWith(mesocycles: newMesocycles);
      });
    }
  }

  // --- HELPER METHODS ---

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
  
  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }


  void _deleteMesocycle(Mesocycle meso) {
    setState(() {
      final updatedMesocycles = _program.mesocycles
          .where((m) => m.id != meso.id)
          .toList();
      _program = _program.copyWith(mesocycles: updatedMesocycles);

      if (_currentEditingMeso == meso) {
        _currentEditingMeso = null;
      }
    });
  }

  // --- CAMBIO: Limpieza de formulario ---
  void _clearMesoForm() {
    _mesoFormKey.currentState?.reset();
    _mesoNameCtrl.clear();
    _mesoObjectiveCtrl.clear(); // --- AÑADIDO ---
    _mesoWeeks = 4;
    _mesoSessions = 3;
    // --- CAMBIO: 'progressionType' eliminado ---
  }

  // --- MEJORA DE UX: Diálogo de Creación (Modal) ---
  void _showCreateMesoModal(BuildContext context, ThemeData theme) {
    _clearMesoForm();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface, // grisPro
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: _buildMesoForm(
                context,
                theme,
                setModalState,
              ), 
            );
          },
        );
      },
    );
  }

  // --- WIDGETS DE CONSTRUCCIÓN ---

  // --- AÑADIDO: Helper para Títulos de Sección en el Modal ---
  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 20), // azulPro
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  // --- AÑADIDO: Helper para Recordatorio de Disponibilidad ---
  Widget _buildAvailabilityReminder(ThemeData theme) {
    // Leemos la disponibilidad del perfil del jugador
    final availability = widget.profile.availability;
    
    // Si no definió días, no mostramos nada.
    if (availability.trainingDays.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Días disponibles del atleta:", 
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7)
            )
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: availability.trainingDays.map((day) => Chip(
              label: Text(day),
              backgroundColor: theme.colorScheme.secondary.withOpacity(0.2), // azulPro
              labelStyle: TextStyle(color: theme.colorScheme.onSurface),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            )).toList(),
          ),
        ],
      ),
    );
  }


  // --- CAMBIO: Formulario de Mesociclo rediseñado con Cards ---
  Widget _buildMesoForm(
    BuildContext context,
    ThemeData theme,
    StateSetter setModalState,
  ) {
    return Form(
      key: _mesoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Crear Bloque de Entrenamiento',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary, // voltNeon
            ),
          ),
          const Divider(height: 24),

          // --- AÑADIDO: Card 1 - Detalles ---
          Card(
            elevation: 0,
            color: theme.colorScheme.background, // negroEnfocado
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(theme, 'Detalles del Bloque', Icons.description_outlined),
                  TextFormField(
                    controller: _mesoNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Bloque',
                      helperText: 'Ej: Bloque de Fuerza, Base',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (val) => val!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mesoObjectiveCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Objetivo SMART del Bloque',
                      helperText: 'Ej: Aumentar salto vertical en 5cm...',
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- AÑADIDO: Card 2 - Configuración ---
          Card(
            elevation: 0,
            color: theme.colorScheme.background, // negroEnfocado
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(theme, 'Configuración Semanal', Icons.calendar_today_outlined),
                  // --- AÑADIDO: Recordatorio de Disponibilidad ---
                  _buildAvailabilityReminder(theme), 
                  _buildNumberStepper(
                    theme: theme,
                    title: 'Duración (Semanas):',
                    value: _mesoWeeks,
                    onChanged: (newValue) => setModalState(() => _mesoWeeks = newValue),
                    max: 12,
                  ),
                  _buildNumberStepper(
                    theme: theme,
                    title: 'Sesiones por Semana:',
                    value: _mesoSessions,
                    onChanged: (newValue) =>
                        setModalState(() => _mesoSessions = newValue),
                    min: 1,
                    max: 7,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Crear Bloque'),
            onPressed: () {
              if (_mesoFormKey.currentState!.validate()) {
                _saveNewMesocycle();
                Navigator.pop(context); 
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberStepper({
    required ThemeData theme,
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
    int min = 1,
    int max = 12,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: theme.colorScheme.secondary,
                ),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  value.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: theme.colorScheme.secondary,
                ),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // --- CAMBIO: Lista de programas rediseñada ---
  List<Widget> _buildProgramListItems() {
    final theme = Theme.of(context);

    if (_program.mesocycles.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'Añade tu primer Bloque de Entrenamiento para empezar.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7)
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return _program.mesocycles.map((meso) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.surface) // Borde grisPro
        ),
        child: ExpansionTile(
          key: ValueKey(meso.id),
          initiallyExpanded: meso == _currentEditingMeso,
          onExpansionChanged: (isExpanded) {
            setState(() {
              _currentEditingMeso = isExpanded ? meso : null;
            });
          },
          backgroundColor: theme.colorScheme.surface, // grisPro
          collapsedBackgroundColor: theme.colorScheme.background, // negroEnfocado
          // --- CAMBIO DE COLOR ---
          leading: Icon(Icons.timeline, color: theme.colorScheme.secondary), // azulPro
          title: Text(
            meso.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          // --- CAMBIO: Subtítulo simplificado ---
          subtitle: Text(
            '${meso.weeks} Semanas • Foco: ${meso.focus}',
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error), // errorRed
            tooltip: 'Eliminar Bloque',
            onPressed: () => _deleteMesocycle(meso),
          ),
          children: [
            // --- AÑADIDO: Mostrar Objetivo SMART ---
            if (meso.objective.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OBJETIVO DEL BLOQUE:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary.withOpacity(0.8) // voltNeon
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meso.objective,
                      style: theme.textTheme.bodyMedium
                    ),
                  ],
                ),
              ),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // Lista de Semanas (Microciclos)
            ...meso.microcycles.map((micro) {
            return ExpansionTile(
              key: ValueKey('${meso.id}_${micro.weekNumber}'),
              leading: Icon(
                Icons.date_range,
                color: theme.colorScheme.secondary.withOpacity(0.7),
              ),
              title: Text(
                'Semana ${micro.weekNumber}',
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text('${micro.sessions.length} sesiones'),
              // --- AÑADIDO: Botón "Aplicar a todas" ---
              trailing: IconButton(
                icon: Icon(Icons.sync, color: theme.colorScheme.primary),
                tooltip: 'Usar esta semana como plantilla para todo el bloque',
                onPressed: () => _showApplyTemplateDialog(meso, micro),
              ),
              childrenPadding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              children: micro.sessions.map((session) {
                // --- CAMBIO: _buildSessionTile modificado ---
                return _buildSessionTile(session, meso, micro);
              }).toList(),
            );
          })],
        ),
      );
    }).toList();
  }
  
  // --- AÑADIDO: Lógica para aplicar plantilla de semana ---
  
  /// Muestra un diálogo de confirmación antes de aplicar la plantilla
  Future<void> _showApplyTemplateDialog(Mesocycle meso, Microcycle templateMicro) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('Aplicar Plantilla de Semana', style: TextStyle(color: theme.colorScheme.primary)),
          content: Text(
            '¿Estás seguro de que quieres usar la "Semana ${templateMicro.weekNumber}" '
            'como plantilla?\n\nEsto sobrescribirá todas las demás semanas de este bloque.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Aplicar'),
            ),
          ],
        );
      }
    );

    if (result == true) {
      _applyWeekTemplate(meso, templateMicro);
    }
  }

  /// Lógica inmutable para copiar las sesiones de una semana a todas las demás
  void _applyWeekTemplate(Mesocycle meso, Microcycle templateMicro) {
    setState(() {
      final newMesocycles = _program.mesocycles.map((m) {
        // Ignorar otros mesociclos
        if (m.id != meso.id) return m;

        // Estas son las sesiones que queremos copiar
        final templateSessions = templateMicro.sessions;
        final totalWeeks = m.weeks;

        // Mapeamos todos los microciclos
        final newMicrocycles = List.generate(m.microcycles.length, (i) {
          final currentMicro = m.microcycles[i];

          // Si es la semana plantilla, la devolvemos sin cambios
          if (currentMicro.id == templateMicro.id) {
            return currentMicro;
          }

          // Es una semana que necesita ser sobrescrita
          // --- CORRECCIÓN: Ahora usamos los métodos copyWith ---
          final newSessions = templateSessions.map((templateSession) {
            
            // 1. Reconstruir WorkoutExercise usando copyWith
            final newExercises = templateSession.exercises.map((e) {
              // Usamos el copyWith de WorkoutExercise
              return e.copyWith(exerciseId: _uuid.v4());
            }).toList();

            // 2. Reconstruir TrainingSession usando copyWith
            // Usamos el copyWith de TrainingSession
            return templateSession.copyWith(
              id: _uuid.v4(), // Nuevo ID de sesión único
              load: _suggestedLoadFor(i, totalWeeks), // Carga recalculada
              exercises: newExercises, // Nueva lista de ejercicios
            );
          }).toList();

          // Devolvemos el microciclo actual con las sesiones reemplazadas
          return currentMicro.copyWith(sessions: newSessions);
        });

        // Devolvemos el mesociclo con los microciclos actualizados
        return m.copyWith(microcycles: newMicrocycles);

      }).toList();

      _program = _program.copyWith(mesocycles: newMesocycles);
    });
    
    _showSuccess('Plantilla de semana aplicada a todo el bloque.');
  }

  // --- CAMBIO: Diseño de la Tarjeta de Sesión ---
  Widget _buildSessionTile(TrainingSession session, Mesocycle meso, Microcycle micro) {
    final theme = Theme.of(context);
    final weekText = 'Semana ${micro.weekNumber}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      color: theme.colorScheme.background, // negroEnfocado
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.surface) // Borde grisPro
      ),
      semanticContainer: true,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
              child: Icon(Icons.fitness_center, color: theme.colorScheme.secondary),
            ),
            title: Text(
              '${session.day} ($weekText)',
              style: theme.textTheme.titleMedium,
            ),
            // --- CAMBIO: Muestra el número de ejercicios ---
            subtitle: Text(
              '${session.exercises.length} ejercicios',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7)
              ),
            ),
            // --- CAMBIO: El trailing ahora es solo el chevron ---
            trailing: const Icon(Icons.chevron_right),
            // --- CAMBIO: El onTap abre el nuevo modal ---
            onTap: () => _showEditSessionModal(meso, micro, session),
          ),
          // --- CAMBIO: El ActionChip y los botones se han movido al modal ---
        ],
      ),
    );
  }

  // --- CAMBIO: _showEditSessionDialog eliminado y reemplazado ---

  // --- AÑADIDO: Nuevo modal para editar sesión y ejercicios ---
  Future<void> _showEditSessionModal(
    Mesocycle meso,
    Microcycle micro,
    TrainingSession session,
  ) async {
    final theme = Theme.of(context);
    final sessionNameCtrl = TextEditingController(text: session.day);
    // Mantenemos una copia local de los ejercicios para el modal
    List<WorkoutExercise> modalExercises = List.from(session.exercises);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface, // grisPro
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        // StatefulBuilder para que el modal maneje su propio estado
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header del Modal
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.background,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // --- CAMBIO DE COLOR ---
                              Icon(Icons.edit, color: theme.colorScheme.secondary), // azulPro
                              const SizedBox(width: 12),
                              Text(
                                'Editar Sesión',
                                style: theme.textTheme.headlineSmall,
                              ),
                            ],
                          ),
                          // Botón de Eliminar Sesión
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                            tooltip: 'Eliminar Sesión',
                            onPressed: () {
                              Navigator.pop(modalContext); // Cierra el modal
                              _deleteSession(meso, micro, session); // Llama a la lógica de borrado
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // 1. Campo para nombrar la sesión
                          TextField(
                            controller: sessionNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la Sesión',
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // 2. Título de la lista de ejercicios
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ejercicios de la Sesión',
                                style: theme.textTheme.titleLarge
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle, color: theme.colorScheme.primary), // voltNeon
                                tooltip: 'Añadir Ejercicio',
                                onPressed: () async {
                                  // 3. Botón para añadir ejercicios
                                  // --- CAMBIO: Llamada a _navigateToExercisePicker ---
                                  // Creamos una sesión temporal para el picker
                                  final tempSession = session.copyWith(exercises: modalExercises);
                                  
                                  final updatedSession = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExercisePickerScreen(
                                        session: tempSession, 
                                        profile: widget.profile
                                      ),
                                    ),
                                  );

                                  if (updatedSession is TrainingSession) {
                                    setModalState(() {
                                      modalExercises = updatedSession.exercises;
                                    });
                                  }
                                },
                              )
                            ],
                          ),
                          const Divider(),
                          
                          // 4. Lista de ejercicios
                          if (modalExercises.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text('No hay ejercicios. Presiona "+" para añadir.'),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: modalExercises.length,
                              itemBuilder: (context, index) {
                                final ex = modalExercises[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.secondary,
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(ex.name),
                                  subtitle: Text('${ex.sets}x${ex.reps} @ ${ex.intensity}'),
                                  // --- CAMBIO: Botones de Editar y Eliminar ---
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: theme.colorScheme.secondary),
                                        tooltip: 'Editar series/reps',
                                        onPressed: () {
                                          _showEditExerciseDialog(
                                            modalContext, 
                                            setModalState, 
                                            ex,
                                            (updatedExercise) {
                                              // Callback para actualizar la lista en el modal
                                              setModalState(() {
                                                modalExercises[index] = updatedExercise;
                                              });
                                            }
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                        tooltip: 'Eliminar ejercicio',
                                        onPressed: () {
                                          setModalState(() {
                                            modalExercises.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    // 5. Botón de Guardar
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Crear la sesión actualizada
                          final updatedSession = session.copyWith(
                            day: sessionNameCtrl.text,
                            exercises: modalExercises,
                          );
                          
                          // Actualizar el estado principal (fuera del modal)
                          _updateSessionInState(meso, micro, updatedSession);
                          
                          Navigator.pop(modalContext); // Cerrar el modal
                        },
                        child: const Text('Guardar Sesión'),
                      ),
                    )
                  ],
                );
              },
            );
          },
        );
      },
    );

    sessionNameCtrl.dispose();
  }
  
  // --- AÑADIDO: Diálogo para editar Reps/Sets/Intensidad ---
  Future<void> _showEditExerciseDialog(
    BuildContext modalContext, // El context del showModalBottomSheet
    StateSetter setModalState, // El setState del StatefulBuilder del modal
    WorkoutExercise exercise,
    Function(WorkoutExercise) onUpdate, // Callback para actualizar la lista
  ) async {
    final theme = Theme.of(context);
    final setsCtrl = TextEditingController(text: exercise.sets.toString());
    final repsCtrl = TextEditingController(text: exercise.reps);
    final intensityCtrl = TextEditingController(text: exercise.intensity);

    final updatedExercise = await showDialog<WorkoutExercise>(
      context: modalContext, // Usa el context del modal
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('Editar ${exercise.name}', style: TextStyle(color: theme.colorScheme.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsCtrl,
                decoration: const InputDecoration(labelText: 'Series'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repsCtrl,
                decoration: const InputDecoration(labelText: 'Repeticiones'),
                keyboardType: TextInputType.text,
              ),
              TextField(
                controller: intensityCtrl,
                decoration: const InputDecoration(labelText: 'Intensidad (RPE)'),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext, rootNavigator: true).maybePop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final updated = exercise.copyWith(
                  sets: int.tryParse(setsCtrl.text) ?? exercise.sets,
                  reps: repsCtrl.text,
                  intensity: intensityCtrl.text,
                );
                Navigator.of(dialogContext, rootNavigator: true).maybePop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (updatedExercise != null) {
      // Llama al callback para que el StatefulBuilder del modal
      // actualice su lista interna de ejercicios.
      onUpdate(updatedExercise);
    }
    
    // Dispose de los controllers
    setsCtrl.dispose();
    repsCtrl.dispose();
    intensityCtrl.dispose();
  }
  
  // --- AÑADIDO: Helper para borrar sesión ---
  void _deleteSession(Mesocycle meso, Microcycle micro, TrainingSession session) {
    setState(() {
      final newMesocycles = _program.mesocycles.map((m) {
        if (m.id != meso.id) return m; // No es el meso correcto

        final newMicrocycles = m.microcycles.map((mic) {
          if (mic.id != micro.id) return mic; // No es el micro correcto

          // Filtramos la sesión
          final newSessions = mic.sessions
              .where((s) => s.id != session.id)
              .toList();
          return mic.copyWith(sessions: newSessions);
        }).toList();

        return m.copyWith(microcycles: newMicrocycles);
      }).toList();
      _program = _program.copyWith(mesocycles: newMesocycles);
    });
    _showSuccess('Sesión eliminada');
  }

  // --- AÑADIDO: Helper para actualizar estado desde el modal ---
  void _updateSessionInState(Mesocycle meso, Microcycle micro, TrainingSession updatedSession) {
    setState(() {
      final newMesocycles = _program.mesocycles.map((m) {
        if (m.id != meso.id) return m;

        final newMicrocycles = m.microcycles.map((mic) {
          if (mic.id != micro.id) return mic;
          
          final newSessions = mic.sessions
              .map((s) => s.id == updatedSession.id ? updatedSession : s)
              .toList();
          return mic.copyWith(sessions: newSessions);
        }).toList();
        
        return m.copyWith(microcycles: newMicrocycles);
      }).toList();

      _program = _program.copyWith(mesocycles: newMesocycles);
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Planificación: ${widget.profile.name}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isSaving 
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Guardar Programa',
                  onPressed: _saveProgram,
                ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 96, top: 16), // Espacio para FAB
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Bloques de Entrenamiento',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              
              ..._buildProgramListItems(),
            ],
          ),

          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton.extended(
                label: const Text('Agregar Bloque'),
                icon: const Icon(Icons.post_add_outlined), 
                onPressed: _isSaving
                    ? null
                    : () => _showCreateMesoModal(context, theme),
                tooltip: 'Crear un nuevo Bloque de Entrenamiento',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

