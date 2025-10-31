// lib/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/core/generator.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/services/firestore_service.dart';

final firestoreProvider = Provider((ref) => FirestoreService());

final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final svc = ref.read(firestoreProvider);
  return svc.getAllExercises();
});

final playerProfileProvider = StateProvider<PlayerProfile?>((ref) => null);

final generatedProgramProvider = StateProvider<Program?>((ref) => null);

// Acción para generar programa
// En tu provider programGeneratorAction
final programGeneratorAction = Provider((ref) {
  final svc = ref.read(firestoreProvider);
  return (PlayerProfile profile, List<Exercise> exercises) async {
    final program = generateProgram(profile, exercises);
    

    await svc.saveProgram(profile.id, program);
    
    ref.read(generatedProgramProvider.notifier).state = program;
    return program;
  };
});
