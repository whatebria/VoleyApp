// lib/src/screens/player_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/auth_provider.dart';
// (Importa tus 3 pantallas de pestañas)
import 'package:voley_app/src/screens/player_calendar_screen.dart';
import 'package:voley_app/src/screens/exercise_library_screen.dart';
import 'package:voley_app/src/screens/player_profile_screen.dart';

// --- (CAMBIADO A ConsumerStatefulWidget) ---
class PlayerHomeScreen extends ConsumerStatefulWidget {
  const PlayerHomeScreen({Key? key}) : super(key: key);

  @override
  _PlayerHomeScreenState createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends ConsumerState<PlayerHomeScreen> {
  int _selectedIndex = 0;

  // 1. Define las pantallas para tu navbar
  static const List<Widget> _widgetOptions = <Widget>[
    PlayerCalendarScreen(),  // Pestaña 0
    ExerciseLibraryScreen(), // Pestaña 1
    PlayerProfileScreen(), // Pestaña 2
  ];

  // 2. Define los títulos para la AppBar
  static const List<String> _widgetTitles = <String>[
    'Mi Programa',
    'Biblioteca de Ejercicios',
    'Mi Perfil'
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 4. --- (Ya no hay '_isLoadingProfile') ---
    return Scaffold(
      appBar: AppBar(
        title: Text(_widgetTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ref.read(authServiceProvider).logout();
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Programa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Biblioteca',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}