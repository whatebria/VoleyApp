// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/models/coach_player_permission.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== User Methods ==========

  Future<app_user.User?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();

    if (!doc.exists) return null;

    return app_user.User.fromJson(doc.data()!);
  }

  /// Create a new player user and automatically link with coach
  Future<app_user.User> createPlayerWithCoachLink({
    required String userId,
    required String email,
    required String name,
    required String coachId,
  }) async {
    // Create user document
    final user = app_user.User(
      id: userId,
      email: email,
      name: name,
      role: app_user.UserRole.player,
      createdAt: DateTime.now(),
      coachId: coachId,
    );

    await _db.collection('users').doc(user.id).set(user.toJson());

    // Create permission link with coach (already accepted)
    await createPermission(
      coachId: coachId,
      playerId: userId,
      initialStatus: PermissionStatus.accepted,
    );

    return user;
  }

  Future<List<app_user.User>> getAllCoaches() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .get();

    return snap.docs.map((d) => app_user.User.fromJson(d.data())).toList();
  }

  Future<List<app_user.User>> getAllPlayers() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'player')
        .get();

    return snap.docs.map((d) => app_user.User.fromJson(d.data())).toList();
  }

  // ========== Coach-Player Permission Methods ==========

  /// Create a permission request from coach to player

  Future<CoachPlayerPermission> createPermission({
    required String coachId,

    required String playerId,

    PermissionStatus initialStatus = PermissionStatus.pending,
  }) async {
    final permission = CoachPlayerPermission(
      id: '${coachId}_$playerId',

      coachId: coachId,

      playerId: playerId,

      status: initialStatus,

      createdAt: DateTime.now(),

      updatedAt: initialStatus != PermissionStatus.pending
          ? DateTime.now()
          : null,
    );

    await _db
        .collection('coach_player_permissions')
        .doc(permission.id)
        .set(permission.toJson());

    return permission;
  }

  /// Update permission status (accept/reject)

  Future<void> updatePermissionStatus({
    required String permissionId,

    required PermissionStatus status,
  }) async {
    await _db.collection('coach_player_permissions').doc(permissionId).update({
      'status': status.toJson(),

      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get all players that a coach has permission to access

  Future<List<app_user.User>> getPlayersByCoach(String coachId) async {
    // Get accepted permissions for this coach

    final permissionsSnap = await _db
        .collection('coach_player_permissions')
        .where('coachId', isEqualTo: coachId)
        .where('status', isEqualTo: 'accepted')
        .get();

    if (permissionsSnap.docs.isEmpty) return [];

    // Get player IDs

    final playerIds = permissionsSnap.docs
        .map((doc) => doc.data()['playerId'] as String)
        .toList();

    // Fetch player users

    final players = <app_user.User>[];

    for (final playerId in playerIds) {
      final player = await getUser(playerId);

      if (player != null) players.add(player);
    }

    return players;
  }

  /// Get all coaches that have permission to access a player

  Future<List<app_user.User>> getCoachesByPlayer(String playerId) async {
    // Get accepted permissions for this player

    final permissionsSnap = await _db
        .collection('coach_player_permissions')
        .where('playerId', isEqualTo: playerId)
        .where('status', isEqualTo: 'accepted')
        .get();

    if (permissionsSnap.docs.isEmpty) return [];

    // Get coach IDs

    final coachIds = permissionsSnap.docs
        .map((doc) => doc.data()['coachId'] as String)
        .toList();

    // Fetch coach users

    final coaches = <app_user.User>[];

    for (final coachId in coachIds) {
      final coach = await getUser(coachId);

      if (coach != null) coaches.add(coach);
    }

    return coaches;
  }

  /// Get pending permission requests for a player

  Future<List<CoachPlayerPermission>> getPendingPermissionsForPlayer(
    String playerId,
  ) async {
    final snap = await _db
        .collection('coach_player_permissions')
        .where('playerId', isEqualTo: playerId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snap.docs
        .map((d) => CoachPlayerPermission.fromJson(d.data()))
        .toList();
  }

  /// Get all permissions for a coach

  Future<List<CoachPlayerPermission>> getPermissionsByCoach(
    String coachId,
  ) async {
    final snap = await _db
        .collection('coach_player_permissions')
        .where('coachId', isEqualTo: coachId)
        .get();

    return snap.docs
        .map((d) => CoachPlayerPermission.fromJson(d.data()))
        .toList();
  }

  /// Check if a coach has permission to access a player

  Future<bool> hasPermission({
    required String coachId,

    required String playerId,
  }) async {
    final snap = await _db
        .collection('coach_player_permissions')
        .where('coachId', isEqualTo: coachId)
        .where('playerId', isEqualTo: playerId)
        .where('status', isEqualTo: 'accepted')
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  /// Delete a permission

  Future<void> deletePermission(String permissionId) async {
    await _db.collection('coach_player_permissions').doc(permissionId).delete();
  }

  /// Update user's coachId field
  Future<void> updateUserCoachId(String userId, String? coachId) async {
    await _db.collection('users').doc(userId).update({'coachId': coachId});
  }

  // ========== Existing Player Profile Methods ==========

  Future<void> savePlayerProfile(PlayerProfile profile) {
    return _db.collection('players').doc(profile.id).set(profile.toJson());
  }

Stream<Program?> getLatestProgramStream(String profileId) {
    return _db
        .collection('players') 
        .doc(profileId)
        .collection('programs')
        .orderBy('startDate', descending: true) 
        .limit(1) 
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null; 
      }
      return Program.fromFirestore(snapshot.docs.first); 
    });
  }

  Future<PlayerProfile?> getPlayerProfile(String id) async {
    final doc = await _db.collection('players').doc(id).get();
    if (!doc.exists) return null;
    return PlayerProfile.fromJson(doc.data()!);
  }

  Future<void> saveProgram(String playerId, Program program) {
    // Guardar dentro de colección players/{id}/programs/{programId}
    return _db
        .collection('players')
        .doc(playerId)
        .collection('programs')
        .doc(program.id)
        .set(program.toJson());
  }

  Future<List<Program>> getProgramsByPlayer(String playerId) async {
    final snap = await _db
        .collection('players')
        .doc(playerId)
        .collection('programs')
        .orderBy('startDate', descending: true)
        .get();

    return snap.docs.map((d) => Program.fromJson(d.data())).toList();
  }

  Stream<List<Program>> getAllProgramsStream(String profileId) {
    // Usamos 'players' porque tus otros métodos (saveProgram, getPlayerProfile)
    // también usan la colección 'players'.
    return _db
        .collection('players')
        .doc(profileId)
        .collection('programs')
        .orderBy('startDate', descending: true)
        .snapshots() // .snapshots() devuelve un Stream
        .map((snapshot) {
          // Convierte el QuerySnapshot en un List<Program>
          if (snapshot.docs.isEmpty) {
            return []; // Devuelve una lista vacía si no hay programas
          }
          return snapshot.docs
              .map(
                (doc) => Program.fromFirestore(doc),
              ) // Usa el constructor que creamos
              .toList();
        });
  }

  Future<PlayerProfile?> getPlayerProfileByUserId(String userId) async {
    final snap = await _db
        .collection('players')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return PlayerProfile.fromJson(snap.docs.first.data());
  }

  Future<List<Exercise>> getAllExercises() async {
    final snap = await _db.collection('exercises').get();
    return snap.docs.map((d) => Exercise.fromJson(d.data())).toList();
  }

  Future<void> saveSessionFeedback(
    String playerId,
    String sessionId,
    Map<String, dynamic> feedback,
  ) {
    return _db
        .collection('players')
        .doc(playerId)
        .collection('feedback')
        .doc(sessionId)
        .set(feedback);
  }
  Stream<List<app_user.User>> getPlayersByCoachStream(String coachId) {
    return _db
        .collection('coach_player_permissions')
        .where('coachId', isEqualTo: coachId)
        .where('status', isEqualTo: 'accepted')
        .snapshots() // <-- 1. Usa .snapshots() para escuchar en tiempo real
        .asyncMap((permissionsSnap) async { // <-- 2. Mapea el stream
      
      if (permissionsSnap.docs.isEmpty) return [];

      // 3. Obtiene los IDs de los jugadores
      final playerIds = permissionsSnap.docs
          .map((doc) => doc.data()['playerId'] as String)
          .toList();

      if (playerIds.isEmpty) return [];

      // 4. Busca todos los documentos de 'users' en paralelo (muy eficiente)
      final playerFutures = playerIds.map((id) => getUser(id)).toList();
      final players = await Future.wait(playerFutures);

      // 5. Filtra los que no sean nulos y devuelve la lista
      return players.whereType<app_user.User>().toList();
    });
    
  }
  /// Observa el perfil del jugador y, si existe,
/// obtiene un [Stream] de su programa más reciente.
final playerProgramProvider = StreamProvider<Program?>((ref) {
  
  // 1. Depende del FutureProvider del perfil
  final profileAsync = ref.watch(ownProfileProvider);
  
  // 2. Mapea el estado del perfil al stream del programa
  return profileAsync.when(
    data: (profile) {
      if (profile == null) {
        // Si no hay perfil, no hay programa.
        return Stream.value(null);
      }
      // Si hay perfil, escucha el stream del programa
      return ref.read(firestoreProvider).getLatestProgramStream(profile.id);
    },
    // Mientras el perfil carga o da error, no hay programa.
    loading: () => Stream.value(null),
    error: (e, s) => Stream.error(e, s),
  );
});
  
}
