import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/goal.dart';
import 'package:voley_app/src/models/player_profile/injury.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';
import 'package:voley_app/src/models/player_profile/form_peak.dart';
import 'package:voley_app/src/models/player_profile/test_score.dart';
import 'package:voley_app/src/screens/forms/player_form_screens.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';

// (Asegúrate de que 'isCreatingPlayerProvider' y 'coachPlayersProvider'
// estén definidos en tu archivo 'providers.dart')

class CreatePlayerScreen extends ConsumerStatefulWidget {
  const CreatePlayerScreen({super.key});

  @override
  ConsumerState<CreatePlayerScreen> createState() => _CreatePlayerScreenState();
}

class _CreatePlayerScreenState extends ConsumerState<CreatePlayerScreen> {
  // --- MEJORA DE UX: Estado del Stepper ---
  int _currentStep = 0;

  // Claves de formulario para validación por paso
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  // Controladores
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final wingspanCtrl = TextEditingController();
  final goalCtrl = TextEditingController();
  final uuid = Uuid();

  PlayerPosition selectedPosition = PlayerPosition.mb; // Central por defecto
  PlayerLevel selectedLevel =
      PlayerLevel.competitivo; // Competitivo por defecto
  List<DayOfWeek> selectedDays = [];

  // Torneos / lesiones / metas / tests / eventos / picos
  List<Tournament> _selectedTournaments = [];
  List<Injury> selectedInjuries = [];
  List<Goal> _goals = [];
  List<TestScore> _testScores = [];
  List<PlayerEvent> _keyEvents = [];
  List<FormPeak> _formPeaks = [];
  // Días disponibles (usa enum)
  final List<DayOfWeek> _allDays = DayOfWeek.values;

  final Map<String, int> _durationOptions = {
    '30-45 minutos': 45,
    '45-60 minutos': 60,
    '60-75 minutos': 75,
    '75-90 minutos': 90,
    '90+ minutos': 120,
  };
  int _selectedDurationMinutes = 60;

  // Helpers de etiqueta
  String _posLabel(PlayerPosition p) {
    switch (p) {
      case PlayerPosition.oh:
        return 'Punta';
      case PlayerPosition.mb:
        return 'Central';
      case PlayerPosition.s:
        return 'Armadora';
      case PlayerPosition.op:
        return 'Opuesto';
      case PlayerPosition.l:
        return 'Líbero';
    }
  }

  String _levelLabel(PlayerLevel l) {
    switch (l) {
      case PlayerLevel.recreativo:
        return 'Recreativo';
      case PlayerLevel.competitivo:
        return 'Competitivo';
      case PlayerLevel.semiprofesional:
        return 'Semiprofesional';
    }
  }

  String _eventTypeLabel(PlayerEventType t) {
    switch (t) {
      case PlayerEventType.cup:
        return 'Copa';
      case PlayerEventType.playoff:
        return 'Play-offs';
      case PlayerEventType.nationalTeam:
        return 'Selección';
      case PlayerEventType.travel:
        return 'Viaje';
      case PlayerEventType.league:
        return 'Liga';
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    ageCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    wingspanCtrl.dispose();
    goalCtrl.dispose();
    super.dispose();
  }

  /// --- MEJORA DE ARQUITECTURA Y UX: Método de Envío ---
  Future<void> _handleSubmit() async {
    // Validar todos los formularios
    if (!_step1Key.currentState!.validate() ||
        !_step2Key.currentState!.validate() ||
        !_step3Key.currentState!.validate()) {
      _showError('Por favor revisa los campos en todos los pasos.');
      return;
    }

    final coachId = ref.read(currentUserAppUserProvider).valueOrNull?.id;
    if (coachId == null) {
      _showError('Error: No se pudo identificar al entrenador');
      return;
    }

    ref.read(isCreatingPlayerProvider.notifier).state = true;

    try {
      // 1. Crear Cuenta de Auth y Usuario en Firestore
      final functions = ref.read(functionsProvider);
      final callable = functions.httpsCallable('createPlayerAccount');
      final result = await callable.call(<String, dynamic>{
        'email': emailCtrl.text.trim(),
        'password': passwordCtrl.text.trim(),
        'name': nameCtrl.text.trim(),
        'coachId': coachId,
      });

      final userId = result.data['userId'];
      if (userId == null) {
        throw Exception('La Cloud Function no devolvió un userId.');
      }

      // 2. Preparar el Perfil de Jugador
      final availability = Availability(
        trainingDays: selectedDays, // ✅ List<DayOfWeek>
        sessionMinutes: _selectedDurationMinutes,
      );

      int? parseAge(String value) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return null;
        return int.tryParse(trimmed);
      }

      double? parseDouble(String value) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return null;
        return double.tryParse(trimmed.replaceAll(',', '.'));
      }

      // --- CAMBIO: Creación del PlayerProfile actualizada ---
      final profileToSave = PlayerProfile(
        id: uuid.v4(),
        userId: userId,
        assignedCoachId: coachId,
        name: nameCtrl.text.trim(),
        position: selectedPosition, // ✅ PlayerPosition
        level: selectedLevel, // ✅ PlayerLevel
        goals: _goals,
        injuries: selectedInjuries,
        availability: availability,
        evaluationHistory: [
          EvaluationResult(date: DateTime.now(), testScores: _testScores),
        ],
        tournaments: _selectedTournaments,
        age: parseAge(ageCtrl.text),
        heightCm: parseDouble(heightCtrl.text),
        weightKg: parseDouble(weightCtrl.text),
        wingspanCm: parseDouble(wingspanCtrl.text),
        keyEvents: _keyEvents,
        formPeaks: _formPeaks,
      );

      // 3. Guardar el Perfil
      await ref.read(firestoreProvider).savePlayerProfile(profileToSave);

      if (mounted) {
        _showSuccess('¡Jugador creado exitosamente!');

        // --- MEJORA DE UX: Refresca la lista y vuelve atrás ---
        ref.invalidate(coachPlayersProvider);
        Navigator.pop(context); // Vuelve a la lista de jugadores
      }
    } catch (e) {
      _showError('Error al guardar: $e');
    } finally {
      if (mounted) {
        ref.read(isCreatingPlayerProvider.notifier).state = false;
      }
    }
  }

  // --- Helpers de UI ---
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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

  Future<void> _showAddTournamentDialog() async {
    final result = await Navigator.push<Tournament>(
      context,
      MaterialPageRoute(builder: (_) => const TournamentFormScreen()),

    );

    if (result != null) {
      setState(() => _selectedTournaments.add(result));
    }
  }

  // --- CAMBIO: _showAddGoalDialog ahora devuelve un objeto Goal ---
  Future<void> _showAddGoalDialog() async {
    goalCtrl.clear();
     final result = await Navigator.push<Goal>(
      context,
      MaterialPageRoute(
        builder: (_) => GoalFormScreen(idBuilder: uuid.v4),
      ),
    );

    if (result != null) {
      setState(() => _goals.add(result));
    }
  }

  // --- CAMBIO: _showAddTestDialog ahora devuelve un objeto TestScore ---
  Future<void> _showAddTestDialog() async {
    final result = await Navigator.push<TestScore>(
      context,
      MaterialPageRoute(builder: (_) => const TestScoreFormScreen()),
    );

    if (result != null) {
      setState(() => _testScores.add(result));
    }
  }

  // --- AÑADIDO: Diálogo para Lesiones ---
  Future<void> _showAddInjuryDialog() async {
    final result = await Navigator.push<Injury>(
      context,
      MaterialPageRoute(
        builder: (_) => InjuryFormScreen(idBuilder: uuid.v4),
      ),
    );

    if (result != null) {
      setState(() => selectedInjuries.add(result));
    }
  }

  Future<void> _showAddEventDialog() async {
    final result = await Navigator.push<PlayerEvent>(
      context,
      MaterialPageRoute(builder: (_) => const PlayerEventFormScreen()),
    );

    if (result != null) {
      setState(() => _keyEvents.add(result));
    }
  }

  Future<void> _showAddFormPeakDialog() async {
    final result = await Navigator.push<FormPeak>(
      context,
      MaterialPageRoute(builder: (_) => const FormPeakFormScreen()),
    );

    if (result != null) {
      setState(() => _formPeaks.add(result));
    }
  }

  // --- AÑADIDO: Helper para formatear IDs de tests ---
  String _formatTestId(String testId) {
    if (testId.isEmpty) return 'Test';
    // Convierte 'salto_vertical' en 'Salto Vertical'
    return testId
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coachUserAsync = ref.watch(currentUserAppUserProvider);
    final isCreating = ref.watch(isCreatingPlayerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nuevo Jugador')),
      body: coachUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error al cargar usuario: $e")),
        data: (currentUser) {
          if (currentUser == null || !currentUser.isCoach) {
            return const Center(
              child: Text("No tienes permisos para esta pantalla."),
            );
          }

          // --- MEJORA DE UI/UX: Implementación del Stepper ---
          return Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepTapped: (step) => setState(() => _currentStep = step),
            onStepContinue: () {
              bool isValid = false;
              if (_currentStep == 0) {
                isValid = _step1Key.currentState?.validate() ?? false;
              } else if (_currentStep == 1) {
                isValid = _step2Key.currentState?.validate() ?? false;
              } else if (_currentStep == 2) {
                isValid = _step3Key.currentState?.validate() ?? false;
                if (isValid) _handleSubmit(); // Enviar en el último paso
              }

              if (isValid && _currentStep < 2) {
                setState(() => _currentStep += 1);
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            // --- MEJORA DE DISEÑO: Botones con tema ---
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == 2;
              return Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: isCreating
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          if (_currentStep > 0)
                            TextButton.icon(
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Atrás'),
                              onPressed: details.onStepCancel,
                            ),
                          const Spacer(),
                          ElevatedButton.icon(
                            icon: Icon(
                              isLastStep
                                  ? Icons.person_add
                                  : Icons.arrow_forward,
                            ),
                            label: Text(
                              isLastStep ? 'Crear Jugador' : 'Siguiente',
                            ),
                            onPressed: details.onStepContinue,
                          ),
                        ],
                      ),
              );
            },
            steps: [
              _buildStep1Cuenta(theme),
              _buildStep2Perfil(theme),
              _buildStep3Disponibilidad(theme),
            ],
          );
        },
      ),
    );
  }

  /// --- Paso 1 del Stepper: Cuenta ---
  Step _buildStep1Cuenta(ThemeData theme) {
    return Step(
      title: const Text('Cuenta'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _step1Key,
        child: Column(
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              validator: (v) =>
                  (v?.isEmpty ?? true) ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'El email es requerido';
                if (!v.contains('@')) return 'Email no válido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña *',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'La contraseña es requerida';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// --- Paso 2 del Stepper: Perfil ---
  Step _buildStep2Perfil(ThemeData theme) {
    return Step(
      title: const Text('Perfil'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _step2Key,
        child: Column(
          children: [
            // Posición
            DropdownButtonFormField<PlayerPosition>(
              value: selectedPosition,
              decoration: const InputDecoration(
                labelText: 'Posición',
                prefixIcon: Icon(Icons.sports_volleyball),
              ),
              items: PlayerPosition.values
                  .map(
                    (p) =>
                        DropdownMenuItem(value: p, child: Text(_posLabel(p))),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => selectedPosition = v ?? selectedPosition),
            ),

            const SizedBox(height: 12),

            // Nivel
            DropdownButtonFormField<PlayerLevel>(
              value: selectedLevel,
              decoration: const InputDecoration(
                labelText: 'Nivel',
                prefixIcon: Icon(Icons.bar_chart),
              ),
              items: PlayerLevel.values
                  .map(
                    (l) =>
                        DropdownMenuItem(value: l, child: Text(_levelLabel(l))),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => selectedLevel = v ?? selectedLevel),
            ),

            const SizedBox(height: 12),
            TextFormField(
              controller: ageCtrl,
              decoration: const InputDecoration(
                labelText: 'Edad',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final parsed = int.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Ingresa una edad válida';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: heightCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Altura (cm)',
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return double.tryParse(value.replaceAll(',', '.')) == null
                          ? 'Número inválido'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: weightCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return double.tryParse(value.replaceAll(',', '.')) == null
                          ? 'Número inválido'
                          : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: wingspanCtrl,
              decoration: const InputDecoration(
                labelText: 'Envergadura (cm)',
                prefixIcon: Icon(Icons.swap_horiz_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return double.tryParse(value.replaceAll(',', '.')) == null
                    ? 'Número inválido'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Objetivos', style: theme.textTheme.titleSmall),
                IconButton(
                  tooltip: 'Agregar objetivo',
                  onPressed: _showAddGoalDialog,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _goals.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Define objetivos concretos para el jugador.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  // --- CAMBIO: Muestra la descripción del objeto Goal ---
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _goals
                          .map(
                            (goal) => Chip(
                              label: Text(goal.toString()), // <-- CAMBIO
                              deleteIcon: const Icon(Icons.cancel, size: 18),
                              onDeleted: () =>
                                  setState(() => _goals.remove(goal)),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Evaluación Inicial', style: theme.textTheme.titleSmall),
                IconButton(
                  tooltip: 'Agregar test',
                  onPressed: _showAddTestDialog,
                  icon: const Icon(Icons.add_chart),
                ),
              ],
            ),
            if (_testScores.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Añade resultados de tests físicos (opcional).',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              // --- CAMBIO: Muestra la lista de TestScore ---
              Column(
                children: _testScores
                    .map(
                      (test) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(_formatTestId(test.testId)), // <-- CAMBIO
                        trailing: Text(
                          '${test.value.toStringAsFixed(1)} ${test.unit}', // <-- CAMBIO
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(
                            () => _testScores.remove(test),
                          ), // <-- CAMBIO
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),

            // --- CAMBIO: Lógica de Lesiones actualizada ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lesiones (opcional)', style: theme.textTheme.titleSmall),
                IconButton(
                  tooltip: 'Agregar lesión',
                  onPressed: _showAddInjuryDialog, // <-- CAMBIO
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // --- CAMBIO: Reemplaza FilterChip por Wrap de Chips ---
            Align(
              alignment: Alignment.centerLeft,
              child: selectedInjuries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Registra lesiones activas o pasadas.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: selectedInjuries
                          .map(
                            (injury) => Chip(
                              label: Text(injury.description), // <-- CAMBIO
                              avatar: Icon(
                                injury.status == InjuryStatus.active
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline,
                                size: 16,
                                color: injury.status == InjuryStatus.active
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              deleteIcon: const Icon(Icons.cancel, size: 18),
                              onDeleted: () => setState(
                                () => selectedInjuries.remove(injury),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// --- Paso 3 del Stepper: Disponibilidad ---
  Step _buildStep3Disponibilidad(ThemeData theme) {
    return Step(
      title: const Text('Disponibilidad'),
      isActive: _currentStep >= 2,
      content: Form(
        key: _step3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Días de Entrenamiento (opcional)',
              style: theme.textTheme.titleSmall,
            ),

            Wrap(
              spacing: 4.0,
              runSpacing: 0.0,
              children: _allDays.map((day) {
                final isOn = selectedDays.contains(day);
                return SizedBox(
                  width: 160,
                  child: CheckboxListTile(
                    title: Text(day.longEs), // usa extension .longEs
                    value: isOn,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          if (!selectedDays.contains(day))
                            selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedDurationMinutes,
              decoration: const InputDecoration(
                labelText: 'Duración por Sesión',
                prefixIcon: Icon(Icons.timer),
              ),
              items: _durationOptions.entries
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.value,
                      child: Text(entry.key),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() => _selectedDurationMinutes = newValue);
                }
              },
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Torneos (opcional)', style: theme.textTheme.titleSmall),
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: theme.colorScheme.secondary,
                  ), // Azul Pro
                  tooltip: 'Añadir Torneo',
                  onPressed: _showAddTournamentDialog,
                ),
              ],
            ),
            _selectedTournaments.isEmpty
                ? const Text(
                    'Añade torneos jugados (opcional).',
                    style: TextStyle(color: Colors.grey),
                  )
                : Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _selectedTournaments.map((tournament) {
                      return Chip(
                        label: Text(
                          '${tournament.name} (${DateFormat('dd/MM/yy').format(tournament.date)})',
                        ),
                        deleteIcon: const Icon(Icons.cancel, size: 18),
                        onDeleted: () {
                          setState(
                            () => _selectedTournaments.remove(tournament),
                          );
                        },
                      );
                    }).toList(),
                  ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fechas Clave', style: theme.textTheme.titleSmall),
                IconButton(
                  icon: Icon(
                    Icons.event_available_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Añadir evento',
                  onPressed: _showAddEventDialog,
                ),
              ],
            ),
            if (_keyEvents.isEmpty)
              const Text(
                'Registra fechas importantes como ligas o viajes.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                children: _keyEvents
                    .map(
                      (event) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${_eventTypeLabel(event.type)} - ${DateFormat('dd/MM/yy').format(event.date)}',
                        ),
                        subtitle: event.description != null
                            ? Text(event.description!)
                            : null,
                        leading: Icon(
                          Icons.flag_outlined,
                          color: theme.colorScheme.secondary,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              setState(() => _keyEvents.remove(event)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Picos de Forma', style: theme.textTheme.titleSmall),
                IconButton(
                  icon: Icon(
                    Icons.trending_up,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Añadir pico',
                  onPressed: _showAddFormPeakDialog,
                ),
              ],
            ),
            if (_formPeaks.isEmpty)
              const Text(
                'Planifica los momentos de máximo rendimiento.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _formPeaks
                    .map(
                      (peak) => Chip(
                        label: Text(
                          '${DateFormat('dd/MM/yy').format(peak.date)}${peak.note != null ? ' • ${peak.note}' : ''}',
                        ),
                        deleteIcon: const Icon(Icons.cancel, size: 18),
                        onDeleted: () =>
                            setState(() => _formPeaks.remove(peak)),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
