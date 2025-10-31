import * as admin from "firebase-admin";
// 1. Cambia la importación a v2
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as functions from "firebase-functions";

// Inicializa Firebase Admin para que la función pueda acceder a Firestore
admin.initializeApp();
const db = admin.firestore();

// --- 1. Definición de Tipos (Interfaces de TypeScript) ---
// Define interfaces que coincidan con tus modelos de Dart y Firestore
// Esto nos da autocompletado y seguridad de tipos.

interface Tournament {
  date: admin.firestore.Timestamp; // Así se manejan fechas en Firestore Admin
  name: string;
}

interface PlayerProfile {
  id: string;
  skillLevel: string;
  goals: string[];
  weaknesses: string[];
  availableDays: number;
  equipment: string[];
  tournaments: Tournament[];
  // ...cualquier otro campo que tengas
}

interface Exercise {
  id: string;
  name: string;
  category: string;
  difficulty: string;
  equipmentNeeded: string;
  tags: string[];
}

interface WorkoutExercise {
  exerciseId: string; // Guardamos solo el ID, no el objeto entero
  name: string;
  sets: number;
  reps: string;
  intensity: string;
}

interface Session {
  focus: string;
  exercises: WorkoutExercise[];
}

interface Microcycle {
  weekNumber: number;
  sessions: Session[];
}

interface Mesocycle {
  phase: "Base" | "Build" | "Peak" | "Intro";
  durationWeeks: number;
  microcycles: Microcycle[];
}

interface Program {
  id: string;
  source: "Automático";
  startDate: admin.firestore.Timestamp;
  endDate: admin.firestore.Timestamp;
  mesocycles: Mesocycle[];
}

// --- 2. Lógica de Generación Pura (Tu Algoritmo) ---
// Estas son las funciones "cerebro", portadas de tu Dart a TypeScript.

function _createMesocycles(weeksToTournament: number): Mesocycle[] {
  // Esta es tu lógica de periodización.
  // Ejemplo:
  if (weeksToTournament <= 4) {
    return [{phase: "Peak", durationWeeks: weeksToTournament, microcycles: []}];
  }
  const peakWeeks = 2;
  const buildWeeks = 4;
  const baseWeeks = weeksToTournament - peakWeeks - buildWeeks;

  const mesos: Mesocycle[] = [];
  if (baseWeeks > 0) {
    mesos.push({phase: "Base", durationWeeks: baseWeeks, microcycles: []});
  }
  mesos.push({phase: "Build", durationWeeks: buildWeeks, microcycles: []});
  mesos.push({phase: "Peak", durationWeeks: peakWeeks, microcycles: []});

  return mesos;
}

function _generateMicrocycles(
  profile: PlayerProfile,
  meso: Mesocycle,
  allExercises: Exercise[]
): Microcycle[] {
  const microcycles: Microcycle[] = [];

  // Por cada semana en el mesociclo...
  for (let i = 0; i < meso.durationWeeks; i++) {
    // Lógica para decidir el split (ej. 3 días = Full Body)
    const availableDays = profile.availableDays;
    const focuses = availableDays <= 3 ?
      ["Full Body", "Full Body", "Full Body"] :
      ["Upper", "Lower", "Push", "Pull"];

    const sessions: Session[] = focuses.map((focus) => {
      // --- Lógica de EVALUACIÓN ---
      // 1. Filtrar ejercicios por equipo, nivel, etc.
      const possibleExercises = allExercises.filter(
        (ex) =>
          profile.equipment.includes(ex.equipmentNeeded) &&
          ex.difficulty === profile.skillLevel // (o una lógica más compleja)
      );

      // 2. Elegir ejercicios basados en 'focus' y 'phase'
      const workoutExercises: WorkoutExercise[] = [];

      const mainExercise =
      possibleExercises.find((ex) => ex.category === "Squat") ||
      possibleExercises[0];
      if (mainExercise) {
        workoutExercises.push({
          exerciseId: mainExercise.id,
          name: mainExercise.name,
          sets: meso.phase === "Base" ? 4 : 3, // Progresión simple
          reps: "8-12",
          intensity: "RPE 7",
        });
      }

      return {focus: focus, exercises: workoutExercises};
    });

    microcycles.push({
      weekNumber: i + 1, // (Esto debería ser el número de semana global)
      sessions: sessions,
    });
  }
  return microcycles;
}

function generateProgram(
  profile: PlayerProfile,
  allExercises: Exercise[]
): Program {
  // Tu lógica de Dart, ahora en TS
  // Encontrar la fecha del primer torneo
  const now = admin.firestore.Timestamp.now();
  const futureTournaments = profile.tournaments
    .filter((t) => t.date > now)
    .sort((a, b) => a.date.toMillis() -
    b.date.toMillis());

  const nextTournament = futureTournaments.length > 0 ?
    futureTournaments[0] : null;

  // Determinar semanas hasta el torneo
  let weeksToTournament = 12; // Default
  if (nextTournament) {
    const diffMillis = nextTournament.date.toMillis() - now.toMillis();
    weeksToTournament = Math.floor(diffMillis / (1000 * 60 * 60 * 24 * 7));
  }

  // Crear bloques según distancia al torneo
  const mesocycles = _createMesocycles(weeksToTournament);

  // Generar los microciclos y sesiones según perfil
  for (const meso of mesocycles) {
    meso.microcycles = _generateMicrocycles(profile, meso, allExercises);
  }

  const startDate = now;
  const endDateMillis =
    startDate.toMillis() + weeksToTournament * 7 * 24 * 60 * 60 * 1000;
  const endDate = admin.firestore.Timestamp.fromMillis(endDateMillis);

  return {
    id: `prog_${startDate.toMillis()}`, // El ID se puede poner en el documento
    source: "Automático",
    startDate: startDate,
    endDate: endDate,
    mesocycles: mesocycles,
  };
}

export const generateMyProgram = onCall(async (request) => {
  // 3. 'context.auth.uid' ahora es 'request.auth.uid'
  const userId = request.auth?.uid;

  if (!userId) {
    // 4. HttpsError se importa directamente
    throw new HttpsError(
      "unauthenticated",
      "El usuario debe estar autenticado."
    );
  }

  try {
    // 2. Recolección de Datos (Eficiente, en el servidor)
    console.log(`Iniciando generación para usuario: ${userId}`);
    // 2a. Obtener el perfil del usuario
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found",
        "Perfil de usuario no encontrado.");
    }
    const profile = userDoc.data() as PlayerProfile;
    // 2b. Obtener TODOS los ejercicios
    const exercisesSnapshot = await db.collection("exercises").get();
    const allExercises: Exercise[] =
    exercisesSnapshot.docs.map((doc) => doc.data() as Exercise);

    console.log(`Perfil cargado. ${allExercises.length} ejercicios cargados.`);

    // 3. Ejecución de Lógica (El "Cerebro")
    const newProgram = generateProgram(profile, allExercises);
    console.log("Programa generado.");

    // 4. Guardado en Firestore
    // Convertimos el objeto 'Program' a un objeto plano para guardar
    // (Firestore no guarda 'undefined' o métodos de clase)
    const programData = JSON.parse(JSON.stringify(newProgram));

    const programRef = await db
      .collection("users")
      .doc(userId)
      .collection("programs")
      .add(programData);

    console.log(`Programa guardado con ID: ${programRef.id}`);

    // 5. Devolver éxito a la app de Flutter
    return {success: true, programId: programRef.id};
  } catch (error) {
    console.error("Error al generar el programa:", error);
    // Informar a Flutter que algo salió mal
    throw new functions.https.HttpsError(
      "internal",
      "No se pudo generar el programa.",
      error
    );
  }
}
);
