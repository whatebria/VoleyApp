import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart'; // Importa el archivo principal
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:uuid/uuid.dart';

// --- 1. Define el ESTADO que gestionará el controlador ---
// (Sin cambios, tu clase EvaluationState es correcta)
@immutable
class EvaluationState {
  // --- Estados de carga y UI ---
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;
  
  // --- Estado del formulario ---
  final bool isCreatingNewUser; // Modo: Crear vs. Editar
  final app_user.User? selectedUser; // Qué usuario se está editando
  
  // --- Datos cargados ---
  final AsyncValue<app_user.User?> currentUser; // El usuario logueado
  // [CAMBIO] Cambiado a usar el provider `coachPlayersWithProfilesProvider`
  // para tener perfiles y jugadores juntos, simplificando la lógica.
  final AsyncValue<List<PlayerWithProfile>> availablePlayersWithProfiles;
  final AsyncValue<PlayerProfile?> loadedProfile; // El perfil del selectedUser

  // --- Constructor ---
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

  // --- Método copyWith para mutaciones de estado ---
  EvaluationState copyWith({
    bool? isSubmitting,
    String? successMessage,
    String? errorMessage,
    bool? isCreatingNewUser,
    // [CAMBIO] Hacemos 'selectedUser' nulleable en copyWith
    app_user.User? selectedUser,
    bool clearSelectedUser = false, // Flag para limpiar
    AsyncValue<app_user.User?>? currentUser,
    AsyncValue<List<PlayerWithProfile>>? availablePlayersWithProfiles,
    AsyncValue<PlayerProfile?>? loadedProfile,
    bool clearLoadedProfile = false, // Flag para limpiar
  }) {
    return EvaluationState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: successMessage, // Null por defecto para limpiar
      errorMessage: errorMessage, // Null por defecto para limpiar
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

// --- 2. Define el CONTROLADOR (Notifier) ---
class EvaluationController extends AutoDisposeNotifier<EvaluationState> {
  // Obtenemos los servicios una vez
  late final _firestore = ref.read(firestoreProvider);
  late final _functions = ref.read(functionsProvider);
  final _uuid = Uuid();

  @override
  EvaluationState build() {
    // El 'build' está vacío, la lógica se dispara con `init()`
    // Esto es un patrón válido para controladores de "página".
    return const EvaluationState();
  }

  Future<void> init() async {
    state = state.copyWith(currentUser: const AsyncLoading());
    
    try {
      // Usa 'ref.read' para obtener el valor de un Future una vez.
      final user = await ref.read(currentUserAppUserProvider.future);

      if (user == null) throw Exception("Usuario no encontrado.");
      
      state = state.copyWith(currentUser: AsyncData(user));
      
      if (user.isCoach) {
        // [CAMBIO] Llama a la función corregida
        await _loadCoachPlayersWithProfiles();
      } else {
        // Es Jugador: Forzar modo edición y cargar su propio perfil
        state = state.copyWith(
          isCreatingNewUser: false, 
          selectedUser: user
        );
        // Carga su propio perfil
        await _loadProfileForUser(user.id);
      }
    } catch (e, s) {
      state = state.copyWith(currentUser: AsyncError(e, s));
    }
  }

  /// [REFACTORIZADO] Carga jugadores y perfiles de un coach
  Future<void> _loadCoachPlayersWithProfiles() async {
    state = state.copyWith(availablePlayersWithProfiles: const AsyncLoading());
    try {
      // [CAMBIO] Usa `ref.read` (no `watch`) y lee el provider que ya
      // agrupa jugadores con perfiles.
      final playersWithProfiles =
          await ref.read(coachPlayersWithProfilesProvider.future);
      state = state.copyWith(
          availablePlayersWithProfiles: AsyncData(playersWithProfiles));
    } catch (e, s) {
      state = state.copyWith(availablePlayersWithProfiles: AsyncError(e, s));
    }
  }
  
  /// Carga el perfil de un jugador específico (sin cambios)
  Future<void> _loadProfileForUser(String userId) async {
    state = state.copyWith(loadedProfile: const AsyncLoading());
    try {
      final profile = await _firestore.getPlayerProfileByUserId(userId);
      // Es válido que el perfil sea 'null' (si es un usuario sin perfil)
      state = state.copyWith(loadedProfile: AsyncData(profile));
    } catch (e, s) {
      state = state.copyWith(loadedProfile: AsyncError(e, s));
    }
  }

  /// Cambia entre "Crear Nuevo" y "Usuario Existente"
  void setMode(bool isCreating) {
    state = state.copyWith(
      isCreatingNewUser: isCreating,
      clearSelectedUser: true, // Limpia la selección
      clearLoadedProfile: true, // Limpia el perfil cargado
    );
  }

  /// [REFACTORIZADO] Selecciona un jugador (con perfil) del Dropdown
  void selectPlayer(PlayerWithProfile? playerWithProfile) {
    if (playerWithProfile == null) {
      state = state.copyWith(
        clearSelectedUser: true,
        clearLoadedProfile: true,
      );
    } else {
      // Almacenamos el usuario y su perfil ya cargado.
      // No necesitamos volver a buscarlo en Firestore.
      state = state.copyWith(
        selectedUser: playerWithProfile.player,
        loadedProfile: AsyncData(playerWithProfile.profile),
      );
    }
  }
  
  /// Limpia los mensajes de error/éxito (para Snackbars)
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  /// --- LÓGICA DE GUARDADO CENTRALIZADA ---
  Future<void> handleSubmit({
    // Datos del formulario
    required String name,
    required String email,
    required String password,
    required String position,
    required String level,
    required List<String> injuries,
    required List<String> availabilityDays,
    required int availabilityMinutes,
    required List<Tournament> tournaments,
    required Map<String, double> testScores,
  }) async {
    state = state.copyWith(isSubmitting: true);
    
    final currentUser = state.currentUser.value;
    if (currentUser == null) {
      state = state.copyWith(errorMessage: "No se pudo identificar al usuario actual.", isSubmitting: false);
      return;
    }
    
    final String coachIdToAssign = currentUser.isCoach ? currentUser.id : (currentUser.coachId ?? "");

    try {
      PlayerProfile profileToSave;

      final availability = Availability(
        trainingDays: availabilityDays,
        sessionMinutes: availabilityMinutes,
      );

      if (state.isCreatingNewUser) {
        // --- 1. CREAR NUEVO USUARIO (Cloud Function) ---
        final callable = _functions.httpsCallable('createPlayerAccount');
        final result = await callable.call(<String, dynamic>{
          'email': email,
          'password': password,
          'name': name,
          'coachId': coachIdToAssign,
        });
        
        final userId = result.data['userId'];
        if (userId == null) throw Exception('La Cloud Function no devolvió un userId.');

        profileToSave = PlayerProfile(
          id: _uuid.v4(),
          userId: userId,
          assignedCoachId: coachIdToAssign,
          name: name,
          position: position,
          level: level.toLowerCase(),
          goals: [], // Añadir en otro formulario
          injuries: injuries.contains('Ninguna') ? [] : injuries,
          availability: availability,
          evaluation: EvaluationResult(
            testScores: testScores,
            strengths: [],
            weaknesses: [],
          ),
          tournaments: tournaments,
        );

      } else {
        // --- 2. ACTUALIZAR O CREAR PERFIL (para usuario existente) ---
        final loadedProfile = state.loadedProfile.value;
        final selectedUser = state.selectedUser;
        if (selectedUser == null) throw Exception("No hay un usuario seleccionado.");

        if (loadedProfile != null) {
          // A. Actualizar Perfil Existente
          profileToSave = loadedProfile.copyWith(
            position: position,
            level: level.toLowerCase(),
            injuries: injuries.contains('Ninguna') ? [] : injuries,
            availability: availability,
            tournaments: tournaments,
            evaluation: loadedProfile.evaluation.copyWith(
              testScores: testScores, 
            ),
          );
        } else {
          // B. Crear Perfil por primera vez (para un Auth User existente)
          profileToSave = PlayerProfile(
            id: _uuid.v4(),
            userId: selectedUser.id,
            assignedCoachId: coachIdToAssign,
            // [CAMBIO] Usamos el nombre del usuario existente, no el del formulario.
            // El campo 'name' del formulario solo debería usarse para 'isCreatingNewUser'
            name: selectedUser.name, 
            position: position,
            level: level.toLowerCase(),
            goals: [],
            injuries: injuries.contains('Ninguna') ? [] : injuries,
            availability: availability,
            evaluation: EvaluationResult(
              testScores: testScores,
              strengths: [],
              weaknesses: [],
            ),
            tournaments: tournaments,
          );
        }
      }

      // --- [REFACTORIZADO] PASO FINAL: GUARDAR E INVALIDAR ---
      await _firestore.savePlayerProfile(profileToSave);
      
      // ¡Esta es la parte clave!
      // Invalidamos los providers correctos para que la app se actualice
      // automáticamente en todas las pantallas.
      
      if (currentUser.isCoach) {
        // Un coach está editando/creando.
        // Refrescar la lista de jugadores con perfiles en el explorador.
        ref.invalidate(coachPlayersWithProfilesProvider);
        
        // Si el jugador editado es el que estaba seleccionado,
        // refrescar también su perfil detallado.
        if (state.selectedUser?.id == ref.read(explorerSelectedPlayerProvider)?.player.id) {
           ref.invalidate(selectedPlayerProfileProvider);
        }

      } else {
        // Un jugador está editando su *propio* perfil.
        // Refrescar el provider global de su perfil.
        ref.invalidate(playerProfileProvider);
      }
      
      state = state.copyWith(
        isSubmitting: false, 
        successMessage: "Evaluación guardada exitosamente",
        loadedProfile: AsyncData(profileToSave), // Asegura que el estado local se actualice
      );

    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: "Error al guardar: $e");
    }
  }
}

// --- 3. El Provider ---
final evaluationControllerProvider = 
    AutoDisposeNotifierProvider<EvaluationController, EvaluationState>(
  EvaluationController.new,
);