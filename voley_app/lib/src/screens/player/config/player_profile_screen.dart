import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/player_profile/goal.dart';
import 'package:voley_app/src/models/player_profile/injury.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';
import 'package:voley_app/src/models/player_profile/form_peak.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';

/// PlayerProfileScreen v2
///
/// Principales mejoras UI/UX y de producto:
/// - Estado de error con CTA de reintento.
/// - Pull-to-refresh en cada pestaña (sincroniza con Riverpod).
/// - KPI hero con acciones rápidas (conversión: evaluación, objetivo, lesión, coach).
/// - Progreso de objetivos (barra + %).
/// - Grid de tests responsive.
/// - Varios detalles de accesibilidad (Semantics), consts, y pequeñas animaciones.
class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileProvider);
    final theme = Theme.of(context);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'No pudimos cargar tu perfil',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Inténtalo nuevamente. Si el problema persiste, revisa tu conexión.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(playerProfileProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Detalles: $e',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      data: (profile) {
        if (profile == null) return _buildEmptyState(context, theme);
        return _buildProfileView(context, theme, profile, ref);
      },
    );
  }

  // --- HUB con pestañas y acciones globales ---
  Widget _buildProfileView(
    BuildContext context,
    ThemeData theme,
    PlayerProfile profile,
    WidgetRef ref,
  ) {
    final bool isLinkedToCoach = profile.assignedCoachId != null;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil de Atleta'),
          actions: [
            if (!isLinkedToCoach)
              IconButton(
                tooltip: 'Conectar con entrenador',
                icon: const Icon(Icons.link),
                onPressed: () => Navigator.pushNamed(context, '/player_link_code'),
              ),
            IconButton(
              tooltip: 'Gestionar mi perfil',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.pushNamed(context, '/profile_settings'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'Resumen'),
              Tab(icon: Icon(Icons.flag_outlined), text: 'Planificación'),
              Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Historial'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Refreshable(
              onRefresh: () async { ref.invalidate(playerProfileProvider); },
              child: _buildOverviewTab(context, theme, profile, ref),
            ),
            _Refreshable(
              onRefresh: () async { ref.invalidate(playerProfileProvider); },
              child: _buildPlanningTab(context, theme, profile),
            ),
            _Refreshable(
              onRefresh: () async { ref.invalidate(playerProfileProvider); },
              child: _buildHistoryTab(context, theme, profile),
            ),
          ],
        ),
      ),
    );
  }

  // --- Pestaña 1: RESUMEN ---
  Widget _buildOverviewTab(
    BuildContext context,
    ThemeData theme,
    PlayerProfile profile,
    WidgetRef ref,
  ) {
    final latestEval = profile.latestEvaluation;

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

    final completedGoals = profile.goals.where((g) => g.isCompleted).length;
    final totalGoals = profile.goals.length;
    final double goalsProgress = totalGoals == 0 ? 0 : completedGoals / totalGoals;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        _buildHeroCard(theme, profile),
        const SizedBox(height: 16),

        // Quick actions orientadas a conversión de valor
        _QuickActions(
          actions: [
            _QuickAction(
              icon: Icons.analytics_outlined,
              label: 'Nueva evaluación',
              onTap: () => Navigator.pushNamed(context, '/player_evaluation'),
            ),
            _QuickAction(
              icon: Icons.add_task_outlined,
              label: 'Añadir objetivo',
              onTap: () => Navigator.pushNamed(context, '/profile_settings/goals'),
            ),
            _QuickAction(
              icon: Icons.healing_outlined,
              label: 'Registrar lesión',
              onTap: () => Navigator.pushNamed(context, '/profile_settings/injuries'),
            ),
            _QuickAction(
              icon: Icons.share_outlined,
              label: 'Compartir perfil',
              onTap: () => Navigator.pushNamed(context, '/profile_share'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bloque: Progreso de objetivos
        _SectionHeader(theme: theme, title: 'Progreso de objetivos'),
        const SizedBox(height: 8),
        if (totalGoals == 0)
          _buildEmptySection(
            theme: theme,
            icon: Icons.track_changes_outlined,
            message: 'Define objetivos para visualizar tu progreso.',
            buttonText: 'Añadir objetivos',
            onPressed: () => Navigator.pushNamed(context, '/profile_settings/goals'),
          )
        else
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(value: goalsProgress),
                      ),
                      const SizedBox(width: 12),
                      Text('${(goalsProgress * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('$completedGoals de $totalGoals objetivos completados',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Bloque: Estadísticas clave
        _buildKeyStatsSection(context, theme, physicalMetrics, latestEval),

        const SizedBox(height: 24),
        if (profile.assignedCoachId == null) _buildLinkCoachPrompt(context, theme),
      ],
    );
  }

  // --- Pestaña 2: PLANIFICACIÓN ---
  Widget _buildPlanningTab(
    BuildContext context,
    ThemeData theme,
    PlayerProfile profile,
  ) {
    final activeInjuries = profile.injuries.where((i) => i.status == InjuryStatus.active).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        Text('Objetivos', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const Divider(height: 16),
        if (profile.goals.isEmpty)
          _buildEmptySection(
            theme: theme,
            icon: Icons.track_changes_outlined,
            message: 'Define objetivos para personalizar tu progreso.',
            buttonText: 'Añadir objetivos',
            onPressed: () => Navigator.pushNamed(context, '/profile_settings/goals'),
          )
        else
          Column(
            children: profile.goals.map((goal) => _buildGoalRow(theme, goal)).toList(),
          ),
        const SizedBox(height: 24),

        Text('Mi Estado', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const Divider(height: 16),
        _InfoRow(
          theme,
          icon: Icons.healing_outlined,
          title: 'Lesiones',
          value: activeInjuries.isEmpty ? 'Ninguna' : activeInjuries.map((i) => i.description).join(', '),
        ),
        _InfoRow(
          theme,
          icon: Icons.calendar_today_outlined,
          title: 'Días Disponibles',
          value: (profile.availability.trainingDays.isEmpty)
              ? 'No especificado'
              : profile.availability.trainingDays.join(', '),
        ),
        _InfoRow(
          theme,
          icon: Icons.timer_outlined,
          title: 'Duración de sesión',
          value: '${profile.availability.sessionMinutes} minutos',
        ),
        const SizedBox(height: 24),

        if (profile.keyEvents.isNotEmpty) ...[
          Text('Fechas clave', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 16),
          ...profile.keyEvents.map(
            (PlayerEvent event) => ListTile(
              leading: Icon(Icons.flag_outlined, color: theme.colorScheme.secondary),
              title: Text(
                '${_eventLabel(event.type)} • ${DateFormat('dd/MM/yyyy').format(event.date)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: event.description != null ? Text(event.description!) : null,
            ),
          ),
          const SizedBox(height: 24),
        ],

        if (profile.formPeaks.isNotEmpty) ...[
          Text('Picos de forma planificados', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: profile.formPeaks
                .map((FormPeak peak) => Chip(
                      label: Text(
                        '${DateFormat('dd/MM/yy').format(peak.date)}${peak.note != null ? ' • ${peak.note}' : ''}',
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  // --- Pestaña 3: HISTORIAL ---
  Widget _buildHistoryTab(
    BuildContext context,
    ThemeData theme,
    PlayerProfile profile,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        Text('Historial de Torneos', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const Divider(height: 16),
        if (profile.tournaments.isEmpty)
          _buildEmptySection(
            theme: theme,
            icon: Icons.emoji_events_outlined,
            message: 'Registra tus torneos pasados para ver tu progreso.',
            buttonText: 'Añadir torneo',
            onPressed: () => Navigator.pushNamed(context, '/profile_settings/tournaments'),
          )
        else
          ...profile.tournaments.map(
            (t) => ListTile(
              leading: Icon(Icons.emoji_events_outlined, color: theme.colorScheme.secondary),
              title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date)),
            ),
          ),
      ],
    );
  }

  // --- Componentes reutilizables ---

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assessment_outlined, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                '¡Tu viaje comienza ahora!',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Completa tu evaluación inicial para desbloquear tu perfil, descubrir tus estadísticas y recibir tu plan de entrenamiento.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodySmall?.color),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Completar evaluación'),
                onPressed: () => Navigator.pushNamed(context, '/player_evaluation'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('Vincular con mi entrenador'),
                onPressed: () => Navigator.pushNamed(context, '/player_link_code'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Estado vacío genérico con CTA reutilizable
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
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme, PlayerProfile profile) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                profile.name.isNotEmpty ? profile.name.substring(0, 2).toUpperCase() : '??',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${profile.position} • ${profile.level.isNotEmpty ? profile.level[0].toUpperCase() + profile.level.substring(1) : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyStatsSection(
    BuildContext context,
    ThemeData theme,
    List<MapEntry<String, String>> physicalMetrics,
    EvaluationResult? latestEval,
  ) {
    final testScores = latestEval?.testScores ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(theme: theme, title: 'Mis estadísticas clave'),
        const Divider(height: 16),
        if (physicalMetrics.isEmpty && testScores.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'Completa tu evaluación para ver tus métricas.',
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
          if (testScores.isNotEmpty) ...[
            Text('Tests físicos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 720
                    ? 3
                    : width >= 520
                        ? 2
                        : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.7,
                  ),
                  itemCount: testScores.length,
                  itemBuilder: (context, index) {
                    final test = testScores[index];
                    return _buildStatCard(
                      theme,
                      title: _formatTestId(test.testId),
                      value: test.value.toStringAsFixed(1),
                      unit: test.unit,
                    );
                  },
                );
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLinkCoachPrompt(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 1,
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
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sincroniza tus programas y recibe feedback directo. Mejora 3x más rápido.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/player_link_code'),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Abrir códigos'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required String title,
    required String value,
    String? unit,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
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
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
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
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _InfoRow(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
  }) {
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
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow(ThemeData theme, Goal goal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            goal.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
            color: goal.isCompleted ? theme.colorScheme.primary : theme.colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              goal.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                decoration: goal.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                color: goal.isCompleted ? theme.colorScheme.onSurface.withOpacity(0.5) : theme.colorScheme.onSurface,
              ),
            ),
          ),
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

  String _formatTestId(String testId) {
    if (testId.isEmpty) return 'Test';
    return testId
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

// --- Widgets auxiliares ---

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.theme, required this.title});
  final ThemeData theme;
  final String title;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _Refreshable extends StatelessWidget {
  const _Refreshable({required this.child, required this.onRefresh});
  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}

class _QuickAction {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.actions});
  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
            child: isWide
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: actions
                        .map((a) => _QuickActionButton(icon: a.icon, label: a.label, onTap: a.onTap))
                        .toList(),
                  )
                : Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 8,
                    runSpacing: 8,
                    children: actions
                        .map((a) => _QuickActionButton(icon: a.icon, label: a.label, onTap: a.onTap))
                        .toList(),
                  ),
          ),
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
