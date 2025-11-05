// lib/src/catalogos/enums.dart
// Catálogos como enums (IDs fijos, type-safe). Se guardan en Firestore por su .name

// Niveles
enum LevelId { beginner, intermediate, advanced }

// Categorías principales
enum CategoryId {
  fuerza,
  potencia,
  pliometria,
  velocidad,
  core,
  acondicionamiento,
  movilidad,
  prevencion,
}

// Patrones de movimiento
enum MovementPatternId {
  squat,
  hinge,
  lunge,
  push,
  pull,
  carry,
  rotation,
  antiRotation,
  landing,
}

// Grupos musculares
enum MuscleGroupId {
  quads,
  glutes,
  hamstrings,
  calves,
  erectors,
  lats,
  delts,
  rotatorCuff,
  core,
}

// Cualidades físicas
enum QualityId { strength, power, speed, agility, endurance, mobility, stability }

// Planos de movimiento
enum PlaneId { sagittal, frontal, transverse }

// Dominancia
enum DominanceId { bilateral, unilateral }

// Transferencias al vóley
enum VolleyballTransferId { jump, block, approach, defenseShuffle, landing, armSwing }

// Equipamiento
enum EquipmentId {
  barra,
  discos,
  mancuernas,
  kettlebell,
  caja,
  banda,
  miniband,
  cuerda,
  colchoneta,
  balon,
  trx,
  escalera,
  conos,
  bosu,
  sogaBatalla,
  cajonBajo,
  banco,
  slider,
}

// Contraindicaciones
enum ContraindicationId { rodilla, tobillo, hombro, lumbar, impactoAlto, cardio }

// Posiciones del vóley
enum VolleyballPositionId { outsideHitter, middleBlocker, setter, libero, opposite }

// Fases de temporada
enum TrainingPhaseId { preseason, inSeason, taper, offSeason }
