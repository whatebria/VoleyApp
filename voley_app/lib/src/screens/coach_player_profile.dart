import 'package:flutter/material.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/form_peak.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:voley_app/theme/app_theme.dart'; 

class CoachPlayerProfile extends StatelessWidget {
  final PlayerProfile profile;

  const CoachPlayerProfile({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Sección de Cabecera ---
          _buildHeader(context),
          const SizedBox(height: 24),

          // --- Sección de Biometría ---
          _buildBiometrics(context),
          const SizedBox(height: 16),

          // --- Sección de Objetivos ---
          _buildListCard(
            context: context,
            title: 'Objetivos',
            items: profile.goals,
            icon: Icons.flag_circle_outlined,
            iconColor: theme.colorScheme.primary, // voltNeon
          ),
          const SizedBox(height: 16),

          // --- Sección de Lesiones ---
          _buildListCard(
            context: context,
            title: 'Historial de Lesiones',
            items: profile.injuries,
            icon: Icons.healing_outlined,
            iconColor: theme.colorScheme.error, // errorRed
          ),
          const SizedBox(height: 16),

          // --- Sección de Equipamiento ---
          _buildListCard(
            context: context,
            title: 'Equipamiento Disponible',
            items: profile.equipment,
            icon: Icons.fitness_center_outlined,
            iconColor: theme.colorScheme.secondary, // azulPro
          ),
          const SizedBox(height: 16),

          // --- Sección de Disponibilidad ---
          _buildAvailabilityCard(context, profile.availability),
          const SizedBox(height: 16),

          // --- Sección de Evaluación ---
          _buildEvaluationCard(context, profile.evaluation),
          const SizedBox(height: 16),

          // --- Sección de Torneos ---
          _buildTournamentsCard(context, profile.tournaments),
          const SizedBox(height: 16),

          // --- Sección de Eventos Clave ---
          _buildKeyEventsCard(context, profile.keyEvents),
          const SizedBox(height: 16),

          // --- Sección de Picos de Forma ---
          _buildFormPeaksCard(context, profile.formPeaks),
        ],
      ),
    );
  }

  /// Widget de cabecera con Posición y Nivel
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      // Usamos el color de superficie (grisPro)
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.person_outline,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.position,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary, // voltNeon
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  profile.level.toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para la cuadrícula de Biometría
  Widget _buildBiometrics(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              context,
              'Datos Biométricos',
              Icons.bar_chart_outlined,
              theme.colorScheme.secondary, // azulPro
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _buildStatItem(
                    context, 'Edad', profile.age?.toString() ?? 'N/A'),
                _buildStatItem(
                    context, 'Peso', '${profile.weightKg?.toString() ?? 'N/A'} kg'),
                _buildStatItem(
                    context, 'Altura', '${profile.heightCm?.toString() ?? 'N/A'} cm'),
                _buildStatItem(context, 'Envergadura',
                    '${profile.wingspanCm?.toString() ?? 'N/A'} cm'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Un solo item de estadística (p.ej. "Edad", "25")
  Widget _buildStatItem(BuildContext context, String title, String value) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Tarjeta genérica para mostrar una lista de strings (Objetivos, Lesiones, etc.)
  Widget _buildListCard({
    required BuildContext context,
    required String title,
    required List<String> items,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, title, icon, iconColor),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                'No hay datos registrados.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                            color: iconColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(item, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Título de sección reutilizable
  Widget _buildSectionTitle(
      BuildContext context, String title, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // --- PLACEHOLDERS PARA OBJETOS COMPLEJOS ---
  // Implementa estos widgets cuando tengas los sub-modelos listos.

  Widget _buildAvailabilityCard(
      BuildContext context, Availability availability) {
    final theme = Theme.of(context);
    // TODO: Implementar la vista para Availability
    // Por ahora, solo muestra un placeholder
    return Card(
      child: ListTile(
        leading: Icon(Icons.event_available_outlined,
            color: theme.colorScheme.secondary),
        title: const Text('Disponibilidad'),
        subtitle: Text('ID de Disponibilidad: ...${availability.hashCode.toString().substring(0, 4)}', // Ejemplo
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navegar a una pantalla de detalle de disponibilidad si se desea
        },
      ),
    );
  }

  Widget _buildEvaluationCard(
      BuildContext context, EvaluationResult evaluation) {
    final theme = Theme.of(context);
    // TODO: Implementar la vista para EvaluationResult
    // p.ej. Mostrar evaluation.verticalJump, evaluation.strength, etc.
    return Card(
      child: ListTile(
        leading: Icon(Icons.assignment_turned_in_outlined,
            color: theme.colorScheme.primary),
        title: const Text('Resultados de Evaluación'),
        subtitle: Text(
            'Ver detalles de la evaluación...',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navegar a la pantalla de detalle de NewEvaluationScreen o similar
        },
      ),
    );
  }

  Widget _buildTournamentsCard(
      BuildContext context, List<Tournament> tournaments) {
    final theme = Theme.of(context);
    // TODO: Implementar la vista para la lista de Torneos
    return Card(
      child: ListTile(
        leading: Icon(Icons.emoji_events_outlined,
            color: theme.colorScheme.secondary),
        title: const Text('Torneos'),
        subtitle: Text(
            tournaments.isEmpty
                ? 'No hay torneos registrados.'
                : '${tournaments.length} torneos registrados.',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navegar a una pantalla que muestre la lista de torneos
        },
      ),
    );
  }

  Widget _buildKeyEventsCard(
      BuildContext context, List<PlayerEvent> keyEvents) {
    final theme = Theme.of(context);
    // TODO: Implementar la vista para la lista de Eventos Clave
    return Card(
      child: ListTile(
        leading: Icon(Icons.calendar_month,
            color: theme.colorScheme.secondary),
        title: const Text('Eventos Clave'),
        subtitle: Text(
            keyEvents.isEmpty
                ? 'No hay eventos registrados.'
                : '${keyEvents.length} eventos registrados.',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }

  Widget _buildFormPeaksCard(
      BuildContext context, List<FormPeak> formPeaks) {
    final theme = Theme.of(context);
    // TODO: Implementar la vista para la lista de Picos de Forma
    return Card(
      child: ListTile(
        leading: Icon(Icons.trending_up_outlined,
            color: theme.colorScheme.secondary),
        title: const Text('Picos de Forma'),
        subtitle: Text(
            formPeaks.isEmpty
                ? 'No hay picos registrados.'
                : '${formPeaks.length} picos registrados.',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
