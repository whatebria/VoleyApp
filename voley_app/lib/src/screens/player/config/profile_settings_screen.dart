// lib/screens/profile_settings_screen.dart
import 'package:flutter/material.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Perfil'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text('Evaluación y Métricas'),
          ),
          ListTile(
            leading: const Icon(Icons.assessment_outlined),
            title: const Text('Mi Evaluación Física'),
            subtitle: const Text('Actualizar mis tests y métricas'),
            onTap: () {
              // Apunta a la pantalla real
              Navigator.pushNamed(context, '/player_evaluation');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Información Básica'),
            subtitle: const Text('Nombre, posición, nivel, etc.'),
            onTap: () {
              // Apunta a la pantalla real
              Navigator.pushNamed(context, '/edit_basic_info');
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text('Planificación'),
          ),
          ListTile(
            leading: const Icon(Icons.track_changes_outlined),
            title: const Text('Mis Objetivos'),
            onTap: () {
              // Apunta a la pantalla real
              Navigator.pushNamed(context, '/edit_goals');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Disponibilidad y Estado'),
            subtitle: const Text('Días de entreno, lesiones'),
            onTap: () {
              // Apunta a la pantalla real
              Navigator.pushNamed(context, '/edit_availability');
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Fechas Clave'),
            onTap: () {
              // Apunta a la pantalla real
              Navigator.pushNamed(context, '/edit_key_events');
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text('Historial'),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Historial de Torneos'),
            onTap: () {
              // Apunta a la pantalla real
              Navigator.pushNamed(context, '/edit_tournaments');
            },
          ),
        ],
      ),
    );
  }
}