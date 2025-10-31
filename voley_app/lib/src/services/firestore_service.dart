// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/user.dart' as app_user;

import 'package:voley_app/src/models/coach_player_permission.dart';

import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final _uuid = const Uuid();

  // ========== User Methods ==========

  Future<app_user.User?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();

    if (!doc.exists) return null;

    return app_user.User.fromJson(doc.data()!);
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
  }) async {
    final permission = CoachPlayerPermission(
      id: _uuid.v4(),

      coachId: coachId,

      playerId: playerId,

      status: PermissionStatus.pending,

      createdAt: DateTime.now(),
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

  // ========== Existing Player Profile Methods ==========

  Future<void> savePlayerProfile(PlayerProfile profile) {
    return _db.collection('players').doc(profile.id).set(profile.toJson());
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
}
