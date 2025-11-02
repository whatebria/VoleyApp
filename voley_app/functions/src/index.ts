import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as functions from "firebase-functions";

admin.initializeApp();
const db = admin.firestore();

// --- 1. DEFINICIÓN DE TIPOS (Interfaces) ---

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
  id: string;
  level: string;
  goals: string[];
  injuries: string[];
  availability: {
    trainingDays: string[];
    sessionMinutes: number;
  };
  evaluation: EvaluationResult;
  equipment: string[];
  tournaments: Tournament[];
  assignedCoachId?: string; // <-- AÑADIDO: UID del entrenador
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

// ... (Interfaces para WorkoutExercise, Session, Microcycle, Mesocycle, Program) ...
// (Estas son las mismas de tu código anterior)
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


// --- 2. LÓGICA DE GENERACIÓN (Tu Algoritmo Avanzado) ---
// (Todas tus funciones: _normalizeLevel, _createMesocycles, _getTagsForFocus, etc.)
// (Omitidas aquí por brevedad, pero deben estar)

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(value, max));
}

function _normalizeLevel(level: string): number {
  const s = level.toLowerCase();
  if (s.includes('principiante') || s.includes('recreativo')) return 1;
  if (s.includes('intermedio') || s.includes('competitivo')) return 2;
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
    { name: "Base", weeks: baseWeeks, focus: "Base", progressionType: "lineal", microcycles: [] },
    { name: "Fuerza", weeks: strengthWeeks, focus: "Fuerza", progressionType: "progresiva", microcycles: [] },
    { name: "Potencia", weeks: powerWeeks, focus: "Potencia", progressionType: "ondulante", microcycles: [] },
  ];
}

function _getTagsForFocus(focus: string, profile: PlayerProfile): string[] {
  const lower = focus.toLowerCase();
  let result: string[] = [];
  if (lower.includes("base")) {
    result.push("movilidad", "core", "fuerza general", "resistencia");
  } else if (lower.includes("fuerza")) {
    result.push("fuerza", "estabilidad", "rodilla", "técnica fuerza");
  } else if (lower.includes("potencia")) {
    result.push("salto", "explosivo", "plyo", "velocidad");
  } else {
    result = profile.goals.map((g) => g.toLowerCase());
  }
  for (const w of profile.evaluation.weaknesses) {
    const lowerWeakness = w.toLowerCase();
    if (!result.includes(lowerWeakness)) {
      result.push(lowerWeakness);
    }
  }
  return result;
}

function _filterExercises(all: Exercise[], tags: string[], profile: PlayerProfile): Exercise[] {
  const profileLevelNum = _normalizeLevel(profile.level);
  const filtered = all.filter((e) => {
    const hasTag = e.tags.some((t) => tags.includes(t));
    const matchesLevel = _normalizeLevel(e.level) <= profileLevelNum;
    const notContra = e.contraindicatedFor.every((c) => !profile.injuries.includes(c));
    return hasTag && matchesLevel && notContra;
  });
  filtered.sort((a, b) => {
    const aMatch = a.tags.filter((t) => tags.includes(t)).length;
    const bMatch = b.tags.filter((t) => tags.includes(t)).length;
    return bMatch - aMatch;
  });
  return filtered;
}

function _calculateSessionLoad(focus: string, profile: PlayerProfile): number {
  const f = focus.toLowerCase();
  let base = 0.6;
  if (f.includes("fuerza")) base = 0.8;
  if (f.includes("potencia")) base = 1.0;
  const level = profile.level.toLowerCase();
  if (level.includes("semiprofesional")) base *= 1.05;
  if (level.includes("recreativo")) base *= 0.9;
  return Number(base.toFixed(2));
}

function generateProgram(profile: PlayerProfile, allExercises: Exercise[]): Program {
  // (Tu lógica de generateProgram completa va aquí...)
  // ...
  const now = admin.firestore.Timestamp.now();
  let nextTournamentDate: admin.firestore.Timestamp | null = null;
  if (profile.tournaments.length > 0) {
    const future = profile.tournaments
      .filter((t) => t.date > now)
      .sort((a, b) => a.date.toMillis() - b.date.toMillis());
    if (future.length > 0) {
      nextTournamentDate = future[0].date;
    }
  }
  let weeksToTournament = 12;
  if (nextTournamentDate) {
    const diffMillis = nextTournamentDate.toMillis() - now.toMillis();
    weeksToTournament = Math.floor(diffMillis / (1000 * 60 * 60 * 24 * 7));
  }
  const mesocycles = _createMesocycles(weeksToTournament);
  const finalMesocycles: Mesocycle[] = [];
  for (const meso of mesocycles) {
    const microcycles: Microcycle[] = [];
    for (let w = 1; w <= meso.weeks; w++) {
      const sessions = profile.availability.trainingDays.map((day) => {
        const tags = _getTagsForFocus(meso.focus, profile);
        const filtered = _filterExercises(allExercises, tags, profile);
        const sessionExercises = filtered.slice(0, 5).map((ex): WorkoutExercise => ({
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
      microcycles.push({ weekNumber: w, sessions: sessions });
    }
    finalMesocycles.push({ ...meso, microcycles: microcycles });
  }
  const endDateMillis = now.toMillis() + weeksToTournament * 7 * 24 * 60 * 60 * 1000;
  const endDate = admin.firestore.Timestamp.fromMillis(endDateMillis);
  return {
    id: `prog_${now.toMillis()}`,
    source: "Automático",
    startDate: now,
    endDate: endDate,
    mesocycles: finalMesocycles,
  };
}


// --- 3. FUNCIÓN "Callable" (Punto de Entrada MODIFICADO) ---

// --- FUNCIÓN PARA CREAR USUARIO SIN AFECTAR SESIÓN ACTUAL ---
export const createPlayerUser = onCall(async (request) => {
  const callerId = request.auth?.uid;
  if (!callerId) {
    throw new HttpsError("unauthenticated", "El usuario debe estar autenticado.");
  }

  const { email, password, name, coachId } = request.data;

  if (!email || !password || !name || !coachId) {
    throw new HttpsError("invalid-argument", "Faltan datos requeridos.");
  }

  try {
    // Verificar que el caller es el coach
    if (callerId !== coachId) {
      throw new HttpsError("permission-denied", "Solo puedes crear usuarios para ti mismo.");
    }

    // Crear usuario en Firebase Auth usando Admin SDK
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
    });

    // Crear documento en Firestore
    const user = {
      id: userRecord.uid,
      email: email,
      name: name,
      role: "player",
      createdAt: admin.firestore.Timestamp.now(),
      coachId: coachId,
      testScores: [],
    };

    await db.collection("users").doc(userRecord.uid).set(user);

    // Crear permiso aceptado
    const permission = {
      id: `${coachId}_${userRecord.uid}`,
      coachId: coachId,
      playerId: userRecord.uid,
      status: "accepted",
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    };

    await db.collection("coach_player_permissions").doc(permission.id).set(permission);

    return { success: true, userId: userRecord.uid };
  } catch (error: any) {
    console.error("Error al crear usuario:", error);
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "El correo ya está en uso.");
    }
    throw new HttpsError("internal", "No se pudo crear el usuario.", error);
  }
});

export const generateMyProgram = onCall(async (request) => {
  // 3a. Identificar al usuario que LLAMA (caller)
  const callerId = request.auth?.uid;
  if (!callerId) {
    throw new HttpsError("unauthenticated", "El usuario debe estar autenticado.");
  }

  // 3b. Identificar para QUIÉN es el programa (target)
  // request.data.playerId es el ID enviado desde Flutter.
  // Si no se envía, se asume que el usuario genera para sí mismo.
  const targetPlayerId = request.data.playerId || callerId;

  try {
    console.log(
      `Usuario ${callerId} generando programa para ${targetPlayerId}`
    );

    // 2. Recolección de Datos
    const userDoc = await db.collection("users").doc(targetPlayerId).get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Perfil de jugador no encontrado.");
    }
    const profile = userDoc.data() as PlayerProfile;

    // --- 3c. VERIFICACIÓN DE PERMISOS ---
    const isOwner = callerId === targetPlayerId;
    const isAssignedCoach = profile.assignedCoachId === callerId;

    if (!isOwner && !isAssignedCoach) {
      // Si el que llama NO es el dueño Y NO es el entrenador asignado
      console.warn(`Permiso denegado: ${callerId} intentó acceder a ${targetPlayerId}`);
      throw new HttpsError(
        "permission-denied",
        "No tienes permiso para generar un programa para este jugador."
      );
    }
    // --- Fin de la verificación ---

    // 2b. Obtener TODOS los ejercicios
    const exercisesSnapshot = await db.collection("exercises").get();
    const allExercises: Exercise[] = exercisesSnapshot.docs.map(
      (doc) => doc.data() as Exercise
    );
    console.log(`Perfil cargado. ${allExercises.length} ejercicios cargados.`);

    // 3. Ejecución de Lógica
    const newProgram = generateProgram(profile, allExercises);
    console.log("Programa generado.");

    // 4. Guardado en Firestore
    const programData = JSON.parse(JSON.stringify(newProgram));

    // Guardar el programa en la subcolección del JUGADOR OBJETIVO
    const programRef = await db
      .collection("users")
      .doc(targetPlayerId) // <-- Guardar en el perfil del jugador
      .collection("programs")
      .add(programData);

    console.log(`Programa guardado con ID: ${programRef.id}`);

    // 5. Devolver éxito a la app de Flutter
    return { success: true, programId: programRef.id };

  } catch (error) {
    console.error("Error al generar el programa:", error);
    if (error instanceof HttpsError) {
      throw error; // Re-lanzar errores Https conocidos
    }
    throw new HttpsError(
      "internal",
      "No se pudo generar el programa.",
      error
    );
  }
});