// lib/src/screens/player_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';
import 'package:voley_app/src/models/player_profile/form_peak.dart';


class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [CORRECCIÓN]: Observamos el FutureProvider. El resultado es un AsyncValue.
    final profileAsync = ref.watch(playerProfileProvider);
    final theme = Theme.of(context);

    // Usamos .when() para manejar los tres estados: loading, error, y data
    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error al cargar el perfil. Intenta de nuevo. Detalles: $e',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (profile) {
        // 'profile' aquí es de tipo PlayerProfile?
        if (profile == null) {
          // Si el perfil es nulo (el jugador aún no lo ha creado)
          return _buildEmptyState(context, theme);
        } else {
          // Si el perfil SÍ existe, lo mostramos
          return _buildProfileView(context, theme, profile);
        }
      },
    );
  }

  // --- Widgets de Vista (Refactorizados para aceptar PlayerProfile) ---

  /// Muestra la vista detallada del perfil del jugador.
  Widget _buildProfileView(BuildContext context, ThemeData theme, PlayerProfile profile) {
    final keyStats = profile.evaluation.testScores;
    final physicalMetrics = <MapEntry<String, String>>[];
    if (profile.age != null) {
      physicalMetrics.add(MapEntry('Edad', '${profile.age} años'));
    }
    if (profile.heightCm != null) {
      physicalMetrics.add(MapEntry('Altura', '${_formatNumber(profile.heightCm!)} cm'));
    }
    if (profile.weightKg != null) {
      physicalMetrics.add(MapEntry('Peso', '${_formatNumber(profile.weightKg!)} kg'));
    }
    if (profile.wingspanCm != null) {
      physicalMetrics.add(MapEntry('Envergadura', '${_formatNumber(profile.wingspanCm!)} cm'));
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        tooltip: 'Editar Evaluación',
        onPressed: () {
          // El perfil existe, navegamos a la edición
          Navigator.pushNamed(context, '/player_evaluation');
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
        children: [
          _buildLinkCoachPrompt(context, theme),
          const SizedBox(height: 24),
          // --- 1. Tarjeta "Héroe" (Quién soy) ---
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      profile.name.isNotEmpty ? profile.name.substring(0, 2).toUpperCase() : '??',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.position} | ${profile.level.isNotEmpty ? profile.level[0].toUpperCase() + profile.level.substring(1) : ""}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.secondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- 2. Sección "Estadísticas Clave" (Mis números) ---
          Text(
            'Mis Estadísticas Clave',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 16),
          if (physicalMetrics.isEmpty && keyStats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'Aún no registras métricas o tests.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodySmall?.color),
                ),
              ),
            )
          else ...[
            if (physicalMetrics.isNotEmpty) ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: physicalMetrics
                    .map(
                      (metric) => SizedBox(
                        width: MediaQuery.of(context).size.width < 360 ? double.infinity : 160,
                        child: _buildStatCard(
                          theme,
                          title: metric.key,
                          value: metric.value,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (keyStats.isNotEmpty) ...[
              Text(
                'Tests físicos',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: keyStats.entries.map((test) {
                  return _buildStatCard(
                    theme,
                    title: test.key,
                    value: test.value.toStringAsFixed(1),
                    unit: 'pts',
                  );
                }).toList(),
              ),
            ],
          ],

          const SizedBox(height: 24),

          // --- Objetivos personales ---
          Text(
            'Objetivos',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 16),
          if (profile.goals.isEmpty)
            Text(
              'Define objetivos desde tu evaluación para personalizar tu progreso.',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodySmall?.color),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: profile.goals
                  .map(
                    (goal) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: theme.colorScheme.secondary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              goal,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),

          const SizedBox(height: 24),

          // --- 3. Sección "Estado Actual" (Mi logística) ---
          Text(
            'Mi Estado',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 16),
          _InfoRow(
            theme,
            icon: Icons.healing_outlined,
            title: 'Lesiones',
            value: profile.injuries.isEmpty ? 'Ninguna' : profile.injuries.join(', '),
          ),
          _InfoRow(
            theme,
            icon: Icons.calendar_today_outlined,
            title: 'Días Disponibles',
            value: profile.availability.trainingDays.isEmpty
                ? 'No especificado'
                : profile.availability.trainingDays.join(', '),
          ),
          _InfoRow(
            theme,
            icon: Icons.timer_outlined,
            title: 'Duración de Sesión',
            value: '${profile.availability.sessionMinutes} minutos',
          ),

          const SizedBox(height: 24),

          if (profile.keyEvents.isNotEmpty) ...[
            Text(
              'Fechas Clave',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            ...profile.keyEvents.map(
              (PlayerEvent event) => ListTile(
                leading: Icon(Icons.flag_outlined, color: theme.colorScheme.secondary),
                title: Text(
                  '${_eventLabel(event.type)} - ${DateFormat('dd/MM/yyyy').format(event.date)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: event.description != null ? Text(event.description!) : null,
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (profile.formPeaks.isNotEmpty) ...[
            Text(
              'Picos de Forma Planificados',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: profile.formPeaks
                  .map(
                    (FormPeak peak) => Chip(
                      label: Text(
                        '${DateFormat('dd/MM/yy').format(peak.date)}${peak.note != null ? ' • ${peak.note}' : ''}',
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // --- 4. Sección "Historial" (Mis logros) ---
          if (profile.tournaments.isNotEmpty) ...[
            Text(
              'Historial de Torneos',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            ...profile.tournaments.map(
              (t) => ListTile(
                leading: Icon(Icons.emoji_events_outlined, color: theme.colorScheme.secondary),
                title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date)),
              ),
            ),
          ],
        ],
      ),
    );
  }

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

  String _formatNumber(double value) {
    final isInt = value % 1 == 0;
    return isInt ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  /// Muestra el estado vacío (jugador sin perfil). (Sin cambios)
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assessment_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '¡Tu viaje comienza ahora!',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Completa tu evaluación inicial para desbloquear tu perfil, descubrir tus estadísticas y recibir tu plan de entrenamiento.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Completar Evaluación'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/player_evaluation');
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('Vincular con mi entrenador'),
                onPressed: () {
                  Navigator.pushNamed(context, '/player_link_code');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
Widget _buildLinkCoachPrompt(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Conecta con tu entrenador',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Comparte tu código o ingresa el de tu entrenador para sincronizar tus programas.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/player_link_code');
                },
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Abrir códigos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  /// Tarjeta de Estadística para el Grid (Sin cambios)
  Widget _buildStatCard(ThemeData theme,
      {required String title, required String value, String? unit}) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.8),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Fila de Información (Sin cambios)
  Widget _InfoRow(ThemeData theme,
      {required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}