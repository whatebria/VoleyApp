import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/catalogos/enums.dart';

// 👇 Ajusta este import según dónde tengas tu modelo
// por ejemplo: src/modelos/exercise_v4.dart o src/models/bd/exercise.dart
import 'package:voley_app/src/models/bd/exercise.dart';

/// Seeder simple de ejercicios de fuerza / hipertrofia.
/// Usa enums mínimos seguros para no romper compilación.
/// Después puedes editar cada ejercicio y enriquecer metadata.
final List<Exercise> exerciseSeed = [
  // -------------------------
  // PIERNAS / SENTADILLAS
  // -------------------------
  Exercise(
    id: 'ex_back_squat',
    slug: 'back_squat',
    name: 'Sentadilla con barra (Back Squat)',
    description:
        'Ejercicio base de fuerza para tren inferior: cuádriceps, glúteos y core.',
    videoUrl: 'https://youtu.be/aclHkVaku9U',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_front_squat',
    slug: 'front_squat',
    name: 'Sentadilla frontal',
    description:
        'Variación con mayor énfasis en cuádriceps y core. Ideal para fuerza y masa muscular.',
    videoUrl: 'https://youtu.be/2z8JmcrW-As',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_goblet_squat',
    slug: 'goblet_squat',
    name: 'Sentadilla Goblet',
    description:
        'Sentadilla sosteniendo mancuerna o kettlebell al pecho. Excelente para técnica y volumen.',
    videoUrl: 'https://youtu.be/6xwGFn-J_Qw',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_bulgarian_split_squat',
    slug: 'bulgarian_split_squat',
    name: 'Sentadilla búlgara',
    description:
        'Trabajo unilateral intenso de cuádriceps y glúteos. Muy útil para hipertrofia y estabilidad.',
    videoUrl: 'https://youtu.be/2C-uNgKwPLE',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_lunges',
    slug: 'lunges',
    name: 'Zancadas caminando',
    description:
        'Zancadas hacia delante o caminando, excelente estímulo de cuádriceps y glúteos.',
    videoUrl: 'https://youtu.be/QOVaHwm-Q6U',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_step_up',
    slug: 'step_up',
    name: 'Step-up al cajón',
    description:
        'Subidas a cajón o banco, unilateral, gran transferencia a salto y cambio de dirección.',
    videoUrl: 'https://youtu.be/dQqApCGd5Ss',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),

  // -------------------------
  // BISAGRA / CADENA POSTERIOR
  // -------------------------
  Exercise(
    id: 'ex_rdl_barbell',
    slug: 'romanian_deadlift',
    name: 'Peso muerto rumano con barra',
    description:
        'Bisagra de cadera con énfasis en isquios y glúteos. Muy útil para hipertrofia de cadena posterior.',
    videoUrl: 'https://youtu.be/hH-ZHYQ0E-c',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_hip_thrust',
    slug: 'hip_thrust_barbell',
    name: 'Hip Thrust con barra',
    description:
        'Ejercicio clave para hipertrofia de glúteos y mejora de la extensión de cadera explosiva.',
    videoUrl: 'https://youtu.be/LM8XHLYJoYs',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_good_morning',
    slug: 'good_morning',
    name: 'Good Morning con barra ligera',
    description:
        'Bisagra de cadera controlada, fortalece erectores espinales, isquios y glúteos.',
    videoUrl: 'https://youtu.be/vu-HG9q_ezg',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),

  // -------------------------
  // EMPUJE HORIZONTAL
  // -------------------------
  Exercise(
    id: 'ex_bench_press',
    slug: 'bench_press_barbell',
    name: 'Press de banca con barra',
    description:
        'Clásico de fuerza e hipertrofia de pectoral, hombros y tríceps.',
    videoUrl: 'https://youtu.be/rT7DgCr-3pg',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_incline_db_press',
    slug: 'incline_db_press',
    name: 'Press inclinado con mancuernas',
    description:
        'Enfoque sobre pectoral superior y deltoides anteriores, excelente para volumen.',
    videoUrl: 'https://youtu.be/8iPEnn-ltC8',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_pushups',
    slug: 'pushups',
    name: 'Flexiones de brazos (Push-Ups)',
    description:
        'Ejercicio básico de empuje horizontal; fácilmente progresable con lastre o variaciones.',
    videoUrl: 'https://youtu.be/_l3ySVKYVJ8',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_db_fly',
    slug: 'dumbbell_fly',
    name: 'Aperturas con mancuernas',
    description:
        'Aislamiento de pectoral, ideal como segundo o tercer ejercicio para hipertrofia.',
    videoUrl: 'https://youtu.be/eozdVDA78K0',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),

  // -------------------------
  // EMPUJE VERTICAL
  // -------------------------
  Exercise(
    id: 'ex_overhead_press',
    slug: 'overhead_press',
    name: 'Press militar de pie',
    description:
        'Desarrollo de fuerza e hipertrofia en deltoides y tríceps. Alta transferencia al remate y bloqueo.',
    videoUrl: 'https://youtu.be/B-aVuyhvLHU',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_lateral_raise',
    slug: 'lateral_raise',
    name: 'Elevaciones laterales con mancuernas',
    description:
        'Aislamiento de deltoides medios, fundamental para volumen de hombro.',
    videoUrl: 'https://youtu.be/3VcKaXpzqRo',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_arnold_press',
    slug: 'arnold_press',
    name: 'Press Arnold',
    description:
        'Variación de press de hombros que recorre un rango más largo, excelente para hipertrofia.',
    videoUrl: 'https://youtu.be/3ml7BH7mNwQ',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),

  // -------------------------
  // TIRÓN HORIZONTAL
  // -------------------------
  Exercise(
    id: 'ex_barbell_row',
    slug: 'barbell_row',
    name: 'Remo con barra',
    description:
        'Tirón horizontal pesado para dorsales, romboides y trapecios. Equilibra el trabajo de empuje.',
    videoUrl: 'https://youtu.be/vT2GjY_Umpw',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_seated_row',
    slug: 'seated_cable_row',
    name: 'Remo sentado en polea',
    description:
        'Control mayor del movimiento, ideal para series de volumen e hipertrofia de espalda.',
    videoUrl: 'https://youtu.be/GZbfZ033f74',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_one_arm_db_row',
    slug: 'one_arm_db_row',
    name: 'Remo a una mano con mancuerna',
    description:
        'Trabajo unilateral que mejora simetrías, dorsales y estabilidad del core.',
    videoUrl: 'https://youtu.be/pYcpY20QaE8',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),

  // -------------------------
  // TIRÓN VERTICAL
  // -------------------------
  Exercise(
    id: 'ex_pullup',
    slug: 'pullup',
    name: 'Dominadas pronas',
    description:
        'Ejercicio avanzado de tirón vertical, excelente para dorsales, bíceps y estabilidad escapular.',
    videoUrl: 'https://youtu.be/eGo4IYlbE5g',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_lat_pulldown',
    slug: 'lat_pulldown',
    name: 'Jalón al pecho en polea',
    description:
        'Alternativa a las dominadas, muy útil para trabajar volumen en dorsales.',
    videoUrl: 'https://youtu.be/CAwf7n6Luuc',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),

  // -------------------------
  // BRAZOS
  // -------------------------
  Exercise(
    id: 'ex_bb_curl',
    slug: 'barbell_curl',
    name: 'Curl de bíceps con barra',
    description:
        'Movimiento básico pesado para bíceps. Útil para completar sesiones de tirón.',
    videoUrl: 'https://youtu.be/kwG2ipFRgfo',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_triceps_extension',
    slug: 'lying_triceps_extension',
    name: 'Extensiones de tríceps tumbado (Press francés)',
    description:
        'Aísla tríceps, buena opción de hipertrofia tras ejercicios compuestos.',
    videoUrl: 'https://youtu.be/y2aKXr-9FZ4',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),

  // -------------------------
  // CORE
  // -------------------------
  Exercise(
    id: 'ex_plank',
    slug: 'front_plank',
    name: 'Plancha frontal',
    description:
        'Core isométrico, base para estabilidad en saltos, cambios de dirección y aterrizajes.',
    videoUrl: 'https://youtu.be/pvIjsG5Svck',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
  Exercise(
    id: 'ex_dead_bug',
    slug: 'dead_bug',
    name: 'Dead Bug',
    description:
        'Ejercicio anti-extensión para core, excelente como activación previa o parte de fuerza de tronco.',
    videoUrl: 'https://youtu.be/Rz0x-7jzBH4',
    levelId: LevelId.intermediate,
    categoryId: CategoryId.fuerza,
    movementPatternId: MovementPatternId.squat,
    planeId: PlaneId.sagittal,
    dominanceId: DominanceId.bilateral,
  ),
];

/// Llama a esto una vez (por ejemplo desde una pantalla admin)
/// para llenar la colección "exercises" en Firestore.
Future<void> seedExercisesToFirestore() async {
  final db = FirebaseFirestore.instance;

  for (final ex in exerciseSeed) {
    await db.collection('exercises').doc(ex.id).set(ex.toJson());
  }

  // Solo para debug en consola
  // ignore: avoid_print
  print('✅ Seeder completado: ${exerciseSeed.length} ejercicios creados');
}
