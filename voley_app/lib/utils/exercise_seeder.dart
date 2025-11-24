import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/catalogos/enums.dart';
import 'package:voley_app/src/models/bd/exercise.dart';

// ===========================================================
// SEEDER COMPLETO DE EJERCICIOS
// Para fuerza, hipertrofia y transferencia al vóleibol.
// ===========================================================

final List<Exercise> exerciseSeed = [

  // ===========================================================
  // SENTADILLAS Y CUÁDRICEPS
  // ===========================================================

  Exercise(
    id: 'ex_back_squat',
    slug: 'back_squat',
    name: 'Sentadilla con barra (Back Squat)',
    description: 'Ejercicio base de fuerza para piernas y salto.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [
      MuscleGroupId.quads,
      MuscleGroupId.glutes,
      MuscleGroupId.core,
    ],
    qualityIds: [
      QualityId.fuerzaMaxima,
      QualityId.hipertrofia,
    ],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [
      VolleyballTransferId.saltoVertical,
      VolleyballTransferId.bloqueo,
    ],
    positions: VolleyballPositionId.values,
    phases: [
      TrainingPhaseId.offSeason,
      TrainingPhaseId.preSeason,
    ],
    equipmentIds: [EquipmentId.barra],
  ),

  Exercise(
    id: 'ex_front_squat',
    slug: 'front_squat',
    name: 'Sentadilla frontal',
    description: 'Mayor énfasis en cuádriceps y core. Excelente para remate.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [
      MuscleGroupId.quads,
      MuscleGroupId.glutes,
      MuscleGroupId.core,
    ],
    qualityIds: [QualityId.fuerzaMaxima, QualityId.hipertrofia],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.saltoVertical],
    positions: VolleyballPositionId.values,
    phases: [
      TrainingPhaseId.offSeason,
    ],
    equipmentIds: [EquipmentId.barra],
  ),

  Exercise(
    id: 'ex_goblet_squat',
    slug: 'goblet_squat',
    name: 'Sentadilla Goblet',
    description: 'Gran ejercicio para técnica y volumen.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [
      MuscleGroupId.quads,
      MuscleGroupId.glutes,
      MuscleGroupId.core
    ],
    qualityIds: [
      QualityId.hipertrofia,
      QualityId.controlMotor,
    ],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.saltoVertical],
    positions: VolleyballPositionId.values,
    phases: [
      TrainingPhaseId.offSeason,
      TrainingPhaseId.rehab,
    ],
    equipmentIds: [EquipmentId.kettlebell, EquipmentId.mancuernas],
  ),

  Exercise(
    id: 'ex_bulgarian_split_squat',
    slug: 'bulgarian_split_squat',
    name: 'Sentadilla búlgara',
    description: 'Unilateral y extremadamente transferible a salto y COD.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.lunge,
    muscleGroupIds: [
      MuscleGroupId.quads,
      MuscleGroupId.glutes,
      MuscleGroupId.hamstrings,
    ],
    qualityIds: [
      QualityId.hipertrofia,
      QualityId.estabilidad,
    ],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [
      VolleyballTransferId.saltoVertical,
      VolleyballTransferId.cambioDeDireccion
    ],
    positions: VolleyballPositionId.values,
    phases: [
      TrainingPhaseId.offSeason,
      TrainingPhaseId.preSeason,
    ],
    equipmentIds: [EquipmentId.banco, EquipmentId.mancuernas],
  ),

  Exercise(
    id: 'ex_walking_lunge',
    slug: 'walking_lunge',
    name: 'Zancadas caminando',
    description: 'Gran volumen para cuádriceps y glúteos.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.lunge,
    muscleGroupIds: [
      MuscleGroupId.quads,
      MuscleGroupId.glutes,
      MuscleGroupId.hamstrings,
    ],
    qualityIds: [QualityId.hipertrofia],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.desplazamientoLateral],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.mancuernas],
  ),


  // ===========================================================
  // BISAGRA – CADENA POSTERIOR
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
    muscleGroupIds: [
      MuscleGroupId.hamstrings,
      MuscleGroupId.glutes,
      MuscleGroupId.core
    ],
    qualityIds: [
      QualityId.fuerzaMaxima,
      QualityId.hipertrofia,
    ],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.saltoVertical],
    positions: VolleyballPositionId.values,
    phases: [
      TrainingPhaseId.offSeason,
      TrainingPhaseId.preSeason,
    ],
    equipmentIds: [EquipmentId.barra],
  ),

  Exercise(
    id: 'ex_hip_thrust',
    slug: 'hip_thrust',
    name: 'Hip Thrust',
    description: 'Top 1 para glúteos. Transferencia directa al remate.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.hinge,
    muscleGroupIds: [
      MuscleGroupId.glutes,
      MuscleGroupId.hamstrings,
      MuscleGroupId.core
    ],
    qualityIds: [
      QualityId.hipertrofia,
      QualityId.potencia
    ],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [
      VolleyballTransferId.saltoVertical,
      VolleyballTransferId.remate
    ],
    positions: VolleyballPositionId.values,
    phases: [
      TrainingPhaseId.offSeason,
      TrainingPhaseId.preSeason
    ],
    equipmentIds: [EquipmentId.barra, EquipmentId.banco],
  ),

  // ===========================================================
  // EMPUJES – PECTORAL / HOMBRO
  // ===========================================================

  Exercise(
    id: 'ex_bench_press',
    slug: 'bench_press',
    name: 'Press banca',
    description: 'Clásico de fuerza en tren superior.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.horizontalPush,
    muscleGroupIds: [
      MuscleGroupId.chest,
      MuscleGroupId.triceps,
      MuscleGroupId.shoulders
    ],
    qualityIds: [
      QualityId.fuerzaMaxima,
      QualityId.hipertrofia
    ],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.remate],
    positions: VolleyballPositionId.values,
    phases: [
      TrainingPhaseId.offSeason,
      TrainingPhaseId.preSeason
    ],
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
    movementPatternId: MovementPatternId.horizontalPush,
    muscleGroupIds: [
      MuscleGroupId.chest,
      MuscleGroupId.shoulders,
      MuscleGroupId.triceps,
    ],
    qualityIds: [QualityId.hipertrofia],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.remate],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.mancuernas],
  ),

  // ===========================================================
  // TIRONES – ESPALDA
  // ===========================================================

  Exercise(
    id: 'ex_lat_pulldown',
    slug: 'lat_pulldown',
    name: 'Jalón en polea',
    description: 'Excelente para espalda y control escapular',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.verticalPull,
    muscleGroupIds: [
      MuscleGroupId.lats,
      MuscleGroupId.biceps,
      MuscleGroupId.upperBack,
    ],
    qualityIds: [QualityId.hipertrofia],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.remate],
    positions: VolleyballPositionId.values,
    equipmentIds: [EquipmentId.polea],
  ),

  Exercise(
    id: 'ex_seated_row',
    slug: 'seated_row',
    name: 'Remo sentado en polea',
    description: 'Tren superior fuerte para bloqueo y remate.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.horizontalPull,
    muscleGroupIds: [
      MuscleGroupId.upperBack,
      MuscleGroupId.biceps,
      MuscleGroupId.lats,
    ],
    qualityIds: [QualityId.hipertrofia],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [
      VolleyballTransferId.bloqueo,
      VolleyballTransferId.remate
    ],
    positions: VolleyballPositionId.values,
    equipmentIds: [EquipmentId.polea],
  ),

  // ===========================================================
  // HOMBRO / ESTABILIDAD
  // ===========================================================

  Exercise(
    id: 'ex_landmine_press',
    slug: 'landmine_press',
    name: 'Landmine Press',
    description: 'Seguro y excelente para hombro y estabilidad del core.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.verticalPush,
    muscleGroupIds: [
      MuscleGroupId.shoulders,
      MuscleGroupId.triceps,
      MuscleGroupId.core,
    ],
    qualityIds: [
      QualityId.fuerzaMaxima,
      QualityId.estabilidad
    ],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [
      VolleyballTransferId.remate,
      VolleyballTransferId.saquePotente
    ],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.barra],
  ),

  // ===========================================================
  // BRAZOS
  // ===========================================================

  Exercise(
    id: 'ex_bicep_curl',
    slug: 'bicep_curl',
    name: 'Curl de bíceps con mancuernas',
    description: 'Ejercicio simple para brazos.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.horizontalPull,
    muscleGroupIds: [MuscleGroupId.biceps],
    qualityIds: [QualityId.hipertrofia],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    positions: VolleyballPositionId.values,
    equipmentIds: [EquipmentId.mancuernas],
  ),

  Exercise(
    id: 'ex_triceps_pushdown',
    slug: 'triceps_pushdown',
    name: 'Extensión de tríceps en polea',
    description: 'Aísla tríceps y ayuda al remate.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.hipertrofia,
    movementPatternId: MovementPatternId.verticalPush,
    muscleGroupIds: [MuscleGroupId.triceps],
    qualityIds: [QualityId.hipertrofia],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    equipmentIds: [EquipmentId.polea],
  ),

  // ===========================================================
  // CORE
  // ===========================================================

  Exercise(
    id: 'ex_plank',
    slug: 'plank',
    name: 'Plancha',
    description: 'Control anti-extensión y base para salto.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.estabilidad,
    movementPatternId: MovementPatternId.coreAntiExtension,
    muscleGroupIds: [MuscleGroupId.core],
    qualityIds: [QualityId.estabilidad],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    positions: VolleyballPositionId.values,
    phases: [
      TrainingPhaseId.offSeason,
      TrainingPhaseId.preSeason,
      TrainingPhaseId.rehab
    ],
    equipmentIds: [EquipmentId.colchoneta],
  ),

];


/// ===========================================================
///  🔥 FUNCIÓN PARA EJECUTAR EL SEEDER
/// ===========================================================

Future<void> runExerciseSeeder() async {
  final db = FirebaseFirestore.instance;

  for (final ex in exerciseSeed) {
    await db.collection('exercises').doc(ex.id).set(ex.toJson());
  }

  print('SEEDER COMPLETADO → ${exerciseSeed.length} ejercicios subidos.');
}
