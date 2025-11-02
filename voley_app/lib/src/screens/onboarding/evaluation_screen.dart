// lib/screens/evaluation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/services/firestore_service.dart';
import 'package:voley_app/src/auth/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart'; // Import para el DatePicker

class EvaluationScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final positionCtrl = TextEditingController();
  final levelCtrl = TextEditingController();
  final testScoreCtrl = TextEditingController();
  // final sessionMinutesCtrl = TextEditingController(); // <-- 1. ELIMINADO
  final uuid = Uuid();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  String selectedPosition = 'Central';
  String selectedLevel = 'Competitivo';
  List<Tournament> _selectedTournaments = [];
  List<String> selectedInjuries = [];

  // --- 1. CAMBIOS EN DISPONIBILIDAD ---
  final List<String> _allDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  List<String> selectedDays = [];

  // Opciones para los rangos de duración (Texto amigable -> Valor en minutos)
  final Map<String, int> _durationOptions = {
    '30-45 minutos': 45,
    '45-60 minutos': 60,
    '60-75 minutos': 75,
    '75-90 minutos': 90,
    '90+ minutos': 120,
  };
  // Valor seleccionado (60 minutos por defecto)
  int _selectedDurationMinutes = 60;
  // --- FIN CAMBIOS EN DISPONIBILIDAD ---

  // User selection state
  bool _isCreatingNewUser = true;
  app_user.User? _selectedUser;
  List<app_user.User> _availablePlayers = [];
  bool _isLoading = true;
  String? _currentCoachId;

  @override
  void initState() {
    super.initState();
    // sessionMinutesCtrl.text = '60'; // <-- 2. ELIMINADO
    _loadCoachPlayers();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    positionCtrl.dispose();
    levelCtrl.dispose();
    testScoreCtrl.dispose();
    // sessionMinutesCtrl.dispose(); // <-- 3. ELIMINADO
    super.dispose();
  }

  Future<void> _loadCoachPlayers() async {
    setState(() => _isLoading = true);

    try {
      final currentFirebaseUser = ref.read(currentUserProvider);
      if (currentFirebaseUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      _currentCoachId = currentFirebaseUser.uid;

      final currentUser = await _firestoreService.getUser(
        currentFirebaseUser.uid,
      );

      if (currentUser != null && currentUser.isCoach) {
        _availablePlayers = await _firestoreService.getPlayersByCoach(
          currentFirebaseUser.uid,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar jugadores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onUserSelected(app_user.User? user) {
    setState(() {
      _selectedUser = user;
      if (user != null) {
        nameCtrl.text = user.name;
        emailCtrl.text = user.email;
      } else {
        nameCtrl.clear();
        emailCtrl.clear();
      }
    });
  }

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
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Evaluación Inicial')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Evaluación Inicial')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... (Card de Selección de Usuario - sin cambios) ...
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleccionar Usuario',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Usuario Existente'),
                          icon: Icon(Icons.person),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Crear Nuevo'),
                          icon: Icon(Icons.person_add),
                        ),
                      ],
                      selected: {_isCreatingNewUser},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _isCreatingNewUser = newSelection.first;
                          if (_isCreatingNewUser) {
                            _selectedUser = null;
                            nameCtrl.clear();
                            emailCtrl.clear();
                            passwordCtrl.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ... (Campos de Usuario Existente/Nuevo - sin cambios) ...
            if (!_isCreatingNewUser) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar Jugador',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (_availablePlayers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No tienes jugadores vinculados. Crea un nuevo usuario.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        DropdownButtonFormField<app_user.User>(
                          value: _selectedUser,
                          decoration: const InputDecoration(
                            labelText: 'Jugador',
                            border: OutlineInputBorder(),
                          ),
                          items: _availablePlayers.map((user) {
                            return DropdownMenuItem<app_user.User>(
                              value: user,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [Text(user.name)],
                              ),
                            );
                          }).toList(),
                          onChanged: _onUserSelected,
                        ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datos del Nuevo Usuario',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ... (Card de Datos del Jugador - sin cambios) ...
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos del Jugador',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isCreatingNewUser || _selectedUser != null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ... (Card de Posición y Nivel - sin cambios) ...
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPosition,
                      decoration: const InputDecoration(
                        labelText: 'Posición',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                            'Central',
                            'Libero',
                            'Punta',
                            'Opuesto',
                            'Armadora',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedPosition = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      // No uses 'initialValue' y 'value' juntos. 'value' es suficiente.
                      value: selectedLevel,
                      decoration: const InputDecoration(
                        labelText: 'Nivel',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Competitivo', 'Recreativo'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedLevel = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- 4. INICIO DE LA UI DE DISPONIBILIDAD MODIFICADA ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disponibilidad',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    // Checkbox para todos los días
                    ..._allDays.map((day) {
                      return CheckboxListTile(
                        title: Text(day),
                        value: selectedDays.contains(day),
                        onChanged: (bool? value) {
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
                      );
                    }).toList(),

                    const SizedBox(height: 16),

                    // Dropdown para los rangos de sesión
                    DropdownButtonFormField<int>(
                      value: _selectedDurationMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Duración por Sesión',
                        border: OutlineInputBorder(),
                      ),
                      items: _durationOptions.entries.map((entry) {
                        // entry.key = "45-60 minutos", entry.value = 60
                        return DropdownMenuItem<int>(
                          value: entry.value,
                          child: Text(entry.key),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedDurationMinutes = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // --- FIN DE LA UI DE DISPONIBILIDAD MODIFICADA ---
            const SizedBox(height: 12),

            // ... (Card de Lesiones - sin cambios) ...
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesiones',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
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
                            final isSelected = selectedInjuries.contains(
                              injury,
                            );
                            return FilterChip(
                              label: Text(injury),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                setState(() {
                                  if (injury == 'Ninguna') {
                                    if (selected) {
                                      selectedInjuries.clear();
                                      selectedInjuries.add('Ninguna');
                                    } else {
                                      selectedInjuries.remove('Ninguna');
                                    }
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
            ),
            const SizedBox(height: 12),

            // ... (Card de Evaluación y Torneos - sin cambios) ...
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Evaluación y Torneos',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.blue,
                          ),
                          tooltip: 'Añadir Torneo',
                          onPressed: _showAddTournamentDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedTournaments.isEmpty)
                      const Text(
                        'Añade torneos presionando el botón "+".',
                        style: TextStyle(color: Colors.grey),
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
                            onDeleted: () {
                              setState(() {
                                _selectedTournaments.remove(tournament);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: testScoreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Puntuación de Test (Ej: Salto)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Guardar evaluación y generar programa',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // ... (Validaciones - sin cambios) ...
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre del jugador'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isCreatingNewUser) {
      if (emailCtrl.text.trim().isEmpty || passwordCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor completa email y contraseña'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_selectedUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona un usuario'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_currentCoachId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo identificar al entrenador'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String userId;

      if (_isCreatingNewUser) {
        // ... (Lógica de creación de usuario - sin cambios) ...
        final result = await _authService.register(
          emailCtrl.text.trim(),
          passwordCtrl.text.trim(),
          nameCtrl.text.trim(),
          app_user.UserRole.player,
        );

        if (result != "success") {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al crear usuario: $result'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final createdUsers = await _firestoreService.getAllPlayers();
        final newUser = createdUsers.firstWhere(
          (u) => u.email == emailCtrl.text.trim(),
        );
        userId = newUser.id;

        await _firestoreService.createPermission(
          coachId: _currentCoachId!,
          playerId: userId,
        );
      } else {
        userId = _selectedUser!.id;
      }

      // --- 5. LÓGICA DE AVAILABILITY MODIFICADA ---
      final availability = Availability(
        trainingDays: selectedDays,
        sessionMinutes:
            _selectedDurationMinutes, // <-- USA EL VALOR DEL DROPDOWN
      );
      // --- FIN DE LA LÓGICA ---

      // Create player profile
      final profile = PlayerProfile(
        id: uuid.v4(),
        userId: userId,
        name: nameCtrl.text.trim(),
        assignedCoachId: _currentCoachId!,
        position: selectedPosition,
        level: selectedLevel.toLowerCase(), // Guardar en minúsculas
        goals: ['salto', 'fuerza'], // (hardcoded, añade UI para esto)
        injuries: selectedInjuries.contains('Ninguna') ? [] : selectedInjuries,
        availability: availability, // <-- USA EL OBJETO CREADO
        evaluation: EvaluationResult(
          testScores: {'salto': double.tryParse(testScoreCtrl.text) ?? 0.0},
          strengths: ['potencia'], // (hardcoded, añade UI para esto)
          weaknesses: ['resistencia'], // (hardcoded, añade UI para esto)
        ),
        tournaments: _selectedTournaments,
      );

      // Save profile to Firestore
      await _firestoreService.savePlayerProfile(profile);

      // Update provider
      ref.read(playerProfileProvider.notifier).state = profile;

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluación guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamed(context, '/generate');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
