// lib/screens/evaluation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/evaluation_provider.dart'; // <-- ¡EL NUEVO PROVIDER!
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:intl/intl.dart';

class EvaluationScreen extends ConsumerStatefulWidget {
  const EvaluationScreen({super.key});

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  // Estado de la UI: El Stepper
  int _currentStep = 0;

  // Controladores de formulario (Estado efímero, se queda en la UI)
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  // Estado del formulario
  String selectedPosition = 'Central';
  String selectedLevel = 'Competitivo';
  List<Tournament> _selectedTournaments = [];
  List<String> selectedInjuries = [];
  Map<String, double> _testScores = {};
  List<String> selectedDays = [];
  int _selectedDurationMinutes = 60;

  // Listas de opciones
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

  /// Rellena el formulario cuando se carga un perfil
  void _populateForm(PlayerProfile? p) {
    if (p == null) {
      // Limpia el formulario (excepto datos de auth)
      setState(() {
        selectedPosition = 'Central';
        selectedLevel = 'Competitivo';
        selectedDays = [];
        _selectedDurationMinutes = 60;
        selectedInjuries = [];
        _selectedTournaments = [];
        _testScores = {};
      });
    } else {
      // Rellena el formulario
      setState(() {
        nameCtrl.text = p.name;
        selectedPosition = p.position;
        selectedLevel = p.level.isNotEmpty
            ? p.level[0].toUpperCase() + p.level.substring(1)
            : 'Competitivo';
        selectedDays = p.availability.trainingDays;
        _selectedDurationMinutes = p.availability.sessionMinutes;
        selectedInjuries = p.injuries.isEmpty ? ['Ninguna'] : p.injuries;
        _selectedTournaments = p.tournaments;
        _testScores = p.evaluation.testScores;
      });
    }
  }

  /// Limpia los campos de Auth (usado al cambiar de modo)
  void _clearAuthFields() {
    nameCtrl.clear();
    emailCtrl.clear();
    passwordCtrl.clear();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(evaluationControllerProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

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
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green, // El verde de éxito suele estar bien
        ),
      );
    }
  }

  /// --- LÓGICA DE ENVÍO SIMPLIFICADA ---
  /// Recoge los datos de la UI y los pasa al controlador
  Future<void> _handleSubmit() async {
    // Validación básica
    if (_formKey.currentState?.validate() == false) return;

    // Obtenemos la referencia al controlador
    final controller = ref.read(evaluationControllerProvider.notifier);

    // Llamamos al método del controlador con los datos locales
    await controller.handleSubmit(
      name: nameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      password: passwordCtrl.text.trim(),
      position: selectedPosition,
      level: selectedLevel,
      injuries: selectedInjuries,
      availabilityDays: selectedDays,
      availabilityMinutes: _selectedDurationMinutes,
      tournaments: _selectedTournaments,
      testScores: _testScores,
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- GESTIÓN DE ESTADO REACTIVA ---
    final state = ref.watch(evaluationControllerProvider);
    final controller = ref.read(evaluationControllerProvider.notifier);
    final theme = Theme.of(context);

    // Escucha los cambios de estado para acciones "de una sola vez"
    ref.listen(evaluationControllerProvider, (previous, next) {
      // 1. Mostrar Errores
      if (next.errorMessage != null) {
        _showError(next.errorMessage!);
        controller.clearMessages(); // Limpia para no volver a mostrar
      }

      // 2. Mostrar Éxito
      if (next.successMessage != null) {
        _showSuccess(next.successMessage!);
        controller.clearMessages();
      }

      // 3. Rellenar el formulario cuando 'loadedProfile' cambia
      final oldProfile = previous?.loadedProfile.value;
      final newProfile = next.loadedProfile.value;
      if (oldProfile != newProfile) {
        _populateForm(newProfile);
      }

      // 4. Rellenar/limpiar campos de auth cuando 'selectedUser' cambia
      if (previous?.selectedUser != next.selectedUser) {
        if (next.selectedUser != null) {
          nameCtrl.text = next.selectedUser!.name;
          emailCtrl.text = next.selectedUser!.email;
        } else {
          _clearAuthFields();
        }
      }
    });

    // Getter para saber si los campos están bloqueados
    // Bloqueado si: El perfil está cargado (editando) Y NO es el coach
    final isPlayerViewing = !(state.currentUser.valueOrNull?.isCoach ?? true);
    final isFormLocked = (state.loadedProfile.value != null && isPlayerViewing);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación de Jugador'),
        // Botón para limpiar formulario (solo para coach en modo 'crear')
        actions: [
          if (state.currentUser.valueOrNull?.isCoach == true &&
              state.isCreatingNewUser)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Limpiar Formulario',
              onPressed: () {
                _clearAuthFields();
                _populateForm(null); // Limpia el resto
              },
            ),
        ],
      ),
      body: state.currentUser.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar usuario: $e')),
        data: (currentUser) {
          if (currentUser == null) {
            return const Center(child: Text("Usuario no encontrado."));
          }

          // --- UI Principal: El Stepper ---
          return Form(
            key: _formKey,
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep += 1);
                } else {
                  // Estamos en el último paso, enviar
                  _handleSubmit();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              // --- Builder para los botones Siguiente/Atrás/Guardar ---
              controlsBuilder: (context, details) {
                final isLastStep = _currentStep == 2;
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: state.isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentStep > 0)
                              TextButton.icon(
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Atrás'),
                                onPressed: details.onStepCancel,
                              ),
                            const Spacer(),
                            // Botón principal
                            ElevatedButton.icon(
                              icon: Icon(
                                isLastStep ? Icons.save : Icons.arrow_forward,
                              ),
                              label: Text(isLastStep ? 'Guardar' : 'Siguiente'),
                              onPressed: details.onStepContinue,
                            ),
                          ],
                        ),
                );
              },
              // --- CONTENIDO DE LOS PASOS ---
              steps: [
                _buildStep1Usuario(theme, state, controller, isPlayerViewing),
                _buildStep2Perfil(theme, state, isFormLocked),
                _buildStep3Evaluacion(
                  theme,
                  state,
                  isPlayerViewing,
                ), // Evaluación siempre editable
              ],
            ),
          );
        },
      ),
    );
  }

  /// --- PASO 1: Selección de Usuario ---
  Step _buildStep1Usuario(
    ThemeData theme,
    EvaluationState state,
    EvaluationController controller,
    bool isPlayerViewing,
  ) {
    return Step(
      title: const Text('Usuario'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            if (!isPlayerViewing) ...[
              // --- Selector de Modo (Solo Coach) ---
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Existente'),
                    icon: Icon(Icons.person_search),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Crear Nuevo'),
                    icon: Icon(Icons.person_add),
                  ),
                ],
                selected: {state.isCreatingNewUser},
                onSelectionChanged: (Set<bool> newSelection) {
                  controller.setMode(newSelection.first);
                },
              ),
              const SizedBox(height: 24),

              // --- Opciones de Modo (Solo Coach) ---
              if (state.isCreatingNewUser)
                _buildCreateNewUserFields() // Campos para crear
              else
                _buildSelectExistingUser(state), // Dropdown para seleccionar
            ] else ...[
              // --- Vista para el Jugador ---
              TextFormField(
                controller: nameCtrl,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Campos para "Crear Nuevo" (Solo Coach)
  Widget _buildCreateNewUserFields() {
    return Column(
      children: [
        TextFormField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Nombre Completo *'),
          validator: (value) =>
              (value?.isEmpty ?? true) ? 'El nombre es requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailCtrl,
          decoration: const InputDecoration(labelText: 'Email *'),
          keyboardType: TextInputType.emailAddress,
          validator: (value) =>
              (value?.isEmpty ?? true) ? 'El email es requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: passwordCtrl,
          decoration: const InputDecoration(labelText: 'Contraseña Temporal *'),
          obscureText: true,
          validator: (value) =>
              (value?.isEmpty ?? true) ? 'La contraseña es requerida' : null,
        ),
      ],
    );
  }

  /// Dropdown para "Usuario Existente" (Solo Coach)
  Widget _buildSelectExistingUser(EvaluationState state) {
    return state.availablePlayers.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => Text('Error al cargar jugadores: $e'),
      data: (players) => DropdownButtonFormField<app_user.User>(
        value: state.selectedUser,
        decoration: const InputDecoration(labelText: 'Seleccionar Jugador'),
        items: players
            .map(
              (user) => DropdownMenuItem(value: user, child: Text(user.name)),
            )
            .toList(),
        onChanged: (user) =>
            ref.read(evaluationControllerProvider.notifier).selectUser(user),
        validator: (value) =>
            value == null ? 'Debes seleccionar un jugador' : null,
      ),
    );
  }

  /// --- PASO 2: Perfil y Disponibilidad ---
  Step _buildStep2Perfil(
    ThemeData theme,
    EvaluationState state,
    bool isFormLocked,
  ) {
    // Un jugador no puede editar su propio nombre
    final isPlayerEditingName = !state.currentUser.valueOrNull!.isCoach;

    // El formulario de perfil está bloqueado si:
    // 1. Es un jugador (no coach) Y
    // 2. Ya tiene un perfil cargado
    final bool isProfileFieldsLocked =
        isPlayerEditingName && state.loadedProfile.value != null;

    return Step(
      title: const Text('Perfil'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre (solo editable si es coach creando, o jugador sin perfil aún)
            TextFormField(
              controller: nameCtrl,
              enabled: !isPlayerEditingName, // Jugador no edita su nombre
              decoration: InputDecoration(
                labelText: 'Nombre',
                filled: isPlayerEditingName,
                fillColor: isPlayerEditingName
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            // --- Posición ---
            DropdownButtonFormField<String>(
              value: selectedPosition,
              decoration: InputDecoration(
                labelText: 'Posición',
                filled: isProfileFieldsLocked,
                fillColor: isProfileFieldsLocked
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
                    : null,
              ),
              items: ['Central', 'Libero', 'Punta', 'Opuesto', 'Armadora']
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: isProfileFieldsLocked
                  ? null
                  : (newValue) {
                      setState(() => selectedPosition = newValue!);
                    },
            ),
            const SizedBox(height: 16),
            // --- Nivel ---
            DropdownButtonFormField<String>(
              value: selectedLevel,
              decoration: InputDecoration(
                labelText: 'Nivel',
                filled: isProfileFieldsLocked,
                fillColor: isProfileFieldsLocked
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
                    : null,
              ),
              items: ['Competitivo', 'Recreativo']
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: isProfileFieldsLocked
                  ? null
                  : (newValue) {
                      setState(() => selectedLevel = newValue!);
                    },
            ),
            const SizedBox(height: 24),
            // --- Disponibilidad ---
            Text('Disponibilidad', style: theme.textTheme.titleMedium),
            const Divider(),
            Wrap(
              spacing: 4.0,
              runSpacing: 0.0,
              children: _allDays
                  .map(
                    (day) => SizedBox(
                      width: 160, // Acomoda 2 por fila
                      child: CheckboxListTile(
                        title: Text(day),
                        value: selectedDays.contains(day),
                        onChanged: isProfileFieldsLocked
                            ? null
                            : (bool? value) {
                                setState(() {
                                  if (value == true) {
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
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedDurationMinutes,
              decoration: InputDecoration(
                labelText: 'Duración por Sesión',
                filled: isProfileFieldsLocked,
                fillColor: isProfileFieldsLocked
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
                    : null,
              ),
              items: _durationOptions.entries
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.value,
                      child: Text(entry.key),
                    ),
                  )
                  .toList(),
              onChanged: isProfileFieldsLocked
                  ? null
                  : (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedDurationMinutes = newValue);
                      }
                    },
            ),
            const SizedBox(height: 24),
            // --- Lesiones ---
            Text('Lesiones', style: theme.textTheme.titleMedium),
            const Divider(),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children:
                  [
                    'Rodilla',
                    'Tobillo',
                    'Hombro',
                    'Espalda',
                    'Muñeca',
                    'Dedo',
                    'Ninguna',
                  ].map((injury) {
                    return FilterChip(
                      label: Text(injury),
                      selected: selectedInjuries.contains(injury),
                      onSelected: isProfileFieldsLocked
                          ? null
                          : (bool selected) {
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
            ),
          ],
        ),
      ),
    );
  }

  /// --- PASO 3: Evaluación y Torneos ---
  /// ¡ESTOS CAMPOS SIEMPRE SON EDITABLES! (Un coach actualiza tests, un jugador añade sus torneos)
  Step _buildStep3Evaluacion(
    ThemeData theme,
    EvaluationState state,
    bool isPlayerViewing,
  ) {
    // Los torneos NO son editables si ya se cargó un perfil (son históricos)
    // PERO los tests SIEMPRE son editables.
    final bool canEditTournaments = state.loadedProfile.value == null;

    return Step(
      title: const Text('Evaluación'),
      isActive: _currentStep >= 2,
      state: StepState.indexed,
      content: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Torneos ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Torneos', style: theme.textTheme.titleMedium),
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: theme.colorScheme.secondary,
                  ),
                  tooltip: 'Añadir Torneo',
                  // Solo habilitado si NO hay perfil cargado (o sea, es nuevo)
                  onPressed: canEditTournaments
                      ? _showAddTournamentDialog
                      : null,
                ),
              ],
            ),
            const Divider(),
            if (_selectedTournaments.isEmpty)
              Text(
                canEditTournaments
                    ? 'Añade torneos jugados...'
                    : 'Historial de torneos del jugador.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _selectedTournaments.map((tournament) {
                  return Chip(
                    label: Text(
                      '${tournament.name} (${DateFormat('dd/MM/yy').format(tournament.date)})',
                    ),
                    deleteIcon: const Icon(Icons.cancel, size: 18),
                    onDeleted: canEditTournaments
                        ? () => setState(
                            () => _selectedTournaments.remove(tournament),
                          )
                        : null,
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            // --- Puntuaciones de Test ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Puntuaciones de Test',
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Añadir Test',
                  onPressed: _showAddTestDialog, // ¡SIEMPRE HABILITADO!
                ),
              ],
            ),
            const Divider(),
            if (_testScores.isEmpty)
              Text(
                'Añade puntuaciones (Ej: Salto Vertical).',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              )
            else
              ..._testScores.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.value.toString(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _testScores.remove(entry.key);
                          });
                        },
                      ),
                    ],
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  // --- Diálogos (Sin cambios, pero ahora bloquean campos si es necesario) ---
  // (He añadido lógica de bloqueo a los onDeleted/onPressed de los widgets)

  Future<void> _showAddTournamentDialog() async {
    final nameController = TextEditingController();
    DateTime? pickedDate;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Añadir Torneo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Torneo',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      pickedDate == null
                          ? 'Seleccionar Fecha'
                          : DateFormat('dd/MM/yyyy').format(pickedDate!),
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2010), // Histórico
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() {
                          pickedDate = date;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && pickedDate != null) {
                      setState(() {
                        _selectedTournaments.add(
                          Tournament(
                            name: nameController.text,
                            date: pickedDate!,
                          ),
                        );
                      });
                      Navigator.pop(context);
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
  }

  Future<void> _showAddTestDialog() async {
    final nameController = TextEditingController();
    final scoreController = TextEditingController();

    // Autocompletar con el nombre de un test existente para editarlo
    String? existingTestToEdit;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir/Editar Puntuación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Autocompletar ---
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return _testScores.keys; // Sugiere tests existentes
                  }
                  return _testScores.keys.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  // Rellena ambos campos si se selecciona uno existente
                  nameController.text = selection;
                  scoreController.text = _testScores[selection].toString();
                  existingTestToEdit = selection;
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      nameController.text =
                          textEditingController.text; // Sincroniza
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Test (Ej: Salto Vertical)',
                        ),
                        autofocus: true,
                      );
                    },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: scoreController,
                decoration: const InputDecoration(
                  labelText: 'Puntuación (Ej: 55.5)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final score = double.tryParse(scoreController.text);
                if (nameController.text.isNotEmpty && score != null) {
                  setState(() {
                    _testScores[nameController.text.trim()] =
                        score; // Añade o sobrescribe
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(existingTestToEdit != null ? 'Actualizar' : 'Añadir'),
            ),
          ],
        );
      },
    );
  }
}
