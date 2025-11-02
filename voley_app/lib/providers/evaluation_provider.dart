import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:uuid/uuid.dart';

// --- 1. Define el ESTADO que gestionará el controlador ---
// Este estado SÍ incluye el modo/usuario seleccionado,
// pero NO incluye los valores de los TextFields.
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
  final AsyncValue<List<app_user.User>> availablePlayers; // Jugadores del coach
  final AsyncValue<PlayerProfile?> loadedProfile; // El perfil del selectedUser

  // --- Constructor ---
  const EvaluationState({
    this.isSubmitting = false,
    this.successMessage,
    this.errorMessage,
    this.isCreatingNewUser = true,
    this.selectedUser,
    this.currentUser = const AsyncLoading(),
    this.availablePlayers = const AsyncLoading(),
    this.loadedProfile = const AsyncLoading(),
  });

  // --- Método copyWith para mutaciones de estado ---
  EvaluationState copyWith({
    bool? isSubmitting,
    String? successMessage,
    String? errorMessage,
    bool? isCreatingNewUser,
    app_user.User? selectedUser,
    AsyncValue<app_user.User?>? currentUser,
    AsyncValue<List<app_user.User>>? availablePlayers,
    AsyncValue<PlayerProfile?>? loadedProfile,
  }) {
    return EvaluationState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: successMessage, // Null por defecto para limpiar
      errorMessage: errorMessage, // Null por defecto para limpiar
      isCreatingNewUser: isCreatingNewUser ?? this.isCreatingNewUser,
      selectedUser: selectedUser ?? this.selectedUser,
      currentUser: currentUser ?? this.currentUser,
      availablePlayers: availablePlayers ?? this.availablePlayers,
      loadedProfile: loadedProfile ?? this.loadedProfile,
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
    return const EvaluationState();
  }

 Future<void> init() async {
    


    state = state.copyWith(currentUser: const AsyncLoading());
    
    try {
      // ¡ARREGLO! Usa 'ref.read' aquí, no 'ref.watch'.
      final user = await ref.read(currentUserAppUserProvider.future);

      if (user == null) throw Exception("Usuario no encontrado.");
      
      state = state.copyWith(currentUser: AsyncData(user));
      
      if (user.isCoach) {
        await _loadCoachPlayers(); // Espera a que carguen
      } else {
        // Es Jugador: Forzar modo edición y cargar su propio perfil
        state = state.copyWith(
          isCreatingNewUser: false, 
          selectedUser: user
        );
        // No necesitas 'await' aquí si no depende de _loadCoachPlayers
        _loadProfileForUser(user.id);
      }
    } catch (e, s) {
      state = state.copyWith(currentUser: AsyncError(e, s));
    }
  }

  /// Carga los jugadores de un coach
  Future<void> _loadCoachPlayers() async {
    state = state.copyWith(availablePlayers: const AsyncLoading());
    final playersAsync = ref.watch(coachPlayersProvider.future);
    try {
      final players = await playersAsync;
      state = state.copyWith(availablePlayers: AsyncData(players));
    } catch (e, s) {
      state = state.copyWith(availablePlayers: AsyncError(e, s));
    }
  }
  
  /// Carga el perfil de un jugador específico
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
      selectedUser: null, // Limpia la selección
      loadedProfile: const AsyncData(null), // Limpia el perfil cargado
    );
  }

  /// Selecciona un jugador del Dropdown
  void selectUser(app_user.User? user) {
    if (user == null) {
      state = state.copyWith(
        selectedUser: null,
        loadedProfile: const AsyncData(null)
      );
    } else {
      state = state.copyWith(selectedUser: user);
      _loadProfileForUser(user.id);
    }
  }
  
  /// Limpia los mensajes de error/éxito (para Snackbars)
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  /// --- LÓGICA DE GUARDADO CENTRALIZADA ---
  /// Recibe los datos del formulario desde la UI
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
            // El jugador o coach solo puede actualizar estas partes
            position: position,
            level: level.toLowerCase(),
            injuries: injuries.contains('Ninguna') ? [] : injuries,
            availability: availability,
            tournaments: tournaments,
            evaluation: loadedProfile.evaluation.copyWith(
              testScores: testScores, // El coach actualiza esto
            ),
          );
        } else {
          // B. Crear Perfil por primera vez (para un Auth User existente)
          profileToSave = PlayerProfile(
            id: _uuid.v4(),
            userId: selectedUser.id,
            assignedCoachId: coachIdToAssign,
            name: name, // El nombre viene del 'selectedUser'
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

      // --- PASO FINAL: GUARDAR ---
      await _firestore.savePlayerProfile(profileToSave);
      ref.read(playerProfileProvider.notifier).state = profileToSave; // Actualiza el provider global
      
      state = state.copyWith(
        isSubmitting: false, 
        successMessage: "Evaluación guardada exitosamente",
        loadedProfile: AsyncData(profileToSave), // Asegura que el estado se actualice
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