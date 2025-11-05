// lib/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:voley_app/src/auth/auth_provider.dart';
import 'package:voley_app/providers/program_editor_notifier.dart';
import 'package:voley_app/providers/program_generator.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/session_log.dart';
import 'package:voley_app/src/models/user.dart' as app_user;
import 'package:voley_app/src/services/firestore_service.dart';

// --- SECCIÓN 1: SERVICIOS PRINCIPALES ---
// (Sin cambios)

final firestoreProvider = Provider((ref) => FirestoreService());
final functionsProvider = Provider((ref) => FirebaseFunctions.instance);

// --- SECCIÓN 2: DATOS GLOBALES Y DE USUARIO LOGUEADO ---
// (Sin cambios)

/// Provee el usuario de Firestore (`app_user.User`) basado en el usuario de Auth.
final currentUserAppUserProvider = FutureProvider<app_user.User?>((ref) async {
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

/// Provee el perfil del **jugador actualmente logueado**.
final playerProfileProvider = FutureProvider<PlayerProfile?>((ref) async {
  final appUser = await ref.watch(currentUserAppUserProvider.future);

  if (appUser == null || appUser.isCoach) {
    return null; // No es un jugador, no hay perfil
  }

  final firestore = ref.read(firestoreProvider);
  final profile = await firestore.getPlayerProfileByUserId(appUser.id);
  return profile;
});

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

// --- SECCIÓN 3: DATOS DEL JUGADOR LOGUEADO ---

/// Escucha el programa más RECIENTE del perfil del **jugador logueado**.
/// (Usado por la pantalla de "Resultado Inmediato" o el Dashboard del jugador)
final generatedProgramProvider = StreamProvider<Program?>((ref) {
  // 1. "Observa" (watch) el resultado del FutureProvider de perfil
  final profileAsync = ref.watch(playerProfileProvider);
  final firestore = ref.read(firestoreProvider);

  // 2. Mapea el resultado
  return profileAsync.when(
    data: (profile) {
      if (profile == null) {
        return Stream.value(null); // Sin perfil -> Sin programa
      }
      // 3. Si hay perfil, escucha el stream
      return firestore.getLatestProgramStream(profile.id);
    },
    loading: () => Stream.value(null), // Cargando perfil -> Cargando programa
    error: (e, s) => Stream.error(e, s), // Error de perfil -> Error de programa
  );
});

/// Escucha el historial de sesiones del **jugador logueado**.
final sessionLogHistoryProvider = StreamProvider<List<SessionLog>>((ref) {
  final profileAsync = ref.watch(playerProfileProvider);

  return profileAsync.when(
    data: (profile) {
      if (profile == null) {
        return Stream.value([]); // Sin perfil -> Sin historial
      }
      return ref.read(firestoreProvider).getSessionHistoryStream(profile.id);
    },
    loading: () => Stream.value([]),
    error: (e, s) => Stream.error(e, s),
  );
});

final playerProgramsProvider = StreamProvider<List<Program>>((ref) {
  final firestore = ref.read(firestoreProvider);

  // 1. Observa el perfil del JUGADOR LOGUEADO
  final profileAsync = ref.watch(playerProfileProvider);

  // 2. Mapea el resultado
  return profileAsync.when(
    data: (profile) {
      if (profile == null) {
        return Stream.value([]); // Sin perfil -> Sin programas
      }
      // 3. Si hay perfil, escucha el stream de TODOS sus programas
      return firestore.getAllProgramsStream(profile.id);
    },
    loading: () => Stream.value([]), // Cargando perfil -> Cargando programas
    error: (e, s) => Stream.error(e, s),
  );
});

// --- SECCIÓN 4: FLUJO DEL "EXPLORADOR" (Para Coach) ---

/// Clase auxiliar para agrupar un jugador con su perfil
class PlayerWithProfile {
  final app_user.User player;
  final PlayerProfile? profile;
  PlayerWithProfile(this.player, this.profile);

  // Es útil para los DropdownButton
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerWithProfile &&
          runtimeType == other.runtimeType &&
          player.id == other.player.id;

  @override
  int get hashCode => player.id.hashCode;
}

/// Provee la lista de jugadores (app_user.User) asignados al coach logueado.
final coachPlayersProvider = StreamProvider<List<app_user.User>>((ref) {
  final currentUser = ref.watch(currentUserAppUserProvider).value;

  if (currentUser == null || !currentUser.isCoach) {
    return Stream.value([]);
  }

  final firestore = ref.read(firestoreProvider);
  return firestore.getPlayersByCoachStream(currentUser.id);
});

/// Provee la lista de jugadores Y sus perfiles asociados.
/// [REFACTORIZADO] Convertido a StreamProvider para ser reactivo.
final coachPlayersWithProfilesProvider =
    StreamProvider<List<PlayerWithProfile>>((ref) async* {
      final firestore = ref.read(firestoreProvider);

      // 1. Escucha el stream de jugadores
      final playersStream = ref.watch(coachPlayersProvider.stream);

      // 2. Por cada nueva lista de jugadores emitida...
      await for (final players in playersStream) {
        if (players.isEmpty) {
          yield [];
          continue;
        }

        // 3. Busca todos sus perfiles en paralelo
        final futures = players.map((player) async {
          final profile = await firestore.getPlayerProfileByUserId(player.id);
          return PlayerWithProfile(player, profile);
        }).toList();

        // 4. Espera a que todos se completen y emite la lista combinada
        yield await Future.wait(futures);
      }
    });

/// Almacena el combo (Jugador + Perfil) que el coach selecciona en el Dropdown.
/// [REFACTORIZADO] Ahora almacena `PlayerWithProfile` en lugar de `app_user.User`.
final explorerSelectedPlayerProvider = StateProvider<PlayerWithProfile?>(
  (ref) => null,
);

final selectedPlayerProfileProvider = Provider<PlayerProfile?>((ref) {
  final selected = ref.watch(explorerSelectedPlayerProvider);
  return selected?.profile;
});

final explorerProgramsProvider = StreamProvider<List<Program>>((ref) {
  final firestore = ref.read(firestoreProvider);

  // 1. Observa el perfil del jugador seleccionado (que ya está cargado)
  final selectedProfile = ref.watch(selectedPlayerProfileProvider);

  if (selectedProfile == null) {
    // Si no hay perfil (o no hay jugador seleccionado), emite lista vacía.
    return Stream.value([]);
  } else {
    // 2. Escucha los programas de ESE perfil
    return firestore.getAllProgramsStream(selectedProfile.id);
  }
});

/// Almacena el programa (Program) que el coach selecciona en el 2do Dropdown.
/// (Sin cambios)
final explorerSelectedProgramProvider = StateProvider<Program?>((ref) => null);

// --- SECCIÓN 5: ESTADOS GLOBALES DE UI ---
// (Agrupados para claridad, sin cambios)

final isGeneratingProgramProvider = StateProvider<bool>((ref) => false);
final isLoggingOutProvider = StateProvider<bool>((ref) => false);
final isCreatingPlayerProvider = StateProvider<bool>((ref) => false);

/// Provider que expone la lógica de negocio para crear programas.
final programGeneratorProvider = Provider<ProgramGenerator>((ref) {
  return ProgramGenerator();
});

final programEditorProvider =
    StateNotifierProvider<ProgramEditorNotifier, Program?>((ref) {
      return ProgramEditorNotifier(ref);
    });

// --- SECCIÓN 6: MAPAS DE ETIQUETAS (IDs -> textos legibles) ---

/// Etiquetas de Categorías (categoryId -> label)
final exerciseCategoryLabelsProvider = Provider<Map<String, String>>((ref) {
  // 🚩 Ajusta estos ids a los que realmente uses en tu catálogo.
  return const {
    'strength': 'Fuerza',
    'power': 'Potencia',
    'plyo': 'Pliometría',
    'mobility': 'Movilidad',
    'stability': 'Estabilidad',
    'conditioning': 'Resistencia',
    'speed': 'Velocidad',
    'agility': 'Agilidad',
    'balance': 'Balance',
    'core': 'Core',
    'rehab': 'Rehabilitación',
    'general': 'General',
  };
});

/// Etiquetas de Niveles (levelId -> label)
final exerciseLevelLabelsProvider = Provider<Map<String, String>>((ref) {
  return const {
    'beginner': 'Principiante',
    'intermediate': 'Intermedio',
    'advanced': 'Avanzado',
  };
});

/// Etiquetas de Equipamiento (equipmentId -> label)
final exerciseEquipmentLabelsProvider = Provider<Map<String, String>>((ref) {
  return const {
    'bodyweight': 'Peso Corporal',
    'dumbbell': 'Mancuerna',
    'barbell': 'Barra',
    'kettlebell': 'Kettlebell',
    'resistance_band': 'Banda Elástica',
    'medicine_ball': 'Balón Medicinal',
    'box': 'Caja/Plyo Box',
    'cone': 'Cono',
    'mat': 'Colchoneta',
    'foam_roller': 'Foam Roller',
    'trx': 'TRX/Suspensión',
    'machines': 'Máquinas',
    'none': 'Sin equipamiento',
  };
});

/// Etiquetas de Tags (tagId -> label)
final exerciseTagLabelsProvider = Provider<Map<String, String>>((ref) {
  return const {
    'lower_body': 'Tren Inferior',
    'upper_body': 'Tren Superior',
    'full_body': 'Cuerpo Completo',
    'explosive': 'Explosivo',
    'push': 'Empuje',
    'pull': 'Jalón',
    'hinge': 'Bisagra',
    'squat': 'Sentadilla',
    'unilateral': 'Unilateral',
    'bilateral': 'Bilateral',
    'rotation': 'Rotación',
    'anti_rotation': 'Anti-rotación',
    'isometric': 'Isométrico',
    'plyo': 'Pliometría',
    'endurance': 'Resistencia',
    'hypertrophy': 'Hipertrofia',
    'strength': 'Fuerza',
    'power': 'Potencia',
    'mobility': 'Movilidad',
    'stability': 'Estabilidad',
    'balance': 'Balance',
    'warmup': 'Calentamiento',
    'cooldown': 'Vuelta a la calma',
    'core': 'Core',
  };
});
