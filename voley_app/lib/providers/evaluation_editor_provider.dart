import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/test_score.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';
import 'package:voley_app/src/models/user.dart';

/// Provider para el estado de "guardando"
final evaluationIsSavingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Provider que maneja el estado del formulario de evaluación
final evaluationEditorProvider =
    StateNotifierProvider.autoDispose<
      EvaluationEditorNotifier,
      List<TestScore>
    >((ref) {
      // Lee el perfil actual para inicializar el estado
      final profile = ref.watch(selectedPlayerProfileProvider);
      // Carga la última evaluación (o una lista vacía)
      final initialScores = profile?.latestEvaluation?.testScores ?? [];
      return EvaluationEditorNotifier(ref, initialScores);
    });

class EvaluationEditorNotifier extends StateNotifier<List<TestScore>> {
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  EvaluationEditorNotifier(this._ref, List<TestScore> initialScores)
    : super(initialScores);

  void addTest(TestScore test) {
    state = [...state, test];
  }

  void removeTest(TestScore test) {
    state = state.where((t) => t.testId != test.testId).toList();
  }

  /// Lógica de negocio principal para guardar la evaluación
  Future<void> saveEvaluation(
    User player,
    PlayerProfile? currentProfile,
  ) async {
    // 1. Poner estado de carga
    _ref.read(evaluationIsSavingProvider.notifier).state = true;

    try {
      final newEvaluation = EvaluationResult(
        date: DateTime.now(),
        testScores: state, // Usa la lista de TestScore del estado actual
      );

      final PlayerProfile profileToSave;

      if (currentProfile == null) {
        // --- MODO CREACIÓN (El perfil no existe) ---
        profileToSave = PlayerProfile(
          id: player.id,
          userId: player.id,
          assignedCoachId: player.coachId,
          name: player.name,
          position: PlayerPosition.oh, // o el que quieras por defecto
          // si quieres un "Sin definir" real, agrega PlayerPosition.unknown al enum
          level: PlayerLevel.recreativo,
          availability: const Availability(
            trainingDays: <DayOfWeek>[], // <- lista tipada
            sessionMinutes: 0,
          ),
          evaluationHistory: [newEvaluation],
          goals: const [],
          injuries: const [],
          tournaments: const [],
          equipmentIds: const [],
          keyEvents: const [],
          formPeaks: const [],
        );
      } else {
        // --- MODO EDICIÓN (El perfil SÍ existe) ---
        // Añade la nueva evaluación a la lista existente
        final updatedHistory = [
          ...currentProfile.evaluationHistory,
          newEvaluation,
        ];

        profileToSave = currentProfile.copyWith(
          evaluationHistory: updatedHistory,
        );
      }

      // 3. Guardar en Firestore
      await _ref.read(firestoreProvider).savePlayerProfile(profileToSave);

      // 4. Invalidar providers para refrescar la app
      _ref.invalidate(selectedPlayerProfileProvider);
      _ref.invalidate(coachPlayersWithProfilesProvider);
      _ref.invalidate(playerProfileProvider);
    } finally {
      _ref.read(evaluationIsSavingProvider.notifier).state = false;
    }
  }
}
