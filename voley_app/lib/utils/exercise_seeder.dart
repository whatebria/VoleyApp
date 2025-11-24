// lib/seeders/rehab_exercise_seeder.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/catalogos/enums.dart';
import 'package:voley_app/src/models/bd/exercise.dart';

/// 🩺 Ejercicios de PREVENCIÓN / REHAB específicos para vóley
///
/// Todos usan: categoryId: CategoryId.prevencion
final List<Exercise> rehabExercises = [

  // =========================
  // 1) HOMBRO / MANGUITO ROTADOR
  // =========================

  Exercise(
    id: 'prev_band_external_rotation_0',
    slug: 'band_external_rotation_side',
    name: 'Rotación Externa de Hombro con Banda (de pie)',
    description:
        'De pie, codo a 90° pegado al cuerpo, rotar hacia afuera contra banda. Clásico de manguito rotador.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.rotation,
    muscleGroupIds: [MuscleGroupId.rotatorCuff],
    qualityIds: [QualityId.stability, QualityId.mobility],
    planeId: PlaneId.transverse,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.armSwing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.banda],
    contraindicationIds: [ContraindicationId.hombro],
  ),

  Exercise(
    id: 'prev_band_internal_rotation_1',
    slug: 'band_internal_rotation_side',
    name: 'Rotación Interna de Hombro con Banda',
    description:
        'De pie, codo a 90° pegado al cuerpo, rotar hacia adentro contra banda. Complemento de la rotación externa.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.rotation,
    muscleGroupIds: [MuscleGroupId.rotatorCuff],
    qualityIds: [QualityId.stability, QualityId.mobility],
    planeId: PlaneId.transverse,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.armSwing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.banda],
    contraindicationIds: [ContraindicationId.hombro],
  ),

  Exercise(
    id: 'prev_scap_pushup_2',
    slug: 'scap_pushup',
    name: 'Flexión Escapular (Scap Push-Up)',
    description:
        'Desde posición de plancha, mover solo escápulas (protracción/retracción) sin flexionar codos.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.push,
    muscleGroupIds: [MuscleGroupId.rotatorCuff, MuscleGroupId.delts, MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.armSwing, VolleyballTransferId.block],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
    contraindicationIds: [ContraindicationId.hombro],
  ),

  Exercise(
    id: 'prev_wall_slide_3',
    slug: 'wall_slide',
    name: 'Wall Slide',
    description:
        'De espaldas a la pared, deslizar antebrazos hacia arriba manteniendo contacto. Mejora movilidad y control escapular.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.push,
    muscleGroupIds: [MuscleGroupId.delts, MuscleGroupId.rotatorCuff],
    qualityIds: [QualityId.mobility, QualityId.stability],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.block, VolleyballTransferId.armSwing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [],
    contraindicationIds: [ContraindicationId.hombro],
  ),

  Exercise(
    id: 'prev_prone_ytw_4',
    slug: 'prone_ytw',
    name: 'Y-T-W Prono en Banco',
    description:
        'Tumbado boca abajo, elevar brazos en posiciones Y, T y W. Excelente para estabilizadores de escápula.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.pull,
    muscleGroupIds: [MuscleGroupId.rotatorCuff, MuscleGroupId.delts],
    qualityIds: [QualityId.stability, QualityId.mobility],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.armSwing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.banco, EquipmentId.colchoneta],
    contraindicationIds: [ContraindicationId.hombro],
  ),

  Exercise(
    id: 'prev_face_pull_band_5',
    slug: 'face_pull_band',
    name: 'Face Pull con Banda',
    description:
        'Remo alto hacia la cara con banda elástica. Trabaja deltoides posteriores y rotadores externos.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.pull,
    muscleGroupIds: [MuscleGroupId.rotatorCuff, MuscleGroupId.delts],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.transverse,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.armSwing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.banda],
    contraindicationIds: [ContraindicationId.hombro],
  ),

  // =========================
  // 2) RODILLA / CADERA
  // =========================

  Exercise(
    id: 'prev_spanish_squat_6',
    slug: 'spanish_squat',
    name: 'Spanish Squat con Banda',
    description:
        'Banda por detrás de las rodillas, torso erguido. Foco en cuádriceps y control de rodilla, muy usado en rehab.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [MuscleGroupId.quads],
    qualityIds: [QualityId.stability, QualityId.strength],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.banda],
    contraindicationIds: [ContraindicationId.rodilla],
  ),

  Exercise(
    id: 'prev_terminal_knee_ext_7',
    slug: 'terminal_knee_extension',
    name: 'Extensión Terminal de Rodilla con Banda',
    description:
        'Banda detrás de la rodilla, extender la pierna enderezando la rodilla. Enfocado en vasto medial.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [MuscleGroupId.quads],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.banda],
    contraindicationIds: [ContraindicationId.rodilla],
  ),

  Exercise(
    id: 'prev_copenhagen_side_plank_8',
    slug: 'copenhagen_side_plank',
    name: 'Plancha Copenhague',
    description:
        'Plancha lateral con la pierna superior apoyada en banco. Trabaja aductores y core, usada en prevención de cadera/ingles.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.antiRotation,
    muscleGroupIds: [MuscleGroupId.core, MuscleGroupId.glutes],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.banco, EquipmentId.colchoneta],
    contraindicationIds: [ContraindicationId.rodilla],
  ),

  Exercise(
    id: 'prev_nordic_hamstring_9',
    slug: 'nordic_hamstring',
    name: 'Nordic Hamstring Curl',
    description:
        'Desde arrodillado, descender el tronco controlando con isquiosurales. Excéntrico clave de prevención de muslo posterior.',
    videoUrl: '',
    levelId: LevelId.advanced,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.hinge,
    muscleGroupIds: [MuscleGroupId.hamstrings],
    qualityIds: [QualityId.strength, QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta, EquipmentId.banco],
    contraindicationIds: [ContraindicationId.rodilla],
  ),

  Exercise(
    id: 'prev_single_leg_bridge_10',
    slug: 'single_leg_glute_bridge',
    name: 'Glute Bridge Unilateral',
    description:
        'Puente de glúteos con una sola pierna. Mejora activación de glúteo y estabilidad de cadera.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.hinge,
    muscleGroupIds: [MuscleGroupId.glutes, MuscleGroupId.hamstrings, MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.jump, VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
    contraindicationIds: [],
  ),

  Exercise(
    id: 'prev_step_down_controlled_11',
    slug: 'step_down_controlado',
    name: 'Step-Down Controlado',
    description:
        'Bajar lentamente desde un cajón o banco con una pierna. Trabaja control excéntrico de rodilla y cadera.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.lunge,
    muscleGroupIds: [MuscleGroupId.quads, MuscleGroupId.glutes],
    qualityIds: [QualityId.stability, QualityId.strength],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.caja, EquipmentId.banco],
    contraindicationIds: [ContraindicationId.rodilla],
  ),

  Exercise(
    id: 'prev_lateral_band_walk_12',
    slug: 'lateral_band_walk',
    name: 'Caminata Lateral con Miniband',
    description:
        'Caminata lateral con banda en las rodillas o tobillos. Enfocado en glúteo medio y control de rodilla.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.lunge,
    muscleGroupIds: [MuscleGroupId.glutes],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.defenseShuffle],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.miniband],
    contraindicationIds: [],
  ),

  // =========================
  // 3) TOBILLO / PIE
  // =========================

  Exercise(
    id: 'prev_single_leg_balance_13',
    slug: 'single_leg_balance',
    name: 'Equilibrio a Una Pierna',
    description:
        'Mantenerse de pie en una pierna, con o sin movimiento de brazos. Base de propiocepción de tobillo.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.landing,
    muscleGroupIds: [MuscleGroupId.calves, MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.landing, VolleyballTransferId.defenseShuffle],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [],
    contraindicationIds: [ContraindicationId.tobillo],
  ),

  Exercise(
    id: 'prev_single_leg_balance_reach_14',
    slug: 'single_leg_balance_reach',
    name: 'Equilibrio a Una Pierna con Alcance',
    description:
        'Desde apoyo unipodal, tocar conos o puntos en diferentes direcciones con la pierna libre.',
    videoUrl: '',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.lunge,
    muscleGroupIds: [MuscleGroupId.calves, MuscleGroupId.glutes, MuscleGroupId.core],
    qualityIds: [QualityId.stability, QualityId.agility],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.landing, VolleyballTransferId.defenseShuffle],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.conos],
    contraindicationIds: [ContraindicationId.tobillo],
  ),

  Exercise(
    id: 'prev_calf_raise_unilateral_15',
    slug: 'single_leg_calf_raise',
    name: 'Elevación de Talón Unilateral',
    description:
        'Subir y bajar el talón apoyado en un borde, con una pierna. Refuerza musculatura del tríceps sural.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [MuscleGroupId.calves],
    qualityIds: [QualityId.stability, QualityId.strength],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.jump, VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [],
    contraindicationIds: [ContraindicationId.tobillo],
  ),

  // =========================
  // 4) CORE / LUMBAR
  // =========================

  Exercise(
    id: 'prev_dead_bug_16',
    slug: 'dead_bug',
    name: 'Dead Bug',
    description:
        'Tumbado boca arriba, alternar brazos y piernas manteniendo zona lumbar pegada al suelo.',
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
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
    contraindicationIds: [ContraindicationId.lumbar],
  ),

  Exercise(
    id: 'prev_bird_dog_17',
    slug: 'bird_dog',
    name: 'Bird Dog',
    description:
        'En cuadrupedia, extender brazo y pierna contraria manteniendo pelvis estable. Clásico de estabilidad lumbo-pélvica.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.antiRotation,
    muscleGroupIds: [MuscleGroupId.core, MuscleGroupId.erectors, MuscleGroupId.glutes],
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
    id: 'prev_side_plank_18',
    slug: 'side_plank',
    name: 'Plancha Lateral',
    description:
        'Isometría en apoyo lateral de antebrazo y pies. Refuerza oblicuos y control lateral del tronco.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.antiRotation,
    muscleGroupIds: [MuscleGroupId.core],
    qualityIds: [QualityId.stability],
    planeId: PlaneId.frontal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
    contraindicationIds: [ContraindicationId.lumbar],
  ),

  Exercise(
    id: 'prev_plank_19',
    slug: 'front_plank',
    name: 'Plancha Frontal',
    description:
        'Apoyos en antebrazos y puntas de pies. Anti-extensión de columna y base para otros ejercicios de core.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.antiRotation,
    muscleGroupIds: [MuscleGroupId.core],
    qualityIds: [QualityId.stability, QualityId.endurance],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
    contraindicationIds: [ContraindicationId.lumbar],
  ),

  // =========================
  // 5) MOVILIDAD / GENERAL
  // =========================

  Exercise(
    id: 'prev_worlds_greatest_stretch_20',
    slug: 'worlds_greatest_stretch',
    name: 'World’s Greatest Stretch',
    description:
        'Secuencia de estiramiento dinámico que incluye cadera, isquios, aductores y columna torácica.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.lunge,
    muscleGroupIds: [MuscleGroupId.hamstrings, MuscleGroupId.glutes, MuscleGroupId.core],
    qualityIds: [QualityId.mobility],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
    contraindicationIds: [],
  ),

  Exercise(
    id: 'prev_hip_90_90_21',
    slug: 'hip_90_90_mobility',
    name: '90/90 de Cadera',
    description:
        'Sentado en el suelo con ambas rodillas a 90°. Trabaja rotación interna y externa de cadera.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.rotation,
    muscleGroupIds: [MuscleGroupId.glutes],
    qualityIds: [QualityId.mobility],
    planeId: PlaneId.transverse,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
    contraindicationIds: [],
  ),

  Exercise(
    id: 'prev_thoracic_rotation_quadruped_22',
    slug: 'thoracic_rotation_quadruped',
    name: 'Rotación Torácica en Cuadrupedia',
    description:
        'En cuadrupedia, mano en la nuca, rotar el tronco abriendo el codo hacia el techo. Mejora movilidad torácica.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.rotation,
    muscleGroupIds: [MuscleGroupId.core, MuscleGroupId.erectors],
    qualityIds: [QualityId.mobility],
    planeId: PlaneId.transverse,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.armSwing, VolleyballTransferId.block],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
    contraindicationIds: [],
  ),

  Exercise(
    id: 'prev_cat_camel_23',
    slug: 'cat_camel_mobility',
    name: 'Cat-Camel',
    description:
        'En cuadrupedia, alternar flexión y extensión de columna. Suave para movilidad de columna y calentamiento.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.rotation,
    muscleGroupIds: [MuscleGroupId.erectors, MuscleGroupId.core],
    qualityIds: [QualityId.mobility],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
    vbTransferIds: [],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [EquipmentId.colchoneta],
    contraindicationIds: [],
  ),

  Exercise(
    id: 'prev_ankle_dorsiflexion_wall_24',
    slug: 'ankle_dorsiflexion_wall',
    name: 'Movilidad de Tobillo en Pared',
    description:
        'De pie frente a la pared, llevar la rodilla hacia adelante sin levantar el talón. Mejora dorsiflexión.',
    videoUrl: '',
    levelId: LevelId.beginner,
    categoryId: CategoryId.prevencion,
    movementPatternId: MovementPatternId.squat,
    muscleGroupIds: [MuscleGroupId.calves],
    qualityIds: [QualityId.mobility],
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.unilateral,
    vbTransferIds: [VolleyballTransferId.landing],
    positions: VolleyballPositionId.values,
    phases: TrainingPhaseId.values,
    equipmentIds: [],
    contraindicationIds: [],
  ),

];

/// 🚀 Seed de ejercicios de PREVENCIÓN / REHAB en Firestore
///
/// Colección sugerida: "exercises"
/// - Usa `id` como documentId.
/// - `merge: true` para poder actualizar descripciones después sin borrar campos extra.
Future<void> seedRehabExercises() async {
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('exercises');

  for (final ex in rehabExercises) {
    await collection.doc(ex.id).set(ex.toJson(), SetOptions(merge: true));
  }
}
