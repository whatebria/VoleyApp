import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:voley_app/src/catalogos/enums.dart';
import 'package:voley_app/src/models/bd/exercise.dart';

final _uuid = const Uuid();

/// ---- LISTA DE EJERCICIOS ----
/// Todos cumplen EXACTAMENTE el modelo Exercise.
/// Puedes insertarlos directamente a Firestore.
final List<Exercise> exerciseSeed = [
  // -------------------------
  // SENTADILLAS & PIERNAS
  // -------------------------
  Exercise(
    id: _uuid.v4(),
    slug: "sentadilla_back_squat",
    name: "Sentadilla con barra (Back Squat)",
    description: "Ejercicio base de fuerza para tren inferior.",
    videoUrl: "https://youtu.be/aclHkVaku9U",
    levelId: LevelId.intermediate,
    categoryId: CategoryId.strength,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [
      MuscleGroupId.quadriceps,
      MuscleGroupId.glutes,
      MuscleGroupId.hamstrings
    ],
    qualityIds: [QualityId.strength, QualityId.hypertrophy],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.jumpPower],
    positions: [VolleyballPositionId.mb, VolleyballPositionId.op],
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barbell, EquipmentId.rack],
    contraindicationIds: [],
  ),

  Exercise(
    id: _uuid.v4(),
    slug: "sentadilla_frontal",
    name: "Sentadilla frontal",
    description: "Mayor enfoque en cuádriceps y core.",
    videoUrl: "https://youtu.be/2z8JmcrW-As",
    levelId: LevelId.advanced,
    categoryId: CategoryId.strength,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [
      MuscleGroupId.quadriceps,
      MuscleGroupId.glutes,
      MuscleGroupId.core
    ],
    qualityIds: [QualityId.strength],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.jumpPower],
    positions: [VolleyballPositionId.mb, VolleyballPositionId.op],
    phases: [TrainingPhaseId.offSeason],
    equipmentIds: [EquipmentId.barbell],
    contraindicationIds: [],
  ),

  Exercise(
    id: _uuid.v4(),
    slug: "zancadas_lunges",
    name: "Zancadas (Lunges)",
    description: "Ejercicio unilateral clave para estabilidad.",
    videoUrl: "https://youtu.be/QOVaHwm-Q6U",
    levelId: LevelId.beginner,
    categoryId: CategoryId.hypertrophy,
    movementPatternId: MovementPatternId.lunge,
    muscleGroupIds: [
      MuscleGroupId.quadriceps,
      MuscleGroupId.glutes,
    ],
    qualityIds: [QualityId.hypertrophy, QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.jumpPower],
    positions: [VolleyballPositionId.mb, VolleyballPositionId.op],
    phases: [TrainingPhaseId.offSeason],
    equipmentIds: [EquipmentId.dumbbell],
    contraindicationIds: [],
  ),

  Exercise(
    id: _uuid.v4(),
    slug: "hip_thrust_barra",
    name: "Hip Thrust con barra",
    description: "Aislamiento de glúteos y potencia horizontal.",
    videoUrl: "https://youtu.be/LM8XHLYJoYs",
    levelId: LevelId.intermediate,
    categoryId: CategoryId.hypertrophy,
    movementPatternId: MovementPatternId.hinge,
    muscleGroupIds: [
      MuscleGroupId.glutes,
      MuscleGroupId.hamstrings,
    ],
    qualityIds: [QualityId.hypertrophy],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.explosiveness],
    positions: [VolleyballPositionId.op, VolleyballPositionId.oh],
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barbell, EquipmentId.bench],
    contraindicationIds: [],
  ),

  // -------------------------
  // PESO MUERTO & HINGE
  // -------------------------
  Exercise(
    id: _uuid.v4(),
    slug: "deadlift_peso_muerto",
    name: "Peso Muerto",
    description: "Trabajo completo de cadena posterior.",
    videoUrl: "https://youtu.be/op9kVnSso6Q",
    levelId: LevelId.advanced,
    categoryId: CategoryId.strength,
    movementPatternId: MovementPatternId.hinge,
    muscleGroupIds: [
      MuscleGroupId.glutes,
      MuscleGroupId.hamstrings,
      MuscleGroupId.lowerBack
    ],
    qualityIds: [QualityId.strength],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.jumpPower],
    positions: [VolleyballPositionId.op, VolleyballPositionId.mb],
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barbell],
    contraindicationIds: [],
  ),

  Exercise(
    id: _uuid.v4(),
    slug: "romanian_deadlift_rdl",
    name: "Peso muerto rumano (RDL)",
    description: "Mayor énfasis en femoral y glúteos.",
    videoUrl: "https://youtu.be/hH-ZHYQ0E-c",
    levelId: LevelId.intermediate,
    categoryId: CategoryId.hypertrophy,
    movementPatternId: MovementPatternId.hinge,
    muscleGroupIds: [MuscleGroupId.hamstrings, MuscleGroupId.glutes],
    qualityIds: [QualityId.hypertrophy],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [],
    positions: [VolleyballPositionId.mb, VolleyballPositionId.op],
    phases: [TrainingPhaseId.offSeason],
    equipmentIds: [EquipmentId.barbell],
    contraindicationIds: [],
  ),

  // -------------------------
  // EMPUJE HORIZONTAL
  // -------------------------
  Exercise(
    id: _uuid.v4(),
    slug: "press_banca_barra",
    name: "Press de banca con barra",
    description: "Desarrolla fuerza y masa del pectoral y tríceps.",
    videoUrl: "https://youtu.be/rT7DgCr-3pg",
    levelId: LevelId.intermediate,
    categoryId: CategoryId.strength,
    movementPatternId: MovementPatternId.pushHorizontal,
    muscleGroupIds: [
      MuscleGroupId.chest,
      MuscleGroupId.triceps,
      MuscleGroupId.shoulders
    ],
    qualityIds: [QualityId.hypertrophy, QualityId.strength],
    planeId: PlaneId.transverse,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.spikePower],
    positions: [VolleyballPositionId.oh, VolleyballPositionId.op],
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barbell],
    contraindicationIds: [],
  ),

  Exercise(
    id: _uuid.v4(),
    slug: "flexiones_pushups",
    name: "Flexiones de brazos",
    description: "Ejercicio básico adaptable para cualquier nivel.",
    videoUrl: "https://youtu.be/_l3ySVKYVJ8",
    levelId: LevelId.beginner,
    categoryId: CategoryId.hypertrophy,
    movementPatternId: MovementPatternId.pushHorizontal,
    muscleGroupIds: [MuscleGroupId.chest, MuscleGroupId.triceps],
    qualityIds: [QualityId.hypertrophy],
    planeId: PlaneId.transverse,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.spikePower],
    positions: [VolleyballPositionId.oh, VolleyballPositionId.op],
    phases: [TrainingPhaseId.inSeason],
    equipmentIds: [],
    contraindicationIds: [],
  ),

  // -------------------------
  // EMPUJE VERTICAL
  // -------------------------
  Exercise(
    id: _uuid.v4(),
    slug: "press_militar_barra",
    name: "Press militar con barra",
    description: "Clave para remate y bloqueo.",
    videoUrl: "https://youtu.be/B-aVuyhvLHU",
    levelId: LevelId.intermediate,
    categoryId: CategoryId.strength,
    movementPatternId: MovementPatternId.pushVertical,
    muscleGroupIds: [
      MuscleGroupId.shoulders,
      MuscleGroupId.triceps,
    ],
    qualityIds: [QualityId.strength],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.spikePower],
    positions: [VolleyballPositionId.oh, VolleyballPositionId.op],
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barbell],
    contraindicationIds: [],
  ),

  Exercise(
    id: _uuid.v4(),
    slug: "elevaciones_laterales",
    name: "Elevaciones laterales",
    description: "Aislamiento de deltoides laterales.",
    videoUrl: "https://youtu.be/3VcKaXpzqRo",
    levelId: LevelId.beginner,
    categoryId: CategoryId.hypertrophy,
    movementPatternId: MovementPatternId.pushVertical,
    muscleGroupIds: [MuscleGroupId.shoulders],
    qualityIds: [QualityId.hypertrophy],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.shoulderStability],
    positions: [VolleyballPositionId.oh],
    phases: [TrainingPhaseId.inSeason],
    equipmentIds: [EquipmentId.dumbbell],
    contraindicationIds: [],
  ),

  // -------------------------
  // TIRÓN VERTICAL
  // -------------------------
  Exercise(
    id: _uuid.v4(),
    slug: "dominadas_pullups",
    name: "Dominadas (Pull-Ups)",
    description: "Fortalece dorsales y mejora estabilidad del hombro.",
    videoUrl: "https://youtu.be/eGo4IYlbE5g",
    levelId: LevelId.advanced,
    categoryId: CategoryId.strength,
    movementPatternId: MovementPatternId.pullVertical,
    muscleGroupIds: [
      MuscleGroupId.lats,
      MuscleGroupId.biceps,
      MuscleGroupId.shoulders,
    ],
    qualityIds: [QualityId.strength, QualityId.hypertrophy],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.blockReach],
    positions: [VolleyballPositionId.mb, VolleyballPositionId.oh],
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.pullupBar],
    contraindicationIds: [],
  ),

  // -------------------------
  // TIRÓN HORIZONTAL
  // -------------------------
  Exercise(
    id: _uuid.v4(),
    slug: "remo_barra",
    name: "Remo con barra",
    description: "Clave para estabilidad escapular.",
    videoUrl: "https://youtu.be/vT2GjY_Umpw",
    levelId: LevelId.intermediate,
    categoryId: CategoryId.hypertrophy,
    movementPatternId: MovementPatternId.pullHorizontal,
    muscleGroupIds: [
      MuscleGroupId.lats,
      MuscleGroupId.trapezius,
      MuscleGroupId.biceps
    ],
    qualityIds: [QualityId.hypertrophy, QualityId.strength],
    planeId: PlaneId.transverse,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.blockReach],
    positions: [VolleyballPositionId.oh, VolleyballPositionId.mb],
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barbell],
    contraindicationIds: [],
  ),

  // -------------------------
  // CORE
  // -------------------------
  Exercise(
    id: _uuid.v4(),
    slug: "plancha_prone_plank",
    name: "Plancha frontal",
    description: "Core isométrico para estabilidad global.",
    videoUrl: "https://youtu.be/pvIjsG5Svck",
    levelId: LevelId.beginner,
    categoryId: CategoryId.stability,
    movementPatternId: MovementPatternId.core,
    muscleGroupIds: [MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [],
    positions: [VolleyballPositionId.all],
    phases: [TrainingPhaseId.inSeason],
    equipmentIds: [],
    contraindicationIds: [],
  ),

  Exercise(
    id: _uuid.v4(),
    slug: "ab_wheel",
    name: "Ab Wheel",
    description: "Desafío avanzado para el core.",
    videoUrl: "https://youtu.be/i3YJ3yWG7uw",
    levelId: LevelId.advanced,
    categoryId: CategoryId.stability,
    movementPatternId: MovementPatternId.core,
    muscleGroupIds: [
      MuscleGroupId.core,
      MuscleGroupId.shoulders,
    ],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [],
    positions: [VolleyballPositionId.all],
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.abWheel],
    contraindicationIds: [],
  ),

  // -------------------------
  // OLÍMPICOS
  // -------------------------
  Exercise(
    id: _uuid.v4(),
    slug: "power_clean",
    name: "Power Clean",
    description: "Desarrollo máximo de potencia explosiva.",
    videoUrl: "https://youtu.be/Q2QYz0ePcvE",
    levelId: LevelId.advanced,
    categoryId: CategoryId.power,
    movementPatternId: MovementPatternId.hinge,
    muscleGroupIds: [
      MuscleGroupId.glutes,
      MuscleGroupId.quadriceps,
      MuscleGroupId.shoulders,
      MuscleGroupId.trapezius
    ],
    qualityIds: [QualityId.power],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.jumpPower],
    positions: [VolleyballPositionId.op, VolleyballPositionId.mb],
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barbell],
    contraindicationIds: [],
  ),

  Exercise(
    id: _uuid.v4(),
    slug: "push_press",
    name: "Push Press",
    description: "Transferencia excelente al remate.",
    videoUrl: "https://youtu.be/iaBVSJm78ko",
    levelId: LevelId.intermediate,
    categoryId: CategoryId.power,
    movementPatternId: MovementPatternId.pushVertical,
    muscleGroupIds: [
      MuscleGroupId.shoulders,
      MuscleGroupId.triceps,
      MuscleGroupId.core
    ],
    qualityIds: [QualityId.power],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.spikePower],
    positions: [VolleyballPositionId.oh, VolleyballPositionId.op],
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barbell],
    contraindicationIds: [],
  ),
];

/// --------------------------------------------
/// FUNCIÓN PARA SUBIR TODO A FIRESTORE
/// --------------------------------------------
Future<void> seedExercisesToFirestore() async {
  final db = FirebaseFirestore.instance;

  for (final ex in exerciseSeed) {
    await db.collection('exercises').doc(ex.id).set(ex.toJson());
  }

  print("Seeder completado con ${exerciseSeed.length} ejercicios.");
}
