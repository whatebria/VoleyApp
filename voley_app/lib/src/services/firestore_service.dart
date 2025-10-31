// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/program/program.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    return _db.collection('players').doc(playerId)
      .collection('programs').doc(program.id).set(program.toJson());
  }

  Future<List<Exercise>> getAllExercises() async {
    final snap = await _db.collection('exercises').get();
    return snap.docs.map((d) => Exercise.fromJson(d.data())).toList();
  }

  Future<void> saveSessionFeedback(String playerId, String sessionId, Map<String, dynamic> feedback) {
    return _db.collection('players').doc(playerId)
      .collection('feedback').doc(sessionId).set(feedback);
  }
}
