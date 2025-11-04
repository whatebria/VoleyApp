// lib/src/screens/permissions/permission_management_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/src/models/coach_player_permission.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/services/firestore_service.dart';

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

  String? _linkCode;

  bool _isLinking = false;

  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final currentFirebaseUser = ref.read(currentUserProvider);
      if (currentFirebaseUser == null) return;

      // Obtener datos del usuario actual
      _currentUser = await _firestoreService.getUser(currentFirebaseUser.uid);
      if (_currentUser == null) return;

      _linkCode = await _firestoreService.ensureUserLinkCode(_currentUser!.id);

      if (_currentUser!.isCoach) {
        // Si es entrenador, obtener sus permisos y jugadores

        _permissions = await _firestoreService.getPermissionsByCoach(
          _currentUser!.id,
        );

        _relatedUsers = await _firestoreService.getPlayersByCoach(
          _currentUser!.id,
        );
      } else {
        // Si es jugador, obtener permisos pendientes y entrenadores

        _permissions = await _firestoreService.getPendingPermissionsForPlayer(
          _currentUser!.id,
        );

        _relatedUsers = await _firestoreService.getCoachesByPlayer(
          _currentUser!.id,
        );
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

  Future<void> _linkWithCode() async {
    if (_currentUser == null) return;

    final input = _codeController.text.trim().toUpperCase();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un código para vincular.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_linkCode != null && input == _linkCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes usar tu propio código.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLinking = true);

    try {
      final targetUser = await _firestoreService.getUserByLinkCode(input);
      if (targetUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Código no encontrado. Verifica e inténtalo de nuevo.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (targetUser.id == _currentUser!.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No puedes vincularte contigo mismo.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_currentUser!.isCoach && !targetUser.isPlayer) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este código no pertenece a un jugador.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_currentUser!.isPlayer && !targetUser.isCoach) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este código no pertenece a un entrenador.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_currentUser!.isCoach) {
        final alreadyLinked = await _firestoreService.hasPermission(
          coachId: _currentUser!.id,
          playerId: targetUser.id,
        );
        if (alreadyLinked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya tienes acceso a este jugador.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        await _firestoreService.linkCoachAndPlayer(
          coachId: _currentUser!.id,
          playerId: targetUser.id,
        );
      } else {
        if (_currentUser!.coachId == targetUser.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya estás vinculado con este entrenador.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        await _firestoreService.linkCoachAndPlayer(
          coachId: targetUser.id,
          playerId: _currentUser!.id,
        );
      }

      _codeController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentUser!.isCoach
                  ? '¡Jugador vinculado correctamente!'
                  : '¡Entrenador vinculado correctamente!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al vincular: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLinking = false);
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).maybePop(false),

            child: const Text('Cancelar'),
          ),

          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),

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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

        body: const Center(child: Text('Error: No se pudo cargar el usuario')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentUser!.isCoach ? 'Mis Jugadores' : 'Mis Entrenadores',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadData,

        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [
            if (_linkCode != null) _buildLinkCodeSection(),

            if (_linkCode != null) const SizedBox(height: 24),

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
                Navigator.pushNamed(context, '/user_management');

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

  Widget _buildLinkCodeSection() {
    final isCoach = _currentUser!.isCoach;
    final theme = Theme.of(context);
    final headline = isCoach
        ? 'Comparte este código con tus jugadores'
        : 'Comparte este código con tu entrenador';
    final helper = isCoach
        ? 'Ingresa el código de un jugador para agregarlo de inmediato.'
        : 'Ingresa el código de tu entrenador para vincularte al equipo.';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _linkCode ?? '------',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: _linkCode == null
                      ? null
                      : () {
                          final code = _linkCode;
                          if (code == null) return;
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código copiado al portapapeles'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copiar código',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(helper, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              onChanged: (value) {
                final upper = value.toUpperCase();
                if (value != upper) {
                  _codeController.value = TextEditingValue(
                    text: upper,
                    selection: TextSelection.collapsed(offset: upper.length),
                  );
                  setState(() {});
                } else {
                  setState(() {});
                }
              },
              decoration: InputDecoration(
                labelText: isCoach
                    ? 'Código del jugador'
                    : 'Código del entrenador',
                prefixIcon: const Icon(Icons.key_outlined),
                counterText: '',
                suffixIcon: _codeController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _codeController.clear,
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLinking ? null : _linkWithCode,
                icon: _isLinking
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.link),
                label: Text(_isLinking ? 'Vinculando...' : 'Vincular'),
              ),
            ),
          ],
        ),
      ),
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

          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        if (_relatedUsers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Text(
                _currentUser!.isCoach
                    ? 'No tienes jugadores autorizados aún. Solicita acceso a un jugador para comenzar.'
                    : 'No tienes entrenadores autorizados aún. Acepta una solicitud para comenzar.',

                textAlign: TextAlign.center,

                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ..._relatedUsers.map(
            (user) => Card(
              margin: const EdgeInsets.only(bottom: 8),

              child: ListTile(
                leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),

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
            ),
          ),
      ],
    );
  }

  Widget _buildPendingPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'Solicitudes Pendientes (${_permissions.length})',

          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        ..._permissions.map(
          (permission) => FutureBuilder<app_user.User?>(
            future: _firestoreService.getUser(
              _currentUser!.isCoach ? permission.playerId : permission.coachId,
            ),

            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Card(child: ListTile(title: Text('Cargando...')));
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
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),

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
          ),
        ),
      ],
    );
  }

  Future<CoachPlayerPermission?> _findPermission(String userId) async {
    try {
      final allPermissions = _currentUser!.isCoach
          ? await _firestoreService.getPermissionsByCoach(_currentUser!.id)
          : await _firestoreService.getPendingPermissionsForPlayer(
              _currentUser!.id,
            );

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
