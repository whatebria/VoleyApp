import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/auth/auth_provider.dart'; // Para currentUserProvider
import 'package:voley_app/src/models/coach_player_permission.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/services/firestore_service.dart';
import 'package:voley_app/providers/providers.dart'; // Para firestoreProvider

// 1. Modelo de datos para la vista (View Model)
// Esto agrupa una invitación con los datos del usuario que la envió.
class PendingPermissionView {
  final CoachPlayerPermission permission;
  final app_user.User user; // El jugador que envió la solicitud

  PendingPermissionView({required this.permission, required this.user});
}

// 2. Modelo de estado para la pantalla
// Contiene todos los datos que la UI necesita mostrar.
class PermissionScreenState {
  final app_user.User currentUser;
  final String linkCode;
  final List<PendingPermissionView> pendingRequests;

  PermissionScreenState({
    required this.currentUser,
    required this.linkCode,
    required this.pendingRequests,
  });
}

// 3. El StateNotifierProvider
final permissionControllerProvider = AutoDisposeAsyncNotifierProvider<
    PermissionController, PermissionScreenState>(
  PermissionController.new,
);

// Provider para el estado de carga del botón "Vincular"
final isLinkingProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Notifier que maneja toda la lógica de la pantalla de permisos.
class PermissionController extends AutoDisposeAsyncNotifier<PermissionScreenState> {
  
  // Helper para acceder a Firestore
  FirestoreService get _firestore => ref.read(firestoreProvider);
  
  @override
  FutureOr<PermissionScreenState> build() async {
    // 1. Obtener el usuario actual
    final currentFirebaseUser = ref.watch(currentUserProvider);
    if (currentFirebaseUser == null) {
      throw Exception('Usuario no autenticado.');
    }

    final currentUser = await _firestore.getUser(currentFirebaseUser.uid);
    if (currentUser == null) {
      throw Exception('Usuario no encontrado en Firestore.');
    }
    
    // Si es un jugador, no cargamos nada más (la UI lo manejará)
    if (!currentUser.isCoach) {
      return PermissionScreenState(
        currentUser: currentUser,
        linkCode: '',
        pendingRequests: [],
      );
    }

    // 2. Obtener el código de enlace
    final linkCode = await _firestore.ensureUserLinkCode(currentUser.id);

    // 3. Obtener permisos pendientes
    // --- CORRECCIÓN: El método no tiene 'status', se filtra localmente ---
    final allPermissions = await _firestore.getPermissionsByCoach(
      currentUser.id,
    );
    final pendingPermissions = allPermissions
        .where((p) => p.status == PermissionStatus.pending)
        .toList();
    
    // 4. Resolver los datos de los usuarios pendientes (soluciona el FutureBuilder)
    final List<PendingPermissionView> pendingRequests = [];
    if (pendingPermissions.isNotEmpty) {
      // Obtenemos los IDs de los jugadores que enviaron la solicitud
      final playerIds = pendingPermissions.map((p) => p.playerId).toList();
      
      // --- CORRECCIÓN: Usar Future.wait con _firestore.getUser ---
      // 1. Creamos una lista de Futures
      final userFutures = playerIds.map((id) => _firestore.getUser(id)).toList();
      
      // 2. Esperamos a que todos se completen
      final usersResults = await Future.wait(userFutures);

      // 3. Filtramos los usuarios (quitando nulos) y los convertimos a un Map
      final usersMap = {
        for (var user in usersResults.where((u) => u != null)) 
          user!.id: user
      };
      
      // 4. Mapeamos los permisos con sus respectivos usuarios
      for (var perm in pendingPermissions) {
        // Busca el usuario en el Map (mucho más rápido)
        // --- CORRECCIÓN: Añadido 'createdAt' al usuario de fallback ---
        final user = usersMap[perm.playerId] ?? 
            app_user.User(
              id: '?', 
              name: 'Usuario Desconocido', 
              email: '?', 
              role: app_user.UserRole.player,
              createdAt: DateTime.now(), // <-- FIX
            );
        
        pendingRequests.add(PendingPermissionView(permission: perm, user: user));
      }
    }

    // 5. Devolver el estado completo
    return PermissionScreenState(
      currentUser: currentUser,
      linkCode: linkCode,
      pendingRequests: pendingRequests,
    );
  }

  /// Lógica de acción: Vincular con un código
  Future<String> linkWithCode(String inputCode) async {
    ref.read(isLinkingProvider.notifier).state = true;
    final currentState = state.value;
    if (currentState == null) throw Exception("El estado no está cargado");

    final currentUser = currentState.currentUser;
    final myLinkCode = currentState.linkCode;

    try {
      if (inputCode.isEmpty) {
        return "Ingresa un código para vincular.";
      }
      if (myLinkCode.isNotEmpty && inputCode == myLinkCode) {
        return "No puedes usar tu propio código.";
      }

      final targetUser = await _firestore.getUserByLinkCode(inputCode);
      if (targetUser == null) {
        return "Código no encontrado. Verifica e inténtalo de nuevo.";
      }
      if (targetUser.id == currentUser.id) {
        return "No puedes vincularte contigo mismo.";
      }
      if (currentUser.isCoach && !targetUser.isPlayer) {
        return "Este código no pertenece a un jugador.";
      }
      if (currentUser.isPlayer && !targetUser.isCoach) {
        return "Este código no pertenece a un entrenador.";
      }

      // Lógica de vinculación
      if (currentUser.isCoach) {
        final alreadyLinked = await _firestore.hasPermission(
          coachId: currentUser.id,
          playerId: targetUser.id,
        );
        if (alreadyLinked) {
          return "Ya tienes acceso a este jugador.";
        }
        await _firestore.linkCoachAndPlayer(
          coachId: currentUser.id,
          playerId: targetUser.id,
        );
        ref.invalidate(coachPlayersProvider); // Invalida la lista de jugadores
        return "¡Jugador vinculado correctamente!";
      } else {
        // ... (lógica de jugador si es necesaria) ...
        return "Error: Los jugadores no deberían poder usar esta acción.";
      }

    } catch (e) {
      return "Error al vincular: $e";
    } finally {
      ref.read(isLinkingProvider.notifier).state = false;
      // Refresca todos los datos en la pantalla
      ref.invalidateSelf(); 
    }
  }

  /// Lógica de acción: Aceptar o Rechazar un permiso
  Future<String> handlePermissionAction(
    CoachPlayerPermission permission,
    PermissionStatus newStatus,
  ) async {
    try {
      await _firestore.updatePermissionStatus(
        permissionId: permission.id,
        status: newStatus,
      );
      
      // Si se acepta, refrescamos la lista de jugadores del coach
      if (newStatus == PermissionStatus.accepted) {
        ref.invalidate(coachPlayersProvider);
      }
      
      // Refresca esta pantalla
      ref.invalidateSelf(); 
      
      return newStatus == PermissionStatus.accepted
          ? '¡Permiso aceptado!'
          : 'Permiso rechazado';
    } catch (e) {
      return "Error: $e";
    }
  }

  /// Lógica de acción: Eliminar un permiso (usado por el coach en pendientes)
  Future<String> deletePermission(String permissionId) async {
    try {
      await _firestore.deletePermission(permissionId);
      ref.invalidateSelf(); // Refresca esta pantalla
      return "Permiso revocado";
    } catch (e) {
      return "Error: $e";
    }
  }
}