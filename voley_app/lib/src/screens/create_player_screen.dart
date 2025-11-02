// lib/src/screens/create_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
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
  final uuid = Uuid();

  // Estado del formulario (Efímero, se queda en la UI)
  String selectedPosition = 'Central';
  String selectedLevel = 'Competitivo';
  List<Tournament> _selectedTournaments = [];
  List<String> selectedInjuries = [];
  List<String> selectedDays = [];
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

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
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

      final profileToSave = PlayerProfile(
        id: uuid.v4(),
        userId: userId,
        assignedCoachId: coachId,
        name: nameCtrl.text.trim(),
        position: selectedPosition,
        level: selectedLevel.toLowerCase(),
        goals: [], // Se definen después en la evaluación
        injuries: selectedInjuries.contains('Ninguna') ? [] : selectedInjuries,
        availability: availability,
        evaluation: EvaluationResult(
          testScores: {}, // Se llena en la pantalla de Evaluación
          strengths: [],
          weaknesses: [],
        ),
        tournaments: _selectedTournaments,
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

  // ... (Tu diálogo _showAddTournamentDialog se queda igual) ...
  Future<void> _showAddTournamentDialog() async {
    /* ... tu código ... */
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
            DropdownButtonFormField<String>(
              value: selectedPosition,
              decoration: const InputDecoration(
                labelText: 'Posición',
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
              onChanged: (newValue) {
                setState(() => selectedPosition = newValue!);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedLevel,
              decoration: const InputDecoration(
                labelText: 'Nivel',
                prefixIcon: Icon(Icons.bar_chart),
              ),
              items: ['Competitivo', 'Recreativo']
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) {
                setState(() => selectedLevel = newValue!);
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Lesiones (opcional)',
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            // --- MEJORA DE DISEÑO: FilterChip con tema ---
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
                    final isSelected = selectedInjuries.contains(injury);
                    return FilterChip(
                      label: Text(injury),
                      selected: isSelected,
                      // --- MEJORA DE DISEÑO: Colores del tema ---
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          if (injury == 'Ninguna') {
                            selectedInjuries.clear();
                            if (selected) selectedInjuries.add('Ninguna');
                          } else {
                            selectedInjuries.remove('Ninguna');
                            if (selected)
                              selectedInjuries.add(injury);
                            else
                              selectedInjuries.remove(injury);
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
          ],
        ),
      ),
    );
  }
}
