import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/user.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/services/firestore_service.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  User? _currentUser;
  List<User> _linkedPlayers = [];
  Map<String, PlayerProfile?> _playerProfiles = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final currentFirebaseUser = ref.read(currentUserProvider);
      if (currentFirebaseUser == null) return;

      _currentUser = await _firestoreService.getUser(currentFirebaseUser.uid);
      
      if (_currentUser != null && _currentUser!.isCoach) {
        _linkedPlayers = await _firestoreService.getPlayersByCoach(_currentUser!.id);
        
        // Fetch player profiles for each linked player
        for (final player in _linkedPlayers) {
          final profile = await _firestoreService.getPlayerProfileByUserId(player.id);
          _playerProfiles[player.id] = profile;
        }
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

  Future<void> _createPlayer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null || !_currentUser!.isCoach) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo los coaches pueden crear jugadores'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      
      // Crear el jugador con vinculación automática al coach
      final result = await authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        UserRole.player,
        coachId: _currentUser!.id,
      );

      if (!mounted) return;

      if (result == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Jugador creado y vinculado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar formulario
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        
        // Recargar lista de jugadores
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ?? 'Error al crear jugador'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de Usuarios')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_currentUser!.isCoach) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de Usuarios')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Esta funcionalidad solo está disponible para coaches.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Jugadores'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Formulario para crear jugador
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crear Nuevo Jugador',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: const Icon(Icons.person_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa el nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa el correo';
                            }
                            if (!value.contains('@')) {
                              return 'Ingresa un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Contraseña inicial',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            helperText: 'El jugador podrá cambiarla después',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa una contraseña';
                            }
                            if (value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _createPlayer,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.person_add),
                            label: const Text('Crear Jugador'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Lista de jugadores vinculados
              Text(
                'Jugadores Vinculados (${_linkedPlayers.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              
              if (_linkedPlayers.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No tienes jugadores vinculados aún. Crea uno usando el formulario de arriba.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                ..._linkedPlayers.map((player) {
                  final profile = _playerProfiles[player.id];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          player.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        player.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(player.email),
                      trailing: const Icon(Icons.expand_more),
                      children: [
                        if (profile == null)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No hay perfil de jugador disponible. Realiza una evaluación primero.',
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(Icons.sports_volleyball, 'Posición', profile.position),
                                const SizedBox(height: 8),
                                _buildInfoRow(Icons.bar_chart, 'Nivel', profile.level),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.healing,
                                  'Lesiones',
                                  profile.injuries.isEmpty
                                      ? 'Ninguna'
                                      : profile.injuries.join(', '),
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  'Días de Entrenamiento',
                                  profile.availability.trainingDays.isEmpty
                                      ? 'No especificado'
                                      : profile.availability.trainingDays.join(', '),
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.timer,
                                  'Duración de Sesión',
                                  '${profile.availability.sessionMinutes} minutos',
                                ),
                                const SizedBox(height: 8),
                                if (profile.tournaments.isNotEmpty) ...[
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: const [
                                      Icon(Icons.emoji_events, size: 20, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text(
                                        'Torneos:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...profile.tournaments.map((tournament) => Padding(
                                        padding: const EdgeInsets.only(left: 28, bottom: 4),
                                        child: Text(
                                          '• ${tournament.name} - ${DateFormat('dd/MM/yyyy').format(tournament.date)}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      )),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}