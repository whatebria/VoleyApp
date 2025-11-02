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
import 'package:voley_app/src/screens/program_editor_screen.dart';
import 'package:voley_app/src/services/firestore_service.dart';
import 'package:voley_app/src/auth/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class EvaluationScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  // Controladores
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final uuid = Uuid();

  // Instancias de servicios
  late final FirestoreService _firestoreService;
  late final AuthService _authService;

  // Estado del formulario
  String selectedPosition = 'Central';
  String selectedLevel = 'Competitivo';
  List<Tournament> _selectedTournaments = [];
  List<String> selectedInjuries = [];
  Map<String, double> _testScores = {};

  // Estado de Disponibilidad
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
  final Map<String, int> _durationOptions = {
    '30-45 minutos': 45,
    '45-60 minutos': 60,
    '60-75 minutos': 75,
    '75-90 minutos': 90,
    '90+ minutos': 120,
  };
  int _selectedDurationMinutes = 60;

  // Estado de la pantalla
  bool _isCreatingNewUser = true; // El Coach ve esto por defecto
  app_user.User? _selectedUser;
  PlayerProfile? _loadedProfile;
  bool _isSubmitting = false;
  String? _currentCoachId;
  bool _profileLoaded = false; // Flag para evitar recargas

  /// Getter para saber si estamos en modo edición (y bloquear campos)
  bool get _isExistingUser => !_isCreatingNewUser && _selectedUser != null;

  @override
  void initState() {
    super.initState();
    _firestoreService = ref.read(firestoreProvider);
    _authService = ref.read(authServiceProvider);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    // Limpia los controladores
    nameCtrl.clear();
    emailCtrl.clear();
    passwordCtrl.clear();
    // Resetea el estado
    setState(() {
      selectedPosition = 'Central';
      selectedLevel = 'Competitivo';
      selectedDays = [];
      _selectedDurationMinutes = 60;
      selectedInjuries = [];
      _selectedTournaments = [];
      _testScores = {};
      _loadedProfile = null;
      _profileLoaded = false;
    });
  }

  Future<void> _loadProfileForUser(String userId) async {
    // Evita recargar si ya está cargado
    if (_profileLoaded) return;

    setState(() {
      _isSubmitting = true;
      _profileLoaded = true; // Marca que hemos intentado cargar
    });

    try {
      final profile = await _firestoreService.getPlayerProfileByUserId(userId);
      if (profile != null && mounted) {
        final p = profile;
        setState(() {
          _loadedProfile = p; // Almacena el perfil cargado
          // Rellena el formulario
          nameCtrl.text = p.name;
          selectedPosition = p.position;
          selectedLevel = p.level.isNotEmpty
              ? p.level[0].toUpperCase() + p.level.substring(1)
              : 'Competitivo';
          selectedDays = p.availability.trainingDays;
          _selectedDurationMinutes = p.availability.sessionMinutes;
          selectedInjuries = p.injuries;
          _selectedTournaments = p.tournaments;
          _testScores = p.evaluation.testScores;
        });
      }
    } catch (e) {
      _showError('Error al cargar perfil: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _onUserSelected(app_user.User? user) {
    setState(() {
      _selectedUser = user;
      _clearForm(); // Limpia todo

      if (user != null) {
        // Rellena los datos básicos
        nameCtrl.text = user.name;
        emailCtrl.text = user.email;
        // Carga el resto
        _loadProfileForUser(user.id);
      }
    });
  }

  // ... (Diálogos _showAddTournamentDialog y _showAddTestDialog - sin cambios) ...
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

  Future<void> _showAddTestDialog() async {
    final nameController = TextEditingController();
    final scoreController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Puntuación de Test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Test (Ej: Salto Vertical)',
                ),
                autofocus: true,
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
                    _testScores[nameController.text] = score;
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
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Carga reactiva
    final coachUserAsync = ref.watch(currentUserAppUserProvider);
    final availablePlayersAsync = ref.watch(coachPlayersProvider);

    final loadingOverlay = _isSubmitting
        ? Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          )
        : const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Evaluación Inicial')),
      body: Stack(
        children: [
          // Espera a que el usuario (coach) esté cargado
          coachUserAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text("Error al cargar usuario: $e")),
            data: (currentUser) {
              if (currentUser == null) {
                return const Center(
                  child: Text("No se pudo cargar el usuario."),
                );
              }

              // --- LÓGICA DE ROL ---
              if (currentUser.isCoach) {
                // Es COACH
                _currentCoachId = currentUser.id;
                return availablePlayersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) =>
                      Center(child: Text("Error al cargar jugadores: $e")),
                  data: (players) =>
                      _buildForm(context, players, isCoach: true),
                );
              } else {
                // Es JUGADOR
                _currentCoachId = currentUser.coachId; // ID del coach asignado

                // Forzamos el modo "edición" para el jugador actual
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_profileLoaded && !_isSubmitting) {
                    setState(() {
                      _isCreatingNewUser = false;
                      _selectedUser = currentUser;
                    });
                    _loadProfileForUser(currentUser.id);
                  }
                });

                return _buildForm(context, [], isCoach: false);
              }
              // --- FIN LÓGICA DE ROL ---
            },
          ),
          loadingOverlay,
        ],
      ),
    );
  }

  /// --- WIDGET QUE CONSTRUYE EL FORMULARIO ---
  Widget _buildForm(
    BuildContext context,
    List<app_user.User> availablePlayers, {
    required bool isCoach,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- ESTA SECCIÓN SOLO SE MUESTRA SI ES COACH ---
          if (isCoach) ...[
            // Card de Selección de Usuario
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
                          _onUserSelected(null);
                          passwordCtrl.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Campos de Usuario Existente/Nuevo (Solo para Coach)
            if (!_isCreatingNewUser) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: DropdownButtonFormField<app_user.User>(
                    value: _selectedUser,
                    decoration: const InputDecoration(
                      labelText: 'Jugador',
                      border: OutlineInputBorder(),
                    ),
                    items: availablePlayers.map((user) {
                      return DropdownMenuItem<app_user.User>(
                        value: user,
                        child: Text(user.name),
                      );
                    }).toList(),
                    onChanged: _onUserSelected, // Esto cargará el perfil
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña *',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
          // --- FIN DE LA SECCIÓN SOLO PARA COACH ---

          // Card de Datos del Jugador
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    // Si es coach Y está creando, es editable.
                    // Si es jugador, está bloqueado.
                    enabled: isCoach && _isCreatingNewUser,
                    decoration: InputDecoration(
                      labelText: 'Nombre *',
                      border: const OutlineInputBorder(),
                      filled: !isCoach || _isExistingUser,
                      fillColor: (!_isCreatingNewUser)
                          ? Colors.grey[200]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPosition,
                    decoration: InputDecoration(
                      labelText: 'Posición',
                      border: const OutlineInputBorder(),
                      filled: _isExistingUser || !isCoach,
                      fillColor: (_isExistingUser || !isCoach)
                          ? Colors.grey[200]
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
                    onChanged: (_isExistingUser || !isCoach)
                        ? null
                        : (newValue) {
                            // Bloqueado
                            setState(() => selectedPosition = newValue!);
                          },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: InputDecoration(
                      labelText: 'Nivel',
                      border: const OutlineInputBorder(),
                      filled: _isExistingUser || !isCoach,
                      fillColor: (_isExistingUser || !isCoach)
                          ? Colors.grey[200]
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
                    onChanged: (_isExistingUser || !isCoach)
                        ? null
                        : (newValue) {
                            // Bloqueado
                            setState(() => selectedLevel = newValue!);
                          },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Card de Disponibilidad
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
                  ..._allDays.map(
                    (day) => CheckboxListTile(
                      title: Text(day),
                      value: selectedDays.contains(day),
                      onChanged: (_isExistingUser || !isCoach)
                          ? null
                          : (bool? value) {
                              // Bloqueado
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
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedDurationMinutes,
                    decoration: InputDecoration(
                      labelText: 'Duración por Sesión',
                      border: const OutlineInputBorder(),
                      filled: _isExistingUser || !isCoach,
                      fillColor: (_isExistingUser || !isCoach)
                          ? Colors.grey[200]
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
                    onChanged: (_isExistingUser || !isCoach)
                        ? null
                        : (newValue) {
                            // Bloqueado
                            if (newValue != null) {
                              setState(
                                () => _selectedDurationMinutes = newValue,
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Card de Lesiones
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
                          final isSelected = selectedInjuries.contains(injury);
                          return FilterChip(
                            label: Text(injury),
                            selected: isSelected,
                            onSelected: (_isExistingUser || !isCoach)
                                ? null
                                : (bool selected) {
                                    // Bloqueado
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

          // Card de Evaluación y Torneos
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
                        'Torneos',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        tooltip: 'Añadir Torneo',
                        onPressed: (_isExistingUser || !isCoach)
                            ? null
                            : _showAddTournamentDialog, // Bloqueado
                      ),
                    ],
                  ),
                  _selectedTournaments.isEmpty
                      ? Text(
                          (_isExistingUser || !isCoach)
                              ? 'Los torneos del jugador se muestran aquí.'
                              : 'Añade torneos (solo para usuarios nuevos).',
                          style: const TextStyle(color: Colors.grey),
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
                              onDeleted: (_isExistingUser || !isCoach)
                                  ? null
                                  : () {
                                      // Bloqueado
                                      setState(
                                        () => _selectedTournaments.remove(
                                          tournament,
                                        ),
                                      );
                                    },
                            );
                          }).toList(),
                        ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Puntuaciones de Test',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.green,
                        ),
                        tooltip: 'Añadir Test',
                        onPressed: _showAddTestDialog, // ¡SIEMPRE HABILITADO!
                      ),
                    ],
                  ),
                  if (_testScores.isEmpty)
                    const Text(
                      'Añade puntuaciones de test presionando el botón "+".',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ..._testScores.entries.map((entry) {
                      return ListTile(
                        title: Text(entry.key),
                        trailing: Text(entry.value.toString()),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botón de Envío
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _isExistingUser
                        ? 'Actualizar Tests y Generar'
                        : 'Guardar y Generar Programa',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
          const SizedBox(height: 10),
          Text("--- O ---"),
          const SizedBox(height: 10),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700], // Color diferente
            ),
            // Solo se activa si es un USUARIO EXISTENTE
            onPressed: (_isExistingUser && _loadedProfile != null)
                ? () {
                    // Navega a la nueva pantalla del editor
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProgramEditorScreen(profile: _loadedProfile!),
                      ),
                    );
                  }
                : null, // Desactivado si es un usuario nuevo
            child: const Text('Crear Programa Manualmente'),
          ),
        ],
      ),
    );
  }

  /// --- Método de Envío (con lógica de 'id' corregida) ---
  Future<void> _handleSubmit() async {
    // Validaciones
    if (nameCtrl.text.trim().isEmpty) {
      _showError('Por favor ingresa el nombre del jugador');
      return;
    }
    if (_isCreatingNewUser &&
        (emailCtrl.text.trim().isEmpty || passwordCtrl.text.trim().isEmpty)) {
      _showError('Por favor completa email y contraseña');
      return;
    }
    // Si no es coach Y no está creando, DEBE ser un jugador existente (para el modo Player)
    // O si es coach Y no está creando, debe haber seleccionado un usuario.
    if (!_isCreatingNewUser && _selectedUser == null) {
      _showError('Por favor selecciona un usuario');
      return;
    }
    if (_currentCoachId == null) {
      // Si el jugador no tiene coach, _currentCoachId será null
      // Asignamos un ID genérico o vacío si es un jugador sin coach
      if (ref.read(currentUserAppUserProvider).value?.isPlayer ?? false) {
        _currentCoachId = ""; // Un jugador puede no tener coach
      } else {
        _showError('Error: No se pudo identificar al entrenador');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      PlayerProfile profileToSave;

      final availability = Availability(
        trainingDays: selectedDays,
        sessionMinutes: _selectedDurationMinutes,
      );

      if (_isCreatingNewUser) {
        // --- LÓGICA DE CREAR NUEVO USUARIO (Solo Coach) ---
        final functions = ref.read(functionsProvider);
        final callable = functions.httpsCallable('createPlayerAccount');
        final result = await callable.call(<String, dynamic>{
          'email': emailCtrl.text.trim(),
          'password': passwordCtrl.text.trim(),
          'name': nameCtrl.text.trim(),
          'coachId': _currentCoachId!,
        });

        final userId = result.data['userId'];
        if (userId == null) {
          throw Exception('La Cloud Function no devolvió un userId.');
        }

        profileToSave = PlayerProfile(
          id: uuid.v4(), // ID Nuevo
          userId: userId, // El ID de Auth que devolvió la función
          assignedCoachId: _currentCoachId!,
          name: nameCtrl.text.trim(),
          position: selectedPosition,
          level: selectedLevel.toLowerCase(),
          goals: ['salto', 'fuerza'],
          injuries: selectedInjuries.contains('Ninguna')
              ? []
              : selectedInjuries,
          availability: availability,
          evaluation: EvaluationResult(
            testScores: _testScores,
            strengths: ['potencia'],
            weaknesses: ['resistencia'],
          ),
          tournaments: _selectedTournaments,
        );
      } else {
        // --- LÓGICA DE ACTUALIZAR (Coach) O CREAR/ACTUALIZAR (Jugador) ---

        // _selectedUser no puede ser null aquí (validado arriba)

        if (_loadedProfile != null) {
          // A. ACTUALIZAR Perfil Existente (Coach o Jugador)
          profileToSave = _loadedProfile!.copyWith(
            // Solo actualizamos el mapa de 'testScores'
            evaluation: _loadedProfile!.evaluation.copyWith(
              testScores: _testScores,
            ),
          );
        } else {
          // B. CREAR Perfil por primera vez (Jugador)
          profileToSave = PlayerProfile(
            id: uuid.v4(), // ID Nuevo
            userId: _selectedUser!.id, // ID del Jugador logueado
            assignedCoachId: _currentCoachId!, // (puede ser "" si no tiene)
            name: _selectedUser!.name, // (Nombre de su cuenta de usuario)
            position: selectedPosition,
            level: selectedLevel.toLowerCase(),
            goals: ['salto', 'fuerza'],
            injuries: selectedInjuries.contains('Ninguna')
                ? []
                : selectedInjuries,
            availability: availability,
            evaluation: EvaluationResult(
              testScores: _testScores,
              strengths: ['potencia'],
              weaknesses: ['resistencia'],
            ),
            tournaments: _selectedTournaments,
          );
        }
      }

      // --- PASOS FINALES ---
      await _firestoreService.savePlayerProfile(profileToSave);
      ref.read(playerProfileProvider.notifier).state = profileToSave;

      if (mounted) {
        setState(() => _isSubmitting = false);
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
        setState(() => _isSubmitting = false);
        _showError('Error al guardar: $e');
      }
    }
  }
}
