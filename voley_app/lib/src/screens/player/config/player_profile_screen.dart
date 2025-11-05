// lib/screens/player_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/providers/providers.dart'; // Asegúrate que esta ruta sea correcta
import 'package:intl/intl.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart'; // (Usando mock)
import 'package:voley_app/src/models/player_profile/player_event.dart'; // (Usando mock)
import 'package:voley_app/src/models/player_profile/form_peak.dart'; // (Usando mock)

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileProvider);
    final theme = Theme.of(context);

    // El manejo de estados .when() se mantiene, es una excelente práctica.
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
        if (profile == null) {
          return _buildEmptyState(context, theme);
        } else {
          // REFACTOR: Pasamos al nuevo _buildProfileView con pestañas
          return _buildProfileView(context, theme, profile);
        }
      },
    );
  }

  // --- 1. VISTA PRINCIPAL (AHORA UN HUB CON PESTAÑAS) ---

  /// REFACTORIZADO: Ahora usa TabBar para segmentar la información.
  Widget _buildProfileView(
      BuildContext context, ThemeData theme, PlayerProfile profile) {
    // Asumimos que el perfil tiene una propiedad para saber si está vinculado.
    // Si no la tiene, puedes chequear si `profile.coachId` es nulo, etc.
    final bool isLinkedToCoach = profile.assignedCoachId != null;

    return DefaultTabController(
      length: 3, // 3 Pestañas: Resumen, Planificación, Historial
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil de Atleta'),
          actions: [
            // ACCIÓN 1: Vínculo (menos intrusivo)
            if (!isLinkedToCoach)
              IconButton(
                icon: const Icon(Icons.link),
                tooltip: 'Conectar con entrenador',
                onPressed: () {
                  Navigator.pushNamed(context, '/player_link_code');
                },
              ),
            // ACCIÓN 2: Configuración (El nuevo "Editar")
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Gestionar mi perfil',
              onPressed: () {
                // Navega al NUEVO hub de configuración
                Navigator.pushNamed(context, '/profile_settings');
              },
            ),
          ],
          // NUEVO: TabBar para organizar el contenido
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'Resumen'),
              Tab(icon: Icon(Icons.flag_outlined), text: 'Planificación'),
              Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Historial'),
            ],
          ),
        ),
        // NUEVO: TabBarView para mostrar el contenido de cada pestaña
        body: TabBarView(
          children: [
            // Pestaña 1: Resumen (Quién soy y Mis Números)
            _buildOverviewTab(context, theme, profile, isLinkedToCoach),
            // Pestaña 2: Planificación (Futuro: Objetivos, Estado, Fechas)
            _buildPlanningTab(context, theme, profile),
            // Pestaña 3: Historial (Pasado: Logros y Torneos)
            _buildHistoryTab(context, theme, profile),
          ],
        ),
        // ELIMINADO: FloatingActionButton (reemplazado por el AppBar)
      ),
    );
  }

  // --- 2. PESTAÑAS INDIVIDUALES ---

  /// Pestaña 1: RESUMEN (Quién soy, métricas clave, prompt de coach)
  Widget _buildOverviewTab(BuildContext context, ThemeData theme,
      PlayerProfile profile, bool isLinkedToCoach) {
    // Lógica de métricas (movida aquí desde el widget principal)
    final keyStats = profile.evaluation.testScores;
    final physicalMetrics = <MapEntry<String, String>>[];
    if (profile.age != null) {
      physicalMetrics.add(MapEntry('Edad', '${profile.age} años'));
    }
    if (profile.heightCm != null) {
      physicalMetrics
          .add(MapEntry('Altura', '${_formatNumber(profile.heightCm!)} cm'));
    }
    if (profile.weightKg != null) {
      physicalMetrics
          .add(MapEntry('Peso', '${_formatNumber(profile.weightKg!)} kg'));
    }
    if (profile.wingspanCm != null) {
      physicalMetrics.add(
          MapEntry('Envergadura', '${_formatNumber(profile.wingspanCm!)} cm'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
      children: [
        // Tarjeta "Héroe" (Avatar, Nombre, Posición)
        _buildHeroCard(theme, profile),
        const SizedBox(height: 24),

        // Sección "Estadísticas Clave"
        _buildKeyStatsSection(
            context, theme, physicalMetrics, keyStats.entries.toList()),
        const SizedBox(height: 24),

        // REFACTORIZADO: El prompt de "Vincular Coach" ahora está al final
        // de la pestaña principal y solo si NO está vinculado.
        if (!isLinkedToCoach) _buildLinkCoachPrompt(context, theme),
      ],
    );
  }

  /// Pestaña 2: PLANIFICACIÓN (Objetivos, Estado, Fechas, Picos)
  Widget _buildPlanningTab(
      BuildContext context, ThemeData theme, PlayerProfile profile) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
      children: [
        // --- Objetivos personales ---
        Text(
          'Objetivos',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Divider(height: 16),
        if (profile.goals.isEmpty)
          // NUEVO: Estado vacío accionable
          _buildEmptySection(
            theme: theme,
            icon: Icons.track_changes_outlined,
            message: 'Define objetivos para personalizar tu progreso.',
            buttonText: 'Añadir Objetivos',
            onPressed: () {
              Navigator.pushNamed(context, '/profile_settings/goals');
            },
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: profile.goals
                .map((goal) => _buildGoalRow(theme, goal))
                .toList(),
          ),
        const SizedBox(height: 24),

        // --- Estado Actual (Logística) ---
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

        // --- Fechas Clave ---
        if (profile.keyEvents.isNotEmpty) ...[
          Text(
            'Fechas Clave',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 16),
          ...profile.keyEvents.map(
            (PlayerEvent event) => ListTile(
              leading: Icon(Icons.flag_outlined, color: theme.colorScheme.secondary),
              title: Text(
                '${_eventLabel(event.type)} - ${DateFormat('dd/MM/yyyy').format(event.date)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle:
                  event.description != null ? Text(event.description!) : null,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // --- Picos de Forma ---
        if (profile.formPeaks.isNotEmpty) ...[
          Text(
            'Picos de Forma Planificados',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
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
      ],
    );
  }

  /// Pestaña 3: HISTORIAL (Torneos y Logros)
  Widget _buildHistoryTab(
      BuildContext context, ThemeData theme, PlayerProfile profile) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
      children: [
        // --- Historial de Torneos ---
        Text(
          'Historial de Torneos',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Divider(height: 16),
        if (profile.tournaments.isEmpty)
          // NUEVO: Estado vacío accionable
          _buildEmptySection(
            theme: theme,
            icon: Icons.emoji_events_outlined,
            message: 'Registra tus torneos pasados para ver tu progreso.',
            buttonText: 'Añadir Torneo',
            onPressed: () {
              Navigator.pushNamed(context, '/edit_tournaments');
            },
          )
        else
          ...profile.tournaments.map(
            (t) => ListTile(
              leading: Icon(Icons.emoji_events_outlined,
                  color: theme.colorScheme.secondary),
              title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date)),
            ),
          ),
      ],
    );
  }

  // --- 3. WIDGETS REUTILIZABLES (Componentes de UI) ---

  /// NUEVO: Estado vacío genérico con un CTA.
  Widget _buildEmptySection({
    required ThemeData theme,
    required IconData icon,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: Text(buttonText),
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }

  /// (Sin cambios) Estado vacío para cuando el perfil NO existe.
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
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.textTheme.bodySmall?.color),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Completar Evaluación'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  /// REFACTORIZADO: Extraído a su propio widget para limpieza.
  Widget _buildHeroCard(ThemeData theme, PlayerProfile profile) {
    return Card(
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
                profile.name.isNotEmpty
                    ? profile.name.substring(0, 2).toUpperCase()
                    : '??',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.name,
              style:
                  theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }

  /// REFACTORIZADO: Extraído a su propio widget para limpieza.
  Widget _buildKeyStatsSection(
      BuildContext context,
      ThemeData theme,
      List<MapEntry<String, String>> physicalMetrics,
      List<MapEntry<String, double>> keyStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                'Completa tu evaluación para ver tus métricas.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.textTheme.bodySmall?.color),
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
                      width: MediaQuery.of(context).size.width < 360
                          ? double.infinity
                          : 160,
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
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: keyStats.map((test) {
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
      ],
    );
  }

  /// (Sin cambios) Prompt para vincular, ahora llamado desde la Pestaña 1.
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
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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

  /// (Sin cambios) Tarjeta de Estadística para el Grid.
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
  
  /// (Sin cambios) Fila de Información (Lesiones, Disponibilidad).
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
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
          ),
        ],
      ),
    );
  }

  /// (Sin cambios) Fila para un objetivo.
  Widget _buildGoalRow(ThemeData theme, String goal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              goal,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. FUNCIONES DE FORMATO (Helpers) ---
  
  /// (Sin cambios) Helper para etiquetas de eventos.
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

  /// (Sin cambios) Helper para formatear números.
  String _formatNumber(double value) {
    final isInt = value % 1 == 0;
    return isInt ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}