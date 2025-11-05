import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:voley_app/src/auth/login_screen.dart';
import 'package:voley_app/src/auth/register_screen.dart';
import 'package:voley_app/src/auth/root_screen.dart';
import 'package:voley_app/src/screens/create_player_screen.dart';
import 'package:voley_app/src/screens/exercise_library_screen.dart';
import 'package:voley_app/src/screens/generate_program_screen.dart';
import 'package:voley_app/src/screens/player/config/add_tournament_screen.dart';
import 'package:voley_app/src/screens/player/config/edit_availability_screen.dart';
import 'package:voley_app/src/screens/player/config/edit_basic_info_screen.dart';
import 'package:voley_app/src/screens/player/config/edit_goals_screen.dart';
import 'package:voley_app/src/screens/player/config/edit_key_events_screen.dart';
import 'package:voley_app/src/screens/player/config/edit_tournaments_screen.dart';
import 'package:voley_app/src/screens/player/new_evaluation_screen.dart';
import 'package:voley_app/src/screens/permissions/permission_management_screen.dart';
import 'package:voley_app/src/screens/player/player_evaluation_screen.dart';
import 'package:voley_app/src/screens/player/player_link_code_screen.dart';
import 'package:voley_app/src/screens/player/config/profile_settings_screen.dart';
import 'package:voley_app/src/screens/program_view/program_explorer_screen.dart';
import 'package:voley_app/src/screens/user_management_screen.dart';
import 'package:voley_app/theme/app_theme.dart'; // Asegúrate de tener esta dependencia

void main() async {
  // 1. Asegura que el binding esté inicializado para llamar a métodos nativos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. [CORRECCIÓN CRÍTICA] Inicializa Firebase de forma asíncrona
  try {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform, // Descomentar si usas FlutterFire CLI
    );
  } catch (e) {
    // Manejo de errores de inicialización (ej: logs)
    print("Error al inicializar Firebase: $e");
  }

  // 3. Lanza la aplicación solo después de que Firebase esté listo
  runApp(const ProviderScope(child: MyApp()));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voley App',
      home: const RootScreen(),
      theme: AppTheme.voltProTheme,

      routes: {
        '/login': (c) => const LoginScreen(),
        '/register': (c) => const RegisterScreen(),
        '/evaluation': (c) => NewEvaluationScreen(),
        '/player_evaluation': (c) => PlayerEvaluationScreen(),
        '/generate': (c) => GenerateProgramScreen(),
        '/program': (c) => ProgramExplorerScreen(),
        '/permiso': (c) => PermissionManagementScreen(),
        '/user_create': (c) => CreatePlayerScreen(),
        '/user_management': (c) => UserManagementScreen(),
        '/player_link_code': (c) => const PlayerLinkCodeScreen(),
        '/library': (c) => const ExerciseLibraryScreen(),
        '/profile_settings': (c) => const ProfileSettingsScreen(),
        '/edit_basic_info': (context) => const EditBasicInfoScreen(),
        '/edit_availability': (context) => const EditAvailabilityScreen(),
        '/edit_goals': (context) => const EditGoalsScreen(),
        '/edit_key_events': (context) => const EditKeyEventsScreen(),
        '/edit_tournaments': (context) => const EditTournamentsScreen(),
        '/profile_settings/tournaments': (context) => AddTournamentScreen()
      },
    );
  }
}
