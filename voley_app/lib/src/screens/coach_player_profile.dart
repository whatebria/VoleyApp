import 'package:flutter/material.dart';
import 'package:voley_app/src/models/player_profile/injury.dart';
import 'package:voley_app/src/models/player_profile/test_score.dart';
import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/form_peak.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:intl/intl.dart'; // Para formateo de fechas

// --- CAMBIO ---
// Renombrado de 'CoachPlayerProfile' a 'CoachPlayerProfile' para
// coincidir con la pantalla que 'user_management_screen.dart' espera.
class CoachPlayerProfile extends StatelessWidget {
  final PlayerProfile profile;

  const CoachPlayerProfile({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- CAMBIO: Lógica de lesiones movida aquí ---
    final activeInjuries = profile.injuries
        .where((i) => i.status == InjuryStatus.active)
        .map((i) => i.description)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(profile.name)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Sección de Cabecera ---
          _buildHeader(context, theme),
          const SizedBox(height: 24),

          // --- CAMBIO: Botones de Acción ---
          _buildActionButtons(context, theme),
          const SizedBox(height: 24),

          // --- Sección de Biometría ---
          _buildBiometrics(context, theme),
          const SizedBox(height: 16),

          // --- Sección de Objetivos ---
          // --- CAMBIO: Mapea la List<Goal> a List<String> ---
          _buildListCard(
            context: context,
            title: 'Objetivos',
            items: profile.goals.map((g) => g.description).toList(),
            icon: Icons.flag_circle_outlined,
            iconColor: theme.colorScheme.primary, // voltNeon
          ),
          const SizedBox(height: 16),

          // --- Sección de Lesiones ---
          // --- CAMBIO: Mapea la List<Injury> a List<String> (solo activas) ---
          _buildListCard(
            context: context,
            title: 'Historial de Lesiones (Activas)',
            items: activeInjuries,
            icon: Icons.healing_outlined,
            iconColor: theme.colorScheme.error, // errorRed
          ),
          const SizedBox(height: 16),

          // --- Sección de Equipamiento ---
          _buildListCard(
            context: context,
            title: 'Equipamiento Disponible',
            items: profile.equipmentIds,
            icon: Icons.fitness_center_outlined,
            iconColor: theme.colorScheme.secondary, // azulPro
          ),
          const SizedBox(height: 16),

          // --- Sección de Disponibilidad ---
          // --- CAMBIO: Usa la data real ---
          _buildAvailabilityCard(context, theme, profile.availability),
          const SizedBox(height: 16),

          // --- Sección de Evaluación ---
          // --- CAMBIO: Pasa la evaluación MÁS RECIENTE ---
          _buildEvaluationCard(context, theme, profile.latestEvaluation),
          const SizedBox(height: 16),

          // --- Sección de Torneos ---
          _buildTournamentsCard(context, theme, profile.tournaments),
          const SizedBox(height: 16),

          // --- Sección de Eventos Clave ---
          _buildKeyEventsCard(context, theme, profile.keyEvents),
          const SizedBox(height: 16),

          // --- Sección de Picos de Forma ---
          _buildFormPeaksCard(context, theme, profile.formPeaks),
        ],
      ),
    );
  }

  /// Widget de cabecera con Posición y Nivel
  Widget _buildHeader(BuildContext context, ThemeData theme) {
    String _enumLabel(Enum e) => e.name[0].toUpperCase() + e.name.substring(1);
    return Card(
      // Usamos el color de superficie (grisPro)
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _enumLabel(profile.position),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              _enumLabel(profile.level).toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CAMBIO: Nuevo Widget para los botones ---
  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Botón 1: Ver/Editar Evaluación
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: theme.colorScheme.secondary, // azulPro
            foregroundColor: theme.colorScheme.onSecondary, // blancoNeutro
          ),
          icon: const Icon(Icons.assessment_outlined),
          label: const Text('Ver/Editar Evaluación'),
          onPressed: () {
            // Navega a la pantalla de evaluación.
            // Esta pantalla debe leer 'explorerSelectedPlayerProvider'
            // que ya fue asignado en la pantalla anterior.
            Navigator.pushNamed(context, '/evaluation');
          },
        ),
        const SizedBox(height: 12),
        // Botón 2: Ver/Crear Programas
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            // Este usará el estilo primario (voltNeon) por defecto
          ),
          icon: const Icon(Icons.list_alt_outlined),
          label: const Text('Ver/Crear Programas'),
          onPressed: () {
            // Navega al hub de programas.
            // Esta pantalla leerá 'explorerSelectedPlayerProvider'
            // y mostrará los programas de este jugador.
            Navigator.pushNamed(context, '/program');
          },
        ),
      ],
    );
  }

  /// Widget para la cuadrícula de Biometría
  Widget _buildBiometrics(BuildContext context, ThemeData theme) {
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
                  context,
                  theme,
                  'Edad',
                  profile.age?.toString() ?? 'N/A',
                ),
                _buildStatItem(
                  context,
                  theme,
                  'Peso',
                  '${profile.weightKg?.toString() ?? 'N/A'} kg',
                ),
                _buildStatItem(
                  context,
                  theme,
                  'Altura',
                  '${profile.heightCm?.toString() ?? 'N/A'} cm',
                ),
                _buildStatItem(
                  context,
                  theme,
                  'Envergadura',
                  '${profile.wingspanCm?.toString() ?? 'N/A'} cm',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Un solo item de estadística (p.ej. "Edad", "25")
  Widget _buildStatItem(
    BuildContext context,
    ThemeData theme,
    String title,
    String value,
  ) {
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
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
                          fontWeight: FontWeight.bold,
                        ),
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
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
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

  // --- CAMBIO: Widget actualizado (ya no es un placeholder) ---
  Widget _buildAvailabilityCard(
    BuildContext context,
    ThemeData theme,
    Availability availability,
  ) {
    final days = availability.trainingDays.isEmpty
        ? 'No especificado'
        : availability.trainingDays.join(', ');

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.event_available_outlined,
          color: theme.colorScheme.secondary,
        ),
        title: const Text('Disponibilidad'),
        subtitle: Text(
          '$days • ${availability.sessionMinutes} min/sesión',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Navegar a la pantalla de edición de disponibilidad
        },
      ),
    );
  }

  // --- CAMBIO: Widget actualizado (ya no es un placeholder) ---
  Widget _buildEvaluationCard(
    BuildContext context,
    ThemeData theme,
    EvaluationResult? evaluation,
  ) {
    final scores = evaluation?.testScores ?? [];

    return Card(
      child: ExpansionTile(
        leading: Icon(
          Icons.assignment_turned_in_outlined,
          color: theme.colorScheme.primary,
        ),
        title: const Text('Resultados de Evaluación'),
        subtitle: Text(
          scores.isEmpty
              ? 'Sin tests registrados'
              : 'Última evaluación: ${DateFormat('dd/MM/yy').format(evaluation!.date)}',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        trailing: Icon(Icons.expand_more, color: theme.colorScheme.primary),
        children: [
          if (scores.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No hay tests registrados en esta evaluación.',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
          else
            ...scores.map((TestScore test) {
              return ListTile(
                title: Text(
                  _formatTestId(
                    test.testId,
                  ), // Formatea 'salto_vertical' a 'Salto Vertical'
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '${test.value.toStringAsFixed(1)} ${test.unit}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
              );
            }),
          // Botón para ir a la pantalla de evaluación
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton.icon(
              icon: const Icon(Icons.edit_note),
              label: const Text('Ver historial o añadir nueva'),
              onPressed: () {
                Navigator.pushNamed(context, '/evaluation');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentsCard(
    BuildContext context,
    ThemeData theme,
    List<Tournament> tournaments,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.emoji_events_outlined,
          color: theme.colorScheme.secondary,
        ),
        title: const Text('Torneos'),
        subtitle: Text(
          tournaments.isEmpty
              ? 'No hay torneos registrados.'
              : '${tournaments.length} torneos registrados.',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navegar a una pantalla que muestre la lista de torneos
        },
      ),
    );
  }

  Widget _buildKeyEventsCard(
    BuildContext context,
    ThemeData theme,
    List<PlayerEvent> keyEvents,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.calendar_month, // Corregido (no existe calendar_star_outlined)
          color: theme.colorScheme.secondary,
        ),
        title: const Text('Eventos Clave'),
        subtitle: Text(
          keyEvents.isEmpty
              ? 'No hay eventos registrados.'
              : '${keyEvents.length} eventos registrados.',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildFormPeaksCard(
    BuildContext context,
    ThemeData theme,
    List<FormPeak> formPeaks,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.trending_up_outlined,
          color: theme.colorScheme.secondary,
        ),
        title: const Text('Picos de Forma'),
        subtitle: Text(
          formPeaks.isEmpty
              ? 'No hay picos registrados.'
              : '${formPeaks.length} picos registrados.',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  // --- AÑADIDO: Helper para formatear IDs de tests ---
  String _formatTestId(String testId) {
    if (testId.isEmpty) return 'Test';
    // Convierte 'salto_vertical' en 'Salto Vertical'
    return testId
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // --- AÑADIDO: Helper para formatear números ---
  String _formatNumber(double value) {
    final isInt = value % 1 == 0;
    return isInt ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  // --- AÑADIDO: Helper para etiquetas de eventos ---
  String _eventLabel(String type) {
    switch (type) {
      case 'cup':
        return 'Copa';
      case 'playoff':
        return 'Play-offs';
      case 'national_team':
        return 'Selección';
      case 'travel':
        return 'Viaje';
      case 'league':
      default:
        return 'Liga';
    }
  }
}
