// lib/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:voley_app/providers/auth_provider.dart'; // Asegúrate de tener auth_provider.dart
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/services/firestore_service.dart';

// --- SECCIÓN 1: SERVICIOS PRINCIPALES ---

final firestoreProvider = Provider((ref) => FirestoreService());
final functionsProvider = Provider((ref) => FirebaseFunctions.instance);


// --- SECCIÓN 2: DATOS GLOBALES Y DE USUARIO ---

/// Provee el usuario de Firestore (`app_user.User`) basado en el usuario de Auth.
final currentUserAppUserProvider = FutureProvider<app_user.User?>((ref) async {
  // Depende de 'authStateProvider' (el StreamProvider)
  final authUser = await ref.watch(authStateProvider.future);
  
  if (authUser == null) return null;
  
  final firestore = ref.read(firestoreProvider);
  return await firestore.getUser(authUser.uid);
});

/// Provee la lista global de ejercicios.
final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final svc = ref.read(firestoreProvider);
  return svc.getAllExercises();
});


// --- SECCIÓN 3: FLUJO DEL "GENERADOR" (Para EvaluationScreen) ---

/// Almacena el perfil del jugador que se está creando o editando.
final playerProfileProvider = StateProvider<PlayerProfile?>((ref) => null);

/// Acción para llamar a la Cloud Function y generar un programa.
final programGeneratorAction = Provider((ref) {
  final functions = ref.read(functionsProvider);

  return (PlayerProfile profile) async {
    final callable = functions.httpsCallable('generateMyProgram');
    final result = await callable.call(<String, dynamic>{
      'playerId': profile.id,
    });
    return result.data as Map<String, dynamic>;
  };
});

/// Escucha el programa más RECIENTE del perfil que se acaba de generar.
/// (Usado por la pantalla de "Resultado Inmediato" si la tienes)
final generatedProgramProvider = StreamProvider<Program?>((ref) {
  final selectedProfile = ref.watch(playerProfileProvider);
  final firestore = ref.read(firestoreProvider);

  if (selectedProfile == null) {
    return Stream.value(null);
  }
  return firestore.getLatestProgramStream(selectedProfile.id);
});


// --- SECCIÓN 4: FLUJO DEL "EXPLORADOR" (Para ProgramViewScreen) ---

/// Provee la lista de jugadores (app_user.User) asignados al coach logueado.
final coachPlayersProvider = StreamProvider<List<app_user.User>>((ref) { // <-- 1. Cambiado a StreamProvider
  // 2. Observa el .value (ya no se usa .future)
  final currentUser = ref.watch(currentUserAppUserProvider).value; 
  
  if (currentUser == null || !currentUser.isCoach) {
    return Stream.value([]); // 3. Devuelve un stream vacío
  }
  
  final firestore = ref.read(firestoreProvider);
  // 4. Llama al nuevo método de Stream
  return firestore.getPlayersByCoachStream(currentUser.id); 
});
/// Almacena el jugador (app_user.User) que el coach selecciona en el Dropdown.
final explorerSelectedPlayerProvider = StateProvider<app_user.User?>((ref) => null);

/// Escucha TODOS los programas del jugador seleccionado en el explorador.
final explorerProgramsProvider = StreamProvider<List<Program>>((ref) async* {
  final firestore = ref.read(firestoreProvider);
  final selectedPlayer = ref.watch(explorerSelectedPlayerProvider);
  
  if (selectedPlayer == null) {
    yield [];
  } else {
    // Busca el *perfil* de ese jugador (basado en el Auth UID de 'selectedPlayer.id')
    // Asumiendo que profile.id es el Auth UID. Ajusta si es necesario.
    final profile = await firestore.getPlayerProfileByUserId(selectedPlayer.id);
    if (profile == null) {
      yield [];
    } else {
      // Escucha todos los programas de ESE perfil
      yield* firestore.getAllProgramsStream(profile.id);
    }
  }
});

final selectedPlayerProfileProvider = FutureProvider<PlayerProfile?>((ref) async {
  final selectedPlayer = ref.watch(explorerSelectedPlayerProvider);
  if (selectedPlayer == null) {
    return null; // Si no hay jugador, no hay perfil
  }
  // Observa el provider de firestore y obtiene el perfil
  return ref.watch(firestoreProvider).getPlayerProfileByUserId(selectedPlayer.id);
});

/// Almacena el programa (Program) que el coach selecciona en el 2do Dropdown.
final explorerSelectedProgramProvider = StateProvider<Program?>((ref) => null);
final isGeneratingProgramProvider = StateProvider<bool>((ref) => false);
