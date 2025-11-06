import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:voley_app/providers/providers.dart'; // coachPlayersWithProfilesProvider, explorerSelectedPlayerProvider, playerProfileProvider, firestoreProvider, functionsProvider, currentUserAppUserProvider
import 'package:voley_app/src/models/shared/day_of_week.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:voley_app/src/models/player_profile/test_score.dart';
import 'package:voley_app/src/models/player_profile/injury.dart';

/// -----------------------------
/// 1) ESTADO
/// -----------------------------
@immutable
class EvaluationState {
  // Carga/UI
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;

  // Modo y selección
  final bool isCreatingNewUser;       // Crear (true) vs Editar (false)
  final app_user.User? selectedUser;  // Usuario que se está editando

  // Datos cargados
  final AsyncValue<app_user.User?> currentUser;
  final AsyncValue<List<PlayerWithProfile>> availablePlayersWithProfiles;
  final AsyncValue<PlayerProfile?> loadedProfile;

  const EvaluationState({
    this.isSubmitting = false,
    this.successMessage,
    this.errorMessage,
    this.isCreatingNewUser = true,
    this.selectedUser,
    this.currentUser = const AsyncLoading(),
    this.availablePlayersWithProfiles = const AsyncLoading(),
    this.loadedProfile = const AsyncLoading(),
  });

  EvaluationState copyWith({
    bool? isSubmitting,
    String? successMessage,
    String? errorMessage,
    bool? isCreatingNewUser,
    app_user.User? selectedUser,
    bool clearSelectedUser = false,
    AsyncValue<app_user.User?>? currentUser,
    AsyncValue<List<PlayerWithProfile>>? availablePlayersWithProfiles,
    AsyncValue<PlayerProfile?>? loadedProfile,
    bool clearLoadedProfile = false,
  }) {
    return EvaluationState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: successMessage,
      errorMessage: errorMessage,
      isCreatingNewUser: isCreatingNewUser ?? this.isCreatingNewUser,
      selectedUser: clearSelectedUser ? null : (selectedUser ?? this.selectedUser),
      currentUser: currentUser ?? this.currentUser,
      availablePlayersWithProfiles:
          availablePlayersWithProfiles ?? this.availablePlayersWithProfiles,
      loadedProfile:
          clearLoadedProfile ? const AsyncData(null) : (loadedProfile ?? this.loadedProfile),
    );
  }
}

/// -----------------------------
/// 2) CONTROLADOR
/// -----------------------------
class EvaluationController extends AutoDisposeNotifier<EvaluationState> {
  late final _firestore = ref.read(firestoreProvider);
  late final _functions = ref.read(functionsProvider);
  final _uuid = const Uuid();

  @override
  EvaluationState build() {
    // Se inicializa luego con init()
    return const EvaluationState();
  }

  Future<void> init() async {
    state = state.copyWith(currentUser: const AsyncLoading());
    try {
      final user = await ref.read(currentUserAppUserProvider.future);
      if (user == null) throw Exception("Usuario no encontrado.");

      state = state.copyWith(currentUser: AsyncData(user));

      if (user.isCoach) {
        await _loadCoachPlayersWithProfiles();
      } else {
        // Es jugador: modo edición y cargar su perfil
        state = state.copyWith(isCreatingNewUser: false, selectedUser: user);
        await _loadProfileForUser(user.id);
      }
    } catch (e, s) {
      state = state.copyWith(currentUser: AsyncError(e, s));
    }
  }

  Future<void> _loadCoachPlayersWithProfiles() async {
    state = state.copyWith(availablePlayersWithProfiles: const AsyncLoading());
    try {
      final playersWithProfiles =
          await ref.read(coachPlayersWithProfilesProvider.future);
      state = state.copyWith(
        availablePlayersWithProfiles: AsyncData(playersWithProfiles),
      );
    } catch (e, s) {
      state = state.copyWith(availablePlayersWithProfiles: AsyncError(e, s));
    }
  }

  Future<void> _loadProfileForUser(String userId) async {
    state = state.copyWith(loadedProfile: const AsyncLoading());
    try {
      final profile = await _firestore.getPlayerProfileByUserId(userId);
      state = state.copyWith(loadedProfile: AsyncData(profile));
    } catch (e, s) {
      state = state.copyWith(loadedProfile: AsyncError(e, s));
    }
  }

  void setMode(bool isCreating) {
    state = state.copyWith(
      isCreatingNewUser: isCreating,
      clearSelectedUser: true,
      clearLoadedProfile: true,
    );
  }

  void selectPlayer(PlayerWithProfile? playerWithProfile) {
    if (playerWithProfile == null) {
      state = state.copyWith(
        clearSelectedUser: true,
        clearLoadedProfile: true,
      );
    } else {
      state = state.copyWith(
        selectedUser: playerWithProfile.player,
        loadedProfile: AsyncData(playerWithProfile.profile),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  /// -----------------------------
  /// 3) GUARDADO CENTRALIZADO (Modelos nuevos)
  /// -----------------------------
 
Future<void> handleSubmit({
  required String name,
  required String email,
  required String password,
  required String position, // viene como id (ej: "oh","mb","s","l","op")
  required String level,    // viene como id (ej: "recreativo","competitivo","semiprofesional")
  required List<Injury> injuries,
  required List<String> availabilityDays, // ["mon","wed","fri"] etc.
  required int availabilityMinutes,
  required List<Tournament> tournaments,
  required List<TestScore> testScores,
}) async {
  state = state.copyWith(isSubmitting: true);
  final currentUser = state.currentUser.value;
  if (currentUser == null) {
    state = state.copyWith(isSubmitting: false, errorMessage: "No se pudo identificar al usuario actual.");
    return;
  }

  // ✅ Convertir a enums seguros (con fallback si quisieras)
  final playerPosition = PlayerPosition.values.byName(position);
  final playerLevel    = PlayerLevel.values.byName(level);
  final daysEnum = availabilityDays.map((d) => DayOfWeek.values.byName(d)).toList();

  try {
    final availability = Availability(
      trainingDays: daysEnum,
      sessionMinutes: availabilityMinutes,
    );

    final newEvaluation = EvaluationResult(
      date: DateTime.now(),
      testScores: testScores,
    );

    PlayerProfile profileToSave;

    if (state.isCreatingNewUser) {
      profileToSave = PlayerProfile(
        id: _uuid.v4(),
        userId: currentUser.id,
        name: name,
        position: playerPosition,   // ✅ enum
        level: playerLevel,         // ✅ enum
        goals: const [],
        injuries: injuries,
        availability: availability, // ✅ Days como enums
        evaluationHistory: [newEvaluation],
        tournaments: tournaments,
      );
    } else {
      final loadedProfile = state.loadedProfile.value;
      final selectedUser = state.selectedUser;
      if (selectedUser == null) {
        throw Exception("No hay un usuario seleccionado.");
      }

      if (loadedProfile != null) {
        final updatedHistory = [...loadedProfile.evaluationHistory, newEvaluation];

        profileToSave = loadedProfile.copyWith(
          position: playerPosition,     // ✅ enum
          level: playerLevel,           // ✅ enum
          injuries: injuries,
          availability: availability,   // ✅ enum list
          tournaments: tournaments,
          evaluationHistory: updatedHistory,
        );
      } else {
        // No tenía perfil aún
        profileToSave = PlayerProfile(
          id: _uuid.v4(),
          userId: selectedUser.id,
          name: selectedUser.name,
          position: playerPosition,
          level: playerLevel,
          goals: const [],
          injuries: injuries,
          availability: availability,
          evaluationHistory: [newEvaluation],
          tournaments: tournaments,
        );
      }
    }

    await _firestore.savePlayerProfile(profileToSave);
    state = state.copyWith(
      isSubmitting: false,
      successMessage: "Evaluación guardada correctamente.",
    );
    // invalidaciones que ya tienes...
  } catch (e, s) {
    state = state.copyWith(isSubmitting: false, errorMessage: "Error al guardar: $e");
  }
}

/// -----------------------------
/// 4) EL PROVIDER
/// -----------------------------
final evaluationControllerProvider =
    AutoDisposeNotifierProvider<EvaluationController, EvaluationState>(
  EvaluationController.new,
);
}