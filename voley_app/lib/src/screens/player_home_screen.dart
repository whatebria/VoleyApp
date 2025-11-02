// lib/src/screens/player_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/screens/exercise_library_screen.dart';
import 'package:voley_app/src/screens/player_calendar_screen.dart';
import 'package:voley_app/src/screens/player_profile_screen.dart';

class PlayerHomeScreen extends ConsumerStatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  _PlayerHomeScreenState createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends ConsumerState<PlayerHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoadingProfile = true;

  // 1. Define las pantallas para tu navbar
  static const List<Widget> _widgetOptions = <Widget>[
    PlayerCalendarScreen(), // Pestaña 0
    ExerciseLibraryScreen(), // Pestaña 1
    PlayerProfileScreen(), 
  ];

  // 2. Define los títulos para la AppBar
  static const List<String> _widgetTitles = <String>[
    'Mi Programa',
    'Biblioteca de Ejercicios',
    'Mi Perfil'
  ];

  @override
  void initState() {
    super.initState();
    // 3. Carga el perfil del jugador en cuanto entra a la app
    //    Esto es crucial para que el calendario ('PlayerCalendarScreen')
    //    y el perfil ('EvaluationScreen') funcionen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlayerProfile();
    });
  }

  Future<void> _loadPlayerProfile() async {
    final authUser = ref.read(authStateProvider).value;
    if (authUser != null) {
      final firestore = ref.read(firestoreProvider);
      final profile = await firestore.getPlayerProfileByUserId(authUser.uid);
      if (profile != null) {
        // Carga el perfil en el provider que las otras pantallas escuchan
        ref.read(playerProfileProvider.notifier).state = profile;
      }
    }
    if (mounted) {
      setState(() { _isLoadingProfile = false; });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Muestra una carga inicial mientras se busca el perfil
    if (_isLoadingProfile) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
      // Muestra la pantalla seleccionada
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      // 4. La "Navbar" (BottomNavigationBar)
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