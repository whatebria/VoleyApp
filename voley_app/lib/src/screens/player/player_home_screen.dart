// lib/src/screens/player_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voley_app/src/screens/player/player_calendar_screen.dart';
import 'package:voley_app/src/screens/player/config/player_profile_screen.dart';
import 'package:voley_app/src/screens/player/progress_dashboard_screen.dart';

class PlayerHomeScreen extends ConsumerStatefulWidget {
  const PlayerHomeScreen({Key? key}) : super(key: key);

  @override
  _PlayerHomeScreenState createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends ConsumerState<PlayerHomeScreen> {
  int _selectedIndex = 0;

  // 1. Lista de widgets actualizada con la pantalla de Progreso
  static const List<Widget> _widgetOptions = <Widget>[
    PlayerCalendarScreen(), // Pestaña 0
    ProgressDashboardScreen(), // Pestaña 1 (¡NUEVA!)
    PlayerProfileScreen(), // Pestaña 2s
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // (AppBar eliminado, como acordamos, para que cada hijo lo maneje)
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: const <Widget>[
          // Pestaña 0: Programa
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Programa',
          ),

          // --- Pestaña 1 (NUEVA): Progreso ---
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined), // Icono de gráfico
            selectedIcon: Icon(Icons.show_chart),
            label: 'Progreso',
          ),

          // Pestaña 2: Perfil
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
