// lib/src/screens/create_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

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
  DateTime? _birthDate;
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final uuid = Uuid();

  // Estado del formulario (Efímero, se queda en la UI)
  String selectedPosition = 'Central';
  List<Tournament> _selectedTournaments = [];
  List<String> selectedInjuries = [];
  List<String> _chronicConditions = [];
  List<String> selectedDays = [];
  List<String> _goals = [];
  Map<String, double> _testScores = {};
  List<PlayerEvent> _keyEvents = [];
  final List<String> _presetGoals = const [
    'Quiero ganar fuerza',
    'Quiero saltar más',
    'Quiero perder peso',
    'Quiero ganar peso',
    'Quiero mejorar mi resistencia',
    'Quiero prevenir lesiones',
  ];
  final List<String> _presetChronicConditions = const [
    'Asma',
    'Diabetes',
    'Hipertensión',
    'Cardiopatía',
  ];
  final List<String> _allDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  final Map<String, int> _durationOptions = {
    '30-45 minutos': 45,
    '45-60 minutos': 60,
    '60-75 minutos': 75,
    '75-90 minutos': 90,
    '90+ minutos': 120,
  };
  int _selectedDurationMinutes = 60;

  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _eventTypeLabel(String type) {
    switch (type) {
      case 'cup':
        return 'Copa';
      case 'playoff':
        return 'Play-offs';
      case 'national_team':
        return 'Selección';
      case 'travel':
        return 'Viaje';
      case 'league':
      default:
        return 'Liga';
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
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
        trainingDays: selectedDays,
        sessionMinutes: _selectedDurationMinutes,
      );

      double? parseDouble(String value) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return null;
        return double.tryParse(trimmed.replaceAll(',', '.'));
      }

      final profileToSave = PlayerProfile(
        id: uuid.v4(),
        userId: userId,
        assignedCoachId: coachId,
        name: nameCtrl.text.trim(),
        position: selectedPosition,
        level: 'personalizado',
        goals: _goals,
        injuries: selectedInjuries.contains('Ninguna') ? [] : selectedInjuries,
        chronicConditions: _chronicConditions,
        availability: availability,
        evaluation: EvaluationResult(
          testScores: _testScores,
          strengths: [],
          weaknesses: [],
        ),
        tournaments: _selectedTournaments,
        age: _calculateAge(_birthDate),
        birthDate: _birthDate,
        heightCm: parseDouble(heightCtrl.text),
        weightKg: parseDouble(weightCtrl.text),
        keyEvents: _keyEvents,
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
    final nameCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Tournament>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Añadir Torneo'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Torneo *',
                        prefixIcon: Icon(Icons.emoji_events),
                        helperText: 'Ej: Copa Nacional 2024',
                      ),
                      validator: (v) => (v?.isEmpty ?? true)
                          ? 'El nombre es requerido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Fecha del Torneo'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).maybePop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final tournament = Tournament(
                        name: nameCtrl.text.trim(),
                        date: selectedDate,
                      );
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pop(tournament);
                    }
                  },
                  child: const Text('Añadir'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _selectedTournaments.add(result));
    }
    nameCtrl.dispose();
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate =
        _birthDate ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 70),
      lastDate: DateTime(now.year - 8),
      helpText: 'Seleccioná tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Listo',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _promptCustomGoal() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar objetivo personal'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Objetivo',
              helperText: 'Ej: Recuperar mi confianza al atacar',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).maybePop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(context, rootNavigator: true).pop(value);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result != null && !_goals.contains(result)) {
      setState(() => _goals.add(result));
    }
    controller.dispose();
  }

  Future<void> _promptCustomChronicCondition() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar condición crónica'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Condición',
              helperText: 'Ej: Tiroides, anemia, etc.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).maybePop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(context, rootNavigator: true).pop(value);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result != null && !_chronicConditions.contains(result)) {
      setState(() => _chronicConditions.add(result));
    }
    controller.dispose();
  }

  Future<void> _showAddTestDialog() async {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<MapEntry<String, double>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar Test Inicial'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Test *',
                    helperText: 'Ej: Salto vertical',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: valueCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Resultado *',
                    helperText: 'Ej: 45.5',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un resultado';
                    }
                    return double.tryParse(value.replaceAll(',', '.')) == null
                        ? 'Ingresa un número válido'
                        : null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).maybePop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final value = double.parse(
                    valueCtrl.text.replaceAll(',', '.'),
                  );
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop(MapEntry(nameCtrl.text.trim(), value));
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => _testScores[result.key] = result.value);
    }
    nameCtrl.dispose();
    valueCtrl.dispose();
  }

  Future<void> _showAddEventDialog() async {
    const eventOptions = {
      'league': 'Liga',
      'cup': 'Copa',
      'playoff': 'Play-offs',
      'national_team': 'Selección',
      'travel': 'Viaje',
    };

    String selectedType = 'league';
    DateTime selectedDate = DateTime.now();
    final descriptionCtrl = TextEditingController();

    final result = await showDialog<PlayerEvent>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Agregar Fecha Clave'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de evento',
                    ),
                    items: eventOptions.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  TextField(
                    controller: descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      helperText: 'Ej: Liga Metropolitana',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).maybePop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop(
                      PlayerEvent(
                        type: selectedType,
                        date: selectedDate,
                        description: descriptionCtrl.text.trim().isEmpty
                            ? null
                            : descriptionCtrl.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _keyEvents.add(result));
    }
    descriptionCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coachUserAsync = ref.watch(currentUserAppUserProvider);
    final isCreating = ref.watch(isCreatingPlayerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Queremos conocerte')),
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
    final birthDateLabel = _birthDate != null
        ? DateFormat('dd/MM/yyyy').format(_birthDate!)
        : 'Selecciona tu fecha';
    final age = _calculateAge(_birthDate);
    return Step(
      title: const Text('Perfil'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Queremos conocerte mejor para personalizar tu experiencia.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPosition,
              decoration: const InputDecoration(
                labelText: '¿Cuál es tu posición principal?',
                prefixIcon: Icon(Icons.sports_volleyball),
              ),
              items: ['Central', 'Libero', 'Punta', 'Opuesto', 'Armadora']
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) =>
                  setState(() => selectedPosition = newValue!),
            ),
            const SizedBox(height: 16),
            Text('Fecha de nacimiento', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectBirthDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            birthDateLabel,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _birthDate == null
                                  ? theme.hintColor
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            'Mostraremos tu edad automáticamente en la app.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (age != null)
                      Text(
                        '$age años',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            Text('Tus objetivos personales', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._presetGoals.map((goal) {
                  final isSelected = _goals.contains(goal);
                  return FilterChip(
                    label: Text(goal),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (!_goals.contains(goal)) _goals.add(goal);
                        } else {
                          _goals.remove(goal);
                        }
                      });
                    },
                  );
                }),
                ..._goals
                    .where((goal) => !_presetGoals.contains(goal))
                    .map(
                      (goal) => InputChip(
                        label: Text(goal),
                        onDeleted: () => setState(() => _goals.remove(goal)),
                      ),
                    ),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text('Agregar otro objetivo'),
                  onPressed: _promptCustomGoal,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tus números iniciales',
                  style: theme.textTheme.titleSmall,
                ),
                IconButton(
                  tooltip: 'Registrar test',
                  onPressed: _showAddTestDialog,
                  icon: const Icon(Icons.add_chart),
                ),
              ],
            ),
            if (_testScores.isEmpty)
              Text(
                'Añade resultados de tests cuando los tengas disponibles (opcional).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              )
            else
              Column(
                children: _testScores.entries
                    .map(
                      (entry) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.key),
                        trailing: Text(
                          entry.value.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              setState(() => _testScores.remove(entry.key)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 24),
            Text('Historial de lesiones (opcional)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
           Wrap(
              spacing: 8.0,
           runSpacing: 8.0,
              children: [
                ...['Rodilla', 'Tobillo', 'Hombro', 'Espalda', 'Muñeca', 'Dedo', 'Ninguna']
                    .map((injury) {
                  final isSelected = selectedInjuries.contains(injury);
                  return FilterChip(
                    label: Text(injury),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.secondary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onSecondary
                          : theme.colorScheme.onSurface,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (injury == 'Ninguna') {
                          selectedInjuries.clear();
                          if (selected) selectedInjuries.add('Ninguna');
                        } else {
                          selectedInjuries.remove('Ninguna');
                          if (selected) {
                            selectedInjuries.add(injury);
                        } else {
                          selectedInjuries.remove(injury);
                          }
                         }
                      });
                    },
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: 24),
            Text('Enfermedades crónicas (opcional)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._presetChronicConditions.map((condition) {
                  final isSelected = _chronicConditions.contains(condition);
                  return FilterChip(
                    label: Text(condition),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (!_chronicConditions.contains(condition)) {
                            _chronicConditions.add(condition);
                          }
                        } else {
                          _chronicConditions.remove(condition);
                        }
                      });
                    },
                  );
                }),
                ..._chronicConditions
                    .where((condition) => !_presetChronicConditions.contains(condition))
                    .map(
                      (condition) => InputChip(
                        label: Text(condition),
                        onDeleted: () =>
                            setState(() => _chronicConditions.remove(condition)),
                      ),
                    ),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text('Agregar condición'),
                  onPressed: _promptCustomChronicCondition,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// --- Paso 3 del Stepper: Disponibilidad ---
  Step _buildStep3Disponibilidad(ThemeData theme) {
    return Step(
      title: const Text('Tu rutina'),
      isActive: _currentStep >= 2,
      content: Form(
        key: _step3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuentanos cuándo te viene mejor entrenar.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Días de entrenamiento (opcional)',
              style: theme.textTheme.titleSmall,
            ),
            Wrap(
              spacing: 4.0,
              runSpacing: 0.0,
              children: _allDays
                  .map(
                    (day) => SizedBox(
                      width: 160,
                      child: CheckboxListTile(
                        title: Text(day),
                        value: selectedDays.contains(day),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true)
                              selectedDays.add(day);
                            else
                              selectedDays.remove(day);
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedDurationMinutes,
              decoration: const InputDecoration(
                labelText: 'Duración habitual por sesión',
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
            
          ],
        ),
      ),
    );
  }
}
