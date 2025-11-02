// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/firebase_options.dart';
import 'package:voley_app/src/auth/auth_wrapper.dart';
import 'package:voley_app/src/auth/login_screen.dart';
import 'package:voley_app/src/auth/register_screen.dart';
import 'package:voley_app/src/screens/create_player_screen.dart';
import 'package:voley_app/src/screens/exercise_library_screen.dart';
import 'package:voley_app/src/screens/generate_program_screen.dart';
import 'package:voley_app/src/screens/new_evaluation_screen.dart';
import 'package:voley_app/src/screens/permissions/permission_management_screen.dart';
import 'package:voley_app/src/screens/program_view_screen.dart';
import 'package:voley_app/src/screens/user_management_screen.dart';
import 'package:voley_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voley App',
      home: const AuthWrapper(),
      theme: AppTheme.voltProTheme,
      
      routes: {
        '/login': (c) => const LoginScreen(),
        '/register': (c) => const RegisterScreen(),
        '/evaluation': (c) => NewEvaluationScreen(),
        '/generate': (c) => GenerateProgramScreen(),
        '/program': (c) => ProgramViewScreen(),
        '/permiso': (c) => PermissionManagementScreen(),
        '/user_create': (c) => CreatePlayerScreen(),
        '/user_management': (c) => UserManagementScreen(),
        '/library': (c) => const ExerciseLibraryScreen(),
      },
    );
  }
}