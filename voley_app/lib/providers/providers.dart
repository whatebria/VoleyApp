import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart'; // <-- 1. IMPORTAR
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/services/firestore_service.dart';

// (Sin cambios)
final firestoreProvider = Provider((ref) => FirestoreService());

// --- 2. AÑADIR PROVIDER PARA CLOUD FUNCTIONS ---
final functionsProvider = Provider((ref) {
  // Puedes ajustar la región si es necesario
  return FirebaseFunctions.instance;
});

// (Sin cambios) - La UI todavía puede necesitar ver los ejercicios
final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final svc = ref.read(firestoreProvider);
  return svc.getAllExercises();
});

// (Sin cambios) - Lo usamos para saber QUÉ jugador está seleccionado
final playerProfileProvider = StateProvider<PlayerProfile?>((ref) => null);


// --- 3. ACCIÓN MODIFICADA (AHORA SÓLO "DISPARA" LA FUNCIÓN) ---
final programGeneratorAction = Provider((ref) {
  final functions = ref.read(functionsProvider);

  // Devuelve una función que toma el PERFIL del jugador
  return (PlayerProfile profile) async {
    // Llama a la Cloud Function llamada 'generateMyProgram'
    final callable = functions.httpsCallable('generateMyProgram');

    // Pasa el ID del jugador a la función en la nube
    // ¡Tu index.ts DEBE estar preparado para recibir 'playerId'!
    final result = await callable.call(<String, dynamic>{
      'playerId': profile.id, 
      // NOTA: No pasamos 'exercises'. La función los obtiene sola.
    });

    // La función devuelve { success: true, programId: ... }
    return result.data as Map<String, dynamic>;
  };
});


// --- 4. PROVIDER MODIFICADO (AHORA "ESCUCHA" EL RESULTADO) ---
// Este provider escucha los cambios en Firestore.
// Cuando la Cloud Function guarda el programa, este provider se actualiza solo.
final generatedProgramProvider = StreamProvider<Program?>((ref) {
  
  // 1. Escucha al provider del perfil seleccionado
  final selectedProfile = ref.watch(playerProfileProvider);
  final firestore = ref.read(firestoreProvider);

  if (selectedProfile == null) {
    return Stream.value(null); // No hay perfil, no hay programa
  }

  // 2. Llama al servicio para obtener un Stream del programa más reciente
  //    de ese jugador. (Necesitas añadir este método a tu service)
  return firestore.getLatestProgramStream(selectedProfile.id);
});