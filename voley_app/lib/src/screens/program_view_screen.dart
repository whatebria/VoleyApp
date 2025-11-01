// lib/screens/program_view_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/src/models/user.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/services/firestore_service.dart';
import 'package:intl/intl.dart';

class ProgramViewScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProgramViewScreen> createState() => _ProgramViewScreenState();
}

class _ProgramViewScreenState extends ConsumerState<ProgramViewScreen> {
  final _firestoreService = FirestoreService();
  
  User? _currentUser;
  List<User> _linkedPlayers = [];
  User? _selectedPlayer;
  List<Program> _programs = [];
  Program? _selectedProgram;
  bool _isLoading = true;
  bool _isLoadingPrograms = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final currentFirebaseUser = ref.read(currentUserProvider);
      if (currentFirebaseUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      _currentUser = await _firestoreService.getUser(currentFirebaseUser.uid);
      
      if (_currentUser != null && _currentUser!.isCoach) {
        // Load linked players for coaches
        _linkedPlayers = await _firestoreService.getPlayersByCoach(_currentUser!.id);
        
        // Auto-select first player if available
        if (_linkedPlayers.isNotEmpty) {
          _selectedPlayer = _linkedPlayers.first;
          await _loadProgramsForPlayer(_selectedPlayer!.id);
        }
      } else if (_currentUser != null && _currentUser!.isPlayer) {
        // For players, load their own programs
        await _loadProgramsForPlayer(_currentUser!.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
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

  Future<void> _loadProgramsForPlayer(String userId) async {
    setState(() => _isLoadingPrograms = true);

    try {
      // Get player profile to get the player ID
      final profile = await _firestoreService.getPlayerProfileByUserId(userId);
      
      if (profile != null) {
        _programs = await _firestoreService.getProgramsByPlayer(profile.id);
        
        // Auto-select first program if available
        if (_programs.isNotEmpty) {
          _selectedProgram = _programs.first;
        } else {
          _selectedProgram = null;
        }
      } else {
        _programs = [];
        _selectedProgram = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar programas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _programs = [];
      _selectedProgram = null;
    } finally {
      if (mounted) {
        setState(() => _isLoadingPrograms = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ver Programas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ver Programas'),
      ),
      body: Column(
        children: [
          // Player selector for coaches
          if (_currentUser != null && _currentUser!.isCoach && _linkedPlayers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleccionar Jugador:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<User>(
                    value: _selectedPlayer,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _linkedPlayers.map((user) {
                      return DropdownMenuItem<User>(
                        value: user,
                        child: Text(user.name),
                      );
                    }).toList(),
                    onChanged: (User? newValue) async {
                      if (newValue != null) {
                        setState(() {
                          _selectedPlayer = newValue;
                        });
                        await _loadProgramsForPlayer(newValue.id);
                      }
                    },
                  ),
                ],
              ),
            ),

          // Program selector
          if (_programs.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleccionar Programa:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Program>(
                    value: _selectedProgram,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _programs.map((program) {
                      return DropdownMenuItem<Program>(
                        value: program,
                        child: Text(
                          '${DateFormat('dd/MM/yyyy').format(program.startDate)} - ${DateFormat('dd/MM/yyyy').format(program.endDate)}',
                        ),
                      );
                    }).toList(),
                    onChanged: (Program? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedProgram = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

          // Program content
          Expanded(
            child: _isLoadingPrograms
                ? const Center(child: CircularProgressIndicator())
                : _selectedProgram == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _currentUser != null && _currentUser!.isCoach && _linkedPlayers.isEmpty
                                    ? 'No tienes jugadores vinculados'
                                    : 'No hay programas generados',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentUser != null && _currentUser!.isCoach && _linkedPlayers.isEmpty
                                    ? 'Vincula jugadores en User Management'
                                    : 'Genera un programa desde la evaluación',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildProgramDetails(_selectedProgram!),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramDetails(Program program) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: program.mesocycles.length,
      itemBuilder: (context, i) {
        final m = program.mesocycles[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ExpansionTile(
            title: Text(
              m.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${m.weeks} semanas — Enfoque: ${m.focus}'),
            children: m.microcycles.map((mc) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    '${mc.weekNumber}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text('Semana ${mc.weekNumber}'),
                subtitle: Text('${mc.sessions.length} sesiones'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) {
                      return DraggableScrollableSheet(
                        initialChildSize: 0.7,
                        minChildSize: 0.5,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (context, scrollController) {
                          return Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Semana ${mc.weekNumber}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: mc.sessions.length,
                                  itemBuilder: (context, index) {
                                    final s = mc.sessions[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.fitness_center,
                                                  color: Colors.orange[700],
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    s.day,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Objetivo: ${s.objective}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Carga: ${s.load}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const Divider(height: 16),
                                            const Text(
                                              'Ejercicios:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...s.exercises.map((e) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 4),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('• ', style: TextStyle(fontSize: 16)),
                                                      Expanded(child: Text(e.name)),
                                                    ],
                                                  ),
                                                )),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
