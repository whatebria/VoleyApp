# Cloud Functions - Voley App

Este directorio contiene las Cloud Functions de Firebase para la aplicación Voley App.

## Funciones Disponibles

### `generateMyProgram`

Genera programas de entrenamiento personalizados para jugadores de voleibol.

**Tipo:** Callable Function (HTTPS)

**Parámetros:**
- `playerId` (opcional): ID del jugador para quien generar el programa

**Respuesta:**
```json
{
  "success": true,
  "programId": "prog_1234567890"
}
```

## Desarrollo

### Instalación

```bash
npm install
```

### Compilación

```bash
npm run build
```

### Compilación en modo watch

```bash
npm run build:watch
```

### Linting

```bash
npm run lint
```

### Testing Local

```bash
npm run serve
```

Esto inicia los emuladores de Firebase en `http://localhost:5001`

## Despliegue

### Desplegar solo las funciones

```bash
firebase deploy --only functions
```

### Desplegar una función específica

```bash
firebase deploy --only functions:generateMyProgram
```

## Estructura del Código

```
functions/
├── src/
│   └── index.ts          # Código fuente de las funciones
├── lib/                  # Código compilado (generado)
├── node_modules/         # Dependencias
├── package.json          # Configuración de npm
├── tsconfig.json         # Configuración de TypeScript
└── .eslintrc.js         # Configuración de ESLint
```

## Dependencias

- `firebase-admin`: SDK de Firebase para Node.js
- `firebase-functions`: Framework de Cloud Functions
- `typescript`: Compilador de TypeScript

## Configuración

### Node.js Version

Este proyecto requiere Node.js 22 (especificado en `package.json`).

### TypeScript

La configuración de TypeScript está en `tsconfig.json`. El código se compila a ES2017.

### ESLint

El código sigue las reglas de ESLint configuradas en `.eslintrc.js`.

## Logs

### Ver logs en tiempo real

```bash
npm run logs
```

O directamente:

```bash
firebase functions:log
```

### Ver logs en Firebase Console

1. Ir a [Firebase Console](https://console.firebase.google.com)
2. Seleccionar el proyecto
3. Ir a "Functions" > "Logs"

## Troubleshooting

### Error: "tsc: command not found"

Ejecutar `npm install` para instalar las dependencias.

### Error de compilación

Verificar que el código TypeScript es válido:
```bash
npm run lint
```

### La función no se despliega

1. Verificar que la compilación es exitosa: `npm run build`
2. Verificar que estás autenticado: `firebase login`
3. Verificar el proyecto activo: `firebase use`

## Recursos

- [Documentación completa](../CLOUD_FUNCTIONS_GUIDE.md)
- [Firebase Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [TypeScript Docs](https://www.typescriptlang.org/docs/)
