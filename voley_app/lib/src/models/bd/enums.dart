// lib/src/catalogos/enums.dart

/// Nivel del ejercicio (dificultad / experiencia)
enum LevelId {
  beginner,      // Principiante
  intermediate,  // Intermedio
  advanced,      // Avanzado
  elite,         // Alto rendimiento
}

/// Gran categoría del ejercicio
enum CategoryId {
  fuerza,
  hipertrofia,
  potencia,
  resistencia,
  movilidad,
  estabilidad,
  acondicionamiento,
}

/// Patrón de movimiento principal
enum MovementPatternId {
  squat,              // Sentadilla
  hinge,              // Bisagra de cadera (peso muerto)
  lunge,              // Zancada / split
  horizontalPush,     // Empuje horizontal
  verticalPush,       // Empuje vertical
  horizontalPull,     // Tirón horizontal
  verticalPull,       // Tirón vertical
  coreAntiExtension,  // Core anti-extensión (planchas)
  coreAntiRotation,   // Core anti-rotación (Pallof, etc.)
  carry,              // Cargadas / farmer walks
  jump,               // Saltos
  landing,            // Aterrizajes
  changeOfDirection,  // Cambios de dirección
}

/// Grupos musculares principales
enum MuscleGroupId {
  quads,          // Cuádriceps
  hamstrings,     // Isquios
  glutes,         // Glúteos
  calves,         // Pantorrillas
  chest,          // Pectoral
  lats,           // Dorsal ancho
  upperBack,      // Trapecios / romboides
  shoulders,      // Deltoides
  biceps,
  triceps,
  forearms,
  core,           // Abdominales / lumbares
  hipFlexors,     // Flexores de cadera
}

/// Cualidad física principal trabajada
enum QualityId {
  fuerzaMaxima,
  hipertrofia,
  fuerzaResistente,
  potencia,
  estabilidad,
  controlMotor,
  movilidad,
}

/// Plano de movimiento
enum PlaneId {
  sagittal,
  frontal,
  transverse,
}

/// Dominancia / soporte
enum DominanceId {
  bilateral,
  unilateral,
  alternating,
}

/// Transferencia específica a gestos de vóley
enum VolleyballTransferId {
  saltoVertical,
  saltoHorizontal,
  bloqueo,
  remate,
  saquePotente,
  desplazamientoLateral,
  cambioDeDireccion,
  caidaControlada,
}

/// Posición principal de vóley a la que beneficia
enum VolleyballPositionId {
  central,
  punta,
  opuesto,
  armador,
  libero,
  universal,
}

/// Fase de entrenamiento donde suele encajar mejor
enum TrainingPhaseId {
  offSeason,
  preSeason,
  inSeason,
  postSeason,
  rehab,
}

/// Equipamiento requerido / principal
enum EquipmentId {
  barra,
  mancuernas,
  kettlebell,
  maquina,
  polea,
  bandas,
  cajaPliometrica,
  banco,
  balonMedicinal,
  colchoneta,
  pesoCorporal,
  trx,
}

/// Contraindicaciones frecuentes
enum ContraindicationId {
  dolorLumbar,
  dolorRodilla,
  dolorHombro,
  inestabilidadTobillo,
  hipertensionNoControlada,
}
