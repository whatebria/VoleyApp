import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/mesocycles.dart';
import 'package:voley_app/src/models/program/microcicle.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:voley_app/src/screens/exercise_picker_screen.dart';
import 'package:uuid/uuid.dart';

/// Pantalla dedicada a crear un nuevo Mesociclo (Bloque).
/// Recibe el [profile] para mostrar contexto (días disponibles)
/// y devuelve un [Mesocycle] completo si se guarda.
class CreateBlockScreen extends ConsumerStatefulWidget {
  final PlayerProfile profile;
  const CreateBlockScreen({super.key, required this.profile});

  @override
  _CreateBlockScreenState createState() => _CreateBlockScreenState();
}

class _CreateBlockScreenState extends ConsumerState<CreateBlockScreen> {
  final _mesoFormKey = GlobalKey<FormState>();
  final _mesoNameCtrl = TextEditingController();
  final _mesoObjectiveCtrl = TextEditingController();
  int _mesoWeeks = 4;
  int _mesoSessions = 3;
  
  // --- AÑADIDO: Estado para la Semana Plantilla ---
  Microcycle? _templateMicro;
  
  final Uuid _uuid = const Uuid();
  
  @override
  void initState() {
    super.initState();
    // Genera la plantilla inicial al cargar la pantalla
    _generateTemplateMicro(_mesoSessions);
  }


  @override
  void dispose() {
    _mesoNameCtrl.dispose();
    _mesoObjectiveCtrl.dispose();
    super.dispose();
  }

  /// Lógica de carga para la progresión de semanas
  double _suggestedLoadFor(int weekIndex, int totalWeeks) {
    final normalizedIndex = totalWeeks <= 1 ? 0 : weekIndex / (totalWeeks - 1);
    // Progresión lineal simple de 0.6 a 0.85
    return double.parse((0.6 + 0.25 * normalizedIndex).toStringAsFixed(2));
  }
  
  // --- AÑADIDO: Generador de Semana Plantilla ---
  /// Crea o actualiza la semana plantilla (Microcycle)
  void _generateTemplateMicro(int sessionsPerWeek) {
    final sessions = List.generate(sessionsPerWeek, (sIndex) {
      // Si ya existe una plantilla, intenta mantener las sesiones existentes
      if (_templateMicro != null && sIndex < _templateMicro!.sessions.length) {
        return _templateMicro!.sessions[sIndex];
      }
      // Si no, crea una sesión vacía
      return TrainingSession(
        id: _uuid.v4(),
        day: 'Sesión ${sIndex + 1}',
        load: _suggestedLoadFor(0, _mesoWeeks), // Carga base para la plantilla
        exercises: [],
      );
    });

    setState(() {
      _templateMicro = Microcycle(
        id: _templateMicro?.id ?? _uuid.v4(),
        weekNumber: 1, // Es una plantilla
        sessions: sessions,
      );
    });
  }
  
  // --- AÑADIDO: Navegación para editar la sesión plantilla ---
  Future<void> _editTemplateSession(int sessionIndex) async {
    if (_templateMicro == null) return;
    
    final sessionToEdit = _templateMicro!.sessions[sessionIndex];

    // Navega al ExercisePickerScreen
    final updatedSession = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExercisePickerScreen(
          session: sessionToEdit, 
          profile: widget.profile
        ),
      ),
    );

    // Actualiza el estado de la plantilla si se devolvió una sesión
    if (updatedSession is TrainingSession) {
      setState(() {
        _templateMicro!.sessions[sessionIndex] = updatedSession;
      });
    }
  }


  /// Guarda el nuevo mesociclo y lo devuelve a la pantalla anterior
  void _saveNewMesocycle() {
    if (_mesoFormKey.currentState!.validate() && _templateMicro != null) {
      final weeks = _mesoWeeks;
      
      // --- CAMBIO: Usa la plantilla para generar todas las semanas ---
      final templateSessions = _templateMicro!.sessions;

      final microcycles = List.generate(weeks, (i) {
        final newSessions = templateSessions.map((templateSession) {
          
          // Copia profunda de ejercicios
          final newExercises = templateSession.exercises
              .map((e) => e.copyWith(exerciseId: _uuid.v4()))
              .toList();

          // Copia la sesión, pero actualiza ID y Carga
          return templateSession.copyWith(
            id: _uuid.v4(),
            load: _suggestedLoadFor(i, weeks), // Recalcula la carga
            exercises: newExercises,
          );
        }).toList();

        return Microcycle(
          weekNumber: i + 1,
          sessions: newSessions,
          id: _uuid.v4(),
        );
      });

      final newMeso = Mesocycle(
        id: _uuid.v4(),
        name: _mesoNameCtrl.text,
        objective: _mesoObjectiveCtrl.text,
        weeks: weeks,
        focus: "Personalizado",
        progressionType: 'lineal', 
        matchDayIndex: 5, // Sábado (valor por defecto)
        microcycles: microcycles,
      );

      // Devuelve el nuevo mesociclo a la pantalla anterior
      Navigator.pop(context, newMeso);
    }
  }


  // --- WIDGETS DE CONSTRUCCIÓN ---

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

  // --- CAMBIO: Eliminado _buildAvailabilityReminder ---

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
  
  // --- AÑADIDO: Card para la Semana Tipo ---
  Widget _buildTemplateWeekCard(ThemeData theme) {
    if (_templateMicro == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface, // grisPro
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme, 'Define tu Semana Tipo', Icons.edit_calendar_outlined),
            const Divider(height: 14),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _templateMicro!.sessions.length,
              itemBuilder: (context, index) {
                final session = _templateMicro!.sessions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  elevation: 0,
                  color: theme.colorScheme.background, // negroEnfocado
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.surface)
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                      child: Icon(Icons.fitness_center, color: theme.colorScheme.secondary, size: 20),
                    ),
                    title: Text(session.day, style: theme.textTheme.titleMedium),
                    subtitle: Text(
                      '${session.exercises.length} ejercicios',
                       style: theme.textTheme.bodyMedium?.copyWith(
                         color: theme.colorScheme.onSurface.withOpacity(0.7)
                       ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editTemplateSession(index),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Bloque'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _mesoFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Detalles del Bloque',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary, // voltNeon
                  ),
                ),
                const Divider(height: 24),
          
                // --- Card 1 - Detalles ---
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surface, // grisPro
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
          
                // --- Card 2 - Configuración ---
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surface, // grisPro
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(theme, 'Configuración Semanal', Icons.calendar_today_outlined),
                        // --- CAMBIO: _buildAvailabilityReminder eliminado ---
                        _buildNumberStepper(
                          theme: theme,
                          title: 'Duración (Semanas):',
                          value: _mesoWeeks,
                          onChanged: (newValue) => setState(() => _mesoWeeks = newValue),
                          max: 12,
                        ),
                        _buildNumberStepper(
                          theme: theme,
                          title: 'Sesiones por Semana:',
                          value: _mesoSessions,
                          onChanged: (newValue) {
                            // --- CAMBIO: Actualiza la plantilla al cambiar sesiones ---
                            setState(() => _mesoSessions = newValue);
                            _generateTemplateMicro(newValue);
                          },
                          min: 1,
                          max: 7,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // --- AÑADIDO: Card 3 - Semana Tipo ---
                _buildTemplateWeekCard(theme),
          
                const SizedBox(height: 24),
          
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Bloque'),
                  onPressed: _saveNewMesocycle,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

