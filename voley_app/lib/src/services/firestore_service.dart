// lib/services/firestore_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/session_log.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/models/coach_player_permission.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Expose the Firestore instance when needed by UI code
  FirebaseFirestore get firestore => _db;

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
    final linkCode = await _generateUniqueLinkCode();

    // Create user document
    final user = app_user.User(
      id: userId,
      email: email,
      name: name,
      role: app_user.UserRole.player,
      createdAt: DateTime.now(),
      coachId: coachId,
      linkCode: linkCode,
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

  Future<void> updatePlayerProfileCoachId(String playerId, String coachId) async {
    final query = await _db
        .collection('players')
        .where('userId', isEqualTo: playerId)
        .get();

    for (final doc in query.docs) {
      await doc.reference.update({'assignedCoachId': coachId});
    }
  }

  Future<String> ensureUserLinkCode(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('Usuario no encontrado');
    }

    final data = userDoc.data();
    final currentCode = (data?['linkCode'] as String?)?.toUpperCase();
    if (currentCode != null && currentCode.isNotEmpty) {
      return currentCode;
    }

    final newCode = await _generateUniqueLinkCode();
    await userDoc.reference.update({'linkCode': newCode});
    return newCode;
  }

  Future<app_user.User?> getUserByLinkCode(String code) async {
    final normalized = code.toUpperCase();
    final snapshot = await _db
        .collection('users')
        .where('linkCode', isEqualTo: normalized)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return app_user.User.fromJson(snapshot.docs.first.data());
  }

  Future<void> linkCoachAndPlayer({
    required String coachId,
    required String playerId,
  }) async {
    final permissionRef =
        _db.collection('coach_player_permissions').doc('${coachId}_$playerId');

    final now = Timestamp.fromDate(DateTime.now());
    final permissionSnapshot = await permissionRef.get();
    final data = <String, dynamic>{
      'id': '${coachId}_$playerId',
      'coachId': coachId,
      'playerId': playerId,
      'status': PermissionStatus.accepted.toJson(),
      'updatedAt': now,
    };

    if (!permissionSnapshot.exists ||
        permissionSnapshot.data()?['createdAt'] == null) {
      data['createdAt'] = now;
    }

    await permissionRef.set(data, SetOptions(merge: true));
    await updateUserCoachId(playerId, coachId);
    await updatePlayerProfileCoachId(playerId, coachId);
  }

  Future<String> _generateUniqueLinkCode() async {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    String _generateCode() {
      return List.generate(
        6,
        (_) => characters[random.nextInt(characters.length)],
      ).join();
    }

    String code;

    while (true) {
      code = _generateCode();
      final snapshot = await _db
          .collection('users')
          .where('linkCode', isEqualTo: code)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return code;
      }
    }
  }

  // ========== Existing Player Profile Methods ==========

  Future<void> savePlayerProfile(PlayerProfile profile) {
    return _db.collection('players').doc(profile.id).set(profile.toJson());
  }

  Future<List<SessionLog>> getSessionLogHistory(String profileId) async {
    final snap = await _db
        .collection('players')
        .doc(profileId)
        .collection('session_logs') // O 'session_logs', como lo hayas llamado
        .orderBy('completedAt', descending: true)
        .limit(50) // Limita a las últimas 50 sesiones para performance
        .get();

    return snap.docs.map((doc) => SessionLog.fromJson(doc.data())).toList();
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
        .asyncMap((permissionsSnap) async {
          // <-- 2. Mapea el stream

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
  
  Future<void> saveSessionLog(SessionLog log) {
    return _db
        .collection('players')
        .doc(log.profileId)
        .collection('session_logs') // O 'session_logs', como prefieras llamarla
        .doc(log.id)
        .set(log.toJson());
  }

  Stream<List<SessionLog>> getSessionHistoryStream(String profileId) {
    return _db
        .collection('players')
        .doc(profileId)
        .collection('session_logs') // La colección donde se guardan los SessionLog
        .orderBy('completedAt', descending: true) 
        .snapshots() // <-- USA .snapshots() EN LUGAR DE .get()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return []; 
      }
      return snapshot.docs
          .map((doc) => SessionLog.fromJson(doc.data()))
          .toList();
    });
  }
final playerProgramProvider = StreamProvider<Program?>((ref) {
  // 1. "Observa" (watch) el resultado del FutureProvider de perfil
  final profileAsync = ref.watch(playerProfileProvider);

  // 2. Mapea el resultado
  return profileAsync.when(
    data: (profile) {
      if (profile == null) {
        return Stream.value(null); // Sin perfil -> Sin programa
      }
      // 3. Si hay perfil, escucha el stream del programa
      return ref.read(firestoreProvider).getLatestProgramStream(profile.id);
    },
    loading: () => Stream.value(null), // Cargando perfil -> Cargando programa
    error: (e, s) => Stream.error(e, s), // Error de perfil -> Error de programa
  );
});
}


