# Evaluation Screen - User Selection/Creation Feature

## Overview
Se ha implementado la funcionalidad para que los entrenadores puedan seleccionar usuarios existentes o crear nuevos usuarios al momento de realizar una evaluación inicial.

## Cambios Realizados

### 1. PlayerProfile Model (`lib/src/models/player_profile/player_profile.dart`)
- **Agregado**: Campo `userId` (opcional) para vincular el perfil del jugador con su cuenta de usuario
- **Actualizado**: Métodos `toJson()` y `fromJson()` para incluir el campo `userId`

### 2. FirestoreService (`lib/src/services/firestore_service.dart`)
- **Agregado**: Método `createPlayerWithCoachLink()` que:
  - Crea un nuevo usuario jugador en Firestore
  - Automáticamente crea el permiso de vinculación con el entrenador
  - Retorna el objeto User creado

### 3. EvaluationScreen (`lib/src/screens/onboarding/evaluation_screen.dart`)
Refactorización completa con las siguientes características:

#### Nuevas Funcionalidades:
- **Toggle de Modo**: Botón segmentado para elegir entre "Usuario Existente" o "Crear Nuevo"
- **Selección de Usuario Existente**:
  - Dropdown que muestra jugadores vinculados al entrenador autenticado
  - Auto-rellena nombre y email cuando se selecciona un usuario
  - Muestra mensaje si no hay jugadores vinculados
- **Creación de Nuevo Usuario**:
  - Campos para email y contraseña
  - Crea cuenta en Firebase Auth
  - Crea documento de usuario en Firestore
  - Automáticamente vincula al entrenador con el nuevo jugador

#### Mejoras de UI:
- Diseño con Cards para mejor organización visual
- Campos agrupados por sección (Usuario, Datos del Jugador, Disponibilidad, Evaluación)
- Uso de `SingleChildScrollView` para mejor experiencia en pantallas pequeñas
- Indicador de carga mientras se obtienen los datos
- Validación de formularios con mensajes de error claros

#### Validaciones Implementadas:
- Nombre del jugador requerido
- Email y contraseña requeridos al crear nuevo usuario
- Usuario debe ser seleccionado al usar modo "Usuario Existente"
- Verificación de que el usuario autenticado sea un entrenador

#### Flujo de Trabajo:
1. Al cargar la pantalla, obtiene el entrenador autenticado
2. Carga la lista de jugadores vinculados al entrenador
3. El entrenador elige entre seleccionar usuario existente o crear nuevo
4. Completa los datos de evaluación (posición, nivel, disponibilidad, etc.)
5. Al guardar:
   - Si es nuevo usuario: crea cuenta en Auth, crea documento en Firestore, crea permiso
   - Si es usuario existente: usa el userId del usuario seleccionado
   - Crea el PlayerProfile vinculado al userId
   - Guarda el perfil en Firestore
   - Navega a la pantalla de generación de programa

## Dependencias
- `firebase_auth`: Para autenticación de usuarios
- `cloud_firestore`: Para almacenamiento de datos
- `flutter_riverpod`: Para gestión de estado
- `uuid`: Para generación de IDs únicos

## Uso

### Para Entrenadores:
1. Navegar a la pantalla de Evaluación Inicial
2. Elegir si desea evaluar un jugador existente o crear uno nuevo
3. Si es existente: seleccionar del dropdown
4. Si es nuevo: ingresar email y contraseña
5. Completar los datos de evaluación
6. Guardar y generar programa

### Permisos:
- Los nuevos usuarios creados automáticamente quedan vinculados al entrenador
- Los permisos se crean con estado "pending" por defecto
- El jugador puede aceptar/rechazar el permiso desde su pantalla de permisos

## Notas Técnicas
- El campo `userId` en PlayerProfile es opcional para mantener compatibilidad con perfiles existentes
- Se utiliza el patrón async/await para todas las operaciones de Firebase
- Los errores se manejan con try-catch y se muestran al usuario mediante SnackBars
- Se implementó dispose() para liberar recursos de los TextEditingControllers
