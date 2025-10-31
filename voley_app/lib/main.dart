// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:voley_app/src/screens/onboarding/evaluation_screen.dart';
import 'package:voley_app/src/screens/generate_program_screen.dart';
import 'package:voley_app/src/screens/program_view_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VolleyPro Trainer',
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: {
        '/': (c) => EvaluationScreen(),
        '/generate': (c) => GenerateProgramScreen(),
        '/program': (c) => ProgramViewScreen(),
      },
    );
  }
}
