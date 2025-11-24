import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/catalogos/enums.dart';
import 'package:voley_app/src/models/bd/exercise.dart';

/// ===============================================================
/// 🚀 SEEDER OFICIAL MAAP — Fuerza, Hipertrofia, Potencia y Vóley
/// ===============================================================

final List<Exercise> exerciseSeed = [

  // ===========================================================
  // 🦵 SENTADILLAS Y CUÁDRICEPS
  // ===========================================================

  Exercise(
    id: 'ex_back_squat',
    slug: 'back_squat',
    name: 'Back Squat (Sentadilla con barra)',
    description: 'Ejercicio base de fuerza para piernas y salto.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [MuscleGroupId.quads, MuscleGroupId.glutes, MuscleGroupId.core],
    qualityIds: [QualityId.strength, QualityId.power],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.jump, VolleyballTransferId.block],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.offSeason, TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barra],
  ),

  Exercise(
    id: 'ex_front_squat',
    slug: 'front_squat',
    name: 'Front Squat (Sentadilla frontal)',
    description: 'Mayor énfasis en cuádriceps y core. Excelente transferencia al salto.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [MuscleGroupId.quads, MuscleGroupId.glutes, MuscleGroupId.core],
    qualityIds: [QualityId.strength, QualityId.power],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.jump],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barra],
  ),

  Exercise(
    id: 'ex_goblet_squat',
    slug: 'goblet_squat',
    name: 'Goblet Squat',
    description: 'Gran ejercicio para técnica, estabilidad y volumen.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [MuscleGroupId.quads, MuscleGroupId.glutes],
    qualityIds: [QualityId.stability, QualityId.strength],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.jump],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.offSeason, TrainingPhaseId.rehab],
    equipmentIds: [EquipmentId.kettlebell],
  ),

  Exercise(
    id: 'ex_bulgarian_split_squat',
    slug: 'bulgarian_split_squat',
    name: 'Bulgarian Split Squat',
    description: 'Unilateral, extremadamente transferible a salto y cambios de dirección.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.lunge,
    muscleGroupIds: [MuscleGroupId.quads, MuscleGroupId.glutes, MuscleGroupId.hamstrings],
    qualityIds: [QualityId.strength, QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.jump, VolleyballTransferId.defenseShuffle],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.offSeason, TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.mancuernas, EquipmentId.banco],
  ),


  // ===========================================================
  // 🔥 CADENA POSTERIOR – BISAGRA
  // ===========================================================

  Exercise(
    id: 'ex_rdl',
    slug: 'rdl_barbell',
    name: 'Peso muerto rumano',
    description: 'Clave para hipertrofia de glúteos e isquios.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.hinge,
    muscleGroupIds: [MuscleGroupId.hamstrings, MuscleGroupId.glutes, MuscleGroupId.core],
    qualityIds: [QualityId.strength, QualityId.power],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.jump],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.offSeason, TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barra],
  ),

  Exercise(
    id: 'ex_hip_thrust',
    slug: 'hip_thrust',
    name: 'Hip Thrust',
    description: 'Máxima activación de glúteos. Transferencia directa al salto.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.hinge,
    muscleGroupIds: [MuscleGroupId.glutes, MuscleGroupId.hamstrings],
    qualityIds: [QualityId.strength, QualityId.power],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [
      VolleyballTransferId.jump,
      VolleyballTransferId.approach,
    ],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barra, EquipmentId.banco],
  ),


  // ===========================================================
  // 🏋️‍♂️ EMPUJES – PECTORAL / HOMBRO
  // ===========================================================

  Exercise(
    id: 'ex_bench_press',
    slug: 'bench_press',
    name: 'Bench Press',
    description: 'Clásico ejercicio de empuje para fuerza máxima.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.push,
    muscleGroupIds: [
      MuscleGroupId.delts,
      MuscleGroupId.chest,
      MuscleGroupId.triceps,
    ],
    qualityIds: [QualityId.strength],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.armSwing],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.offSeason],
    equipmentIds: [EquipmentId.barra],
  ),

  Exercise(
    id: 'ex_incline_db_press',
    slug: 'incline_db_press',
    name: 'Press inclinado con mancuernas',
    description: 'Gran estímulo para deltoides y pectoral alto.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.push,
    muscleGroupIds: [
      MuscleGroupId.delts,
      MuscleGroupId.chest,
      MuscleGroupId.triceps,
    ],
    qualityIds: [QualityId.hipertrofia],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.armSwing],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.mancuernas],
  ),


  // ===========================================================
  // 🏋️‍♀️ TIRONES – ESPALDA
  // ===========================================================

  Exercise(
    id: 'ex_lat_pulldown',
    slug: 'lat_pulldown',
    name: 'Jalón en polea',
    description: 'Excelente para espalda y control escapular.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.pull,
    muscleGroupIds: [
      MuscleGroupId.lats,
      MuscleGroupId.delts,
      MuscleGroupId.core,
    ],
    qualityIds: [QualityId.hipertrofia],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.armSwing],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.inSeason],
    equipmentIds: [EquipmentId.polea],
  ),

  Exercise(
    id: 'ex_seated_row',
    slug: 'seated_row',
    name: 'Remo sentado',
    description: 'Remo horizontal para control escapular y fuerza del tronco.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.pull,
    muscleGroupIds: [
      MuscleGroupId.upperBack,
      MuscleGroupId.biceps,
      MuscleGroupId.core,
    ],
    qualityIds: [QualityId.hipertrofia],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [
      VolleyballTransferId.block,
      VolleyballTransferId.armSwing,
    ],
    positions: VolleyballPositionId.values,
    equipmentIds: [EquipmentId.polea],
  ),

  // ===========================================================
  // 💥 CORE / ESTABILIDAD
  // ===========================================================

  Exercise(
    id: 'ex_plank',
    slug: 'plank',
    name: 'Plancha',
    description: 'Control anti-extensión y base para salto y bloqueo.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.core,
    movementPatternId: MovementPatternId.antiRotation,
    muscleGroupIds: [MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [
      VolleyballTransferId.landing,
      VolleyballTransferId.block,
    ],
    positions: VolleyballPositionId.values,
    phases: [
      TrainingPhaseId.offSeason,
      TrainingPhaseId.preSeason,
      TrainingPhaseId.rehab,
    ],
    equipmentIds: [EquipmentId.colchoneta],
  ),

];


/// ===============================================================
/// 🚀 FUNCIÓN PARA EJECUTAR EL SEEDER
/// ===============================================================

Future<void> runExerciseSeeder() async {
  final db = FirebaseFirestore.instance;

  for (final ex in exerciseSeed) {
    await db.collection('exercises').doc(ex.id).set(ex.toJson());
  }

  print('🔥 SEEDER COMPLETADO: ${exerciseSeed.length} ejercicios subidos.');
}
