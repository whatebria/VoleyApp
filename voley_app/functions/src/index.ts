import * as admin from "firebase-admin";
// Importar desde v2 (versión 2)
import {onCall, HttpsError} from "firebase-functions/v2/https";

// Inicializa Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// --- 1. DEFINICIÓN DE TIPOS (Interfaces) ---
// (Estas interfaces deben coincidir con tus modelos de Firestore)

interface Tournament {
  date: admin.firestore.Timestamp;
  name: string;
}

interface EvaluationResult {
  testScores: { [key: string]: number };
  strengths: string[];
  weaknesses: string[];
}

interface PlayerProfile {
  id: string; // El ID del documento (UUID)
  userId: string; // El ID de autenticación (Auth UID) del jugador
  assignedCoachId: string; // El Auth UID del entrenador
  level: string;
  goals?: string[];
  injuries?: string[];
  availability: {
    trainingDays: string[];
    sessionMinutes: number;
  };
  evaluation?: EvaluationResult;
  tournaments?: Tournament[];
  // (Añade 'equipment' si lo usas)
  // equipment?: string[];
}

interface Exercise {
  id: string;
  name: string;
  category: string;
  level: string;
  equipmentNeeded: string;
  tags: string[];
  contraindicatedFor: string[];
}

interface WorkoutExercise {
  exerciseId: string;
  name: string;
  sets: number;
  reps: string;
  intensity: string;
}

interface Session {
  day: string;
  objective: string;
  load: number;
  exercises: WorkoutExercise[];
}

interface Microcycle {
  weekNumber: number;
  sessions: Session[];
}

interface Mesocycle {
  name: string;
  weeks: number;
  focus: string;
  progressionType: string;
  microcycles: Microcycle[];
}

interface Program {
  id: string;
  source: "Automático";
  startDate: admin.firestore.Timestamp;
  endDate: admin.firestore.Timestamp;
  mesocycles: Mesocycle[];
}


// --- 2. LÓGICA DE GENERACIÓN (Funciones "Seguras" traducidas de Dart) ---

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(value, max));
}

function _normalizeLevel(level: string): number {
  const s = (level ?? "principiante").toLowerCase();
  if (s.includes("principiante") || s.includes("recreativo")) return 1;
  if (s.includes("intermedio") || s.includes("competitivo")) return 2;
  return 3; // avanzado
}

function _createMesocycles(totalWeeks: number): Mesocycle[] {
  if (totalWeeks <= 6) {
    return [
      {
        name: "Potencia",
        weeks: clamp(totalWeeks, 1, 6),
        focus: "Potencia",
        progressionType: "lineal",
        microcycles: [],
      },
    ];
  }

  const baseWeeks = clamp(Math.round(totalWeeks * 0.4), 3, 8);
  const strengthWeeks = clamp(Math.round(totalWeeks * 0.35), 3, 8);
  let powerWeeks = totalWeeks - baseWeeks - strengthWeeks;
  powerWeeks = clamp(powerWeeks, 2, 6);

  return [
    {
      name: "Base", weeks: baseWeeks, focus: "Base",
      progressionType: "lineal", microcycles: [],
    },
    {
      name: "Fuerza", weeks: strengthWeeks, focus: "Fuerza",
      progressionType: "progresiva", microcycles: [],
    },
    {
      name: "Potencia", weeks: powerWeeks, focus: "Potencia",
      progressionType: "ondulante", microcycles: [],
    },
  ];
}

function _getTagsForFocus(focus: string, profile: PlayerProfile):
  string[] {
  const lower = focus.toLowerCase();
  let result: string[] = [];

  if (lower.includes("base")) {
    result.push("movilidad", "core", "fuerza general",
      "resistencia");
  } else if (lower.includes("fuerza")) {
    result.push("fuerza", "estabilidad", "rodilla",
      "técnica fuerza");
  } else if (lower.includes("potencia")) {
    result.push("salto", "explosivo", "plyo", "velocidad");
  } else {
    result = (profile.goals ?? []).map((g) => g.toLowerCase());
  }

  const weaknesses = profile.evaluation?.weaknesses ?? [];
  for (const w of weaknesses) {
    const lowerWeakness = w.toLowerCase();
    if (!result.includes(lowerWeakness)) {
      result.push(lowerWeakness);
    }
  }
  return result;
}

function _filterExercises(
  all: Exercise[],
  tags: string[],
  profile: PlayerProfile
): Exercise[] {
  const profileLevelNum = _normalizeLevel(profile.level);
  const profileInjuries = profile.injuries ?? [];

  const filtered = all.filter((e) => {
    const hasTag = e.tags.some((t) => tags.includes(t));
    const matchesLevel = _normalizeLevel(e.level) <= profileLevelNum;
    const contra = e.contraindicatedFor ?? [];
    const notContra = contra.every((c) =>
      !profileInjuries.includes(c));
    return hasTag && matchesLevel && notContra;
  });

  filtered.sort((a, b) => {
    const aMatch = a.tags.filter((t) => tags.includes(t)).length;
    const bMatch = b.tags.filter((t) => tags.includes(t)).length;
    return bMatch - aMatch;
  });

  return filtered;
}

function _calculateSessionLoad(focus: string, profile:
  PlayerProfile): number {
  const f = focus.toLowerCase();
  let base = 0.6;
  if (f.includes("fuerza")) base = 0.8;
  if (f.includes("potencia")) base = 1.0;

  const level = (profile.level ?? "recreativo").toLowerCase();
  if (level.includes("semiprofesional")) base *= 1.05;
  if (level.includes("recreativo")) base *= 0.9;

  return Number(base.toFixed(2));
}

/**
 * Lógica principal del programa (AHORA MÁS SEGURA)
 */
function generateProgram(
  profile: PlayerProfile,
  allExercises: Exercise[]
): Program {
  const now = admin.firestore.Timestamp.now();

  // --- CORRECCIÓN DE SEGURIDAD ---
  // Provee un array vacío '[]' si 'profile.tournaments' es undefined
  const tournaments = profile.tournaments ?? [];

  let nextTournamentDate: admin.firestore.Timestamp | null = null;
  if (tournaments.length > 0) {
    const future = tournaments
      .filter((t) => t.date > now) // Esto ya no fallará
      .sort((a, b) => a.date.toMillis() - b.date.toMillis());
    if (future.length > 0) {
      nextTournamentDate = future[0].date;
    }
  }

  let weeksToTournament = 12;
  if (nextTournamentDate) {
    const diffMillis = nextTournamentDate.toMillis() -
      now.toMillis();
    weeksToTournament = Math.floor(diffMillis / (1000 * 60 * 60 * 24 * 7));
  }

  const mesocycles = _createMesocycles(weeksToTournament);
  const finalMesocycles: Mesocycle[] = [];

  for (const meso of mesocycles) {
    const microcycles: Microcycle[] = [];

    for (let w = 1; w <= meso.weeks; w++) {
      // Valor por defecto para días de entrenamiento si no existen
      const trainingDays = profile.availability?.trainingDays ??
        ["Lunes", "Miércoles", "Viernes"];

      const sessions = trainingDays.map((day) => {
        const tags = _getTagsForFocus(meso.focus, profile);
        const filtered = _filterExercises(allExercises, tags, profile);

        // TODO: Rotar los ejercicios
        const sessionExercises = filtered.slice(0, 5).map((ex):
          WorkoutExercise => ({
          exerciseId: ex.id,
          name: ex.name,
          sets: meso.focus === "Base" ? 4 : 3,
          reps: "8-12",
          intensity: "RPE 7",
        }));

        return {
          day: day,
          objective: meso.focus,
          load: _calculateSessionLoad(meso.focus, profile),
          exercises: sessionExercises,
        };
      });

      microcycles.push({weekNumber: w, sessions: sessions});
    }

    finalMesocycles.push({
      ...meso,
      microcycles: microcycles,
    });
  }

  const endDateMillis =
    now.toMillis() + weeksToTournament * 7 * 24 * 60 * 60 * 1000;
  const endDate = admin.firestore.Timestamp.fromMillis(endDateMillis);

  return {
    id: `prog_${now.toMillis()}`,
    source: "Automático",
    startDate: now,
    endDate: endDate,
    mesocycles: finalMesocycles,
  };
}


// --- 3. FUNCIÓN "Callable" (Punto de Entrada CORREGIDO) ---

export const generateMyProgram = onCall(async (request) => {
  // El usuario que hace la llamada (el coach o el jugador)
  const callerId = request.auth?.uid;
  if (!callerId) {
    throw new HttpsError("unauthenticated",
      "El usuario debe estar autenticado.");
  }

  // El 'playerId' que envía la app es el ID del PERFIL (el UUID)
  const targetProfileId = request.data.playerId;

  if (!targetProfileId) {
    throw new HttpsError("invalid-argument",
      "No se proporcionó un ID de perfil (playerId).");
  }

  try {
    console.log(
      `Usuario ${callerId} generando programa para Perfil ID: 
      ${targetProfileId}`
    );

    // --- ¡CORRECCIÓN CLAVE! ---
    // Buscamos en la colección 'players', no en 'users'
    const profileDoc =
      await db.collection("players").doc(targetProfileId).get();
    // --- FIN DE LA CORRECCIÓN ---

    if (!profileDoc.exists) {
      throw new HttpsError("not-found",
        "Perfil de jugador no encontrado en la colección 'players'.");
    }

    // Usamos 'as any' para que TS confíe en nuestras comprobaciones de '??'
    const profile = profileDoc.data() as any as PlayerProfile;

    // --- Verificación de Permisos ---
    // (Asegúrate de que tu perfil en 'players' tenga 'userId' y 'assignedCoachId')

    const isOwner = profile.userId === callerId;
    const isAssignedCoach = (profile.assignedCoachId === callerId);

    if (!isOwner && !isAssignedCoach) {
      console.warn(`Permiso denegado: 
        ${callerId} intentó acceder a ${targetProfileId}`);
      throw new HttpsError(
        "permission-denied",
        "No tienes permiso para generar un programa para este jugador."
      );
    }
    // --- Fin Verificación ---

    const exercisesSnapshot = await db.collection("exercises").get();
    const allExercises: Exercise[] = exercisesSnapshot.docs.map(
      (doc) => doc.data() as Exercise
    );
    console.log(`Perfil cargado. ${allExercises.length} 
      ejercicios cargados.`);

    const newProgram = generateProgram(profile, allExercises);
    console.log("Programa generado.");

    // --- ¡CORRECCIÓN CLAVE 2! ---
    // Guardamos en la subcolección de 'players'
    const programRef = await db
      .collection("players")
      .doc(targetProfileId)
      .collection("programs")
      .add(newProgram);

    console.log(`Programa guardado con ID: ${programRef.id}`);

    return {success: true, programId: programRef.id};
  } catch (error) {
    console.error("Error al generar el programa:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError(
      "internal",
      "No se pudo generar el programa.",
      error
    );
  }
});
