# Guía de Cloud Functions - Generación de Programas

## Descripción General

Este proyecto utiliza Firebase Cloud Functions para generar programas de entrenamiento de voleibol de forma automática. La función `generateMyProgram` analiza el perfil del jugador y crea un programa personalizado basado en sus objetivos, nivel, disponibilidad y próximos torneos.

## Arquitectura

### Cloud Function: `generateMyProgram`

**Ubicación:** `/functions/src/index.ts`

**Tipo:** Callable Function (Firebase Functions v2)

**Propósito:** Generar programas de entrenamiento personalizados para jugadores de voleibol.

## Estructura de Datos

### Entrada (Request Data)

```typescript
{
  playerId?: string  // Opcional: ID del jugador para quien generar el programa
                     // Si no se proporciona, se usa el UID del usuario autenticado
}
```

### Salida (Response)

```typescript
{
  success: boolean,
  programId: string  // ID del programa generado en Firestore
}
```

## Flujo de Funcionamiento

### 1. Autenticación y Permisos

La función verifica:
- El usuario debe estar autenticado
- Si `playerId` no se proporciona, genera el programa para el usuario actual
- Si `playerId` se proporciona, verifica que el usuario sea:
  - El dueño del perfil (mismo UID), O
  - El entrenador asignado (`assignedCoachId` en el perfil del jugador)

### 2. Recolección de Datos

La función obtiene:
- **Perfil del jugador** de `players/{playerId}`
- **Todos los ejercicios** de la colección `exercises`

### 3. Generación del Programa

El algoritmo:

1. **Calcula la duración del programa:**
   - Busca el próximo torneo en `profile.tournaments`
   - Calcula las semanas hasta el torneo (default: 12 semanas)

2. **Crea mesociclos:**
   - **Base** (40% del tiempo): Movilidad, core, resistencia
   - **Fuerza** (35% del tiempo): Fuerza, estabilidad, técnica
   - **Potencia** (25% del tiempo): Saltos, explosividad, velocidad

3. **Filtra ejercicios:**
   - Por nivel del jugador
   - Por tags relevantes al mesociclo
   - Excluye ejercicios contraindicados por lesiones
   - Considera el equipamiento disponible

4. **Genera sesiones:**
   - Una sesión por cada día de entrenamiento disponible
   - 5 ejercicios por sesión
   - Sets, reps e intensidad según el mesociclo

### 4. Guardado en Firestore

El programa se guarda en:
```
players/{playerId}/programs/{programId}
```

## Estructura del Programa Generado

```typescript
{
  id: string,
  source: "Automático",
  startDate: Timestamp,
  endDate: Timestamp,
  mesocycles: [
    {
      name: string,           // "Base", "Fuerza", "Potencia"
      weeks: number,
      focus: string,
      progressionType: string, // "lineal", "progresiva", "ondulante"
      microcycles: [
        {
          weekNumber: number,
          sessions: [
            {
              day: string,      // "Lunes", "Miércoles", etc.
              objective: string,
              load: number,     // 0.6 - 1.0
              exercises: [
                {
                  exerciseId: string,
                  name: string,
                  sets: number,
                  reps: string,
                  intensity: string
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

## Uso desde Flutter

### 1. Generar programa para el usuario actual

```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<void> generateMyProgram() async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('generateMyProgram');
    final result = await callable.call();
    
    print('Programa generado: ${result.data['programId']}');
  } on FirebaseFunctionsException catch (e) {
    print('Error: ${e.code} - ${e.message}');
  }
}
```

### 2. Generar programa para un jugador específico (como entrenador)

```dart
Future<void> generateProgramForPlayer(String playerId) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('generateMyProgram');
    final result = await callable.call({
      'playerId': playerId,
    });
    
    print('Programa generado: ${result.data['programId']}');
  } on FirebaseFunctionsException catch (e) {
    print('Error: ${e.code} - ${e.message}');
  }
}
```

### 3. Usando Riverpod (Implementación actual)

```dart
// En providers.dart
final programGeneratorAction = Provider((ref) {
  final functions = ref.read(functionsProvider);

  return (PlayerProfile profile) async {
    final callable = functions.httpsCallable('generateMyProgram');
    final result = await callable.call(<String, dynamic>{
      'playerId': profile.id,
    });
    return result.data as Map<String, dynamic>;
  };
});

// En la UI
final generateAction = ref.read(programGeneratorAction);
await generateAction(profile);
```

## Manejo de Errores

### Códigos de Error

| Código | Descripción | Solución |
|--------|-------------|----------|
| `unauthenticated` | Usuario no autenticado | Iniciar sesión |
| `not-found` | Perfil de jugador no encontrado | Completar evaluación inicial |
| `permission-denied` | Sin permisos para generar programa | Verificar permisos de entrenador |
| `internal` | Error interno del servidor | Revisar logs de Firebase |

### Ejemplo de Manejo

```dart
try {
  await generateMyProgram();
} on FirebaseFunctionsException catch (e) {
  switch (e.code) {
    case 'unauthenticated':
      // Redirigir a login
      break;
    case 'not-found':
      // Redirigir a evaluación inicial
      break;
    case 'permission-denied':
      // Mostrar mensaje de permisos
      break;
    default:
      // Error genérico
      break;
  }
}
```

## Despliegue

### Compilar las funciones

```bash
cd functions
npm install
npm run build
```

### Desplegar a Firebase

```bash
# Desplegar solo las funciones
firebase deploy --only functions

# Desplegar todo el proyecto
firebase deploy
```

### Verificar el despliegue

1. Ir a [Firebase Console](https://console.firebase.google.com)
2. Seleccionar el proyecto `voleyapp-77661`
3. Ir a "Functions" en el menú lateral
4. Verificar que `generateMyProgram` aparece en la lista

## Monitoreo y Logs

### Ver logs en tiempo real

```bash
firebase functions:log
```

### Ver logs en Firebase Console

1. Ir a Firebase Console > Functions
2. Click en `generateMyProgram`
3. Ver la pestaña "Logs"

### Logs importantes

La función registra:
- Usuario que genera el programa
- ID del jugador objetivo
- Número de ejercicios cargados
- ID del programa generado
- Errores y advertencias

## Requisitos del Perfil del Jugador

Para que la función genere un programa correctamente, el perfil debe tener:

### Campos Obligatorios

```dart
PlayerProfile(
  id: String,              // ID único del perfil
  name: String,            // Nombre del jugador
  level: String,           // "recreativo", "competitivo", "semiprofesional"
  goals: List<String>,     // Objetivos del jugador
  injuries: List<String>,  // Lesiones actuales o históricas
  availability: Availability(
    trainingDays: List<String>,  // ["Lunes", "Miércoles", "Viernes"]
    sessionMinutes: int,         // Duración de cada sesión
  ),
  evaluation: EvaluationResult(
    testScores: Map<String, double>,
    strengths: List<String>,
    weaknesses: List<String>,
  ),
  tournaments: List<Tournament>,
  equipment: List<String>,       // Equipamiento disponible
  assignedCoachId: String?,      // UID del entrenador (opcional)
)
```

## Optimizaciones y Consideraciones

### Performance

- La función carga TODOS los ejercicios en memoria
- Para bases de datos grandes (>1000 ejercicios), considerar:
  - Caché de ejercicios
  - Filtrado en la query de Firestore
  - Paginación

### Costos

- Cada llamada consume:
  - 1 invocación de Cloud Function
  - 1 lectura del perfil del jugador
  - N lecturas de ejercicios (donde N = número total de ejercicios)
  - 1 escritura del programa generado

### Límites

- Timeout: 60 segundos (default para Cloud Functions v2)
- Memoria: 256 MB (default)
- Tamaño máximo de respuesta: 10 MB

## Testing

### Testing Local con Emuladores

```bash
cd functions
npm run serve
```

Esto inicia los emuladores de Firebase. La función estará disponible en:
```
http://localhost:5001/voleyapp-77661/us-central1/generateMyProgram
```

### Testing desde Flutter con Emuladores

```dart
// En main.dart o donde inicialices Firebase
if (kDebugMode) {
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

## Troubleshooting

### La función no aparece después del despliegue

1. Verificar que la compilación fue exitosa: `npm run build`
2. Verificar que el despliegue fue exitoso: `firebase deploy --only functions`
3. Esperar 1-2 minutos para que la función se propague

### Error "Function not found"

1. Verificar el nombre de la función en el código
2. Verificar que la función está exportada: `export const generateMyProgram = ...`
3. Verificar la región (default: us-central1)

### Error de permisos

1. Verificar que el usuario está autenticado
2. Verificar que `assignedCoachId` está correctamente configurado
3. Revisar las reglas de Firestore

### Programa generado está vacío

1. Verificar que hay ejercicios en la colección `exercises`
2. Verificar que los ejercicios tienen los tags correctos
3. Verificar que el perfil tiene `availability.trainingDays` configurado

## Próximas Mejoras

- [ ] Caché de ejercicios para mejorar performance
- [ ] Generación de programas con periodización más avanzada
- [ ] Ajuste automático basado en feedback de sesiones
- [ ] Soporte para múltiples idiomas
- [ ] Generación de programas para equipos completos
- [ ] Integración con calendario del jugador
- [ ] Notificaciones push cuando se genera un nuevo programa

## Recursos Adicionales

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Callable Functions Guide](https://firebase.google.com/docs/functions/callable)
- [Cloud Functions Pricing](https://firebase.google.com/pricing)
