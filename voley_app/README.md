# 🏐 Voley App

Aplicación Flutter para la gestión y generación automática de programas de entrenamiento de voleibol.

## 🚀 Características

- **Generación Automática de Programas**: Utiliza Cloud Functions para crear programas personalizados
- **Gestión de Jugadores**: Sistema de perfiles con evaluaciones y objetivos
- **Sistema Coach-Jugador**: Permisos y gestión de relaciones entrenador-jugador
- **Programas Personalizados**: Basados en nivel, objetivos, lesiones y disponibilidad
- **Periodización Inteligente**: Mesociclos y microciclos adaptados a torneos

## 📋 Requisitos Previos

- Flutter SDK (3.9.0+)
- Node.js 22+
- Firebase CLI
- Cuenta de Firebase

## 🛠️ Instalación

### 1. Clonar el repositorio

```bash
git clone <repository-url>
cd voley_app
```

### 2. Instalar dependencias de Flutter

```bash
flutter pub get
```

### 3. Instalar dependencias de Cloud Functions

```bash
cd functions
npm install
cd ..
```

### 4. Configurar Firebase

```bash
firebase login
firebase use voleyapp-77661
```

### 5. Verificar la configuración

```bash
./verify_setup.sh
```

## 🔥 Cloud Functions

Este proyecto utiliza Firebase Cloud Functions para la generación de programas.

### Compilar las funciones

```bash
cd functions
npm run build
```

### Desplegar las funciones

```bash
firebase deploy --only functions
```

### Documentación completa

Ver [CLOUD_FUNCTIONS_GUIDE.md](./CLOUD_FUNCTIONS_GUIDE.md) para documentación detallada.

## 📱 Ejecutar la App

### Modo Debug

```bash
flutter run
```

### Build para Android

```bash
flutter build apk --release
```

### Build para iOS

```bash
flutter build ios --release
```

## 📚 Documentación

- [**CLOUD_FUNCTIONS_GUIDE.md**](./CLOUD_FUNCTIONS_GUIDE.md) - Guía completa de Cloud Functions
- [**DEPLOYMENT.md**](./DEPLOYMENT.md) - Guía de despliegue
- [**functions/README.md**](./functions/README.md) - Documentación de las funciones

## 🏗️ Estructura del Proyecto

```
voley_app/
├── lib/
│   ├── src/
│   │   ├── models/          # Modelos de datos
│   │   ├── screens/         # Pantallas de la app
│   │   ├── widgets/         # Widgets reutilizables
│   │   ├── services/        # Servicios (Firestore, etc.)
│   │   └── auth/            # Autenticación
│   ├── providers/           # Providers de Riverpod
│   └── main.dart
├── functions/
│   ├── src/
│   │   └── index.ts         # Cloud Functions
│   └── package.json
├── assets/
│   └── seeders/
│       └── exercises.json   # Datos de ejercicios
└── firebase.json
```

## 🔑 Funcionalidades Principales

### Generación de Programas

La app utiliza la Cloud Function `generateMyProgram` para crear programas personalizados:

```dart
final callable = FirebaseFunctions.instance.httpsCallable('generateMyProgram');
final result = await callable.call({'playerId': playerId});
```

### Sistema de Permisos

Los entrenadores pueden gestionar múltiples jugadores con un sistema de permisos:

- Solicitudes de permiso
- Aceptación/rechazo por parte del jugador
- Acceso a perfiles y programas

### Evaluación de Jugadores

Sistema completo de evaluación que incluye:

- Tests físicos
- Fortalezas y debilidades
- Objetivos personales
- Historial de lesiones
- Disponibilidad de entrenamiento

## 🧪 Testing

### Testing de Cloud Functions (Local)

```bash
cd functions
npm run serve
```

### Testing de Flutter

```bash
flutter test
```

## 📊 Monitoreo

### Ver logs de Cloud Functions

```bash
firebase functions:log
```

### Ver logs en tiempo real

```bash
firebase functions:log --only generateMyProgram
```

## 🔐 Seguridad

- Autenticación requerida para todas las operaciones
- Validación de permisos en Cloud Functions
- Reglas de Firestore configuradas
- Datos sensibles protegidos

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📝 Licencia

Este proyecto es privado y confidencial.

## 📞 Soporte

Para problemas o preguntas:

1. Revisa la documentación en `/docs`
2. Consulta los logs: `firebase functions:log`
3. Verifica la configuración: `./verify_setup.sh`

## 🎯 Roadmap

- [ ] Integración con wearables
- [ ] Análisis de video
- [ ] Estadísticas avanzadas
- [ ] Modo offline
- [ ] Notificaciones push
- [ ] Calendario integrado
- [ ] Exportación de programas a PDF

## 🙏 Agradecimientos

- Firebase por la infraestructura
- Flutter por el framework
- La comunidad de voleibol

---

**Proyecto:** voleyapp-77661  
**Versión:** 1.0.0+1  
**Última actualización:** Noviembre 2025
