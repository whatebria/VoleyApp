import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/mesocycle.dart';
import 'package:voley_app/src/models/program/microcycle.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/screens/program_view/exercise_picker_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';

/// Pantalla dedicada a crear o EDITAR un nuevo Mesociclo (Bloque).
/// Recibe el [profile] para mostrar contexto (días disponibles)
/// y devuelve un [Mesocycle] completo si se guarda.
class CreateBlockScreen extends ConsumerStatefulWidget {
  final PlayerProfile profile;
  // --- AÑADIDO: Parámetro opcional para editar ---
  final Mesocycle? mesoToEdit;

  const CreateBlockScreen({
    super.key,
    required this.profile,
    this.mesoToEdit, // <-- AÑADIDO
  });

  @override
  _CreateBlockScreenState createState() => _CreateBlockScreenState();
}

class _CreateBlockScreenState extends ConsumerState<CreateBlockScreen> {
  final _mesoFormKey = GlobalKey<FormState>();
  final _mesoNameCtrl = TextEditingController();
  final _mesoObjectiveCtrl = TextEditingController();
  int _mesoWeeks = 4;
  int _mesoSessions = 3;
  String _dayLabel(DayOfWeek d) => {
    DayOfWeek.mon: 'Lun',
    DayOfWeek.tue: 'Mar',
    DayOfWeek.wed: 'Mié',
    DayOfWeek.thu: 'Jue',
    DayOfWeek.fri: 'Vie',
    DayOfWeek.sat: 'Sáb',
    DayOfWeek.sun: 'Dom',
  }[d]!;

  // --- AÑADIDO: Estado para la Semana Plantilla ---
  Microcycle? _templateMicro;

  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();

    // --- AÑADIDO: Lógica de Edición ---
    if (widget.mesoToEdit != null) {
      // Estamos en modo EDICIÓN
      final meso = widget.mesoToEdit!;
      _mesoNameCtrl.text = meso.name;
      _mesoObjectiveCtrl.text = meso.objective;
      _mesoWeeks = meso.weeks;
      // Usamos la primera semana como la "plantilla"
      // Asumimos que todas las sesiones tienen la misma longitud
      _mesoSessions = meso.microcycles.first.sessions.length;
      _templateMicro = meso.microcycles.first.copyWith(id: _uuid.v4());
    } else {
      // Estamos en modo CREACIÓN
      // Genera la plantilla inicial al cargar la pantalla
      _generateTemplateMicro(_mesoSessions);
    }
  }

  @override
  void dispose() {
    _mesoNameCtrl.dispose();
    _mesoObjectiveCtrl.dispose();
    super.dispose();
  }

  // --- CAMBIO: Lógica movida a program_generator.dart ---
  // double _suggestedLoadFor(int weekIndex, int totalWeeks) { ... }

  // --- AÑADIDO: Generador de Semana Plantilla ---
  /// Crea o actualiza la semana plantilla (Microcycle)
  void _generateTemplateMicro(int sessionsPerWeek) {
    // --- CAMBIO: Llama al provider para la lógica ---
    final generator = ref.read(programGeneratorProvider);

    final sessions = List.generate(sessionsPerWeek, (sIndex) {
      // Si ya existe una plantilla, intenta mantener las sesiones existentes
      if (_templateMicro != null && sIndex < _templateMicro!.sessions.length) {
        return _templateMicro!.sessions[sIndex];
      }
      // Si no, crea una sesión vacía
      DayOfWeek dayFromIndex(int i) =>
          DayOfWeek.values[i % DayOfWeek.values.length];

      return TrainingSession(
        id: _uuid.v4(),
        day: dayFromIndex(sIndex), // ✅ enum
        load: generator.suggestedLoadFor(0, _mesoWeeks),
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
          profile: widget.profile,
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
    // --- CAMBIO: Lógica movida a ProgramGenerator ---
    if (_mesoFormKey.currentState!.validate() && _templateMicro != null) {
      // 1. Leer el servicio/provider
      final generator = ref.read(programGeneratorProvider);

      final Mesocycle resultingMeso;

      // 2. Decidir si crear o actualizar
      if (widget.mesoToEdit != null) {
        // --- MODO EDICIÓN ---
        resultingMeso = generator.updateMesocycle(
          mesoToEdit: widget.mesoToEdit!,
          name: _mesoNameCtrl.text,
          objective: _mesoObjectiveCtrl.text,
          weeks: _mesoWeeks,
          templateMicro: _templateMicro!,
        );
      } else {
        // --- MODO CREACIÓN ---
        resultingMeso = generator.createNewMesocycle(
          name: _mesoNameCtrl.text,
          objective: _mesoObjectiveCtrl.text,
          weeks: _mesoWeeks,
          templateMicro: _templateMicro!,
        );
      }

      // 3. Devolver el resultado
      Navigator.pop(context, resultingMeso);
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

  Widget _buildAvailabilityReminder(ThemeData theme) {
    final availability = widget.profile.availability;

    // Asumiendo que el modelo tiene 'trainingDays' como en tu query
    final trainingDays =
        availability.trainingDays; // O usa availability.trainingDays si existe

    if (trainingDays.isEmpty) {
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
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: trainingDays
                .map(
                  (day) => Chip(
                    label: Text(_dayLabel(day)), // ✅ 'day' del map
                    backgroundColor: theme.colorScheme.secondary.withOpacity(
                      0.2,
                    ),
                    labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                )
                .toList(),
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
            _buildSectionHeader(
              theme,
              'Define tu Semana Tipo',
              Icons.edit_calendar_outlined,
            ),
            Text(
              'Edita las sesiones de esta semana. Se copiarán a las ${_mesoWeeks} semanas del bloque.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const Divider(height: 24),
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
                    side: BorderSide(color: theme.colorScheme.surface),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary.withOpacity(
                        0.2,
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      session.day.shortEs,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${session.totalExercises} ejercicios',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
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
    // --- AÑADIDO: Determina el modo ---
    final isEditing = widget.mesoToEdit != null;

    return Scaffold(
      appBar: AppBar(
        // --- CAMBIO: Título dinámico ---
        title: Text(isEditing ? 'Editar Bloque' : 'Crear Bloque'),
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
                  // --- CAMBIO: Título dinámico ---
                  isEditing
                      ? 'Detalles del Bloque'
                      : 'Crear Bloque de Entrenamiento',
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          theme,
                          'Detalles del Bloque',
                          Icons.description_outlined,
                        ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          theme,
                          'Configuración Semanal',
                          Icons.calendar_today_outlined,
                        ),
                        _buildAvailabilityReminder(theme),
                        _buildNumberStepper(
                          theme: theme,
                          title: 'Duración (Semanas):',
                          value: _mesoWeeks,
                          onChanged: (newValue) =>
                              setState(() => _mesoWeeks = newValue),
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
                  icon: Icon(isEditing ? Icons.save_as : Icons.add),
                  // --- CAMBIO: Texto de botón dinámico ---
                  label: Text(isEditing ? 'Guardar Cambios' : 'Crear Bloque'),
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
