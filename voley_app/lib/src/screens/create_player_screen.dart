// lib/src/screens/create_player_screen.dart
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
import 'package:intl/intl.dart';

// 1. Nombre de la clase cambiado
class CreatePlayerScreen extends ConsumerStatefulWidget {
  const CreatePlayerScreen({super.key});

  @override
  ConsumerState<CreatePlayerScreen> createState() => _CreatePlayerScreenState();
}

class _CreatePlayerScreenState extends ConsumerState<CreatePlayerScreen> {
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
  // (Tests eliminados de esta pantalla)
  // Map<String, double> _testScores = {}; 

  // Estado de Disponibilidad
  final List<String> _allDays = [ 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo' ];
  List<String> selectedDays = [];
  final Map<String, int> _durationOptions = {
    '30-45 minutos': 45, '45-60 minutos': 60, '60-75 minutos': 75,
    '75-90 minutos': 90, '90+ minutos': 120,
  };
  int _selectedDurationMinutes = 60; 

  // Estado de la pantalla
  bool _isSubmitting = false;
  String? _currentCoachId;

  // 2. Lógica de "Usuario Existente" eliminada

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
  
  /// Limpia todos los campos del formulario
  void _clearForm() {
      nameCtrl.clear();
      emailCtrl.clear();
      passwordCtrl.clear();
      setState(() {
        selectedPosition = 'Central';
        selectedLevel = 'Competitivo';
        selectedDays = [];
        _selectedDurationMinutes = 60;
        selectedInjuries = [];
        _selectedTournaments = [];
        // _testScores = {};
      });
  }

  // 3. _loadProfileForUser y _onUserSelected eliminados

  // ... (Diálogo _showAddTournamentDialog - sin cambios) ...
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
                    decoration:
                        const InputDecoration(labelText: 'Nombre del Torneo'),
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
                        _selectedTournaments.add(Tournament(
                          name: nameController.text,
                          date: pickedDate!,
                        ));
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

  // 4. _showAddTestDialog eliminado

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
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green, // Color de éxito
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // 5. Build simplificado
    final coachUserAsync = ref.watch(currentUserAppUserProvider);
    
    final loadingOverlay = _isSubmitting
        ? Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          )
        : const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nuevo Jugador')),
      body: Stack(
        children: [
          coachUserAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e,s) => Center(child: Text("Error al cargar usuario: $e")),
            data: (currentUser) {
              if (currentUser == null || !currentUser.isCoach) {
                 return const Center(child: Text("No tienes permisos para esta pantalla."));
              }
              _currentCoachId = currentUser.id;
              // Muestra el formulario directamente
              return _buildForm(context);
            },
          ),
          loadingOverlay,
        ],
      ),
    );
  }


  /// --- 6. Formulario Simplificado ---
  Widget _buildForm(BuildContext context) {
     return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          // 7. Sección de "Seleccionar Usuario" ELIMINADA

          // 8. Campos de Auth/User siempre visibles
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
          const SizedBox(height: 16),

          // Card de Datos del Jugador (Siempre editable)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    enabled: true, 
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPosition,
                    decoration: const InputDecoration(
                      labelText: 'Posición',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Central', 'Libero', 'Punta', 'Opuesto', 'Armadora']
                        .map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ))
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
                      border: OutlineInputBorder(),
                    ),
                    items: ['Competitivo', 'Recreativo']
                        .map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (newValue) {
                      setState(() => selectedLevel = newValue!);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Card de Disponibilidad (Siempre editable)
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
                  ..._allDays.map((day) => CheckboxListTile(
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
                      )),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedDurationMinutes,
                    decoration: const InputDecoration(
                      labelText: 'Duración por Sesión',
                      border: OutlineInputBorder(),
                    ),
                    items: _durationOptions.entries
                        .map((entry) => DropdownMenuItem<int>(
                              value: entry.value,
                              child: Text(entry.key),
                            ))
                        .toList(),
                    onChanged: (newValue) { 
                      if (newValue != null) {
                        setState(() => _selectedDurationMinutes = newValue);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Card de Lesiones (Siempre editable)
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
                    children: [ 'Rodilla', 'Tobillo', 'Hombro', 'Espalda', 'Muñeca', 'Dedo', 'Ninguna']
                        .map((injury) {
                      final isSelected = selectedInjuries.contains(injury);
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

          // Card de Torneos (Siempre editable)
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
                        onPressed: _showAddTournamentDialog, 
                      ),
                    ],
                  ),
                  _selectedTournaments.isEmpty
                      ? const Text(
                          'Añade torneos (opcional).',
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
                                setState(() => _selectedTournaments.remove(tournament));
                              },
                            );
                          }).toList(),
                        ),
                  
                  // 9. Sección de Puntuaciones de Test ELIMINADA
                
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
                : const Text(
                    'Crear Jugador y Perfil', // Texto cambiado
                    style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// --- 10. Método de Envío Simplificado ---
  Future<void> _handleSubmit() async {
    // Solo valida la creación
    if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || passwordCtrl.text.trim().isEmpty) {
      _showError('Por favor completa Nombre, Email y Contraseña');
      return;
    }
    if (_currentCoachId == null) {
      _showError('Error: No se pudo identificar al entrenador');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // --- SOLO LÓGICA DE CREAR NUEVO USUARIO ---
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

      final availability = Availability(
        trainingDays: selectedDays,
        sessionMinutes: _selectedDurationMinutes,
      );

      // Crea el Perfil NUEVO
      final profileToSave = PlayerProfile(
        id: uuid.v4(), // ID Nuevo
        userId: userId, // El ID de Auth que devolvió la función
        assignedCoachId: _currentCoachId!,
        name: nameCtrl.text.trim(),
        position: selectedPosition,
        level: selectedLevel.toLowerCase(),
        goals: ['salto', 'fuerza'],
        injuries: selectedInjuries.contains('Ninguna') ? [] : selectedInjuries,
        availability: availability,
        evaluation: EvaluationResult(
          testScores: {}, // Se guarda vacío, se llena en la otra pantalla
          strengths: ['potencia'],
          weaknesses: ['resistencia'],
        ),
        tournaments: _selectedTournaments,
      );

      // --- PASOS FINALES ---
      await _firestoreService.savePlayerProfile(profileToSave);
      
      // Ya no actualizamos 'playerProfileProvider' ni navegamos a '/generate'
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccess('¡Jugador creado exitosamente!');
        _clearForm(); // Limpia el formulario para el siguiente
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('Error al guardar: $e');
      }
    }
  }
}