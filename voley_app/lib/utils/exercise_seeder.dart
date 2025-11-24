import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/catalogos/enums.dart';
import 'package:voley_app/src/models/bd/exercise.dart';

/// ===============================================
/// 🩺 SEEDER – EJERCICIOS DE PREVENCIÓN / REHAB
/// ===============================================

final List<Exercise> rehabExerciseSeed = [

  // =========================================================
  // 🦵 RODILLA – CONTROL / FUERZA SUAVE
  // =========================================================

  Exercise(
    id: 'rehab_terminal_knee_extension_band',
    slug: 'terminal_knee_extension_band',
    name: 'Extensión terminal de rodilla con banda',
    description: 'Trabajo específico de cuádriceps en rangos cortos. '
        'Útil en fases tempranas de rehab de rodilla.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [MuscleGroupId.quads],
    qualityIds: [QualityId.stability, QualityId.strength],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.jump],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.offSeason],
    equipmentIds: [EquipmentId.banda],
    contraindicationIds: [ContraindicationId.rodilla],
  ),

  Exercise(
    id: 'rehab_step_down_low_box',
    slug: 'step_down_low_box',
    name: 'Step-down controlado desde cajón bajo',
    description: 'Descenso lento desde un cajón bajo, controlando la rodilla. '
        'Enfocado en control excéntrico y alineación.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.lunge,
    muscleGroupIds: [MuscleGroupId.quads, MuscleGroupId.glutes],
    qualityIds: [QualityId.stability, QualityId.strength],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.jump, VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.offSeason],
    equipmentIds: [EquipmentId.cajonBajo],
    contraindicationIds: [ContraindicationId.rodilla, ContraindicationId.impactoAlto],
  ),

  Exercise(
    id: 'rehab_wall_squat_isometric',
    slug: 'wall_squat_isometric',
    name: 'Sentadilla isométrica en pared',
    description: 'Sostener posición de media sentadilla contra la pared. '
        'Carga controlada para rodillas y cuádriceps.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [MuscleGroupId.quads, MuscleGroupId.glutes, MuscleGroupId.core],
    qualityIds: [QualityId.stability, QualityId.endurance],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.jump],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.offSeason, TrainingPhaseId.preSeason],
    contraindicationIds: [ContraindicationId.rodilla],
  ),

  // =========================================================
  // 🦶 TOBILLO – PROPIOCEPCIÓN / CONTROL
  // =========================================================

  Exercise(
    id: 'rehab_single_leg_balance_floor',
    slug: 'single_leg_balance_floor',
    name: 'Equilibrio a una pierna en el suelo',
    description: 'Mantener el equilibrio sobre un pie, con mirada al frente. '
        'Se puede progresar cerrando ojos o moviendo brazos.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.carry,
    muscleGroupIds: [MuscleGroupId.calves, MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.landing, VolleyballTransferId.defenseShuffle],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    contraindicationIds: [ContraindicationId.tobillo],
  ),

  Exercise(
    id: 'rehab_single_leg_balance_bosu',
    slug: 'single_leg_balance_bosu',
    name: 'Equilibrio a una pierna sobre BOSU',
    description: 'Variante más inestable del equilibrio unipodal para tobillo. '
        'Sólo usar en fases avanzadas.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.carry,
    muscleGroupIds: [MuscleGroupId.calves, MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.offSeason, TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.bosu],
    contraindicationIds: [ContraindicationId.tobillo],
  ),

  Exercise(
    id: 'rehab_calf_raise_slow',
    slug: 'calf_raise_slow',
    name: 'Elevaciones de talón lentas en el suelo',
    description: 'Trabajo controlado de pantorrillas con énfasis en fase excéntrica. '
        'Relevante para tendón de Aquiles.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [MuscleGroupId.calves],
    qualityIds: [QualityId.strength, QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.jump, VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    contraindicationIds: [ContraindicationId.impactoAlto],
  ),

  // =========================================================
  // 🧠 CORE / LUMBAR – BAJA CARGA
  // =========================================================

  Exercise(
    id: 'rehab_dead_bug',
    slug: 'rehab_dead_bug',
    name: 'Dead Bug (rehab)',
    description: 'Ejercicio de control lumbo-pélvico con brazos y piernas alternados. '
        'Ideal para iniciar trabajo de core en rehab.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.antiRotation,
    muscleGroupIds: [MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.offSeason],
    equipmentIds: [EquipmentId.colchoneta],
    contraindicationIds: [ContraindicationId.lumbar],
  ),

  Exercise(
    id: 'rehab_bird_dog',
    slug: 'bird_dog',
    name: 'Bird Dog',
    description: 'Desde cuadrupedia, extender brazo y pierna contraria. '
        'Trabajo de estabilidad lumbar y control de cadera.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.antiRotation,
    muscleGroupIds: [MuscleGroupId.core, MuscleGroupId.glutes],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
    contraindicationIds: [ContraindicationId.lumbar],
  ),

  Exercise(
    id: 'rehab_side_plank_knees',
    slug: 'side_plank_knees',
    name: 'Plancha lateral apoyando rodillas',
    description: 'Variante de plancha lateral reduciendo la palanca para '
        'tolerar mejor la carga en rehab.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.antiRotation,
    muscleGroupIds: [MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.defenseShuffle, VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
  ),

  // =========================================================
  // 🦴 HOMBRO / MANGUITO ROTADOR
  // =========================================================

  Exercise(
    id: 'rehab_external_rotation_band',
    slug: 'rehab_external_rotation_band',
    name: 'Rotación externa de hombro con banda, codo pegado',
    description: 'Trabajo de rotadores externos con carga ligera. '
        'Muy importante para salud del hombro en atacantes y armadoras.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.rotation,
    muscleGroupIds: [MuscleGroupId.rotatorCuff],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.transverse,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.armSwing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.banda],
    contraindicationIds: [ContraindicationId.hombro],
  ),

  Exercise(
    id: 'rehab_internal_external_90_90',
    slug: 'rehab_internal_external_90_90',
    name: 'Rotaciones internas/externas 90-90 con banda',
    description: 'Rotación de hombro con brazo en 90° abducción y 90° flexión, '
        'imitando posición de armado.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.rotation,
    muscleGroupIds: [MuscleGroupId.rotatorCuff, MuscleGroupId.delts],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.transverse,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.armSwing, VolleyballTransferId.block],
    positions: VolleyballPositionId.values,
    phases: [TrainingPhaseId.offSeason, TrainingPhaseId.preSeason],
    equipmentIds: [EquipmentId.banda],
    contraindicationIds: [ContraindicationId.hombro],
  ),

  Exercise(
    id: 'rehab_scap_push_up_wall',
    slug: 'scap_push_up_wall',
    name: 'Flexiones escapulares en pared',
    description: 'Versión suave de las flexiones escapulares. Menos carga, ideal para rehab.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.push,
    muscleGroupIds: [MuscleGroupId.delts, MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.block, VolleyballTransferId.armSwing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    contraindicationIds: [ContraindicationId.hombro],
  ),

  Exercise(
    id: 'rehab_prone_t_y_w',
    slug: 'prone_t_y_w',
    name: 'T-Y-W en prono',
    description: 'Tumbado boca abajo, levantar brazos formando T, Y y W. '
        'Activa trapecio medio/inferior y rotadores externos.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.pull,
    muscleGroupIds: [MuscleGroupId.delts, MuscleGroupId.rotatorCuff],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.transverse,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.armSwing, VolleyballTransferId.block],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
    contraindicationIds: [ContraindicationId.hombro],
  ),

  // =========================================================
  // 🧍 ESTABILIDAD CADERA / VALGO DINÁMICO
  // =========================================================

  Exercise(
    id: 'rehab_monster_walk',
    slug: 'monster_walk_miniband',
    name: 'Monster Walk con miniband',
    description: 'Caminata en semi-sentadilla con miniband. '
        'Activa glúteo medio y mejora control de rodilla.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.carry,
    muscleGroupIds: [MuscleGroupId.glutes, MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.jump, VolleyballTransferId.defenseShuffle],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.miniband],
    contraindicationIds: [ContraindicationId.rodilla],
  ),

  Exercise(
    id: 'rehab_side_step_miniband',
    slug: 'side_step_miniband',
    name: 'Side steps con miniband',
    description: 'Pasos laterales manteniendo tensión constante en la miniband. '
        'Enfocado en glúteo medio.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.carry,
    muscleGroupIds: [MuscleGroupId.glutes],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.defenseShuffle],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.miniband],
  ),

  Exercise(
    id: 'rehab_glute_bridge',
    slug: 'glute_bridge',
    name: 'Glute Bridge en el suelo',
    description: 'Elevación de cadera tumbado boca arriba. '
        'Enfoque en activación de glúteos con baja carga.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.hinge,
    muscleGroupIds: [MuscleGroupId.glutes, MuscleGroupId.hamstrings, MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.jump, VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
  ),

  // =========================================================
  // 🤸 MOVILIDAD SUAVE (CADERA / TOBILLO / T-SPINE)
  // =========================================================

  Exercise(
    id: 'rehab_hip_flexor_stretch_half_kneeling',
    slug: 'hip_flexor_stretch_half_kneeling',
    name: 'Estiramiento de flexores de cadera en zancada',
    description: 'Rodilla trasera apoyada, pelvis en retroversión suave. '
        'Busca abrir cadera sin dolor.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.movilidad,
    movementPatternId: MovementPatternId.lunge,
    muscleGroupIds: [MuscleGroupId.glutes, MuscleGroupId.hamstrings, MuscleGroupId.core],
    qualityIds: [QualityId.mobility],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.approach],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
  ),

  Exercise(
    id: 'rehab_ankle_dorsiflexion_wall_mobility',
    slug: 'ankle_dorsiflexion_wall_mobility',
    name: 'Movilidad de tobillo de rodilla a pared',
    description: 'Llevar la rodilla hacia la pared manteniendo el talón apoyado. '
        'Mejora dorsiflexión para mejores aterrizajes.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.movilidad,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [MuscleGroupId.calves],
    qualityIds: [QualityId.mobility],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
  ),

  Exercise(
    id: 'rehab_t_spine_open_book',
    slug: 't_spine_open_book',
    name: 'Open Book (apertura torácica)',
    description: 'Tumbado de lado, abrir brazo como si se “abriera un libro”. '
        'Movilidad suave de columna torácica.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.movilidad,
    movementPatternId: MovementPatternId.rotation,
    muscleGroupIds: [MuscleGroupId.core],
    qualityIds: [QualityId.mobility],
    planeId: PlaneId.transverse,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.armSwing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
  ),

];

/// ===============================================
/// 🚀 FUNCIÓN PARA EJECUTAR ESTE SEEDER
/// ===============================================
Future<void> runRehabExerciseSeeder() async {
  final db = FirebaseFirestore.instance;

  for (final ex in rehabExerciseSeed) {
    await db.collection('exercises').doc(ex.id).set(ex.toJson());
  }

  // ignore: avoid_print
  print('🩺 SEEDER REHAB COMPLETADO: ${rehabExerciseSeed.length} ejercicios subidos.');
}
