// lib/src/screens/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:intl/intl.dart';

// (Pega aquí las definiciones de PlayerWithProfile, isCreatingPlayerProvider,
// y coachPlayersWithProfilesProvider si no las pusiste en 'providers.dart')


class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  // --- MEJORA DE ARQUITECTURA ---
  // El estado local SOLO maneja el formulario.
  // No más _isLoading, _currentUser, _linkedPlayers, etc.
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// --- MEJORA DE ARQUITECTURA: Lógica de creación refactorizada ---
  Future<void> _createPlayer() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Obtenemos el ID del coach desde el provider
    final coachId = ref.read(currentUserAppUserProvider).valueOrNull?.id;
    if (coachId == null) {
      _showError('No se pudo identificar al coach.');
      return;
    }

    // 1. Pone el estado de carga global
    ref.read(isCreatingPlayerProvider.notifier).state = true;

    try {
      final authService = ref.read(authServiceProvider);
      
      // (Asumo que tu 'authService.register' ahora usa la Cloud Function
      // que crea el usuario en Auth y Firestore al mismo tiempo)
      final result = await authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        app_user.UserRole.player,
        coachId: coachId,
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
        _formKey.currentState?.reset();
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        
        // --- MEJORA REACTIVA ---
        // 2. Invalida el provider. Esto FORZARÁ que se
        //    recargue automáticamente. No más _loadData().
        ref.invalidate(coachPlayersProvider);
        // 'coachPlayersWithProfilesProvider' se recargará solo
        // porque está observando a 'coachPlayersProvider'.

      } else {
        _showError(result ?? 'Error al crear jugador');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      // 3. Quita el estado de carga
      if (mounted) {
        ref.read(isCreatingPlayerProvider.notifier).state = false;
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Observa el provider del coach.
    final coachUserAsync = ref.watch(currentUserAppUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Jugadores'),
      ),
      // El body principal ahora es un .when() del usuario
      body: coachUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar usuario: $e')),
        data: (coachUser) {
          // Manejo de permisos
          if (coachUser == null || !coachUser.isCoach) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Esta funcionalidad solo está disponible para coaches.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          
          // Observa el estado de carga del formulario
          final isCreating = ref.watch(isCreatingPlayerProvider);

          // El RefreshIndicator ahora es mucho más simple
          return RefreshIndicator(
            // --- MEJORA REACTIVA ---
            onRefresh: () async {
              // Simplemente refresca los providers
              ref.invalidate(coachPlayersProvider);
              await ref.read(coachPlayersWithProfilesProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- MEJORA DE DISEÑO: Formulario con tema ---
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crear Nuevo Jugador',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: Icon(Icons.person_outlined),
                              ),
                              validator: (value) => (value?.isEmpty ?? true) ? 'Ingresa el nombre' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Ingresa el correo';
                                if (!value.contains('@')) return 'Ingresa un correo válido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Contraseña inicial',
                                prefixIcon: Icon(Icons.lock_outlined),
                                helperText: 'El jugador podrá cambiarla después',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Ingresa una contraseña';
                                if (value.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isCreating ? null : _createPlayer,
                                icon: isCreating
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          // --- MEJORA DE DISEÑO ---
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.person_add),
                                label: const Text('Crear Jugador'),
                                // Estilo ya viene de tu 'voltProTheme'
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // --- MEJORA DE ARQUITECTURA: Lista de jugadores reactiva ---
                  _buildPlayerList(theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Widget separado para la lista de jugadores
  Widget _buildPlayerList(ThemeData theme) {
    // Observa el nuevo provider que tiene jugadores + perfiles
    final playersWithProfilesAsync = ref.watch(coachPlayersWithProfilesProvider);

    return playersWithProfilesAsync.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      )),
      error: (e, s) => Center(child: Text('Error al cargar jugadores: $e')),
      data: (playersWithProfiles) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jugadores Vinculados (${playersWithProfiles.length})',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (playersWithProfiles.isEmpty)
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No tienes jugadores vinculados aún. Crea uno usando el formulario de arriba.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...playersWithProfiles.map((item) {
                final player = item.player;
                final profile = item.profile;
                // --- MEJORA DE DISEÑO: Lista con tema ---
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary, // Volt
                      child: Text(
                        player.name[0].toUpperCase(),
                        style: TextStyle(color: theme.colorScheme.onPrimary), // Texto oscuro
                      ),
                    ),
                    title: Text(
                      player.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(player.email),
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
                              _buildInfoRow(theme, Icons.sports_volleyball, 'Posición', profile.position),
                              const SizedBox(height: 8),
                              _buildInfoRow(theme, Icons.bar_chart, 'Nivel', profile.level),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                theme,
                                Icons.healing,
                                'Lesiones',
                                profile.injuries.isEmpty ? 'Ninguna' : profile.injuries.join(', '),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                theme,
                                Icons.calendar_today,
                                'Días',
                                profile.availability.trainingDays.isEmpty
                                    ? 'No especificado'
                                    : profile.availability.trainingDays.join(', '),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                theme,
                                Icons.timer,
                                'Duración',
                                '${profile.availability.sessionMinutes} min',
                              ),
                              if (profile.tournaments.isNotEmpty) ...[
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    Icon(Icons.emoji_events, size: 20, color: theme.colorScheme.secondary), // Azul Pro
                                    const SizedBox(width: 8),
                                    Text(
                                      'Torneos:',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...profile.tournaments.map((tournament) => Padding(
                                      padding: const EdgeInsets.only(left: 28, bottom: 4),
                                      child: Text(
                                        '• ${tournament.name} - ${DateFormat('dd/MM/yy').format(tournament.date)}',
                                        style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
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
        );
      },
    );
  }

  /// --- MEJORA DE DISEÑO: Widget de info con tema ---
  Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary), // Azul Pro
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface), // Color de texto del tema
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