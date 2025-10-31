# Sistema de Permisos Entrenador-Jugador

## 📋 Resumen

Se ha implementado un sistema completo de permisos que permite a los entrenadores gestionar y acceder a los datos de sus jugadores mediante un sistema de solicitudes de permiso.

## 🗂️ Archivos Creados

### 1. **lib/src/models/user.dart**
Modelo de usuario con soporte para roles:
- `UserRole` enum: `coach` (entrenador) y `player` (jugador)
- Campos: id, email, name, role, createdAt
- Métodos helper: `isCoach`, `isPlayer`

### 2. **lib/src/models/coach_player_permission.dart**
Modelo para gestionar permisos entre entrenadores y jugadores:
- `PermissionStatus` enum: `pending`, `accepted`, `rejected`
- Campos: id, coachId, playerId, status, createdAt, updatedAt
- Métodos helper: `isPending`, `isAccepted`, `isRejected`

### 3. **firestore.rules**
Reglas de seguridad de Firestore que controlan el acceso a los datos:
- Los usuarios solo pueden leer/escribir sus propios datos
- Los entrenadores pueden leer datos de jugadores con permiso aceptado
- Los jugadores pueden aceptar/rechazar solicitudes de permiso
- Colecciones de ejercicios, lesiones, tests y fases son de solo lectura

## 🔄 Archivos Modificados

### **lib/src/auth/auth_service.dart**
- Actualizado método `register()` para incluir:
  - Parámetro `name` (nombre del usuario)
  - Parámetro `role` (rol del usuario: coach/player)
  - Creación automática de documento de usuario en Firestore

### **lib/src/services/firestore_service.dart**
Agregados métodos para gestionar usuarios y permisos:

#### Métodos de Usuario:
- `getUser(userId)` - Obtener usuario por ID
- `getAllCoaches()` - Obtener todos los entrenadores
- `getAllPlayers()` - Obtener todos los jugadores

#### Métodos de Permisos:
- `createPermission({coachId, playerId})` - Crear solicitud de permiso
- `updatePermissionStatus({permissionId, status})` - Actualizar estado del permiso
- `getPlayersByCoach(coachId)` - Obtener jugadores de un entrenador
- `getCoachesByPlayer(playerId)` - Obtener entrenadores de un jugador
- `getPendingPermissionsForPlayer(playerId)` - Obtener solicitudes pendientes
- `getPermissionsByCoach(coachId)` - Obtener todos los permisos de un entrenador
- `hasPermission({coachId, playerId})` - Verificar si existe permiso
- `deletePermission(permissionId)` - Eliminar permiso

### **lib/src/screens/auth/register_screen.dart**
- Agregado campo de nombre completo
- Agregado selector de rol (Jugador/Entrenador) con RadioButtons
- Actualizada lógica de registro para incluir nombre y rol

### **firebase.json**
- Agregada configuración de Firestore rules

## 🗄️ Estructura de Base de Datos

```
Firestore Database
│
├── users/{userId}
│   ├── id: string
│   ├── email: string
│   ├── name: string
│   ├── role: "coach" | "player"
│   └── createdAt: timestamp
│
├── coach_player_permissions/{permissionId}
│   ├── id: string
│   ├── coachId: string (ref to users)
│   ├── playerId: string (ref to users)
│   ├── status: "pending" | "accepted" | "rejected"
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp (nullable)
│
└── players/{playerId}
    ├── ... (datos existentes del perfil del jugador)
    ├── programs/{programId}
    └── feedback/{sessionId}
```

## 🔐 Flujo de Permisos

### 1. Entrenador solicita permiso a un jugador:
```dart
final firestoreService = FirestoreService();
final permission = await firestoreService.createPermission(
  coachId: currentCoachId,
  playerId: targetPlayerId,
);
// Estado inicial: pending
```

### 2. Jugador ve solicitudes pendientes:
```dart
final pendingPermissions = await firestoreService
    .getPendingPermissionsForPlayer(currentPlayerId);
```

### 3. Jugador acepta o rechaza:
```dart
// Aceptar
await firestoreService.updatePermissionStatus(
  permissionId: permission.id,
  status: PermissionStatus.accepted,
);

// Rechazar
await firestoreService.updatePermissionStatus(
  permissionId: permission.id,
  status: PermissionStatus.rejected,
);
```

### 4. Entrenador accede a datos del jugador:
```dart
// Verificar permiso
final hasAccess = await firestoreService.hasPermission(
  coachId: currentCoachId,
  playerId: targetPlayerId,
);

if (hasAccess) {
  // Obtener perfil del jugador
  final playerProfile = await firestoreService
      .getPlayerProfile(targetPlayerId);
}
```

## 💻 Ejemplos de Uso

### Registro de Usuario Entrenador
```dart
// En RegisterScreen, el usuario selecciona "Entrenador"
// Al registrarse, se crea automáticamente:
// 1. Usuario en Firebase Auth
// 2. Documento en Firestore users/ con role: "coach"
```

### Registro de Usuario Jugador
```dart
// En RegisterScreen, el usuario selecciona "Jugador" (por defecto)
// Al registrarse, se crea automáticamente:
// 1. Usuario en Firebase Auth
// 2. Documento en Firestore users/ con role: "player"
```

### Obtener Jugadores de un Entrenador
```dart
final firestoreService = FirestoreService();
final myPlayers = await firestoreService.getPlayersByCoach(coachId);

// Retorna solo jugadores con permiso aceptado
for (final player in myPlayers) {
  print('${player.name} - ${player.email}');
}
```

### Obtener Entrenadores de un Jugador
```dart
final firestoreService = FirestoreService();
final myCoaches = await firestoreService.getCoachesByPlayer(playerId);

for (final coach in myCoaches) {
  print('Entrenador: ${coach.name}');
}
```

### Listar Todos los Entrenadores (para que jugador elija)
```dart
final firestoreService = FirestoreService();
final allCoaches = await firestoreService.getAllCoaches();

// Mostrar en UI para que jugador pueda enviar solicitud
```

## 🎯 Casos de Uso

### Para Entrenadores:
1. **Ver mis jugadores**: Obtener lista de jugadores con permiso aceptado
2. **Solicitar acceso**: Enviar solicitud de permiso a un nuevo jugador
3. **Ver solicitudes**: Ver estado de todas mis solicitudes (pending/accepted/rejected)
4. **Acceder a datos**: Ver perfiles, programas y feedback de jugadores autorizados
5. **Revocar acceso**: Eliminar permiso existente

### Para Jugadores:
1. **Ver solicitudes**: Ver entrenadores que solicitan acceso
2. **Aceptar/Rechazar**: Gestionar solicitudes de permiso
3. **Ver mis entrenadores**: Lista de entrenadores con acceso autorizado
4. **Revocar acceso**: Eliminar permiso a un entrenador

## 🔒 Seguridad

Las reglas de Firestore garantizan:
- ✅ Los usuarios solo pueden leer/escribir sus propios datos
- ✅ Los entrenadores solo pueden crear solicitudes de permiso
- ✅ Los jugadores pueden aceptar/rechazar solicitudes
- ✅ Los entrenadores solo acceden a datos de jugadores con permiso aceptado
- ✅ Ambas partes pueden eliminar permisos
- ✅ Colecciones de referencia (exercises, injuries, tests) son de solo lectura

## 🚀 Próximos Pasos Sugeridos

### Pantallas a Crear:

1. **CoachDashboardScreen**
   - Lista de jugadores con permiso
   - Botón para solicitar acceso a nuevo jugador
   - Estado de solicitudes pendientes

2. **PlayerDashboardScreen**
   - Lista de entrenadores autorizados
   - Notificaciones de solicitudes pendientes
   - Gestión de permisos

3. **PermissionRequestScreen**
   - Para jugadores: ver y gestionar solicitudes
   - Botones de aceptar/rechazar
   - Información del entrenador solicitante

4. **PlayerSearchScreen**
   - Para entrenadores: buscar jugadores
   - Enviar solicitud de permiso
   - Ver estado de solicitudes

5. **PermissionManagementScreen**
   - Ver todos los permisos activos
   - Revocar acceso
   - Historial de permisos

### Funcionalidades Adicionales:

1. **Notificaciones Push**
   - Notificar a jugador cuando recibe solicitud
   - Notificar a entrenador cuando se acepta/rechaza

2. **Sistema de Invitaciones**
   - Generar código de invitación
   - Jugador ingresa código para autorizar entrenador

3. **Permisos Temporales**
   - Agregar fecha de expiración a permisos
   - Renovación automática o manual

4. **Niveles de Permiso**
   - Solo lectura vs lectura/escritura
   - Acceso a programas pero no a datos personales

5. **Auditoría**
   - Registro de accesos del entrenador
   - Historial de cambios en permisos

## 📦 Dependencias Utilizadas

Todas las dependencias ya estaban en `pubspec.yaml`:
- `firebase_core`: ^3.15.2
- `firebase_auth`: ^5.3.0
- `cloud_firestore`: ^5.4.0
- `flutter_riverpod`: ^2.3.0
- `uuid`: ^3.0.7

## 🔧 Despliegue de Reglas de Firestore

Para desplegar las reglas de seguridad a Firebase:

```bash
# Desde el directorio raíz del proyecto
firebase deploy --only firestore:rules
```

## ✅ Estado de Implementación

- ✅ Modelo de Usuario con roles
- ✅ Modelo de Permisos Entrenador-Jugador
- ✅ Servicio de autenticación actualizado
- ✅ Métodos CRUD para permisos en FirestoreService
- ✅ Pantalla de registro con selector de rol
- ✅ Reglas de seguridad de Firestore
- ✅ Documentación completa
- ⏳ Pantallas de gestión de permisos (pendiente)
- ⏳ Sistema de notificaciones (pendiente)

## 📝 Notas Importantes

1. **Migración de Usuarios Existentes**: Los usuarios registrados antes de esta implementación no tienen rol asignado. Considera crear un script de migración.

2. **Validación de Permisos**: Siempre valida permisos en el backend (Firestore Rules) además del frontend.

3. **IDs de Permisos**: Actualmente se usa UUID v4. Considera usar una combinación de `coachId_playerId` para evitar duplicados.

4. **Índices de Firestore**: Puede que necesites crear índices compuestos para queries complejas. Firebase te notificará con un link si es necesario.

5. **Testing**: Prueba las reglas de Firestore usando el emulador local antes de desplegar a producción.

¡El sistema de permisos está completo y listo para usar! 🎉
