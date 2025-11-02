# Guía de Despliegue - Voley App

Esta guía te ayudará a desplegar las Cloud Functions y la aplicación Flutter.

## Requisitos Previos

### Software Necesario

- [Node.js 22+](https://nodejs.org/)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Git

### Instalación de Firebase CLI

```bash
npm install -g firebase-tools
```

### Autenticación

```bash
firebase login
```

## Despliegue de Cloud Functions

### 1. Preparación

```bash
cd functions
npm install
```

### 2. Compilación

```bash
npm run build
```

Verifica que no hay errores de compilación.

### 3. Testing Local (Opcional)

```bash
npm run serve
```

Esto inicia los emuladores locales. Puedes probar las funciones antes de desplegarlas.

### 4. Despliegue

```bash
# Desde el directorio raíz del proyecto
firebase deploy --only functions
```

O para desplegar una función específica:

```bash
firebase deploy --only functions:generateMyProgram
```

### 5. Verificación

1. Ir a [Firebase Console](https://console.firebase.google.com)
2. Seleccionar el proyecto `voleyapp-77661`
3. Ir a "Functions"
4. Verificar que `generateMyProgram` aparece en la lista

## Despliegue de Firestore Rules

```bash
firebase deploy --only firestore:rules
```

## Despliegue Completo

Para desplegar todo (functions + firestore rules):

```bash
firebase deploy
```

## Configuración de Flutter

### 1. Instalar Dependencias

```bash
flutter pub get
```

### 2. Configurar Firebase

Si es la primera vez o has cambiado de proyecto:

```bash
flutterfire configure
```

### 3. Build para Android

```bash
flutter build apk
```

O para un APK de release:

```bash
flutter build apk --release
```

### 4. Build para iOS

```bash
flutter build ios
```

## Testing

### Testing de Cloud Functions

#### Desde Flutter (Emuladores)

En `main.dart`, agrega:

```dart
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Solo en modo debug
  if (kDebugMode) {
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  }
  
  runApp(MyApp());
}
```

Luego inicia los emuladores:

```bash
cd functions
npm run serve
```

#### Desde la Consola

Puedes probar las funciones directamente desde Firebase Console:

1. Ir a Functions
2. Click en `generateMyProgram`
3. Click en "Testing"
4. Ingresar datos de prueba

### Testing de la App Flutter

```bash
flutter test
```

## Monitoreo Post-Despliegue

### Ver Logs de Cloud Functions

```bash
firebase functions:log
```

O en tiempo real:

```bash
firebase functions:log --only generateMyProgram
```

### Métricas en Firebase Console

1. Ir a Firebase Console > Functions
2. Ver métricas de:
   - Invocaciones
   - Tiempo de ejecución
   - Errores
   - Uso de memoria

## Rollback

Si necesitas revertir a una versión anterior:

```bash
# Ver versiones anteriores
firebase functions:list

# No hay rollback automático, debes redesplegar el código anterior
git checkout <commit-anterior>
firebase deploy --only functions
```

## Troubleshooting

### Error: "Insufficient permissions"

Verifica que tu cuenta tiene los permisos necesarios en el proyecto Firebase.

```bash
firebase projects:list
```

### Error: "Build failed"

1. Verifica que Node.js es la versión correcta (22+)
2. Limpia y reinstala dependencias:

```bash
cd functions
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Error: "Function deployment failed"

1. Verifica los logs:

```bash
firebase functions:log
```

2. Verifica que el proyecto está configurado correctamente:

```bash
firebase use
```

### La app Flutter no se conecta a las funciones

1. Verifica que Firebase está inicializado correctamente
2. Verifica que `cloud_functions` está en `pubspec.yaml`
3. Verifica la configuración de Firebase en la app

## Checklist de Despliegue

Antes de desplegar a producción:

- [ ] Todas las pruebas pasan
- [ ] El código está en la rama `main` o `production`
- [ ] Las Cloud Functions compilan sin errores
- [ ] Las reglas de Firestore están actualizadas
- [ ] La documentación está actualizada
- [ ] Se ha probado en emuladores locales
- [ ] Se ha notificado al equipo del despliegue

## Ambientes

### Desarrollo

```bash
firebase use default
```

### Producción

Si tienes múltiples ambientes:

```bash
firebase use production
```

## Costos

Monitorea los costos en:
- [Firebase Console > Usage and Billing](https://console.firebase.google.com)

### Límites del Plan Spark (Gratuito)

- Cloud Functions: 125K invocaciones/mes
- Firestore: 50K lecturas/día, 20K escrituras/día
- Storage: 1 GB

### Plan Blaze (Pay as you go)

Consulta los precios en: https://firebase.google.com/pricing

## Seguridad

### Antes de Desplegar

1. **No incluyas secretos en el código**
   - Usa Firebase Config o Secret Manager
   - Nunca hagas commit de API keys

2. **Revisa las reglas de Firestore**
   - Asegúrate de que solo usuarios autorizados pueden acceder a los datos

3. **Configura CORS si es necesario**
   - Para funciones HTTP que se llaman desde web

### Después de Desplegar

1. **Monitorea los logs**
   - Busca errores o comportamientos inusuales

2. **Configura alertas**
   - En Firebase Console > Alerting

3. **Revisa el uso**
   - Asegúrate de que no hay picos inusuales

## Recursos Adicionales

- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Cloud Functions Deployment](https://firebase.google.com/docs/functions/manage-functions)
- [Flutter Deployment](https://flutter.dev/docs/deployment)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

## Soporte

Si tienes problemas:

1. Revisa los logs: `firebase functions:log`
2. Consulta la documentación: [CLOUD_FUNCTIONS_GUIDE.md](./CLOUD_FUNCTIONS_GUIDE.md)
3. Revisa el código en: `/functions/src/index.ts`
