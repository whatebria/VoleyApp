import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/mesocycle.dart';
import 'package:voley_app/src/models/program/microcycle.dart';
import 'package:voley_app/src/models/program/program_template.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/screens/program_view/create_block_screen.dart';
import 'package:voley_app/src/screens/program_view/edit_session_screen.dart'; // <-- AÑADIDO
import 'package:uuid/uuid.dart';

// --- CAMBIO: Nombre de la clase ---
class CreateNewProgramScreen extends ConsumerStatefulWidget {
  final PlayerProfile profile;
  final Program? template;
  const CreateNewProgramScreen({
    super.key,
    required this.profile,
    this.template,
  });

  @override
  _CreateNewProgramScreenState createState() => _CreateNewProgramScreenState();
}

class _CreateNewProgramScreenState
    extends ConsumerState<CreateNewProgramScreen> {
  Mesocycle? _currentEditingMeso;
  late Program _program;
  bool _isSaving = false;
  final Uuid _uuid = const Uuid();
  late Set<String> _selectedProfileIds;

  // --- AÑADIDO: Controlador para el título del programa ---
  late TextEditingController _programNameCtrl;

  // --- CAMBIO: State del formulario movido a CreateBlockScreen ---

  @override
  void initState() {
    super.initState();
    _program = widget.template != null
        ? widget.template!.copyWith(id: _uuid.v4(), startDate: DateTime.now())
        : Program(
            id: _uuid.v4(),
            // --- CAMBIO: Título inicial en blanco ---
            title: '',
            source: 'Manual',
            startDate: DateTime.now(),
            endDate: DateTime.now(),
            mesocycles: [],
          );
    _selectedProfileIds = {widget.profile.id};
    // --- AÑADIDO: Inicializar controlador de título ---
    _programNameCtrl = TextEditingController(text: _program.title);
  }

  // --- CAMBIO: _generateSessionTemplates, _suggestedLoadFor movidos ---
  // --- CAMBIO: _buildDefaultSegmentExercises movido ---

  @override
  void dispose() {
    _programNameCtrl.dispose(); // --- AÑADIDO ---
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

    final totalWeeks = _program.mesocycles.fold<int>(
      0,
      (sum, meso) => sum + meso.weeks,
    );

    // --- CAMBIO: Actualizar título y fecha de fin ---
    _program = _program.copyWith(
      // --- CAMBIO: Guardar el título del programa ---
      title: _programNameCtrl.text.isEmpty
          ? 'Programa sin título'
          : _programNameCtrl.text,
      endDate: _program.startDate.add(Duration(days: totalWeeks * 7)),
    );

    try {
      final firestore = ref.read(firestoreProvider);
      final targetProfileIds = _selectedProfileIds.isNotEmpty
          ? _selectedProfileIds.toList()
          : [widget.profile.id];

      await firestore.saveProgramForPlayers(targetProfileIds, _program);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Programa guardado'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Error al guardar: $e');
      }
    }
  }

  Future<void> _saveAsTemplate() async {
    if (_program.mesocycles.isEmpty) {
      _showError('Añade al menos un bloque para guardar la plantilla.');
      return;
    }

    final currentUser = ref.read(currentUserAppUserProvider).valueOrNull;
    if (currentUser == null || !currentUser.isCoach) {
      _showError('Solo los coaches pueden guardar plantillas.');
      return;
    }

    final nameCtrl = TextEditingController(
      text: _programNameCtrl.text.isEmpty
          ? 'Plantilla sin nombre'
          : _programNameCtrl.text,
    );
    final descCtrl = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Guardar como plantilla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la plantilla',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    final normalizedName = nameCtrl.text.trim().isEmpty
        ? 'Plantilla sin nombre'
        : nameCtrl.text.trim();

    final template = ProgramTemplate(
      id: _uuid.v4(),
      name: normalizedName,
      description: descCtrl.text.trim(),
      program: _program.copyWith(id: _uuid.v4(), title: normalizedName),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(saveProgramTemplateProvider)(template);
      if (mounted) {
        _showSuccess('Plantilla guardada');
      }
    } catch (e) {
      _showError('No se pudo guardar la plantilla: $e');
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

  // --- CAMBIO: _clearMesoForm eliminado ---
  // --- CAMBIO: _showCreateMesoModal eliminado ---

  // --- AÑADIDO: Navegación a la nueva pantalla ---
  void _navigateToAddBlock() async {
    // Navega a la new screen y espera por un Mesocycle
    final newMeso = await Navigator.push<Mesocycle>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBlockScreen(profile: widget.profile),
      ),
    );

    if (newMeso != null && mounted) {
      setState(() {
        final updatedMesocycles = List<Mesocycle>.from(_program.mesocycles);
        updatedMesocycles.insert(0, newMeso); // Add to top
        _program = _program.copyWith(mesocycles: updatedMesocycles);
        _currentEditingMeso = newMeso; // Focus the new one
      });
    }
  }

  // --- AÑADIDO: Lógica de navegación para Editar ---
  void _navigateToEditBlock(Mesocycle mesoToEdit) async {
    final updatedMeso = await Navigator.push<Mesocycle>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBlockScreen(
          profile: widget.profile,
          mesoToEdit: mesoToEdit, // <-- Pasa el bloque a editar
        ),
      ),
    );

    if (updatedMeso != null && mounted) {
      // Reemplaza el bloque antiguo por el actualizado
      setState(() {
        final updatedMesocycles = _program.mesocycles.map((meso) {
          if (meso.id == updatedMeso.id) {
            return updatedMeso; // Reemplaza el bloque editado
          }
          return meso; // Mantiene los demás
        }).toList();

        _program = _program.copyWith(mesocycles: updatedMesocycles);
        _currentEditingMeso = updatedMeso; // Re-enfoca el bloque editado
      });
    }
  }

  // --- AÑADIDO: Navegación a la pantalla de edición de sesión ---
  void _navigateToEditSession(
    Mesocycle meso,
    Microcycle micro,
    TrainingSession session,
  ) async {
    final updatedSession = await Navigator.push<TrainingSession>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditSessionScreen(session: session, profile: widget.profile),
      ),
    );

    if (updatedSession != null && mounted) {
      _updateSessionInState(meso, micro, updatedSession);
    }
  }

  // --- WIDGETS DE CONSTRUCCIÓN ---

  // --- CAMBIO: Formularios y helpers de modal eliminados ---

  // --- CAMBIO: Lista de programas rediseñada ---
  List<Widget> _buildProgramListItems() {
    final theme = Theme.of(context);

    // No necesitamos el mensaje de "vacío" aquí,
    // ya que se maneja en el build() principal.

    // --- CAMBIO: Usar asMap().entries.map() para obtener el índice ---
    return _program.mesocycles.asMap().entries.map((entry) {
      final int index = entry.key;
      final Mesocycle meso = entry.value;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.surface), // Borde grisPro
        ),
        // --- CAMBIO: El Card ya no es un ExpansionTile ---
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CAMBIO: Nuevo Header de la Card ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Bloque ${index + 1}: ${meso.name}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary, // voltNeon
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // --- AÑADIDO: Botón de Editar ---
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: theme.colorScheme.secondary,
                        ), // azulPro
                        tooltip: 'Editar Bloque',
                        onPressed: () => _navigateToEditBlock(meso),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ), // errorRed
                        tooltip: 'Eliminar Bloque',
                        onPressed: () => _deleteMesocycle(meso),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${meso.weeks} Semanas',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),

              // --- CAMBIO: Objetivo del Bloque ---
              if (meso.objective.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OBJETIVO:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary, // azulPro
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(meso.objective, style: theme.textTheme.bodyMedium),
                  ],
                ),

              const Divider(height: 24),

              // --- CAMBIO: ExpansionTile de Semanas (anidado) ---
              ...meso.microcycles.map((micro) {
                return ExpansionTile(
                  key: ValueKey('${meso.id}_${micro.weekNumber}'),
                  // Fondo transparente para que se integre al Card
                  backgroundColor: Colors.transparent,
                  collapsedBackgroundColor: Colors.transparent,
                  tilePadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.date_range,
                    color: theme.colorScheme.secondary.withOpacity(0.7),
                  ),
                  title: Text(
                    'Semana ${micro.weekNumber}',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text('${micro.sessions.length} sesiones'),
                  trailing: IconButton(
                    icon: Icon(Icons.sync, color: theme.colorScheme.primary),
                    tooltip:
                        'Usar esta semana como plantilla para todo el bloque',
                    onPressed: () => _showApplyTemplateDialog(meso, micro),
                  ),
                  childrenPadding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  children: micro.sessions.map((session) {
                    return _buildSessionTile(session, meso, micro);
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      );
    }).toList();
  }

  // --- AÑADIDO: Lógica para aplicar plantilla de semana ---

  /// Muestra un diálogo de confirmación antes de aplicar la plantilla
  Future<void> _showApplyTemplateDialog(
    Mesocycle meso,
    Microcycle templateMicro,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _ApplyTemplateScreen(weekNumber: templateMicro.weekNumber),
      ),
    );

    if (result == true) {
      _applyWeekTemplate(meso, templateMicro);
    }
  }

  /// Lógica inmutable para copiar las sesiones de una semana a todas las demás
  void _applyWeekTemplate(Mesocycle meso, Microcycle templateMicro) {
    // --- CAMBIO: Llama al provider para la lógica ---
    final generator = ref.read(programGeneratorProvider);

    setState(() {
      final newMesocycles = _program.mesocycles.map((m) {
        if (m.id != meso.id) return m;

        // --- CAMBIO: Delega la generación al provider ---
        final newMicrocycles = generator.generateMicrocyclesFromTemplate(
          weeks: m.weeks,
          templateMicro: templateMicro,
        );

        return m.copyWith(microcycles: newMicrocycles);
      }).toList();

      _program = _program.copyWith(mesocycles: newMesocycles);
    });

    _showSuccess('Plantilla de semana aplicada a todo el bloque.');
  }

  // --- CAMBIO: Diseño de la Tarjeta de Sesión ---
  Widget _buildSessionTile(
    TrainingSession session,
    Mesocycle meso,
    Microcycle micro,
  ) {
    final theme = Theme.of(context);
    final weekText = 'Semana ${micro.weekNumber}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      color: theme.colorScheme.background, // negroEnfocado
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.surface), // Borde grisPro
      ),
      semanticContainer: true,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
              child: Icon(
                Icons.fitness_center,
                color: theme.colorScheme.secondary,
              ),
            ),
            title: Text(
              '${session.day} ($weekText)',
              style: theme.textTheme.titleMedium,
            ),
            // --- CAMBIO: Muestra el número de ejercicios ---
            subtitle: Text(
              '${session.totalExercises} ejercicios',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            // --- CAMBIO: El trailing ahora es solo el chevron ---
            trailing: const Icon(Icons.chevron_right),
            // --- CAMBIO: El onTap abre la nueva pantalla ---
            onTap: () => _navigateToEditSession(meso, micro, session),
          ),
          // --- CAMBIO: El ActionChip y los botones se han movido al modal ---
        ],
      ),
    );
  }

  // --- CAMBIO: _showEditSessionModal eliminado ---
  // --- CAMBIO: _showEditExerciseDialog eliminado ---
  // --- CAMBIO: _deleteSession eliminado ---

  // --- AÑADIDO: Helper para actualizar estado desde el modal ---
  void _updateSessionInState(
    Mesocycle meso,
    Microcycle micro,
    TrainingSession updatedSession,
  ) {
    setState(() {
      final newMesocycles = _program.mesocycles.map((m) {
        if (m.id != meso.id) return m;

        final newMicrocycles = m.microcycles.map((mic) {
          if (mic.id != micro.id) return mic;

          final newSessions = mic.sessions
              .map((s) => s.id == updatedSession.id ? updatedSession : s)
              // --- CORRECCIÓN: Líneas erróneas eliminadas ---
              .toList();
          return mic.copyWith(sessions: newSessions);
        }).toList();

        return m.copyWith(microcycles: newMicrocycles);
      }).toList();

      _program = _program.copyWith(mesocycles: newMesocycles);
    });
  }

  // --- AÑADIDO: Widget para el nombre del programa ---
  Widget _buildProgramNameEditor(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextFormField(
        controller: _programNameCtrl,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: 'Nombre del Programa',
          // --- CAMBIO: Estilo de diseño ---
          hintText: 'Ej: Plan de Fuerza 2024',
          filled: true,
          fillColor: theme.colorScheme.surface, // grisPro
          border: theme.inputDecorationTheme.border, // Usar borde del tema
          prefixIcon: Icon(Icons.edit, color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildStartDatePicker(ThemeData theme) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(_program.startDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ListTile(
        tileColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(Icons.calendar_today, color: theme.colorScheme.secondary),
        title: const Text('Fecha de inicio'),
        subtitle: Text(formattedDate),
        trailing: FilledButton.tonalIcon(
          icon: const Icon(Icons.edit_calendar),
          label: const Text('Cambiar'),
          onPressed: _pickStartDate,
        ),
      ),
    );
  }

  Widget _buildPlayerAssignment(ThemeData theme) {
    final currentUser = ref.watch(currentUserAppUserProvider).valueOrNull;

    if (currentUser == null || !currentUser.isCoach) {
      return const SizedBox.shrink();
    }

    final playersAsync = ref.watch(coachPlayersWithProfilesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error al cargar jugadores: $e'),
        data: (players) {
          final profiles = players
              .map((p) => p.profile)
              .whereType<PlayerProfile>()
              .toList();

          if (!profiles.any((p) => p.id == widget.profile.id)) {
            profiles.insert(0, widget.profile);
          }

          if (profiles.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Asignar a jugadores',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: profiles.map((profile) {
                  final isSelected = _selectedProfileIds.contains(profile.id);

                  return FilterChip(
                    label: Text(profile.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedProfileIds.add(profile.id);
                        } else if (_selectedProfileIds.length > 1) {
                          _selectedProfileIds.remove(profile.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona todos los jugadores que recibirán este programa.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _program.startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null && mounted) {
      setState(() {
        _program = _program.copyWith(startDate: picked);
      });
    }
  }

  // --- AÑADIDO: Widget para el header de los bloques ---
  Widget _buildBlockHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Bloques',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          // --- CAMBIO: Botón "+ bloque" ---
          FilledButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir'),
            // --- CAMBIO: Navega a la nueva pantalla ---
            onPressed: _isSaving ? null : _navigateToAddBlock,
            style: FilledButton.styleFrom(
              // Un botón más sutil
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserAppUserProvider).valueOrNull;

    return Scaffold(
      // --- CAMBIO: Título de AppBar ---
      appBar: AppBar(
        title: const Text('Nuevo Programa'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'Guardar Programa',
                    onPressed: _saveProgram,
                  ),
          ),
          if (currentUser?.isCoach == true)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'template') {
                  _saveAsTemplate();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'template',
                  child: Text('Guardar como plantilla'),
                ),
              ],
            ),
        ],
      ),
      // --- CAMBIO: Estructura del Body ---
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96), // Espacio para scroll
        children: [
          // 1. Editor de nombre de programa
          _buildProgramNameEditor(theme),

          // 1c. Selector de jugadores (solo coach)
          _buildPlayerAssignment(theme),

          // 1b. Selector de fecha de inicio
          _buildStartDatePicker(theme),

          // 2. Header de Bloques
          _buildBlockHeader(theme),

          // 3. Lista de Bloques (o mensaje de vacío)
          if (_program.mesocycles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'Añade tu primer Bloque de Entrenamiento para empezar.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._buildProgramListItems(),
        ],
      ),
      // --- CAMBIO: FAB eliminado ---
    );
  }
}

class _ApplyTemplateScreen extends StatelessWidget {
  final int weekNumber;

  const _ApplyTemplateScreen({required this.weekNumber});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Aplicar Plantilla de Semana')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Usar la semana $weekNumber como plantilla?\n\nEsto sobrescribirá todas las demás semanas de este bloque.',
              style: theme.textTheme.bodyLarge,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
