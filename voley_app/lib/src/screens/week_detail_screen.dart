import 'package:flutter/material.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/program/microcicle.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/screens/edit_session_screen.dart'; // Importa la pantalla de edición

/// Muestra las Sesiones (Cards) de un Microciclo (Semana)
class WeekDetailScreen extends StatelessWidget {
  final Microcycle microcycle;
  final PlayerProfile profile;

  const WeekDetailScreen({
    super.key, 
    required this.microcycle,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Semana ${microcycle.weekNumber}'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: microcycle.sessions.length,
        itemBuilder: (context, index) {
          final session = microcycle.sessions[index];
          return _buildSessionCard(context, theme, session, profile);
        },
      ),
    );
  }

  /// Construye la Card para una Sesión (TrainingSession)
  Widget _buildSessionCard(
    BuildContext context, 
    ThemeData theme, 
    TrainingSession session,
    PlayerProfile profile,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: theme.colorScheme.surface, // grisPro
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
          child: Icon(Icons.fitness_center, color: theme.colorScheme.secondary),
        ),
        title: Text(
          session.day,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${session.exercises.length} ejercicios • Carga: ${session.load}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7)
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navega a la pantalla de EDICIÓN de la sesión
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditSessionScreen(
                session: session,
                profile: profile,
              ),
            ),
          );
        },
      ),
    );
  }
}
