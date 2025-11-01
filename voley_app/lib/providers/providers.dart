import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/services/firestore_service.dart';

// --- SECCIÓN 1: SERVICIOS PRINCIPALES ---

/// Provee la instancia del servicio de Firestore.
final firestoreProvider = Provider((ref) => FirestoreService());

/// Provee la instancia de Cloud Functions.
final functionsProvider = Provider((ref) {
  return FirebaseFunctions.instance;
});

// --- SECCIÓN 2: DATOS GLOBALES Y DE USUARIO ---

/// Provee el usuario de Firestore (`app_user.User`) basado en el usuario de Auth.
final currentUserAppUserProvider = FutureProvider<app_user.User?>((ref) async {
  // Ahora observamos 'authStateProvider', que SÍ tiene .future
  final authUser = await ref.watch(authStateProvide.future); 
  
  if (authUser == null) {
    return null; // El usuario no está logueado
  }
  
  // 'authUser' es ahora un 'User?' (de Auth) y .uid existe
  final firestore = ref.read(firestoreProvider);
  return await firestore.getUser(authUser.uid); 
});

/// Provee la lista global de ejercicios.
final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final svc = ref.read(firestoreProvider);
  return svc.getAllExercises();
});


// --- SECCIÓN 3: FLUJO DEL "GENERADOR" (EvaluationScreen -> GenerateProgramScreen) ---

/// Almacena el perfil del jugador que se está creando o editando.
/// La 'EvaluationScreen' escribe en este provider.
final playerProfileProvider = StateProvider<PlayerProfile?>((ref) => null);

/// Provee la ACCIÓN para llamar a la Cloud Function y generar un programa.
final programGeneratorAction = Provider((ref) {
  final functions = ref.read(functionsProvider);

  return (PlayerProfile profile) async {
    final callable = functions.httpsCallable('generateMyProgram');
    
    // Pasa el ID del perfil del jugador (que es un UUID, no el Auth ID)
    final result = await callable.call(<String, dynamic>{
      'playerId': profile.id,
    });

    return result.data as Map<String, dynamic>;
  };
});

/// ESCUCHA el programa más RECIENTE del perfil que se acaba de generar.
/// Usado por 'ProgramViewScreen' después de la generación.
final generatedProgramProvider = StreamProvider<Program?>((ref) {
  // Observa el perfil que se guardó en el StateProvider
  final selectedProfile = ref.watch(playerProfileProvider);
  final firestore = ref.read(firestoreProvider);

  if (selectedProfile == null) {
    return Stream.value(null);
  }

  // Escucha el último programa de ESE perfil
  return firestore.getLatestProgramStream(selectedProfile.id);
});

// --- 2. ERROR CORREGIDO: El bloque duplicado ha sido eliminado ---
// (La lógica que estaba aquí abajo era un duplicado de la de arriba y fue borrada).


// --- SECCIÓN 4: FLUJO DEL "EXPLORADOR" (ProgramViewScreen como explorador) ---

/// Provee la lista de jugadores (app_user.User) asignados al coach logueado.
final coachPlayersProvider = FutureProvider<List<app_user.User>>((ref) async {
  // Observa el provider del usuario de Firestore
  final currentUser = ref.watch(currentUserAppUserProvider).value;
  
  // '.isCoach' ahora está disponible porque 'currentUser' es del tipo correcto
  if (currentUser == null || !currentUser.isCoach) return [];
  
  final firestore = ref.read(firestoreProvider);
  return firestore.getPlayersByCoach(currentUser.id);
});

/// Almacena el jugador (app_user.User) que el coach selecciona en el Dropdown.
final explorerSelectedPlayerProvider = StateProvider<app_user.User?>((ref) => null);

/// Escucha TODOS los programas del jugador seleccionado en el explorador.
final explorerProgramsProvider = StreamProvider<List<Program>>((ref) async* {
  final firestore = ref.read(firestoreProvider);
  // Observa al jugador seleccionado por el coach
  final selectedPlayer = ref.watch(explorerSelectedPlayerProvider);
  
  if (selectedPlayer == null) {
    yield [];
  } else {
    // Busca el *perfil* de ese jugador (basado en el Auth UID de 'selectedPlayer.id')
    final profile = await firestore.getPlayerProfileByUserId(selectedPlayer.id);
    if (profile == null) {
      yield [];
    } else {
      // Escucha todos los programas de ESE perfil
      yield* firestore.getAllProgramsStream(profile.id);
    }
  }
});

/// Almacena el programa (Program) que el coach selecciona en el 2do Dropdown.
final explorerSelectedProgramProvider = StateProvider<Program?>((ref) => null);