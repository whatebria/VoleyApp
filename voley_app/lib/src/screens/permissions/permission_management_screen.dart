// lib/src/screens/permissions/permission_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/models/coach_player_permission.dart';
import 'package:voley_app/src/services/firestore_service.dart';
import 'package:voley_app/providers/auth_provider.dart';

/// Pantalla para gestionar permisos entre entrenadores y jugadores
/// 
/// Para Entrenadores:
/// - Ver lista de jugadores con acceso
/// - Ver solicitudes pendientes
/// - Solicitar acceso a nuevos jugadores
/// 
/// Para Jugadores:
/// - Ver solicitudes pendientes
/// - Aceptar/rechazar solicitudes
/// - Ver entrenadores autorizados
class PermissionManagementScreen extends ConsumerStatefulWidget {
  const PermissionManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PermissionManagementScreen> createState() =>
      _PermissionManagementScreenState();
}

class _PermissionManagementScreenState
    extends ConsumerState<PermissionManagementScreen> {
  final _firestoreService = FirestoreService();
  bool _isLoading = true;
  app_user.User? _currentUser;
  List<CoachPlayerPermission> _permissions = [];
  List<app_user.User> _relatedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final currentFirebaseUser = ref.read(currentUserProvider);
      if (currentFirebaseUser == null) return;

      // Obtener datos del usuario actual
      _currentUser = await _firestoreService.getUser(currentFirebaseUser.uid);
      if (_currentUser == null) return;

      if (_currentUser!.isCoach) {
        // Si es entrenador, obtener sus permisos y jugadores
        _permissions = await _firestoreService.getPermissionsByCoach(_currentUser!.id);
        _relatedUsers = await _firestoreService.getPlayersByCoach(_currentUser!.id);
      } else {
        // Si es jugador, obtener permisos pendientes y entrenadores
        _permissions = await _firestoreService.getPendingPermissionsForPlayer(_currentUser!.id);
        _relatedUsers = await _firestoreService.getCoachesByPlayer(_currentUser!.id);
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

  Future<void> _handlePermissionAction(
    CoachPlayerPermission permission,
    PermissionStatus newStatus,
  ) async {
    try {
      await _firestoreService.updatePermissionStatus(
        permissionId: permission.id,
        status: newStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == PermissionStatus.accepted
                  ? '¡Permiso aceptado!'
                  : 'Permiso rechazado',
            ),
            backgroundColor: newStatus == PermissionStatus.accepted
                ? Colors.green
                : Colors.orange,
          ),
        );
        _loadData(); // Recargar datos
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
    }
  }

  Future<void> _handleDeletePermission(String permissionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Estás seguro de revocar este permiso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestoreService.deletePermission(permissionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso revocado'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de Permisos')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de Permisos')),
        body: const Center(
          child: Text('Error: No se pudo cargar el usuario'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentUser!.isCoach
              ? 'Mis Jugadores'
              : 'Mis Entrenadores',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sección de usuarios relacionados (jugadores o entrenadores)
            _buildRelatedUsersSection(),
            
            const SizedBox(height: 24),
            
            // Sección de solicitudes pendientes
            if (_permissions.isNotEmpty) _buildPendingPermissionsSection(),
          ],
        ),
      ),
      floatingActionButton: _currentUser!.isCoach
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: Navegar a pantalla de búsqueda de jugadores
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Función de búsqueda en desarrollo'),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Agregar Jugador'),
            )
          : null,
    );
  }

  Widget _buildRelatedUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentUser!.isCoach
              ? 'Jugadores con Acceso (${_relatedUsers.length})'
              : 'Entrenadores Autorizados (${_relatedUsers.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (_relatedUsers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _currentUser!.isCoach
                    ? 'No tienes jugadores autorizados aún.\nSolicita acceso a un jugador para comenzar.'
                    : 'No tienes entrenadores autorizados aún.\nAcepta una solicitud para comenzar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ..._relatedUsers.map((user) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user.name[0].toUpperCase()),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      // Buscar el permiso correspondiente
                      final permission = await _findPermission(user.id);
                      if (permission != null) {
                        _handleDeletePermission(permission.id);
                      }
                    },
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildPendingPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solicitudes Pendientes (${_permissions.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ..._permissions.map((permission) => FutureBuilder<app_user.User?>(
              future: _firestoreService.getUser(
                _currentUser!.isCoach
                    ? permission.playerId
                    : permission.coachId,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Card(
                    child: ListTile(
                      title: Text('Cargando...'),
                    ),
                  );
                }

                final user = snapshot.data!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text(user.name[0].toUpperCase()),
                    ),
                    title: Text(user.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        const SizedBox(height: 4),
                        Text(
                          'Estado: ${_getStatusText(permission.status)}',
                          style: TextStyle(
                            color: _getStatusColor(permission.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: _currentUser!.isPlayer && permission.isPending
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _handlePermissionAction(
                                  permission,
                                  PermissionStatus.accepted,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _handlePermissionAction(
                                  permission,
                                  PermissionStatus.rejected,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            )),
      ],
    );
  }

  Future<CoachPlayerPermission?> _findPermission(String userId) async {
    try {
      final allPermissions = _currentUser!.isCoach
          ? await _firestoreService.getPermissionsByCoach(_currentUser!.id)
          : await _firestoreService.getPendingPermissionsForPlayer(_currentUser!.id);

      return allPermissions.firstWhere(
        (p) => _currentUser!.isCoach
            ? p.playerId == userId && p.isAccepted
            : p.coachId == userId && p.isAccepted,
      );
    } catch (e) {
      return null;
    }
  }

  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.pending:
        return 'Pendiente';
      case PermissionStatus.accepted:
        return 'Aceptado';
      case PermissionStatus.rejected:
        return 'Rechazado';
    }
  }

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.pending:
        return Colors.orange;
      case PermissionStatus.accepted:
        return Colors.green;
      case PermissionStatus.rejected:
        return Colors.red;
    }
  }
}
